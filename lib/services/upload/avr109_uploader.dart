/// AVR109 (Caterina) bootloader protocol implementation.
///
/// Reference: Atmel AVR109 — Self-Programming Guide
/// https://ww1.microchip.com/downloads/en/Appnotes/doc1644.pdf
///
/// Supported boards: Arduino Leonardo, Micro, Esplora (ATmega32u4 native USB).
///
/// Key differences from STK500:
/// - Device has native USB (no UART bridge chip)
/// - 1200-baud-touch triggers bootloader (handled by AndroidUploader)
/// - Protocol uses ASCII commands: 'S'=ID, 'b'=block support, 'B'=write, 'P'/'L'=prog mode
/// - Block addressing is in **word** units (byte_addr / 2)
/// - Bootloader auto-exits after ~8 seconds of inactivity
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
///
/// Arduino Leonardo, Micro 등 ATmega32u4 네이티브 USB 보드용.
/// Uno/Nano의 STK500v1과는 완전히 다른 프로토콜입니다.
class Avr109Uploader {
  // --------------- AVR109 protocol commands ---------------
  static const int _cmdEsc           = 0x1B; // ESC — clear state
  static const int _cmdSoftwareId    = 0x53; // 'S' — request bootloader ID
  static const int _cmdBlockSupport  = 0x62; // 'b' — query block support
  static const int _cmdEnterProg     = 0x50; // 'P' — enter programming mode
  static const int _cmdChipErase     = 0x65; // 'e' — chip erase
  static const int _cmdSetAddress    = 0x41; // 'A' — set word address
  static const int _cmdBlockWrite    = 0x42; // 'B' — block write
  static const int _cmdLeaveProg     = 0x4C; // 'L' — leave programming mode
  static const int _cmdExitBootloader = 0x45; // 'E' — exit bootloader → run app
  static const int _memFlash         = 0x46; // 'F' — flash memory type
  static const int _responseYes      = 0x59; // 'Y' — positive response
  static const int _responseCR       = 0x0D; // CR  — acknowledge

  final UsbPort _port;
  final void Function(String) _log;
  final List<int> _rxBuf = [];
  StreamSubscription<Uint8List>? _sub;

  Avr109Uploader(this._port, this._log);

  void _attach() {
    _sub = _port.inputStream?.listen((data) => _rxBuf.addAll(data));
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<List<int>> _read(int n, {int timeoutMs = 3000}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (_rxBuf.length < n) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'AVR109: $n 바이트 대기 중 타임아웃 (수신: ${_rxBuf.length})',
        );
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

  Future<int> _readByte({int timeoutMs = 2000}) async {
    return (await _read(1, timeoutMs: timeoutMs))[0];
  }

  Future<void> _expectCR({int timeoutMs = 3000}) async {
    final b = await _readByte(timeoutMs: timeoutMs);
    if (b != _responseCR) {
      throw Exception(
        'AVR109: CR(0x0D) 예상, 수신: 0x${b.toRadixString(16)}',
      );
    }
  }

  /// AVR109 프로토콜로 펌웨어 업로드
  ///
  /// [hexData]    - 주소 0부터 시작하는 플랫 바이너리
  /// [pageSize]   - 플래시 페이지 크기 (ATmega32u4 = 128)
  /// [onProgress] - 진행률 콜백 (0.0 ~ 1.0)
  Future<void> upload(
    Uint8List hexData, {
    int pageSize = 128,
    void Function(double)? onProgress,
  }) async {
    _attach();
    try {
      // 부트로더 동기화 (최대 3회 재시도)
      _log('AVR109: 부트로더 동기화 중...');
      int blockSize = 0;
      bool synced = false;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          // ESC로 초기 상태 정리
          _rxBuf.clear();
          await _send([_cmdEsc]); // ESC
          await Future.delayed(const Duration(milliseconds: 150));
          _rxBuf.clear();

          // 소프트웨어 ID 요청으로 부트로더 존재 확인
          await _send([_cmdSoftwareId]); // 'S' — Software identifier
          final swId = await _read(7, timeoutMs: 1500);
          _log('AVR109: 부트로더 ID: ${String.fromCharCodes(swId)}');

          // 블록 업로드 지원 확인
          await _send([_cmdBlockSupport]); // 'b'
          final blockFlag = await _readByte(timeoutMs: 1500);
          if (blockFlag != _responseYes) {
            throw Exception('블록 업로드 미지원 (응답: 0x${blockFlag.toRadixString(16)})');
          }
          final blockHi = await _readByte();
          final blockLo = await _readByte();
          blockSize = (blockHi << 8) | blockLo;
          _log('AVR109: 블록 크기 $blockSize bytes (시도 $attempt/3)');
          synced = true;
          break;
        } catch (e) {
          _log('AVR109: 동기화 시도 $attempt/3 실패: $e');
          if (attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }

      if (!synced) {
        throw Exception('AVR109: 부트로더 동기화 실패 — 부트로더가 응답하지 않습니다.\n'
            '- USB 케이블을 확인하세요\n'
            '- 리셋 버튼을 빠르게 2번 누른 직후 재시도하세요');
      }

      // 프로그래밍 모드 진입
      await _send([_cmdEnterProg]); // 'P'
      await _expectCR();
      _log('AVR109: 프로그래밍 모드 진입');

      // 칩 초기화
      _log('AVR109: 칩 초기화 중...');
      await _send([_cmdChipErase]); // 'e'
      await _expectCR(timeoutMs: 6000);
      _log('AVR109: 칩 초기화 완료');

      // 페이지 단위 업로드
      final totalPages = (hexData.length + pageSize - 1) ~/ pageSize;
      _log('AVR109: 업로드 시작 (${hexData.length} bytes / $totalPages 페이지)');

      for (int page = 0; page < totalPages; page++) {
        final byteAddr = page * pageSize;
        final wordAddr = byteAddr ~/ 2;

        // 주소 설정 (워드 주소)
        await _send([_cmdSetAddress, (wordAddr >> 8) & 0xFF, wordAddr & 0xFF]); // 'A'
        await _expectCR();

        // 페이지 데이터 준비 (0xFF 패딩)
        final end = (byteAddr + pageSize).clamp(0, hexData.length);
        final pageBytes = Uint8List(pageSize)..fillRange(0, pageSize, 0xFF);
        pageBytes.setRange(0, end - byteAddr, hexData.sublist(byteAddr, end));

        // 블록 업로드: 'B' + size_hi + size_lo + 'F'(Flash) + data
        await _send([
          _cmdBlockWrite,
          (pageSize >> 8) & 0xFF,
          pageSize & 0xFF,
          _memFlash,
          ...pageBytes,
        ]);
        await _expectCR(timeoutMs: 3000);

        onProgress?.call((page + 1) / totalPages);
      }

      // 프로그래밍 모드 종료
      await _send([_cmdLeaveProg]); // 'L'
      await _expectCR();
      _log('AVR109: 업로드 완료!');

      // 부트로더 종료 → 앱 실행
      await _send([_cmdExitBootloader]); // 'E'
    } finally {
      await _detach();
    }
  }
}
