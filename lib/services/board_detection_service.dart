/// USB device → FQBN auto-detection service.
///
/// Detection strategy (highest to lowest confidence):
/// 1. **VID:PID exact match** — e.g. `2341:0043` → `arduino:avr:uno`
/// 2. **VID family + name hints** — e.g. VID `1a86` (CH340) + name contains "esp32"
/// 3. **Name-only fallback** — e.g. product name contains "mega"
///
/// VID/PID values sourced from:
/// - Arduino official: https://github.com/arduino/ArduinoCore-avr/blob/master/boards.txt
/// - Espressif: https://github.com/espressif/usb-pids
/// - USB-IF assignments for CH340 (1a86), CP210x (10c4), FTDI (0403)
library;

import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/board_label_service.dart';

/// Maps USB device attributes to Arduino FQBN strings.
class BoardDetectionService {
  /// DeviceInfo로부터 FQBN을 감지한다.
  /// 감지 실패 시 [fallback]을 반환한다.
  static String detect(DeviceInfo? device, {required String fallback}) {
    if (device == null) return fallback;

    final deviceName = device.name.toLowerCase();
    final address = device.address.toLowerCase();

    // 1) VID:PID 정확 매칭 (가장 신뢰도 높음)
    for (final entry in vidPidToFqbn.entries) {
      if (address.contains(entry.key)) return entry.value;
    }

    // 2) VID 기반 패밀리 매칭 + 이름 보조
    final vid = _extractVid(address);
    if (vid != null) {
      final family = vidFamilyFqbn[vid];
      if (family != null) {
        final refined = _refineByName(deviceName);
        if (refined != null) return refined;
        return family;
      }
    }

    // 3) 이름 기반 fallback
    for (final entry in nameHints.entries) {
      if (deviceName.contains(entry.key)) return entry.value;
    }

    return fallback;
  }

  /// 주소(USB:vid:pid)로 보드 표시 이름 추정 (UI 표시용)
  static String displayNameFromAddress(String address) {
    final lower = address.toLowerCase();
    // VID:PID 정확 매칭
    for (final entry in vidPidToFqbn.entries) {
      if (lower.contains(entry.key)) return BoardLabelService.getLabel(entry.value);
    }
    // VID 패밀리 매칭
    final parts = lower.split(':');
    if (parts.length >= 2) {
      final vid = parts[1];
      final family = vidFamilyFqbn[vid];
      if (family != null) return BoardLabelService.getLabel(family);
    }
    return '';
  }

  // ─── VID:PID → FQBN 정확 매칭 테이블 ───

  static const vidPidToFqbn = <String, String>{
    // Arduino 공식 (VID 2341 / 2A03)
    '2341:0043': 'arduino:avr:uno',       // Uno R3
    '2341:0001': 'arduino:avr:uno',       // Uno
    '2341:0243': 'arduino:avr:uno',       // Uno R3 (alt)
    '2a03:0043': 'arduino:avr:uno',       // Uno (org)
    '2341:0058': 'arduino:avr:nano',      // Nano Every
    '2341:0070': 'arduino:esp32:nano_nora', // Nano ESP32 (ESP32-S3)
    '2341:8036': 'arduino:avr:leonardo',  // Leonardo
    '2341:0036': 'arduino:avr:leonardo',  // Leonardo (bootloader)
    '2341:8037': 'arduino:avr:micro',     // Micro
    '2341:0037': 'arduino:avr:micro',     // Micro (bootloader)
    '2341:003e': 'arduino:avr:micro',     // Micro (alt)
    '2341:0042': 'arduino:avr:mega',      // Mega 2560 R3
    '2341:0010': 'arduino:avr:mega',      // Mega 2560
    '2a03:0042': 'arduino:avr:mega',      // Mega 2560 (org)
    '2341:003f': 'arduino:megaavr:nanoevery', // Nano Every
    '2341:0056': 'arduino:samd:mkrzero',  // MKR Zero
    '2341:804e': 'arduino:samd:nano_33_iot', // Nano 33 IoT
    '2341:8054': 'arduino:mbed_nano:nanorp2040connect', // Nano RP2040 Connect
    '2341:005a': 'arduino:mbed_nano:nano33ble', // Nano 33 BLE
    '2341:0069': 'arduino:renesas_uno:unor4wifi', // UNO R4 WiFi
    '2341:0068': 'arduino:renesas_uno:unor4minima', // UNO R4 Minima
    '2341:804d': 'arduino:samd:mkrwifi1010', // MKR WiFi 1010
    '2341:005e': 'arduino:mbed_portenta:envie_m7', // Portenta H7

    // Espressif 네이티브 USB (VID 303a)
    '303a:1001': 'esp32:esp32:esp32s2',   // ESP32-S2
    '303a:0002': 'esp32:esp32:esp32s3',   // ESP32-S3
    '303a:0042': 'esp32:esp32:esp32c3',   // ESP32-C3

    // Raspberry Pi (VID 2e8a)
    '2e8a:0005': 'rp2040:rp2040:rpipico', // Pico
    '2e8a:000a': 'rp2040:rp2040:rpipicow', // Pico W

    // STM32 (VID 0483)
    '0483:5740': 'STMicroelectronics:stm32:GenF4', // STM32 CDC
    '1eaf:0004': 'STMicroelectronics:stm32:Maple', // Maple Mini

    // Teensy (VID 16c0)
    '16c0:0483': 'teensy:avr:teensy41',   // Teensy 4.x
    '16c0:0478': 'teensy:avr:teensy36',   // Teensy 3.x

    // Adafruit (VID 239a)
    '239a:800b': 'adafruit:samd:adafruit_feather_m0', // Feather M0
    '239a:80cb': 'adafruit:nrf52:feather52840', // Feather nRF52840
    '239a:8120': 'rp2040:rp2040:adafruit_qtpy_rp2040', // QT Py RP2040

    // Seeed (VID 2886)
    '2886:802f': 'Seeeduino:samd:seeed_XIAO_m0', // XIAO SAMD21
    '2886:0044': 'Seeeduino:nrf52:xiaonRF52840', // XIAO nRF52840
    '2886:004c': 'esp32:esp32:XIAO_ESP32S3', // XIAO ESP32S3
  };

