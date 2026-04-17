/// Cloud Arduino compilation service.
///
/// Sends sketch source code to `jinhan.site` compile server and returns
/// a [CompileResult] containing the binary firmware + FQBN metadata.
///
/// Endpoint: POST /utility/compiler/compile/
/// Request body: JSON {"code", "fqbn"}
/// Response: JSON {"success", "hex_content", "fqbn", "message"}
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:serial_lab/models/compile_result.dart';

/// 원격 서버를 통한 Arduino 코드 컴파일 서비스
class CloudCompileService {
  static const String _serverUrl = 'https://jinhan.site';
  static const Duration _timeout = Duration(seconds: 60);

  /// 서버가 확실히 지원하는 보드 목록
  static const _serverBoards = <String>{
    // ─── arduino:avr ───
    'arduino:avr:uno',
    'arduino:avr:nano',
    'arduino:avr:mega',
    'arduino:avr:leonardo',
    'arduino:avr:micro',
    'arduino:avr:pro',
    'arduino:avr:mini',
    'arduino:avr:diecimila',
    'arduino:avr:megaADK',
    'arduino:avr:esplora',
    'arduino:avr:yun',
    'arduino:avr:yunmini',
    'arduino:avr:lilypad',
    'arduino:avr:LilyPadUSB',
    'arduino:avr:fio',
    'arduino:avr:bt',
    'arduino:avr:ethernet',
    'arduino:avr:robotControl',
    'arduino:avr:robotMotor',
    'arduino:avr:circuitplay32u4cat',
    // ─── arduino:megaavr ───
    'arduino:megaavr:nanoevery',
    // ─── arduino:samd ───
    'arduino:samd:mkrzero',
    'arduino:samd:mkr1000',
    'arduino:samd:mkrwifi1010',
    'arduino:samd:nano_33_iot',
    'arduino:samd:mkrfox1200',
    'arduino:samd:mkrwan1300',
    'arduino:samd:mkrwan1310',
    'arduino:samd:mkrgsm1400',
    'arduino:samd:mkrnb1500',
    'arduino:samd:mkrvidor4000',
    // ─── arduino:renesas_uno ───
    'arduino:renesas_uno:unor4wifi',
    'arduino:renesas_uno:unor4minima',
    // ─── esp32:esp32 ───
    'esp32:esp32:esp32',
    'esp32:esp32:esp32s2',
    'esp32:esp32:esp32s3',
    'esp32:esp32:esp32c3',
    'esp32:esp32:esp32c6',
    'esp32:esp32:esp32h2',
    // ─── esp8266:esp8266 ───
    'esp8266:esp8266:generic',
    'esp8266:esp8266:d1_mini',
    'esp8266:esp8266:d1_mini_pro',
    'esp8266:esp8266:d1_mini_lite',
    'esp8266:esp8266:d1_mini_clone',
    'esp8266:esp8266:d1',
    'esp8266:esp8266:d1_wroom_02',
    'esp8266:esp8266:nodemcuv2',
    'esp8266:esp8266:nodemcu',
    'esp8266:esp8266:esp8285',
    // ─── STMicroelectronics:stm32 ───
    'STMicroelectronics:stm32:GenF4',
    'STMicroelectronics:stm32:GenF1',
    'STMicroelectronics:stm32:GenF0',
    'STMicroelectronics:stm32:GenF3',
    'STMicroelectronics:stm32:GenL4',
    'STMicroelectronics:stm32:Nucleo_64',
    'STMicroelectronics:stm32:Nucleo_144',
    'STMicroelectronics:stm32:Disco',
    'STMicroelectronics:stm32:Maple',
    // ─── rp2040:rp2040 ───
    'rp2040:rp2040:rpipico',
    'rp2040:rp2040:rpipicow',
    'rp2040:rp2040:rpipico2',
    // ─── adafruit:samd ───
    'adafruit:samd:adafruit_feather_m0',
    'adafruit:samd:adafruit_itsybitsy_m0',
    'adafruit:samd:adafruit_itsybitsy_m4',
    'adafruit:samd:adafruit_metro_m4',
    'adafruit:samd:adafruit_qtpy_m0',
    // ─── adafruit:nrf52 ───
    'adafruit:nrf52:feather52840',
  };

