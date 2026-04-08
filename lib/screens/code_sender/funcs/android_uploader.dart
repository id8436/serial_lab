import 'dart:io';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'hex_parser.dart';
import 'stk500_uploader.dart';

/// 보드별 설정
class BoardUploadConfig {
  final int pageSize;
  final int baudRate;

  const BoardUploadConfig({required this.pageSize, required this.baudRate});
}

/// Android USB 업로드 오케스트레이터
///
/// PC에서는 기존 arduino-cli 방식을 유지하고,
/// Android에서는 STK500v1 프로토콜로 직접 업로드합니다.
class AndroidUploader {
  /// FQBN → 보드 설정 매핑
  static const Map<String, BoardUploadConfig> _boardConfigs = {
    'uno': BoardUploadConfig(pageSize: 128, baudRate: 115200),
    'nano': BoardUploadConfig(pageSize: 128, baudRate: 115200),
    'mega': BoardUploadConfig(pageSize: 256, baudRate: 115200),
    'mega2560': BoardUploadConfig(pageSize: 256, baudRate: 115200),
    'leonardo': BoardUploadConfig(pageSize: 128, baudRate: 57600),
    'micro': BoardUploadConfig(pageSize: 128, baudRate: 57600),
    'pro': BoardUploadConfig(pageSize: 128, baudRate: 57600),
    'promini': BoardUploadConfig(pageSize: 128, baudRate: 57600),
  };

  static const BoardUploadConfig _defaultConfig = BoardUploadConfig(
    pageSize: 128,
    baudRate: 115200,
  );

  /// FQBN에서 보드 설정 조회
  /// 예: 'arduino:avr:nano' → 'nano' → BoardUploadConfig(128, 115200)
  static BoardUploadConfig _configFor(String fqbn) {
    final lower = fqbn.toLowerCase();
    for (final entry in _boardConfigs.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return _defaultConfig;
  }

  /// .hex 파일을 USB로 연결된 Arduino에 업로드합니다.
  ///
  /// [hexContent]     - Intel HEX 파일 문자열
  /// [fqbn]           - 보드 FQBN (예: 'arduino:avr:uno')
  /// [deviceAddress]  - USB 장치 주소 (`USB:<vid>:<pid>:<deviceId>` 형식)
  /// [onLog]          - 로그 출력 콜백
  /// [onProgress]     - 진행률 콜백 (0.0 ~ 1.0)
  static Future<String> uploadHex({
    required String hexContent,
    required String fqbn,
    required String deviceAddress,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      return '❌ AndroidUploader는 Android에서만 사용 가능합니다.';
    }

    final log = onLog ?? (_) {};

    // USB 주소 파싱: 'USB:<vid>:<pid>:<deviceId>'
    final parts = deviceAddress.split(':');
    if (parts.length < 3 || parts[0] != 'USB') {
      return '❌ 유효하지 않은 USB 주소: $deviceAddress';
    }

    final vid = int.tryParse(parts[1]);
    final pid = int.tryParse(parts[2]);
    if (vid == null || pid == null) {
      return '❌ VID/PID 파싱 실패: $deviceAddress';
    }

    // HEX 파싱
    log('HEX 파일 파싱 중...');
    final rawData = IntelHexParser.parse(hexContent);
    if (rawData.isEmpty) {
      return '❌ HEX 파일이 비어있거나 형식이 올바르지 않습니다.';
    }

    final config = _configFor(fqbn);
    final hexData = IntelHexParser.padToPageSize(rawData, config.pageSize);
    log('펌웨어 크기: ${rawData.length} bytes → ${hexData.length} bytes (패딩 후)');

    // USB 장치 검색
    log('USB 장치 검색 중 (VID:$vid PID:$pid)...');
    final devices = await UsbSerial.listDevices();
    UsbDevice? device;
    for (final d in devices) {
      if (d.vid == vid && d.pid == pid) {
        device = d;
        break;
      }
    }

    if (device == null) {
      return '❌ USB 장치를 찾을 수 없습니다 (VID:$vid PID:$pid)\n'
          '장치가 연결되어 있는지 확인하세요.';
    }

    // 포트 열기
    log('USB 포트 열기 중...');
    final port = await device.create();
    if (port == null) return '❌ USB 포트 생성 실패';

    final opened = await port.open();
    if (!opened) return '❌ USB 포트 열기 실패 (권한 문제일 수 있습니다)';

    try {
      await port.setPortParameters(
        config.baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      final uploader = Stk500Uploader(port, log);
      await uploader.upload(
        hexData,
        pageSize: config.pageSize,
        onProgress: onProgress,
      );

      return '✅ 업로드 완료!';
    } catch (e) {
      return '❌ 업로드 오류: $e';
    } finally {
      await port.close();
      log('USB 포트 닫힘');
    }
  }

  /// 서버에서 받은 바이너리 데이터(Intel HEX 문자열)를 USB로 업로드합니다.
  ///
  /// [hexBytes]       - 서버에서 받은 Intel HEX 파일 바이트 데이터
  /// [fqbn]           - 보드 FQBN (예: 'arduino:avr:uno')
  /// [deviceAddress]  - USB 장치 주소 (`USB:<vid>:<pid>:<deviceId>` 형식)
  /// [onLog]          - 로그 출력 콜백
  /// [onProgress]     - 진행률 콜백 (0.0 ~ 1.0)
  static Future<String> uploadFromBytes({
    required Uint8List hexBytes,
    required String fqbn,
    required String deviceAddress,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final hexContent = String.fromCharCodes(hexBytes);
    return uploadHex(
      hexContent: hexContent,
      fqbn: fqbn,
      deviceAddress: deviceAddress,
      onLog: onLog,
      onProgress: onProgress,
    );
  }
}
