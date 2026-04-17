/// STK500v1 protocol implementation for AVR bootloaders (Optiboot).
///
/// Reference: Atmel AVR061 — STK500 Communication Protocol
/// https://ww1.microchip.com/downloads/en/Appnotes/doc2525.pdf
///
/// Supported boards: Arduino Uno, Nano, Mega (any Optiboot-based AVR).
///
/// Upload flow:
/// 1. DTR/RTS pulse → MCU reset → bootloader starts (~300ms window)
/// 2. STK_GET_SYNC (0x30) + CRC_EOP (0x20) → wait STK_INSYNC + STK_OK
/// 3. Enter programming mode (0x50)
/// 4. For each page: load word address (0x55) + program page (0x64)
/// 5. Leave programming mode (0x51) → MCU runs user sketch
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
///
/// 사용법:
///   final uploader = Stk500Uploader(port, (msg) => print(msg));
///   await uploader.upload(hexData, pageSize: 128);
class Stk500Uploader {
  // STK500v1 상수
  static const int _stkOk = 0x10;
  static const int _stkInSync = 0x14;
  static const int _crcEop = 0x20;
  static const int _stkGetSync = 0x30;
  static const int _stkEnterProgMode = 0x50;
  static const int _stkLeaveProgMode = 0x51;
  static const int _stkLoadAddress = 0x55;
  static const int _stkProgPage = 0x64;

  final UsbPort _port;
  final void Function(String) _log;
  final List<int> _rxBuf = [];
  StreamSubscription<Uint8List>? _sub;

  Stk500Uploader(this._port, this._log);

  void _attach() {
    _sub = _port.inputStream?.listen((data) => _rxBuf.addAll(data));
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// 정확히 n 바이트 읽기 (타임아웃 포함)
  Future<List<int>> _read(int n, {int timeoutMs = 1500}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (_rxBuf.length < n) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'STK500 타임아웃: $n 바이트 대기 중 (수신됨: ${_rxBuf.length})',
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

  /// [STK_INSYNC, STK_OK] 응답 확인
  Future<void> _expectOk({int timeoutMs = 1500}) async {
    final resp = await _read(2, timeoutMs: timeoutMs);
    if (resp[0] != _stkInSync) {
      throw Exception(
        'STK500: INSYNC 예상, 수신: 0x${resp[0].toRadixString(16)}',
      );
    }
    if (resp[1] != _stkOk) {
      throw Exception(
        'STK500: OK 예상, 수신: 0x${resp[1].toRadixString(16)}',
      );
    }
  }

  /// 부트로더와 동기화 (최대 8회 시도)
  Future<void> _sync() async {
    for (int attempt = 1; attempt <= 8; attempt++) {
      _rxBuf.clear();
      await _send([_stkGetSync, _crcEop]);
      try {
        await _expectOk(timeoutMs: 600);
        _log('부트로더 동기화 성공 (시도 $attempt/8)');
        return;
      } catch (_) {
        _log('동기화 시도 $attempt/8...');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    throw Exception('STK500: 부트로더 동기화 실패\n'
        '- 보드가 연결되어 있는지 확인하세요\n'
        '- 지원 보드: Uno, Nano, Mega (Optiboot 탑재 AVR 계열)\n'
        '- ESP32/ESP8266 보드라면 보드 설정을 확인해 주세요\n'
        '  (CH340 칩 사용 시 자동 감지가 Uno로 될 수 있습니다)');
  }

  Future<void> _enterProgMode() async {
    await _send([_stkEnterProgMode, _crcEop]);
    await _expectOk();
  }

  Future<void> _leaveProgMode() async {
    await _send([_stkLeaveProgMode, _crcEop]);
    await _expectOk();
  }

  /// 워드 주소 로드 (바이트 주소 / 2)
  Future<void> _loadAddress(int wordAddr) async {
    await _send([
      _stkLoadAddress,
      wordAddr & 0xFF,
      (wordAddr >> 8) & 0xFF,
      _crcEop,
    ]);
    await _expectOk();
  }

  /// 플래시 페이지 기록
  Future<void> _programPage(Uint8List pageData) async {
    final size = pageData.length;
    await _send([
      _stkProgPage,
      (size >> 8) & 0xFF,
      size & 0xFF,
      0x46, // 'F' = Flash
      ...pageData,
      _crcEop,
    ]);
    await _expectOk();
  }

  /// DTR 펄스로 Arduino 리셋 후 STK500v1 프로토콜로 펌웨어 업로드
  ///
  /// [hexData]    - 주소 0부터 시작하는 플랫 바이너리 (hex_parser.dart 결과)
  /// [pageSize]   - 플래시 페이지 크기 (ATmega328P=128, ATmega2560=256)
  /// [onProgress] - 진행률 콜백 (0.0 ~ 1.0)
  Future<void> upload(
    Uint8List hexData, {
    int pageSize = 128,
    void Function(double progress)? onProgress,
  }) async {
    _attach();
    try {
      // DTR + RTS 펄스로 리셋 트리거 (CH340/CP210x 호환)
      _log('Arduino 리셋 중...');
      // 먼저 LOW 상태 보장
      await _port.setDTR(false);
      await _port.setRTS(false);
      await Future.delayed(const Duration(milliseconds: 50));
      // HIGH → 리셋 핀 HOLD
      await _port.setDTR(true);
      await _port.setRTS(true);
      await Future.delayed(const Duration(milliseconds: 250));
      // LOW → 리셋 해제, 부트로더 시작
      await _port.setDTR(false);
      await _port.setRTS(false);
      // 부트로더 초기화 대기 (Optiboot: ~100~300ms)
      await Future.delayed(const Duration(milliseconds: 400));

      // 부트로더 동기화
      _log('부트로더 연결 중...');
      await _sync();

      // 프로그래밍 모드 진입
      await _enterProgMode();
      _log('프로그래밍 모드 진입 완료');

      // 페이지 단위 업로드
      final totalPages = (hexData.length + pageSize - 1) ~/ pageSize;
      _log('업로드 시작: ${hexData.length} bytes / $totalPages 페이지');

      for (int page = 0; page < totalPages; page++) {
        final byteAddr = page * pageSize;
        final wordAddr = byteAddr ~/ 2;

        final start = byteAddr;
        final end = (byteAddr + pageSize).clamp(0, hexData.length);
        final pageBytes = Uint8List(pageSize)..fillRange(0, pageSize, 0xFF);
        pageBytes.setRange(0, end - start, hexData.sublist(start, end));

        await _loadAddress(wordAddr);
        await _programPage(pageBytes);

        onProgress?.call((page + 1) / totalPages);
      }

      await _leaveProgMode();
      _log('업로드 완료!');
    } finally {
      await _detach();
    }
  }
}