  /// 서버에 없는 변형 보드를 호환 FQBN으로 변환 (서버가 직접 지원하지 않는 보드만)
  static const _fqbnFallback = <String, String>{
    // ─── ESP8266 기타 보드 → generic ───
    'esp8266:esp8266:espduino': 'esp8266:esp8266:generic',
    'esp8266:esp8266:espino': 'esp8266:esp8266:generic',
    'esp8266:esp8266:espinotee': 'esp8266:esp8266:generic',
    'esp8266:esp8266:espresso_lite_v1': 'esp8266:esp8266:generic',
    'esp8266:esp8266:espresso_lite_v2': 'esp8266:esp8266:generic',
    'esp8266:esp8266:wifinfo': 'esp8266:esp8266:generic',
    'esp8266:esp8266:wifiduino': 'esp8266:esp8266:generic',
    'esp8266:esp8266:wifi_kit_8': 'esp8266:esp8266:generic',
    'esp8266:esp8266:wifi_slot': 'esp8266:esp8266:generic',
    'esp8266:esp8266:modwifi': 'esp8266:esp8266:generic',
    'esp8266:esp8266:thing': 'esp8266:esp8266:generic',
    'esp8266:esp8266:thingdev': 'esp8266:esp8266:generic',
    'esp8266:esp8266:blynk': 'esp8266:esp8266:generic',
    'esp8266:esp8266:sonoff': 'esp8266:esp8266:generic',
    'esp8266:esp8266:oak': 'esp8266:esp8266:generic',
    'esp8266:esp8266:wiolink': 'esp8266:esp8266:generic',
    'esp8266:esp8266:espectro': 'esp8266:esp8266:generic',
    'esp8266:esp8266:inventone': 'esp8266:esp8266:generic',
    'esp8266:esp8266:agruminolemon': 'esp8266:esp8266:generic',
    'esp8266:esp8266:gen4iod': 'esp8266:esp8266:generic',
    'esp8266:esp8266:espmxdevkit': 'esp8266:esp8266:generic',
    'esp8266:esp8266:phoenix_v1': 'esp8266:esp8266:generic',
    'esp8266:esp8266:phoenix_v2': 'esp8266:esp8266:generic',
    'esp8266:esp8266:eduinowifi': 'esp8266:esp8266:generic',
    'esp8266:esp8266:arduino-esp8266': 'esp8266:esp8266:generic',
    'esp8266:esp8266:mercury': 'esp8266:esp8266:generic',

    // ─── ESP32 변형 → 칩별 기본 보드 ───
    'esp32:esp32:esp32da': 'esp32:esp32:esp32',
    'esp32:esp32:esp32wrover': 'esp32:esp32:esp32',
    'esp32:esp32:esp32wroverkit': 'esp32:esp32:esp32',
    'esp32:esp32:nodemcu-32s': 'esp32:esp32:esp32',
    'esp32:esp32:lolin32': 'esp32:esp32:esp32',
    'esp32:esp32:lolin32_lite': 'esp32:esp32:esp32',
    'esp32:esp32:d1_mini32': 'esp32:esp32:esp32',
    'esp32:esp32:pico32': 'esp32:esp32:esp32',
    'esp32:esp32:nano32': 'esp32:esp32:esp32',
    'esp32:esp32:pocket_32': 'esp32:esp32:esp32',
    'esp32:esp32:fm_devkit': 'esp32:esp32:esp32',
    'esp32:esp32:featheresp32': 'esp32:esp32:esp32',
    'esp32:esp32:esp32thing': 'esp32:esp32:esp32',
    'esp32:esp32:esp32thing_plus': 'esp32:esp32:esp32',
    'esp32:esp32:esp32-poe': 'esp32:esp32:esp32',
    'esp32:esp32:esp32-poe-iso': 'esp32:esp32:esp32',
    'esp32:esp32:esp32-evb': 'esp32:esp32:esp32',
    'esp32:esp32:esp32-gateway': 'esp32:esp32:esp32',
    'esp32:esp32:ttgo-t1': 'esp32:esp32:esp32',
    'esp32:esp32:ttgo-lora32-v1': 'esp32:esp32:esp32',
    'esp32:esp32:ttgo-lora32-v21new': 'esp32:esp32:esp32',
    'esp32:esp32:ttgo-t-beam': 'esp32:esp32:esp32',
    'esp32:esp32:firebeetle32': 'esp32:esp32:esp32',
    'esp32:esp32:heltec_wifi_kit_32': 'esp32:esp32:esp32',
    'esp32:esp32:heltec_wifi_lora_32': 'esp32:esp32:esp32',
    'esp32:esp32:heltec_wifi_lora_32_V2': 'esp32:esp32:esp32',
    'esp32:esp32:m5stack-core-esp32': 'esp32:esp32:esp32',
    'esp32:esp32:m5stack-core2': 'esp32:esp32:esp32',
    'esp32:esp32:m5stick-c': 'esp32:esp32:esp32',
    'esp32:esp32:m5stack-atom': 'esp32:esp32:esp32',
    'esp32:esp32:m5stack-fire': 'esp32:esp32:esp32',
    'esp32:esp32:m5stack-timer-cam': 'esp32:esp32:esp32',
    'esp32:esp32:odroid_esp32': 'esp32:esp32:esp32',
    'esp32:esp32:wifiduino32': 'esp32:esp32:esp32',
    'esp32:esp32:hornbill32dev': 'esp32:esp32:esp32',
    'esp32:esp32:onehorse32dev': 'esp32:esp32:esp32',
    'esp32:esp32:watchy': 'esp32:esp32:esp32',
    'esp32:esp32:denky32': 'esp32:esp32:esp32',
    'esp32:esp32:denky_d4': 'esp32:esp32:esp32',
    'esp32:esp32:lolin_s2_mini': 'esp32:esp32:esp32s2',
    'esp32:esp32:lolin_s2_pico': 'esp32:esp32:esp32s2',
    'esp32:esp32:um_feathers2': 'esp32:esp32:esp32s2',
    'esp32:esp32:um_tinys2': 'esp32:esp32:esp32s2',
    'esp32:esp32:adafruit_feather_esp32s2': 'esp32:esp32:esp32s2',
    'esp32:esp32:adafruit_feather_esp32s2_tft': 'esp32:esp32:esp32s2',
    'esp32:esp32:adafruit_qtpy_esp32s2': 'esp32:esp32:esp32s2',
    'esp32:esp32:lolin_s3': 'esp32:esp32:esp32s3',
    'esp32:esp32:lolin_s3_mini': 'esp32:esp32:esp32s3',
    'esp32:esp32:lolin_s3_pro': 'esp32:esp32:esp32s3',
    'esp32:esp32:XIAO_ESP32S3': 'esp32:esp32:esp32s3',
    'esp32:esp32:um_feathers3': 'esp32:esp32:esp32s3',
    'esp32:esp32:um_tinys3': 'esp32:esp32:esp32s3',
    'esp32:esp32:um_pros3': 'esp32:esp32:esp32s3',
    'esp32:esp32:adafruit_feather_esp32s3': 'esp32:esp32:esp32s3',
    'esp32:esp32:adafruit_feather_esp32s3_tft': 'esp32:esp32:esp32s3',
    'esp32:esp32:adafruit_qtpy_esp32s3_nopsram': 'esp32:esp32:esp32s3',
    'esp32:esp32:dfrobot_firebeetle2_esp32s3': 'esp32:esp32:esp32s3',
    'esp32:esp32:m5stack-stamps3': 'esp32:esp32:esp32s3',
    'esp32:esp32:m5stack-atoms3': 'esp32:esp32:esp32s3',
    'esp32:esp32:heltec_wifi_lora_32_V3': 'esp32:esp32:esp32s3',
    'esp32:esp32:YB_ESP32_S3': 'esp32:esp32:esp32s3',
    'esp32:esp32:bee_s3': 'esp32:esp32:esp32s3',
    'esp32:esp32:lolin_c3_mini': 'esp32:esp32:esp32c3',
    'esp32:esp32:lolin_c3_pico': 'esp32:esp32:esp32c3',
    'esp32:esp32:XIAO_ESP32C3': 'esp32:esp32:esp32c3',
    'esp32:esp32:adafruit_qtpy_esp32c3': 'esp32:esp32:esp32c3',
    'esp32:esp32:AirM2M_CORE_ESP32C3': 'esp32:esp32:esp32c3',

    // ─── Arduino AVR 와 SAMD → cpu 옵션 차이 ───
    'arduino:avr:nano:cpu=atmega328old': 'arduino:avr:nano',
    // ─── arduino:mbed_nano → 서버에 없으면 가장 유사한 보드로 ───
    'arduino:mbed_nano:nanorp2040connect': 'rp2040:rp2040:rpipico',
    'arduino:mbed_nano:nano33ble': 'arduino:samd:nano_33_iot',
    // ─── Arduino ESP32 (공식) → esp32:esp32 ───
    'arduino:esp32:nano_nora': 'esp32:esp32:esp32s3',
    // ─── Seeed → Adafruit (비슷한 칩 기반) ───
    'Seeeduino:samd:seeed_XIAO_m0': 'adafruit:samd:adafruit_qtpy_m0',
    'Seeeduino:nrf52:xiaonRF52840': 'adafruit:nrf52:feather52840',
    // ─── RP2040 변형 ───
    'rp2040:rp2040:adafruit_qtpy_rp2040': 'rp2040:rp2040:rpipico',
    'rp2040:rp2040:adafruit_feather_rp2040': 'rp2040:rp2040:rpipico',
    'rp2040:rp2040:sparkfun_promicro_rp2040': 'rp2040:rp2040:rpipico',
    'rp2040:rp2040:seeed_xiao_rp2040': 'rp2040:rp2040:rpipico',
    'rp2040:rp2040:waveshare_rp2040_zero': 'rp2040:rp2040:rpipico',
    'rp2040:rp2040:pimoroni_tiny2040': 'rp2040:rp2040:rpipico',
  };

