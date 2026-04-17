/// SAMD SAM-BA bootloader flasher (BOSSA protocol).
///
/// Reference: Atmel SAM-BA Monitor Commands
/// https://ww1.microchip.com/downloads/en/Appnotes/Atmel-42366-SAM-BA-Bootloader-for-SAM-D21_ApplicationNote_AT07175.pdf
///
/// Supports: SAMD21 (Arduino Zero, MKR, Nano 33 IoT), SAMD51.
///
/// Protocol overview:
/// - SAM-BA uses text commands over serial: 'W' (write word), 'S' (send file)
/// - 1200-baud-touch triggers bootloader entry (same as Caterina)
/// - Flash layout: SAMD21 app starts at 0x2000 (8KB bootloader),
///                 SAMD51 app starts at 0x4000 (16KB bootloader)
/// - Page sizes: SAMD21 = 256 bytes, SAMD51 = 512 bytes
/// - NVM controller registers used for erase/write operations
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
///
/// Arduino Zero, MKR, Nano 33 IoT 등 SAMD21/51 보드의
/// SAM-BA 부트로더와 통신하여 펌웨어를 플래시에 기록합니다.
/// 부트로더 진입은 1200 baud touch (Caterina와 동일).
class BossaUploader {
  static const int _flashBase = 0x00002000; // SAMD21 app start (8KB bootloader)
  static const int _flashBaseSamd51 = 0x00004000; // SAMD51 app start (16KB)
  static const int _pageSize = 256; // SAMD21
  static const int _pageSizeSamd51 = 512; // SAMD51
  static const int _rowPages = 4; // SAMD21: 4 pages per row

  final UsbPort _port;
  final void Function(String) _log;
  final List<int> _rxBuf = [];
  StreamSubscription<Uint8List>? _sub;
  bool _isSamd51 = false;

  BossaUploader(this._port, this._log);

