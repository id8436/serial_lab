/// Android USB firmware uploader — protocol router.
///
/// Receives compiled firmware bytes + [UploadProtocol] and delegates to
/// the correct protocol-specific uploader:
///   STK500 → [Stk500Uploader]   (Uno, Nano, Mega)
///   AVR109 → [Avr109Uploader]   (Leonardo, Micro)
///   ESP    → [EsptoolUploader]  (ESP32, ESP8266)
///   STM32  → [Stm32Uploader]    (STM32Fx/Gx/Hx)
///   BOSSA  → [BossaUploader]    (SAMD21, SAMD51)
///
/// Also handles 1200-baud-touch for bootloaders that require it
/// (Caterina, SAMD).
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:serial_lab/models/upload_protocol.dart';
import 'hex_parser.dart';
import 'stk500_uploader.dart';
import 'avr109_uploader.dart';
import 'esptool_uploader.dart';
import 'stm32_uploader.dart';
import 'bossa_uploader.dart';

/// Android USB 업로드 오케스트레이터
///
/// PC에서는 기존 arduino-cli 방식을 유지하고,
/// Android에서는 STK500v1 프로토콜로 직접 업로드합니다.
class AndroidUploader {
  /// FQBN → 보드 설정 매핑
  static const Map<String, BoardUploadConfig> _boardConfigs = {
    'uno': BoardUploadConfig(pageSize: 128, baudRate: 115200),
    // 구형 Nano 클론은 부트로더 속도가 57600 (old bootloader)
    'nano': BoardUploadConfig(pageSize: 128, baudRate: 57600),
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

  /// Android USB 직접 업로드가 가능한 보드인지 확인
  static bool isSupportedBoard(String fqbn) {
    return getUploadProtocol(fqbn) != UploadProtocol.unsupported;
  }

  /// FQBN에서 업로드 프로토콜 결정
  static UploadProtocol getUploadProtocol(String fqbn) {
    final lower = fqbn.toLowerCase();
    // AVR (STK500 / AVR109)
    if (lower.contains('arduino:avr:')) {
      if (isCaterinaBoard(fqbn)) return UploadProtocol.avr109;
      return UploadProtocol.stk500;
    }
    // ESP32 계열 (esptool)
    if (lower.contains('esp32') || lower.contains('esp8266')) {
      return UploadProtocol.esptool;
    }
    // STM32 (UART bootloader)
    if (lower.contains('stm32') || lower.contains('stmicroelectronics')) {
      return UploadProtocol.stm32;
    }
    // SAMD (SAM-BA / BOSSA)
    if (lower.contains('samd') || lower.contains('arduino:samd') ||
        lower.contains('mkr') || lower.contains('nano_33_iot')) {
      return UploadProtocol.bossa;
    }
    return UploadProtocol.unsupported;
  }

  /// 서버 컴파일 시 요청할 포맷 (hex / bin)
  static String getCompileFormat(String fqbn) {
    final proto = getUploadProtocol(fqbn);
    switch (proto) {
      case UploadProtocol.stk500:
      case UploadProtocol.avr109:
        return 'hex';
      case UploadProtocol.esptool:
      case UploadProtocol.stm32:
      case UploadProtocol.bossa:
        return 'bin';
      case UploadProtocol.unsupported:
        return 'hex';
    }
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

    // Caterina 보드는 uploadCaterina를 사용해야 함
    if (isCaterinaBoard(fqbn)) {
      return '❌ $fqbn는 Caterina(AVR109) 보드입니다.\n'
          'uploadCaterina를 사용해야 합니다.';
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

    // USB 포트 안정화 대기 (드라이버 초기화 완료 후 파라미터 설정)
    await Future.delayed(const Duration(milliseconds: 400));

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

  /// 이미 열린 UsbPort를 사용하여 업로드합니다 (disconnect 없이 업로드할 때 사용).
  ///
  /// [hexContent]  - Intel HEX 파일 문자열
  /// [fqbn]        - 보드 FQBN
  /// [port]        - 이미 열린 UsbPort
  /// [onLog]       - 로그 출력 콜백
  /// [onProgress]  - 진행률 콜백 (0.0 ~ 1.0)
  static Future<String> uploadHexViaPort({
    required String hexContent,
    required String fqbn,
    required UsbPort port,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    // Caterina 보드는 STK500이 아닌 AVR109를 사용해야 함
    if (isCaterinaBoard(fqbn)) {
      return '❌ $fqbn는 Caterina(AVR109) 보드입니다.\n'
          'uploadCaterina를 사용해야 합니다.';
    }

    final log = onLog ?? (_) {};

    // HEX 파싱
    log('HEX 파일 파싱 중...');
    final rawData = IntelHexParser.parse(hexContent);
    if (rawData.isEmpty) {
      return '❌ HEX 파일이 비어있거나 형식이 올바르지 않습니다.';
    }

    final config = _configFor(fqbn);
    final hexData = IntelHexParser.padToPageSize(rawData, config.pageSize);
    log('펌웨어 크기: ${rawData.length} bytes → ${hexData.length} bytes (패딩 후)');

    // 업로드 전 보드레이트 재설정 후 안정화 대기
    await port.setPortParameters(
      config.baudRate,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final uploader = Stk500Uploader(port, log);
      await uploader.upload(hexData, pageSize: config.pageSize, onProgress: onProgress);
      return '✅ 업로드 완료!';
    } catch (e) {
      // baud rate fallback: 115200 ↔ 57600 자동 전환
      final altBaud = config.baudRate == 115200 ? 57600 : 115200;
      log('보드레이트 $altBaud 으로 재시도 중...');
      try {
        await port.setPortParameters(
          altBaud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
        await Future.delayed(const Duration(milliseconds: 200));
        final uploader2 = Stk500Uploader(port, log);
        await uploader2.upload(hexData, pageSize: config.pageSize, onProgress: onProgress);
        return '✅ 업로드 완료! (baud=$altBaud)';
      } catch (_) {
        return '❌ 업로드 오류: $e';
      }
    }
    // 포트는 닫지 않음 — 호출자(SerialProvider)가 관리
  }

  /// CH340/CP210x 칩 기반 장치일 때 보드 오감지 가능성 안내
  static String _ch340Hint(String deviceAddress) {
    final addr = deviceAddress.toLowerCase();
    if (addr.contains(':1a86:') || addr.contains(':10c4:')) {
      return '💡 이 USB 칩(CH340/CP210x)은 ESP8266/ESP32 보드에서도 사용됩니다.\n'
          '보드가 ESP 계열이면 Android USB 업로드를 지원하지 않습니다.\n'
          '기기 설정에서 올바른 보드를 선택해 주세요.';
    }
    return '';
  }

  /// uploadFromBytes의 이미 열린 포트 버전
  static Future<String> uploadFromBytesViaPort({
    required Uint8List hexBytes,
    required String fqbn,
    required UsbPort port,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final hexContent = String.fromCharCodes(hexBytes);
    return uploadHexViaPort(
      hexContent: hexContent,
      fqbn: fqbn,
      port: port,
      onLog: onLog,
      onProgress: onProgress,
    );
  }

  // ─── Caterina (AVR109) ────────────────────────────────────

  /// ATmega32u4 네이티브 USB 보드 (Caterina 부트로더) 여부 판별
  static bool isCaterinaBoard(String fqbn) {
    final lower = fqbn.toLowerCase();
    return lower.contains('leonardo') ||
        lower.contains(':micro') ||
        lower.contains('esplora') ||
        lower.contains('robotControl') ||
        lower.contains('yun');
  }

  /// 앱 PID → Caterina 부트로더 PID (상위 1비트 클리어)
  static int _caterinaBootloaderPid(int appPid) => appPid & 0x7FFF;

  /// Arduino LLC(0x2341) ↔ Arduino SRL(0x2A03) VID 교차 매핑
  /// 일부 Leonardo/Micro 보드는 앱 모드와 부트로더 모드에서 VID가 다름
  static int? _arduinoAlternateVid(int vid) {
    const llc = 9025;  // 0x2341
    const srl = 10755; // 0x2A03
    if (vid == llc) return srl;
    if (vid == srl) return llc;
    return null;
  }

  /// VID가 원래 VID 또는 대체 Arduino VID인지 확인
  static bool _vidMatches(int? deviceVid, int vid) {
    if (deviceVid == vid) return true;
    final alt = _arduinoAlternateVid(vid);
    return alt != null && deviceVid == alt;
  }

  /// Arduino Caterina 부트로더를 통한 업로드
  ///
  /// 1200 baud touch로 리셋 유도 → 부트로더 장치 탐지 → AVR109 업로드
  ///
  /// [touchPort] - 이미 열린 포트가 있으면 그걸로 1200 baud touch (새 포트 안 염)
  static Future<String> uploadCaterina({
    required String hexContent,
    required String fqbn,
    required String deviceAddress,
    UsbPort? touchPort,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final log = onLog ?? (_) {};

    // VID/PID 파싱
    final parts = deviceAddress.split(':');
    if (parts.length < 3 || parts[0] != 'USB') {
      return '❌ 유효하지 않은 USB 주소: $deviceAddress';
    }
    final vid = int.tryParse(parts[1]);
    final appPid = int.tryParse(parts[2]);
    if (vid == null || appPid == null) {
      return '❌ VID/PID 파싱 실패';
    }
    final bootloaderPid = _caterinaBootloaderPid(appPid);
    // Arduino LLC(0x2341=9025) ↔ Arduino SRL(0x2A03=10755): 부트로더와 앱 VID가 다를 수 있음
    final altVid = _arduinoAlternateVid(vid);
    log('Leonardo: VID=$vid${altVid != null ? "(alt=$altVid)" : ""}, '
        'appPID=0x${appPid.toRadixString(16)}, bootloaderPID=0x${bootloaderPid.toRadixString(16)}');

    // HEX 파싱
    log('HEX 파일 파싱 중...');
    final rawData = IntelHexParser.parse(hexContent);
    if (rawData.isEmpty) {
      return '❌ HEX 파일이 비어있거나 형식이 올바르지 않습니다.';
    }
    final config = _configFor(fqbn);
    final hexData = IntelHexParser.padToPageSize(rawData, config.pageSize);
    log('펌웨어 크기: ${rawData.length} bytes → ${hexData.length} bytes');

    // ── 1200 baud touch ──
    bool touchDone = false;
    for (int touchAttempt = 1; touchAttempt <= 2; touchAttempt++) {
      log('Leonardo 리셋 중... (1200 baud touch, 시도 $touchAttempt/2)');
      try {
        if (touchPort != null) {
          // 기존 열린 포트 사용 (권한 다이얼로그 없음)
          await touchPort.setPortParameters(
            1200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
          await touchPort.setDTR(true);
          await Future.delayed(const Duration(milliseconds: 300));
          await touchPort.setDTR(false);
          await Future.delayed(const Duration(milliseconds: 50));
          await touchPort.close();
          touchPort = null; // 한번 사용 후 무효화
          touchDone = true;
          log('1200 baud touch 완료 (기존 포트 사용)');
        } else {
          // 새 포트 열기 (첫 시도 fallback 또는 재시도)
          final allDevices = await UsbSerial.listDevices();
          final appDevice = allDevices.firstWhere(
            (d) => _vidMatches(d.vid, vid) && (d.pid == appPid || d.pid == bootloaderPid),
            orElse: () => throw Exception('장치 미발견'),
          );
          final newPort = await appDevice.create();
          if (newPort != null) {
            await newPort.open();
            await newPort.setPortParameters(
              1200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
            await newPort.setDTR(true);
            await Future.delayed(const Duration(milliseconds: 300));
            await newPort.setDTR(false);
            await Future.delayed(const Duration(milliseconds: 50));
            await newPort.close();
            touchDone = true;
            log('1200 baud touch 완료 (새 포트)');
          }
        }
      } catch (e) {
        log('1200 baud touch 실패: $e — 이미 부트로더 모드일 수 있음');
      }

      if (!touchDone) break; // 장치 자체가 없으면 재시도 무의미

      // USB 재열거 대기
      await Future.delayed(const Duration(milliseconds: 1000));

      // ── 부트로더 장치 대기 (최대 8초) ──
      log('부트로더 장치 대기 중...');
      UsbDevice? bootloaderDevice;
      bool foundWithAppPid = false;

      for (int i = 0; i < 16; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final devices = await UsbSerial.listDevices();

        if (i == 0) {
          final devList = devices.map((d) =>
              'VID:${d.vid} PID:0x${d.pid?.toRadixString(16)} ${d.productName ?? ""}').join(', ');
          log('USB 장치 목록: [$devList]');
        }

        // 1차: bootloader PID 정확 매칭 (확실한 부트로더 모드, VID 교차 허용)
        for (final d in devices) {
          if (_vidMatches(d.vid, vid) && d.pid == bootloaderPid && bootloaderPid != appPid) {
            bootloaderDevice = d;
            log('부트로더 장치 발견 (VID:${d.vid} PID:0x${d.pid?.toRadixString(16)}) ✓ bootloader PID');
            break;
          }
        }
        if (bootloaderDevice != null) break;

        // 2차 (4초 이후): app PID도 매칭 (VID 교차 허용)
        if (i >= 8) {
          for (final d in devices) {
            if (_vidMatches(d.vid, vid) && d.pid == appPid) {
              bootloaderDevice = d;
              foundWithAppPid = true;
              log('app PID로 장치 발견 — 부트로더 PID=${bootloaderPid != appPid ? "다름" : "동일"}');
              break;
            }
          }
          if (bootloaderDevice != null) break;
        }

        // 3차 (6초 이후): VID(교차 포함)만으로 매칭
        if (i >= 12) {
          for (final d in devices) {
            if (_vidMatches(d.vid, vid)) {
              bootloaderDevice = d;
              log('VID 매칭으로 장치 발견 (PID=0x${d.pid?.toRadixString(16)})');
              break;
            }
          }
          if (bootloaderDevice != null) break;
        }
      }

      if (bootloaderDevice == null) {
        if (touchAttempt < 2) {
          log('부트로더 미발견 — 1200 baud touch 재시도');
          continue;
        }
        return '❌ 부트로더 장치를 찾을 수 없습니다.\n'
            '- USB 케이블 연결 상태를 확인하세요\n'
            '- 리셋 버튼을 빠르게 2번 누른 직후 재시도하세요';
      }

      // app PID로 찾았으면 부트로더 진입 안 됐을 가능성
      if (foundWithAppPid && bootloaderPid != appPid) {
        log('⚠️ app PID 매칭 — 부트로더 진입 실패일 수 있음, 1200 baud touch 재시도');
        if (touchAttempt < 2) continue;
        log('⚠️ 그래도 시도합니다...');
      }

      // ── 부트로더 포트 열기 + AVR109 업로드 ──
      log('부트로더 포트 열기 중...');
      final bootPort = await bootloaderDevice.create();
      if (bootPort == null) return '❌ 부트로더 포트 생성 실패';
      final opened = await bootPort.open();
      if (!opened) return '❌ 부트로더 포트 열기 실패 (USB 권한 확인)';

      await bootPort.setPortParameters(
        57600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
      await bootPort.setDTR(true);
      await bootPort.setRTS(true);
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final uploader = Avr109Uploader(bootPort, log);
        await uploader.upload(hexData, pageSize: config.pageSize, onProgress: onProgress);
        return '✅ 업로드 완료!';
      } catch (e) {
        await bootPort.close();
        if (touchAttempt < 2) {
          log('AVR109 통신 실패 — 1200 baud touch 재시도: $e');
          await Future.delayed(const Duration(milliseconds: 500));
          continue; // 재시도
        }
        final hint = _ch340Hint(deviceAddress);
        return '❌ 업로드 오류: $e${hint.isNotEmpty ? '\n$hint' : ''}';
      } finally {
        try { await bootPort.close(); } catch (_) {}
        log('부트로더 포트 닫힘');
      }
    }

    return '❌ Leonardo 업로드 실패 — 모든 시도 소진';
  }

  /// uploadCaterina의 bytes 버전
  static Future<String> uploadCaterinaFromBytes({
    required Uint8List hexBytes,
    required String fqbn,
    required String deviceAddress,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    return uploadCaterina(
      hexContent: String.fromCharCodes(hexBytes),
      fqbn: fqbn,
      deviceAddress: deviceAddress,
      onLog: onLog,
      onProgress: onProgress,
    );
  }

  // ─── ESP32 / ESP8266 (esptool) ────────────────────────────

  /// ESP32/ESP8266 펌웨어 업로드 (raw binary)
  static Future<String> uploadEsp({
    required Uint8List firmware,
    required String fqbn,
    required String deviceAddress,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final log = onLog ?? (_) {};

    if (firmware.isEmpty) {
      return '❌ 펌웨어 데이터가 비어있습니다.';
    }
    log('펌웨어 크기: ${firmware.length} bytes');

    // USB 장치 검색 + 포트 열기
    final port = await _openPort(deviceAddress, log);
    if (port == null) return '❌ USB 포트 열기 실패';

    try {
      await port.setPortParameters(
          115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
      await Future.delayed(const Duration(milliseconds: 200));

      final uploader = EsptoolUploader(port, log);
      await uploader.upload(firmware, onProgress: onProgress);
      return '✅ 업로드 완료!';
    } catch (e) {
      return '❌ 업로드 오류: $e';
    } finally {
      await port.close();
      log('USB 포트 닫힘');
    }
  }

  // ─── STM32 (UART bootloader) ──────────────────────────────

  /// STM32 펌웨어 업로드 (raw binary)
  static Future<String> uploadStm32({
    required Uint8List firmware,
    required String fqbn,
    required String deviceAddress,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final log = onLog ?? (_) {};

    if (firmware.isEmpty) {
      return '❌ 펌웨어 데이터가 비어있습니다.';
    }
    log('펌웨어 크기: ${firmware.length} bytes');

    final port = await _openPort(deviceAddress, log);
    if (port == null) return '❌ USB 포트 열기 실패';

    try {
      // STM32 bootloader는 even parity 사용
      await port.setPortParameters(
          115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_EVEN);
      await Future.delayed(const Duration(milliseconds: 200));

      final uploader = Stm32Uploader(port, log);
      await uploader.upload(firmware, onProgress: onProgress);
      return '✅ 업로드 완료!';
    } catch (e) {
      return '❌ 업로드 오류: $e';
    } finally {
      await port.close();
      log('USB 포트 닫힘');
    }
  }

  // ─── SAMD (SAM-BA / BOSSA) ────────────────────────────────

  /// SAMD 펌웨어 업로드 — 1200 baud touch 후 SAM-BA 프로토콜
  static Future<String> uploadSamd({
    required Uint8List firmware,
    required String fqbn,
    required String deviceAddress,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final log = onLog ?? (_) {};

    if (firmware.isEmpty) {
      return '❌ 펌웨어 데이터가 비어있습니다.';
    }
    log('펌웨어 크기: ${firmware.length} bytes');

    // VID/PID 파싱
    final parts = deviceAddress.split(':');
    if (parts.length < 3 || parts[0] != 'USB') {
      return '❌ 유효하지 않은 USB 주소: $deviceAddress';
    }
    final vid = int.tryParse(parts[1]);
    final appPid = int.tryParse(parts[2]);
    if (vid == null || appPid == null) return '❌ VID/PID 파싱 실패';

    // 1200 baud touch로 SAM-BA 부트로더 진입 (Caterina와 동일)
    log('SAMD 리셋 중... (1200 baud touch)');
    try {
      final allDevices = await UsbSerial.listDevices();
      final appDevice = allDevices.firstWhere(
        (d) => d.vid == vid && d.pid == appPid,
        orElse: () => throw Exception('장치 미발견'),
      );
      final touchPort = await appDevice.create();
      if (touchPort != null) {
        await touchPort.open();
        await touchPort.setPortParameters(
            1200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
        await touchPort.setDTR(true);
        await Future.delayed(const Duration(milliseconds: 300));
        await touchPort.setDTR(false);
        await Future.delayed(const Duration(milliseconds: 50));
        await touchPort.close();
        log('1200 baud touch 완료');
      }
    } catch (e) {
      log('원래 장치 미발견 — 이미 부트로더 모드일 수 있음');
    }

    // USB 재열거 대기
    await Future.delayed(const Duration(milliseconds: 1500));

    // 부트로더 장치 대기 (최대 10초)
    log('SAM-BA 부트로더 대기 중...');
    UsbDevice? bootDevice;
    for (int i = 0; i < 16; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final devices = await UsbSerial.listDevices();
      for (final d in devices) {
        if (d.vid == vid) {
          bootDevice = d;
          break;
        }
      }
      if (bootDevice != null) break;
    }

    if (bootDevice == null) {
      return '❌ SAM-BA 부트로더 장치를 찾을 수 없습니다.';
    }

    final bootPort = await bootDevice.create();
    if (bootPort == null) return '❌ 부트로더 포트 생성 실패';
    final opened = await bootPort.open();
    if (!opened) return '❌ 부트로더 포트 열기 실패';

    await bootPort.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final isSamd51 = fqbn.toLowerCase().contains('samd51');
      final uploader = BossaUploader(bootPort, log);
      await uploader.upload(firmware,
          isSamd51: isSamd51, onProgress: onProgress);
      return '✅ 업로드 완료!';
    } catch (e) {
      return '❌ 업로드 오류: $e';
    } finally {
      await bootPort.close();
      log('부트로더 포트 닫힘');
    }
  }

  // ─── 통합 업로드 (프로토콜 자동 감지) ─────────────────────

  /// 바이너리 데이터를 프로토콜에 맞게 자동 업로드
  ///
  /// [touchPort] - Caterina/SAMD용: 이미 열린 포트로 1200 baud touch 수행
  static Future<String> uploadBinary({
    required Uint8List binaryData,
    required String fqbn,
    required String format,
    required String deviceAddress,
    UsbPort? touchPort,
    void Function(String)? onLog,
    void Function(double)? onProgress,
  }) async {
    final protocol = getUploadProtocol(fqbn);

    switch (protocol) {
      case UploadProtocol.stk500:
      case UploadProtocol.avr109:
        // AVR: 데이터가 HEX 텍스트
        final hexContent = String.fromCharCodes(binaryData);
        if (protocol == UploadProtocol.avr109) {
          return uploadCaterina(
            hexContent: hexContent, fqbn: fqbn,
            deviceAddress: deviceAddress,
            touchPort: touchPort,
            onLog: onLog, onProgress: onProgress,
          );
        }
        return uploadHex(
          hexContent: hexContent, fqbn: fqbn,
          deviceAddress: deviceAddress,
          onLog: onLog, onProgress: onProgress,
        );

      case UploadProtocol.esptool:
        // ESP: raw binary
        final firmware = _extractFirmware(binaryData, format);
        return uploadEsp(
          firmware: firmware, fqbn: fqbn,
          deviceAddress: deviceAddress,
          onLog: onLog, onProgress: onProgress,
        );

      case UploadProtocol.stm32:
        final firmware = _extractFirmware(binaryData, format);
        return uploadStm32(
          firmware: firmware, fqbn: fqbn,
          deviceAddress: deviceAddress,
          onLog: onLog, onProgress: onProgress,
        );

      case UploadProtocol.bossa:
        final firmware = _extractFirmware(binaryData, format);
        return uploadSamd(
          firmware: firmware, fqbn: fqbn,
          deviceAddress: deviceAddress,
          onLog: onLog, onProgress: onProgress,
        );

      case UploadProtocol.unsupported:
        return '❌ $fqbn 보드는 Android USB 업로드를 지원하지 않습니다.\n'
            'PC에서 업로드해 주세요.';
    }
  }

  /// 서버 응답 포맷에 따라 raw firmware 바이트 추출
  static Uint8List _extractFirmware(Uint8List data, String format) {
    if (format == 'bin') {
      return data; // 이미 raw binary
    }
    // HEX 포맷이면 파싱
    final hexContent = String.fromCharCodes(data);
    return IntelHexParser.parse(hexContent);
  }

  // ─── 공통 유틸 ────────────────────────────────────────────

  /// USB 장치 주소에서 포트 열기
  static Future<UsbPort?> _openPort(
      String deviceAddress, void Function(String) log) async {
    final parts = deviceAddress.split(':');
    if (parts.length < 3 || parts[0] != 'USB') {
      log('❌ 유효하지 않은 USB 주소: $deviceAddress');
      return null;
    }
    final vid = int.tryParse(parts[1]);
    final pid = int.tryParse(parts[2]);
    if (vid == null || pid == null) {
      log('❌ VID/PID 파싱 실패');
      return null;
    }

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
      log('❌ USB 장치를 찾을 수 없습니다');
      return null;
    }

    log('USB 포트 열기 중...');
    final port = await device.create();
    if (port == null) {
      log('❌ USB 포트 생성 실패');
      return null;
    }
    final opened = await port.open();
    if (!opened) {
      log('❌ USB 포트 열기 실패');
      return null;
    }
    await Future.delayed(const Duration(milliseconds: 400));
    return port;
  }
}