  /// 서버가 지원하는 FQBN을 결정 (정적 맵 → 플랫폼 추론 → 원본)
  static String _resolveEffectiveFqbn(String fqbn) {
    // 1) 서버에서 바로 지원
    if (_serverBoards.contains(fqbn)) return fqbn;
    // 2) 정확한 매핑이 있는 경우
    final mapped = _fqbnFallback[fqbn];
    if (mapped != null) return mapped;
    // 3) 플랫폼+칩 기반 추론 (맵에 없는 미래 보드 대응)
    final parts = fqbn.split(':');
    if (parts.length >= 3) {
      final platform = '${parts[0]}:${parts[1]}';
      final board = parts[2].toLowerCase();
      switch (platform) {
        case 'esp8266:esp8266':
          return 'esp8266:esp8266:generic';
        case 'esp32:esp32':
          if (board.contains('s3')) return 'esp32:esp32:esp32s3';
          if (board.contains('s2')) return 'esp32:esp32:esp32s2';
          if (board.contains('c3')) return 'esp32:esp32:esp32c3';
          if (board.contains('c6')) return 'esp32:esp32:esp32c3';
          if (board.contains('h2')) return 'esp32:esp32:esp32c3';
          return 'esp32:esp32:esp32';
        case 'arduino:avr':
          return 'arduino:avr:uno';
        case 'arduino:megaavr':
          return 'arduino:megaavr:nanoevery';
        case 'arduino:samd':
          return 'arduino:samd:mkrzero';
        case 'arduino:renesas_uno':
          return 'arduino:renesas_uno:unor4minima';
        case 'arduino:mbed_nano':
          return 'arduino:samd:nano_33_iot';
        case 'arduino:mbed_rp2040':
          return 'rp2040:rp2040:rpipico';
        case 'arduino:esp32':
          return 'esp32:esp32:esp32s3';
        case 'STMicroelectronics:stm32':
          return 'STMicroelectronics:stm32:GenF4';
        case 'rp2040:rp2040':
          return 'rp2040:rp2040:rpipico';
        case 'adafruit:samd':
          return 'adafruit:samd:adafruit_feather_m0';
        case 'adafruit:nrf52':
          return 'adafruit:nrf52:feather52840';
        case 'Seeeduino:samd':
          return 'adafruit:samd:adafruit_qtpy_m0';
        case 'Seeeduino:nrf52':
          return 'adafruit:nrf52:feather52840';
      }
    }
    return fqbn;
  }

