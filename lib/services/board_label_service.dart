/// FQBN-to-human-readable board name resolver.
///
/// Lookup priority:
/// 1. [boardCatalog] exact FQBN match
/// 2. Static label map (legacy fallback)
///
/// Used by AppBar title and compile-target selector.
library;

import 'package:serial_lab/models/board_catalog.dart';
class BoardLabelService {
  /// FQBN → 보드 이름 (카탈로그 우선, fallback으로 라벨 맵 사용)
  static String getLabel(String fqbn) {
    // 1) 카탈로그에서 검색
    for (final board in boardCatalog) {
      if (board.fqbn == fqbn) return board.name;
    }
    // 2) 라벨 맵 fallback (카탈로그에 없는 변형 보드)
    final label = _labels[fqbn];
    if (label != null) return label;
    // 3) FQBN 마지막 세그먼트
    return fqbn.split(':').last;
  }

  /// FQBN → 보드 설명
  static String getDescription(String fqbn) {
    for (final board in boardCatalog) {
      if (board.fqbn == fqbn) return board.description;
    }
    return 'Arduino 호환 보드';
  }

  /// 카탈로그에 없는 변형 보드용 라벨 맵
  static const _labels = <String, String>{
    // Arduino AVR
    'arduino:avr:uno': 'Arduino Uno',
    'arduino:avr:nano': 'Arduino Nano',
    'arduino:avr:mega': 'Arduino Mega',
    'arduino:avr:leonardo': 'Arduino Leonardo',
    'arduino:avr:micro': 'Arduino Micro',
    'arduino:avr:pro': 'Arduino Pro Mini',
    'arduino:avr:mini': 'Arduino Mini',
    'arduino:avr:diecimila': 'Arduino Diecimila',
    'arduino:avr:megaADK': 'Arduino Mega ADK',
    'arduino:avr:esplora': 'Arduino Esplora',
    'arduino:avr:yun': 'Arduino Yun',
    'arduino:avr:lilypad': 'LilyPad',
    'arduino:avr:LilyPadUSB': 'LilyPad USB',
    // Arduino 최신
    'arduino:megaavr:nanoevery': 'Arduino Nano Every',
    'arduino:samd:mkrzero': 'Arduino MKR Zero',
    'arduino:samd:mkr1000': 'Arduino MKR 1000',
    'arduino:samd:mkrwifi1010': 'Arduino MKR WiFi 1010',
    'arduino:samd:nano_33_iot': 'Arduino Nano 33 IoT',
    'arduino:samd:mkrfox1200': 'Arduino MKR FOX 1200',
    'arduino:samd:mkrwan1300': 'Arduino MKR WAN 1300',
    'arduino:samd:mkrwan1310': 'Arduino MKR WAN 1310',
    'arduino:samd:mkrgsm1400': 'Arduino MKR GSM 1400',
    'arduino:samd:mkrnb1500': 'Arduino MKR NB 1500',
    'arduino:samd:mkrvidor4000': 'Arduino MKR Vidor 4000',
    'arduino:mbed_nano:nanorp2040connect': 'Arduino Nano RP2040',
    'arduino:mbed_nano:nano33ble': 'Arduino Nano 33 BLE',
    'arduino:renesas_uno:unor4wifi': 'Arduino UNO R4 WiFi',
    'arduino:renesas_uno:unor4minima': 'Arduino UNO R4 Minima',
    'arduino:esp32:nano_nora': 'Arduino Nano ESP32',
    // ESP32
    'esp32:esp32:esp32': 'ESP32',
    'esp32:esp32:esp32s2': 'ESP32-S2',
    'esp32:esp32:esp32s3': 'ESP32-S3',
    'esp32:esp32:esp32c3': 'ESP32-C3',
    'esp32:esp32:esp32c6': 'ESP32-C6',
    'esp32:esp32:esp32h2': 'ESP32-H2',
    'esp32:esp32:XIAO_ESP32S3': 'XIAO ESP32-S3',
    // ESP8266
    'esp8266:esp8266:generic': 'ESP8266',
    'esp8266:esp8266:d1_mini': 'D1 Mini',
    'esp8266:esp8266:d1_mini_pro': 'D1 Mini Pro',
    'esp8266:esp8266:d1_mini_lite': 'D1 Mini Lite',
    'esp8266:esp8266:d1': 'D1 R1',
    'esp8266:esp8266:nodemcuv2': 'NodeMCU',
    'esp8266:esp8266:nodemcu': 'NodeMCU 0.9',
    'esp8266:esp8266:esp8285': 'ESP8285',
    // RP2040
    'rp2040:rp2040:rpipico': 'Raspberry Pi Pico',
    'rp2040:rp2040:rpipicow': 'Raspberry Pi Pico W',
    'rp2040:rp2040:rpipico2': 'Raspberry Pi Pico 2',
    // STM32
    'STMicroelectronics:stm32:GenF4': 'STM32 F4',
    'STMicroelectronics:stm32:GenF1': 'STM32 F1',
    'STMicroelectronics:stm32:GenF0': 'STM32 F0',
    'STMicroelectronics:stm32:GenF3': 'STM32 F3',
    'STMicroelectronics:stm32:GenL4': 'STM32 L4',
    'STMicroelectronics:stm32:Nucleo_64': 'Nucleo 64',
    'STMicroelectronics:stm32:Nucleo_144': 'Nucleo 144',
    'STMicroelectronics:stm32:Disco': 'STM32 Discovery',
    'STMicroelectronics:stm32:Maple': 'Maple Mini',
    // Adafruit
    'adafruit:samd:adafruit_feather_m0': 'Feather M0',
    'adafruit:samd:adafruit_itsybitsy_m0': 'ItsyBitsy M0',
    'adafruit:samd:adafruit_itsybitsy_m4': 'ItsyBitsy M4',
    'adafruit:samd:adafruit_metro_m4': 'Metro M4',
    'adafruit:samd:adafruit_qtpy_m0': 'QT Py SAMD21',
    'adafruit:nrf52:feather52840': 'Feather nRF52840',
    // Seeed
    'Seeeduino:samd:seeed_XIAO_m0': 'XIAO SAMD21',
    'Seeeduino:nrf52:xiaonRF52840': 'XIAO nRF52840',
    // Teensy
    'teensy:avr:teensy41': 'Teensy 4.x',
    'teensy:avr:teensy36': 'Teensy 3.x',
    'rp2040:rp2040:adafruit_qtpy_rp2040': 'QT Py RP2040',
  };
}
