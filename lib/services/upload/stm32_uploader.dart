/// STM32 UART bootloader flasher (AN3155 protocol).
///
/// Reference: ST Application Note AN3155
/// https://www.st.com/resource/en/application_note/an3155.pdf
///
/// Supports: STM32F0/F1/F2/F3/F4/F7/L0/L1/L4/G0/G4/H7 series.
///
/// Protocol overview:
/// - Sync: send 0x7F, wait for ACK (0x79)
/// - Commands: GET (0x00), GET_ID (0x02), ERASE (0x43/0x44),
///   WRITE_MEMORY (0x31), GO (0x21)
/// - Each command byte is followed by its complement (XOR 0xFF)
/// - Write address: 0x08000000 (flash base) + offset
/// - Max 256 bytes per write block
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
///
/// STM32의 내장 system memory bootloader와 UART로 통신하여
/// 펌웨어를 플래시에 기록합니다.
class Stm32Uploader {
  // ─── 프로토콜 상수 ───
  static const int _ack = 0x79;
  static const int _nack = 0x1F;
  static const int _cmdGet = 0x00;
  static const int _cmdGetId = 0x02;
  static const int _cmdEraseExtended = 0x44;
  static const int _cmdErase = 0x43;
  static const int _cmdWriteMemory = 0x31;
  static const int _cmdGo = 0x21;
  static const int _syncByte = 0x7F;
  static const int _flashBase = 0x08000000;
  static const int _maxWriteBlock = 256;

  final UsbPort _port;
  final void Function(String) _log;
  final List<int> _rxBuf = [];
  StreamSubscription<Uint8List>? _sub;
  bool _extendedErase = false;

  Stm32Uploader(this._port, this._log);