  /// 코드를 원격 서버에서 컴파일하고 바이너리를 반환합니다.
  ///
  /// [code] - Arduino 스케치 코드
  /// [fqbn] - 보드 FQBN (예: 'arduino:avr:uno')
  static Future<CompileResult> compile({
    required String code,
    required String fqbn,
    String? format,
  }) async {
    // 서버에 없는 변형 보드는 호환 FQBN으로 교체
    final effectiveFqbn = _resolveEffectiveFqbn(fqbn);

    final url = _serverUrl.endsWith('/')
        ? '${_serverUrl}utility/compiler/compile/'
        : '$_serverUrl/utility/compiler/compile/';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'fqbn': effectiveFqbn,
              if (format != null && format.isNotEmpty) 'format': format,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      final output = body['output'] as String? ?? body['message'] as String? ?? '';
      final resultFormat = body['format'] as String? ?? 'hex';
      final requestId = body['request_id'] as String?;
      final errorCode = body['error_code'] as String?;
      final compileMs = (body['compile_ms'] as num?)?.toInt();
      final artifactBase64 = body['artifact_base64'] as String?;
      final legacyHexBase64 = body['hex'] as String?;

      Uint8List? binaryData;
      final encoded = artifactBase64 ?? legacyHexBase64;
      if (success && encoded != null && encoded.isNotEmpty) {
        binaryData = base64Decode(encoded);
      }

      return CompileResult(
        success: success,
        binaryData: binaryData,
        output: output,
        format: resultFormat,
        requestId: requestId,
        errorCode: errorCode,
        compileMs: compileMs,
        statusCode: response.statusCode,
      );
    } on FormatException {
      return const CompileResult(
        success: false,
        errorCode: 'INVALID_RESPONSE',
        output: 'Invalid JSON response from compile server',
      );
    } on http.ClientException catch (e) {
      return CompileResult(
        success: false,
        errorCode: 'NETWORK_ERROR',
        output: 'Connection error: ${e.message}',
      );
    } on Exception catch (e) {
      final isTimeout = e.toString().toLowerCase().contains('timeout');
      return CompileResult(
        success: false,
        errorCode: isTimeout ? 'TIMEOUT' : 'CLIENT_ERROR',
        output: isTimeout ? 'Request timed out after ${_timeout.inSeconds}s' : 'Error: $e',
      );
    } catch (e) {
      return CompileResult(
        success: false,
        errorCode: 'UNKNOWN_ERROR',
        output: 'Error: $e',
      );
    }
  }
}