  // ─── VID → 기본 FQBN (VID만으로 패밀리 추정) ───

  static const vidFamilyFqbn = <String, String>{
    '2341': 'arduino:avr:uno',
    '2a03': 'arduino:avr:uno',
    '303a': 'esp32:esp32:esp32s3',
    '10c4': 'esp32:esp32:esp32',     // CP210x → 대부분 ESP32
    '1a86': 'arduino:avr:uno',       // CH340 → Uno/Nano 클론 (기본 Uno)
    '0403': 'arduino:avr:uno',       // FTDI → Uno/Nano/Pro Mini 클론
    '2e8a': 'rp2040:rp2040:rpipico', // Raspberry Pi
    '0483': 'STMicroelectronics:stm32:GenF4', // STM32
    '16c0': 'teensy:avr:teensy41',   // Teensy
    '239a': 'adafruit:samd:adafruit_feather_m0', // Adafruit
    '2886': 'Seeeduino:samd:seeed_XIAO_m0', // Seeed
  };

  // ─── 디바이스 이름 키워드 → FQBN ───

  static const nameHints = <String, String>{
    'leonardo': 'arduino:avr:leonardo',
    'micro': 'arduino:avr:micro',
    'uno': 'arduino:avr:uno',
    'nano': 'arduino:avr:nano',
    'mega': 'arduino:avr:mega',
    'esp32s3': 'esp32:esp32:esp32s3',
    'esp32-s3': 'esp32:esp32:esp32s3',
    'esp32s2': 'esp32:esp32:esp32s2',
    'esp32-s2': 'esp32:esp32:esp32s2',
    'esp32c3': 'esp32:esp32:esp32c3',
    'esp32-c3': 'esp32:esp32:esp32c3',
    'esp32c6': 'esp32:esp32:esp32c6',
    'esp32-c6': 'esp32:esp32:esp32c6',
    'esp32': 'esp32:esp32:esp32',
    'esp8266': 'esp8266:esp8266:generic',
    'd1 mini': 'esp8266:esp8266:d1_mini',
    'd1_mini': 'esp8266:esp8266:d1_mini',
    'wemos': 'esp8266:esp8266:d1_mini',
    'nodemcu': 'esp8266:esp8266:nodemcuv2',
    'pico': 'rp2040:rp2040:rpipico',
    'teensy': 'teensy:avr:teensy41',
    'xiao': 'Seeeduino:samd:seeed_XIAO_m0',
    'feather': 'adafruit:samd:adafruit_feather_m0',
    'stm32': 'STMicroelectronics:stm32:GenF4',
  };

  static String? _extractVid(String address) {
    final parts = address.split(':');
    if (parts.length >= 2) return parts[1];
    return null;
  }

  static String? _refineByName(String name) {
    for (final entry in nameHints.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
