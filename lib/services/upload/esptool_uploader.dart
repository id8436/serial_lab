/// ESP32/ESP8266 ROM bootloader flasher (SLIP protocol).
///
/// Reference: Espressif esptool protocol
/// https://docs.espressif.com/projects/esptool/en/latest/esp32/advanced-topics/serial-protocol.html
///
/// Supports: ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP8266.
///
/// Protocol overview:
/// - Communication uses SLIP framing (RFC 1055): 0xC0 = END, 0xDB = ESC
/// - Commands are 16-byte headers + payload, wrapped in SLIP frames
/// - Upload flow: sync → detect chip → SPI attach → change baud →
///   flash_begin → flash_data (1KB blocks) → flash_end
/// - Chip detection via magic register at 0x40001000
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
///
/// ROM bootloader와 SLIP 프레임 기반으로 통신하여 펌웨어를 플래시에 기록합니다.
/// ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP8266 지원.
class EsptoolUploader {
  // ─── SLIP 상수 ───
  static const int _slipEnd = 0xC0;
  static const int _slipEsc = 0xDB;
  static const int _slipEscEnd = 0xDC;
  static const int _slipEscEsc = 0xDD;

  // ─── ESP bootloader 명령어 ───
  static const int _cmdFlashBegin = 0x02;
  static const int _cmdFlashData = 0x03;
  static const int _cmdFlashEnd = 0x04;
  static const int _cmdSync = 0x08;
  static const int _cmdReadReg = 0x0A;
  static const int _cmdSpiAttach = 0x0D;
  static const int _cmdChangeBaud = 0x0F;

  // ─── 칩 감지 레지스터 ───
  static const int _chipDetectMagicReg = 0x40001000;

  static const Map<int, String> _chipMagicValues = {
    0x00F01D83: 'ESP32',
    0x000007C6: 'ESP32-S2',
    0x6921506F: 'ESP32-C3', // also ESP32-C3 ECO 1/2
    0x1B31506F: 'ESP32-C3', // ECO 3
    0x09: 'ESP32-S3',
    0xFFF0888F: 'ESP8266',
  };

  // ─── 플래시 기본 설정 ───
  static const int _flashSectorSize = 0x1000; // 4KB
  static const int _flashBlockSize = 0x10000; // 64KB for erase
  static const int _flashWriteSize = 0x400; // 1KB per data packet

  // ─── 칩별 기본 플래시 오프셋 ───
  static const Map<String, int> _defaultAppOffset = {
    'ESP32': 0x10000,
    'ESP32-S2': 0x10000,
    'ESP32-S3': 0x10000,
    'ESP32-C3': 0x10000,
    'ESP8266': 0x0,
  };

  // ─── SYNC / checksum ───
  /// XOR checksum initial value (Espressif convention).
  static const int _checksumInit = 0xEF;
  /// SYNC frame magic header bytes.
  static const List<int> _syncMagic = [0x07, 0x07, 0x12, 0x20];
  /// SYNC frame padding (32 x 0x55).
  static const int _syncPaddingLength = 32;
  static const int _syncPaddingByte = 0x55;

  final UsbPort _port;
  final void Function(String) _log;
  final List<int> _rxBuf = [];
  StreamSubscription<Uint8List>? _sub;
  String _detectedChip = 'ESP32';
  bool _isStub = false; // ignore: prefer_final_fields

  EsptoolUploader(this._port, this._log);

  // ─── SLIP 프레이밍 ───

  Uint8List _slipEncode(List<int> data) {
    final buf = <int>[_slipEnd];
    for (final b in data) {
      if (b == _slipEnd) {
        buf.addAll([_slipEsc, _slipEscEnd]);
      } else if (b == _slipEsc) {
        buf.addAll([_slipEsc, _slipEscEsc]);
      } else {
        buf.add(b);
      }
    }
    buf.add(_slipEnd);
    return Uint8List.fromList(buf);
  }

  List<int> _slipDecode(List<int> raw) {
    final result = <int>[];
    bool escaped = false;
    for (final b in raw) {
      if (escaped) {
        if (b == _slipEscEnd) {
          result.add(_slipEnd);
        } else if (b == _slipEscEsc) {
          result.add(_slipEsc);
        } else {
          result.add(b);
        }
        escaped = false;
      } else if (b == _slipEsc) {
        escaped = true;
      } else if (b != _slipEnd) {
        result.add(b);
      }
    }
    return result;
  }

  // ─── 직렬 통신 ───