  void _attach() {
    _sub = _port.inputStream?.listen((data) => _rxBuf.addAll(data));
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<int> _readByte({int timeoutMs = 2000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (_rxBuf.isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('STM32: 응답 타임아웃');
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }
    return _rxBuf.removeAt(0);
  }

  Future<List<int>> _readBytes(int n, {int timeoutMs = 2000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (_rxBuf.length < n) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('STM32: $n 바이트 대기 타임아웃 (수신: ${_rxBuf.length})');
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }
    final result = _rxBuf.sublist(0, n);
    _rxBuf.removeRange(0, n);
    return result;
  }

  Future<void> _send(List<int> bytes) async {
    await _port.write(Uint8List.fromList(bytes));
  }

  Future<void> _waitAck({int timeoutMs = 5000, String context = ''}) async {
    final b = await _readByte(timeoutMs: timeoutMs);
    if (b == _nack) {
      throw Exception('STM32: NACK 수신${context.isNotEmpty ? " ($context)" : ""}');
    }
    if (b != _ack) {
      throw Exception(
          'STM32: ACK 예상, 수신: 0x${b.toRadixString(16)}${context.isNotEmpty ? " ($context)" : ""}');
    }
  }

  /// 명령 + complement 전송 후 ACK 대기
  Future<void> _sendCmd(int cmd, {String context = ''}) async {
    await _send([cmd, cmd ^ 0xFF]);
    await _waitAck(context: context);
  }

  // ─── 부트로더 진입 ───

  Future<void> _enterBootloader() async {
    _log('STM32 부트로더 진입 중...');
    // BOOT0 = HIGH + RESET 토글
    // 일반적 회로: DTR → RESET, RTS → BOOT0
    await _port.setDTR(false);
    await _port.setRTS(false);
    await Future.delayed(const Duration(milliseconds: 100));
    await _port.setRTS(true); // BOOT0 HIGH
    await Future.delayed(const Duration(milliseconds: 50));
    await _port.setDTR(true); // RESET LOW
    await Future.delayed(const Duration(milliseconds: 100));
    await _port.setDTR(false); // RESET 해제 → 부트로더 시작
    await Future.delayed(const Duration(milliseconds: 300));
    _rxBuf.clear();
  }

  /// UART 동기화 (0x7F 전송 → ACK 대기)
  Future<bool> _sync() async {
    for (int attempt = 1; attempt <= 5; attempt++) {
      _rxBuf.clear();
      try {
        await _send([_syncByte]);
        await _waitAck(timeoutMs: 1000, context: 'SYNC');
        _log('STM32 부트로더 동기화 성공 (시도 $attempt/5)');
        return true;
      } catch (_) {
        _log('STM32 동기화 시도 $attempt/5...');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return false;
  }

  // ─── GET 명령 (지원 명령어 확인) ───

  Future<void> _get() async {
    await _sendCmd(_cmdGet, context: 'GET');
    final n = await _readByte();
    final data = await _readBytes(n + 1);
    await _waitAck(context: 'GET end');
    // Extended Erase (0x44) 지원 여부 확인
    _extendedErase = data.contains(_cmdEraseExtended);
    _log('STM32 부트로더 버전: ${data[0] >> 4}.${data[0] & 0x0F}');
  }

  // ─── GET_ID 명령 ───

  Future<int> _getId() async {
    await _sendCmd(_cmdGetId, context: 'GET_ID');
    final n = await _readByte();
    final idBytes = await _readBytes(n + 1);
    await _waitAck(context: 'GET_ID end');
    int chipId = 0;
    for (final b in idBytes) {
      chipId = (chipId << 8) | b;
    }
    _log('STM32 Chip ID: 0x${chipId.toRadixString(16)}');
    return chipId;
  }

  // ─── ERASE ───

  Future<void> _eraseAll() async {
    _log('플래시 전체 삭제 중...');
    if (_extendedErase) {
      // Extended Erase: Mass Erase
      await _sendCmd(_cmdEraseExtended, context: 'ERASE_EXT');
      await _send([0xFF, 0xFF]); // 전체 삭제 special code
      await _send([0x00]); // checksum
      await _waitAck(timeoutMs: 30000, context: 'ERASE_EXT data');
    } else {
      // Standard Erase: Global Erase
      await _sendCmd(_cmdErase, context: 'ERASE');
      await _send([0xFF]); // 전체 삭제
      await _send([0x00]); // checksum
      await _waitAck(timeoutMs: 30000, context: 'ERASE data');
    }
    _log('플래시 삭제 완료');
  }

  // ─── WRITE_MEMORY ───

  Future<void> _writeMemory(int address, Uint8List data) async {
    assert(data.length <= _maxWriteBlock && data.length % 4 == 0);

    await _sendCmd(_cmdWriteMemory, context: 'WRITE');
    // 주소 (4바이트 + checksum)
    final addrBytes = [
      (address >> 24) & 0xFF,
      (address >> 16) & 0xFF,
      (address >> 8) & 0xFF,
      address & 0xFF,
    ];
    int cs = 0;
    for (final b in addrBytes) {
      cs ^= b;
    }
    await _send([...addrBytes, cs]);
    await _waitAck(context: 'WRITE addr');

    // 데이터 (N + data + checksum)
    final n = data.length - 1;
    int dataCs = n;
    for (final b in data) {
      dataCs ^= b;
    }
    await _send([n, ...data, dataCs]);
    await _waitAck(timeoutMs: 5000, context: 'WRITE data');
  }

  // ─── GO (실행) ───

  Future<void> _go(int address) async {
    await _sendCmd(_cmdGo, context: 'GO');
    final addrBytes = [
      (address >> 24) & 0xFF,
      (address >> 16) & 0xFF,
      (address >> 8) & 0xFF,
      address & 0xFF,
    ];
    int cs = 0;
    for (final b in addrBytes) {
      cs ^= b;
    }
    await _send([...addrBytes, cs]);
    try {
      await _waitAck(timeoutMs: 2000, context: 'GO addr');
    } catch (_) {
      // GO 후 응답 없을 수 있음 (바로 앱 실행)
    }
  }

  // ─── 메인 업로드 ───

  Future<void> upload(
    Uint8List firmware, {
    int flashAddress = _flashBase,
    void Function(double)? onProgress,
  }) async {
    _attach();
    try {
      // 1) 부트로더 진입
      await _enterBootloader();

      // 2) 동기화
      if (!await _sync()) {
        await _enterBootloader();
        if (!await _sync()) {
          throw Exception('STM32 부트로더 동기화 실패\n'
              '- BOOT0 점퍼/버튼이 설정되어 있는지 확인하세요\n'
              '- USB 케이블을 확인하세요');
        }
      }

      // 3) 부트로더 정보 확인
      await _get();
      await _getId();

      // 4) 플래시 삭제
      await _eraseAll();

      // 5) 펌웨어 쓰기
      _log('펌웨어 기록 중: ${firmware.length} bytes');
      // 4바이트 정렬 패딩
      final padded = _padTo(firmware, 4);
      final totalBlocks = (padded.length + _maxWriteBlock - 1) ~/ _maxWriteBlock;

      for (int i = 0; i < totalBlocks; i++) {
        final offset = i * _maxWriteBlock;
        final end = (offset + _maxWriteBlock).clamp(0, padded.length);
        final block = Uint8List(_maxWriteBlock)..fillRange(0, _maxWriteBlock, 0xFF);
        block.setRange(0, end - offset, padded.sublist(offset, end));

        await _writeMemory(flashAddress + offset, block);
        onProgress?.call((i + 1) / totalBlocks);
      }

      // 6) 앱 실행
      _log('앱 실행 중...');
      await _go(flashAddress);
      _log('업로드 완료!');
    } finally {
      // BOOT0 해제 (정상 부팅 모드)
      await _port.setRTS(false);
      await _detach();
    }
  }

  static Uint8List _padTo(Uint8List data, int alignment) {
    final rem = data.length % alignment;
    if (rem == 0) return data;
    final padded = Uint8List(data.length + alignment - rem)
      ..fillRange(0, data.length + alignment - rem, 0xFF);
    padded.setRange(0, data.length, data);
    return padded;
  }
}
