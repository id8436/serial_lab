import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

/// STK500v1 프로토콜 구현 (Arduino Uno/Nano/Mega Optiboot 호환)
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
  Future<List<int>> _read(int n, {int timeoutMs = 3000}) async {
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
  Future<void> _expectOk() async {
    final resp = await _read(2);
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

  /// 부트로더와 동기화 (최대 6회 시도)
  Future<void> _sync() async {
    for (int attempt = 1; attempt <= 6; attempt++) {
      _rxBuf.clear();
      await _send([_stkGetSync, _crcEop]);
      try {
        await _expectOk();
        _log('부트로더 동기화 성공');
        return;
      } catch (_) {
        _log('동기화 시도 $attempt/6...');
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    throw Exception('STK500: 부트로더 동기화 실패\n'
        '- 보드가 연결되어 있는지 확인하세요\n'
        '- 지원 보드: Uno, Nano, Mega (Optiboot 탑재 AVR 계열)');
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
      // DTR 펄스로 리셋 트리거
      _log('Arduino 리셋 중...');
      await _port.setDTR(true);
      await Future.delayed(const Duration(milliseconds: 100));
      await _port.setDTR(false);
      // 부트로더가 준비될 때까지 대기 (optiboot: ~100ms)
      await Future.delayed(const Duration(milliseconds: 200));

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