  void _attach() {
    _sub = _port.inputStream?.listen((data) => _rxBuf.addAll(data));
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _send(String cmd) async {
    await _port.write(Uint8List.fromList(cmd.codeUnits));
  }

  Future<void> _sendBinary(List<int> data) async {
    await _port.write(Uint8List.fromList(data));
  }

  /// 줄바꿈까지 응답 읽기
  Future<String> _readLine({int timeoutMs = 3000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    final buf = <int>[];
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('SAM-BA: 줄 읽기 타임아웃');
      }
      if (_rxBuf.isNotEmpty) {
        final b = _rxBuf.removeAt(0);
        if (b == 0x0A || b == 0x0D) {
          if (buf.isNotEmpty) break;
          continue;
        }
        buf.add(b);
      } else {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    return String.fromCharCodes(buf);
  }

  // ─── SAM-BA 명령 ───

  /// 워드 읽기 (32비트)
  Future<int> _readWord(int addr) async {
    await _send('w${_hex8(addr)},4#');
    final resp = await _readLine(timeoutMs: 2000);
    return int.tryParse(resp.trim(), radix: 16) ?? 0;
  }

  /// 워드 쓰기 (32비트)
  Future<void> _writeWord(int addr, int value) async {
    await _send('W${_hex8(addr)},${_hex8(value)}#');
    // SAM-BA는 쓰기 후 응답 없음 (또는 짧은 응답)
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// 바이트 블록 전송
  Future<void> _sendBlock(int addr, Uint8List data) async {
    await _send('S${_hex8(addr)},${_hex8(data.length)}#');
    await _sendBinary(data);
    await Future.delayed(const Duration(milliseconds: 5));
  }

  // ─── SAMD NVM Controller ───

  // SAMD21 NVM Controller 레지스터
  static const int _nvmctrlBase = 0x41004000;
  static const int _nvmctrlCtrla = _nvmctrlBase + 0x00;
  static const int _nvmctrlIntflag = _nvmctrlBase + 0x14;
  static const int _nvmctrlAddr = _nvmctrlBase + 0x1C;

  // NVM 명령
  static const int _nvmCmdEraseRow = 0x02;
  static const int _nvmCmdWritePage = 0x04;

  Future<void> _nvmWaitReady() async {
    for (int i = 0; i < 100; i++) {
      final intflag = await _readWord(_nvmctrlIntflag);
      if ((intflag & 0x01) != 0) return; // READY bit
      await Future.delayed(const Duration(milliseconds: 10));
    }
    throw Exception('SAM-BA: NVM 준비 타임아웃');
  }

  Future<void> _nvmCommand(int cmd) async {
    await _nvmWaitReady();
    // CMDEX (0xA5) | CMD
    await _writeWord(_nvmctrlCtrla, (0xA5 << 8) | cmd);
  }

  Future<void> _eraseRow(int addr) async {
    // 주소 설정 후 Erase Row 명령
    await _writeWord(_nvmctrlAddr, addr ~/ 2); // word address
    await _nvmCommand(_nvmCmdEraseRow);
    await _nvmWaitReady();
  }

  Future<void> _writePage(int addr, Uint8List data) async {
    await _sendBlock(addr, data);
    await _nvmCommand(_nvmCmdWritePage);
    await _nvmWaitReady();
  }

  // ─── 칩 감지 ───

  Future<void> _detectChip() async {
    try {
      // DSU Device ID 레지스터
      final devId = await _readWord(0x41002018);
      final devsel = (devId >> 12) & 0xFF;
      _isSamd51 = devsel >= 0x60; // SAMD51 device IDs
      _log('SAM-BA: Device ID=0x${devId.toRadixString(16)}, '
          '${_isSamd51 ? "SAMD51" : "SAMD21"}');
    } catch (e) {
      _log('SAM-BA: 칩 감지 실패, SAMD21로 가정');
      _isSamd51 = false;
    }
  }

  // ─── 부트로더 동기화 ───

  Future<bool> _sync() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      _rxBuf.clear();
      try {
        // SAM-BA 바이너리 모드 진입
        await _send('N#');
        await Future.delayed(const Duration(milliseconds: 100));
        _rxBuf.clear();
        // 버전 확인
        await _send('V#');
        final resp = await _readLine(timeoutMs: 1500);
        if (resp.isNotEmpty) {
          _log('SAM-BA 부트로더: $resp');
          return true;
        }
      } catch (_) {
        _log('SAM-BA 동기화 시도 $attempt/3...');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return false;
  }

  // ─── 메인 업로드 ───

  Future<void> upload(
    Uint8List firmware, {
    bool isSamd51 = false,
    void Function(double)? onProgress,
  }) async {
    _attach();
    try {
      _isSamd51 = isSamd51;

      // 1) 부트로더 동기화
      if (!await _sync()) {
        throw Exception('SAM-BA 부트로더 동기화 실패\n'
            '- 부트로더 모드 진입을 확인하세요 (리셋 2회 탭)');
      }

      // 2) 칩 감지
      await _detectChip();

      final pageSize = _isSamd51 ? _pageSizeSamd51 : _pageSize;
      final flashBase = _isSamd51 ? _flashBaseSamd51 : _flashBase;

      // 3) 펌웨어 패딩
      final padded = _padTo(firmware, pageSize);
      final totalPages = padded.length ~/ pageSize;
      _log('펌웨어: ${firmware.length} bytes → $totalPages 페이지');

      // 4) 플래시 삭제 + 기록
      final pagesPerRow = _rowPages;
      for (int page = 0; page < totalPages; page++) {
        final addr = flashBase + page * pageSize;

        // Row 시작마다 Erase
        if (page % pagesPerRow == 0) {
          await _eraseRow(addr);
        }

        // 페이지 쓰기
        final data = padded.sublist(page * pageSize, (page + 1) * pageSize);
        await _writePage(addr, Uint8List.fromList(data));
        onProgress?.call((page + 1) / totalPages);
      }

      // 5) 리셋 (앱 시작)
      _log('업로드 완료! 재부팅 중...');
      // AIRCR (Application Interrupt and Reset Control Register) → System Reset
      await _writeWord(0xE000ED0C, 0x05FA0004);
    } finally {
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

  static String _hex8(int v) =>
      v.toRadixString(16).padLeft(8, '0').toUpperCase();
}