  void _attach() {
    _sub = _port.inputStream?.listen((data) => _rxBuf.addAll(data));
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// SLIP 프레임 하나 읽기
  Future<List<int>> _readSlipFrame({int timeoutMs = 3000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    // 프레임 시작 (0xC0) 찾기
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('SLIP 프레임 시작 대기 타임아웃');
      }
      if (_rxBuf.isNotEmpty && _rxBuf.first == _slipEnd) {
        _rxBuf.removeAt(0);
        break;
      } else if (_rxBuf.isNotEmpty) {
        _rxBuf.removeAt(0); // 프레임 시작 전 쓰레기 바이트 버림
      } else {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }

    // 프레임 끝 (0xC0) 까지 읽기
    final frame = <int>[];
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('SLIP 프레임 완료 대기 타임아웃');
      }
      if (_rxBuf.isNotEmpty) {
        final b = _rxBuf.removeAt(0);
        if (b == _slipEnd) break;
        frame.add(b);
      } else {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    return _slipDecode(frame);
  }

  // ─── 명령 패킷 ───

  static int _checksum(List<int> data) {
    int cs = _checksumInit;
    for (final b in data) {
      cs ^= b;
    }
    return cs;
  }

  Future<void> _sendCommand(int cmd, List<int> payload,
      {int checksum = 0}) async {
    final size = payload.length;
    final pkt = <int>[
      0x00, // direction: request
      cmd,
      size & 0xFF, (size >> 8) & 0xFF,
      checksum & 0xFF, (checksum >> 8) & 0xFF,
      (checksum >> 16) & 0xFF, (checksum >> 24) & 0xFF,
      ...payload,
    ];
    await _port.write(_slipEncode(pkt));
  }

  /// 응답 읽기, 명령과 일치하는 응답만 반환
  Future<_EspResponse> _readResponse(int cmd,
      {int timeoutMs = 3000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('ESP 응답 타임아웃 (cmd=0x${cmd.toRadixString(16)})');
      }
      final remaining = deadline.difference(DateTime.now()).inMilliseconds;
      final frame = await _readSlipFrame(
          timeoutMs: remaining.clamp(100, timeoutMs));
      if (frame.length < 8) continue;
      if (frame[0] != 0x01) continue; // direction: response
      if (frame[1] != cmd) continue;
      final value = frame[4] |
          (frame[5] << 8) |
          (frame[6] << 16) |
          (frame[7] << 24);
      final data = frame.length > 8 ? frame.sublist(8) : <int>[];
      // status는 data의 마지막 2~4바이트
      int status = 0;
      int error = 0;
      if (data.length >= 2) {
        status = data[data.length - 2];
        error = data[data.length - 1];
      }
      return _EspResponse(
          value: value, data: data, status: status, error: error);
    }
  }

  Future<_EspResponse> _command(int cmd, List<int> payload,
      {int checksum = 0, int timeoutMs = 3000}) async {
    await _sendCommand(cmd, payload, checksum: checksum);
    return _readResponse(cmd, timeoutMs: timeoutMs);
  }

  // ─── 부트로더 진입 ───

  /// NodeMCU/D1 Mini 회로: DTR→GPIO0, RTS→EN (트랜지스터 반전)
  /// - setDTR(true) → GPIO0 LOW,  setDTR(false) → GPIO0 HIGH
  /// - setRTS(true) → EN LOW (리셋), setRTS(false) → EN HIGH (정상)
  Future<void> _enterBootloaderA() async {
    _log('리셋 시퀀스 A (NodeMCU/D1 Mini)...');
    await _port.setDTR(false); // GPIO0 HIGH (정상)
    await _port.setRTS(false); // EN HIGH (정상)
    await Future.delayed(const Duration(milliseconds: 50));
    await _port.setDTR(false); // GPIO0 HIGH
    await _port.setRTS(true);  // EN LOW (리셋 시작)
    await Future.delayed(const Duration(milliseconds: 120));
    await _port.setDTR(true);  // GPIO0 LOW (다운로드 모드 진입)
    await _port.setRTS(false); // EN HIGH (리셋 해제 → 부트로더 진입)
    await Future.delayed(const Duration(milliseconds: 50));
    await _port.setDTR(false); // GPIO0 HIGH (해제)
    await Future.delayed(const Duration(milliseconds: 600));
    _rxBuf.clear();
  }

  /// ESP32 DevKit 회로: DTR→EN, RTS→GPIO0
  Future<void> _enterBootloaderB() async {
    _log('리셋 시퀀스 B (ESP32 DevKit)...');
    await _port.setDTR(false); // EN HIGH (정상)
    await _port.setRTS(false); // GPIO0 HIGH (정상)
    await Future.delayed(const Duration(milliseconds: 50));
    await _port.setRTS(false); // GPIO0 HIGH
    await _port.setDTR(true);  // EN LOW (리셋 시작)
    await _port.setRTS(true);  // GPIO0 LOW (다운로드 모드 진입)
    await Future.delayed(const Duration(milliseconds: 120));
    await _port.setDTR(false); // EN HIGH (리셋 해제 → 부트로더 진입)
    await Future.delayed(const Duration(milliseconds: 50));
    await _port.setRTS(false); // GPIO0 HIGH (해제)
    await Future.delayed(const Duration(milliseconds: 600));
    _rxBuf.clear();
  }

  // ─── SYNC ───

  Future<bool> _sync() async {
    // SYNC 패킷: magic header + padding
    final syncPayload = <int>[
      ..._syncMagic,
      ...List.filled(_syncPaddingLength, _syncPaddingByte),
    ];
    // 실제 esptool과 동일하게: 한 번에 8개 패킷 연속 전송 후 응답 대기
    const outerAttempts = 10;
    for (int attempt = 1; attempt <= outerAttempts; attempt++) {
      _rxBuf.clear();
      try {
        // 8개 패킷 burst 전송 (esptool 동작과 동일)
        for (int i = 0; i < 8; i++) {
          await _sendCommand(_cmdSync, syncPayload);
        }
        // 8개 응답 중 status==0인 것을 찾음
        bool gotSuccess = false;
        for (int r = 0; r < 8; r++) {
          try {
            final resp = await _readResponse(_cmdSync, timeoutMs: 500);
            if (resp.status == 0) {
              gotSuccess = true;
              break;
            }
          } catch (_) {
            break;
          }
        }
        if (gotSuccess) {
          _log('ESP 동기화 성공 (시도 $attempt/$outerAttempts)');
          await Future.delayed(const Duration(milliseconds: 100));
          _rxBuf.clear();
          return true;
        }
      } catch (_) {
        // ignore, retry
      }
      _log('ESP 동기화 시도 $attempt/$outerAttempts...');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  // ─── 칩 감지 ───

  Future<int> _readReg(int addr) async {
    final payload = _uint32LE(addr);
    final resp = await _command(_cmdReadReg, payload, timeoutMs: 3000);
    return resp.value;
  }

  Future<String> _detectChip() async {
    try {
      final magic = await _readReg(_chipDetectMagicReg);
      final chip = _chipMagicValues[magic];
      if (chip != null) return chip;
      // ESP32-S3는 magic value가 다를 수 있음
      if (magic == 0x09) return 'ESP32-S3';
      _log('알 수 없는 칩 magic: 0x${magic.toRadixString(16)}');
    } catch (e) {
      _log('칩 감지 실패: $e');
    }
    return 'ESP32'; // 기본값
  }

  // ─── SPI Flash 연결 ───

  Future<void> _spiAttach() async {
    // SPI flash 연결 (기본 핀 사용)
    final payload = List.filled(8, 0);
    await _command(_cmdSpiAttach, payload, timeoutMs: 3000);
  }

  // ─── Baud rate 변경 (선택적, 속도 향상) ───

  Future<bool> _changeBaud(int newBaud) async {
    final payload = <int>[
      ..._uint32LE(newBaud),
      ..._uint32LE(0), // 0 = ROM loader가 현재 baud 감지
    ];
    try {
      await _command(_cmdChangeBaud, payload, timeoutMs: 1000);
      await _port.setPortParameters(
          newBaud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
      await Future.delayed(const Duration(milliseconds: 100));
      _rxBuf.clear();
      // 변경 후 SYNC로 확인
      final ok = await _sync();
      if (ok) {
        _log('전송 속도 변경: $newBaud baud');
        return true;
      }
    } catch (_) {
      // 실패 시 원래 속도로 복원
    }
    return false;
  }

  // ─── 플래시 기록 ───

  Future<void> _flashBegin(int size, int offset) async {
    final numBlocks =
        (size + _flashWriteSize - 1) ~/ _flashWriteSize;
    final eraseSize = _eraseFlashSize(size, offset);
    final payload = <int>[
      ..._uint32LE(eraseSize),
      ..._uint32LE(numBlocks),
      ..._uint32LE(_flashWriteSize),
      ..._uint32LE(offset),
    ];
    await _command(_cmdFlashBegin, payload, timeoutMs: 10000);
  }

  Future<void> _flashData(Uint8List data, int seq) async {
    final payload = <int>[
      ..._uint32LE(data.length),
      ..._uint32LE(seq),
      ..._uint32LE(0), // reserved
      ..._uint32LE(0), // reserved
      ...data,
    ];
    final cs = _checksum(data);
    await _command(_cmdFlashData, payload,
        checksum: cs, timeoutMs: 3000);
  }

  Future<void> _flashEnd({bool reboot = false}) async {
    final payload = _uint32LE(reboot ? 0 : 1);
    try {
      await _command(_cmdFlashEnd, payload, timeoutMs: 2000);
    } catch (_) {
      // 재부팅 시 응답 없을 수 있음
    }
  }

  int _eraseFlashSize(int dataSize, int offset) {
    final sectorsPerBlock = _flashBlockSize ~/ _flashSectorSize;
    final sectorCount =
        (dataSize + _flashSectorSize - 1) ~/ _flashSectorSize;
    final startSector = offset ~/ _flashSectorSize;
    final headSectors = sectorsPerBlock - (startSector % sectorsPerBlock);
    if (sectorCount < headSectors) {
      return (sectorCount + 1) ~/ 2 * _flashSectorSize;
    }
    return (sectorCount - headSectors) * _flashSectorSize +
        _flashBlockSize;
  }

  // ─── 메인 업로드 ───

  Future<void> upload(
    Uint8List firmware, {
    int? flashOffset,
    void Function(double)? onProgress,
  }) async {
    _attach();
    try {
      // 포트 열린 직후 초기 상태를 명시적으로 설정 (DTR/RTS 불확정 상태 방지)
      await _port.setDTR(false); // GPIO0 HIGH (정상 상태)
      await _port.setRTS(false); // EN HIGH (정상 상태)
      await Future.delayed(const Duration(milliseconds: 50));

      bool synced = false;

      // 시도 1: 시퀀스 A (NodeMCU/D1 Mini: DTR→GPIO0, RTS→EN)
      await _enterBootloaderA();
      synced = await _sync();

      // 시도 2: 시퀀스 B (ESP32 DevKit: DTR→EN, RTS→GPIO0)
      if (!synced) {
        await _enterBootloaderB();
        synced = await _sync();
      }

      // 시도 3: 시퀀스 A 한번 더 (타이밍 이슈)
      if (!synced) {
        await _enterBootloaderA();
        synced = await _sync();
      }

      // 시도 4: 시퀀스 B 한번 더
      if (!synced) {
        await _enterBootloaderB();
        synced = await _sync();
      }

      if (!synced) {
        throw Exception('ESP 부트로더 동기화 실패\n'
            '- BOOT(FLASH) 버튼을 누른 상태에서 업로드를 다시 시도하세요\n'
            '- USB 케이블이 데이터 전송을 지원하는지 확인하세요\n'
            '- 일부 보드는 자동 리셋 회로가 없어 수동으로 BOOT 버튼을 눌러야 합니다');
      }

      // 3) 칩 감지
      _detectedChip = await _detectChip();
      _log('칩 감지: $_detectedChip');

      // 4) SPI flash 연결
      await _spiAttach();

      // 5) 전송 속도 향상 시도 (460800)
      if (!_isStub) {
        await _changeBaud(460800);
      }

      // 6) 플래시 오프셋 결정
      final offset =
          flashOffset ?? (_defaultAppOffset[_detectedChip] ?? 0x10000);
      _log('플래시 오프셋: 0x${offset.toRadixString(16)}');

      // 7) 플래시 기록 시작
      _log('플래시 기록 시작: ${firmware.length} bytes');
      await _flashBegin(firmware.length, offset);

      // 8) 데이터 전송
      final totalBlocks =
          (firmware.length + _flashWriteSize - 1) ~/ _flashWriteSize;
      for (int seq = 0; seq < totalBlocks; seq++) {
        final start = seq * _flashWriteSize;
        final end =
            (start + _flashWriteSize).clamp(0, firmware.length);
        // 패딩: 부족한 부분은 0xFF로 채움
        final block = Uint8List(_flashWriteSize)
          ..fillRange(0, _flashWriteSize, 0xFF);
        block.setRange(0, end - start, firmware.sublist(start, end));

        await _flashData(block, seq);
        onProgress?.call((seq + 1) / totalBlocks);
      }

      // 9) 플래시 완료 + 재부팅
      await _flashEnd(reboot: true);
      _log('플래시 완료! 재부팅 중...');
    } finally {
      await _detach();
    }
  }

  // ─── 유틸 ───

  static List<int> _uint32LE(int v) => [
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ];
}

class _EspResponse {
  final int value;
  final List<int> data;
  final int status;
  final int error;
  const _EspResponse(
      {required this.value,
      required this.data,
      required this.status,
      required this.error});
}
