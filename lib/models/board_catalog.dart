import 'package:serial_lab/models/board_info.dart';

/// 지원 보드 전체 카탈로그 (63개)
const List<BoardInfo> boardCatalog = [
  // ── Arduino AVR ───────────────────────────────────────────
  BoardInfo(
    fqbn: 'arduino:avr:uno',
    name: 'Arduino Uno',
    description: 'ATmega328P • 16MHz • 32KB Flash • 표준 입문 보드',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:nano',
    name: 'Arduino Nano',
    description: 'ATmega328P • 16MHz • 소형 • 브레드보드 친화적',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:mega',
    name: 'Arduino Mega 2560',
    description: 'ATmega2560 • 16MHz • 256KB Flash • 대형 프로젝트',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:leonardo',
    name: 'Arduino Leonardo',
    description: 'ATmega32u4 • 16MHz • 네이티브 USB HID',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:micro',
    name: 'Arduino Micro',
    description: 'ATmega32u4 • 16MHz • 소형 • 네이티브 USB',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:pro',
    name: 'Arduino Pro Mini',
    description: 'ATmega328P • 5V/3.3V 선택 • USB 없음 • 초소형',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:lilypad',
    name: 'LilyPad Arduino',
    description: 'ATmega168 • 3.3V • 웨어러블 & 섬유 프로젝트',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:ethernet',
    name: 'Arduino Ethernet',
    description: 'ATmega328P • 이더넷 W5100 내장',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:fio',
    name: 'Arduino Fio',
    description: 'ATmega328P • 3.3V • XBee 슬롯 내장',
    category: 'Arduino AVR',
  ),
  BoardInfo(
    fqbn: 'arduino:avr:yun',
    name: 'Arduino Yún',
    description: 'ATmega32u4 + AR9331 • WiFi • Linux 공존',
    category: 'Arduino AVR',
  ),
  // ── Arduino megaAVR ───────────────────────────────────────
  BoardInfo(
    fqbn: 'arduino:megaavr:nanoevery',
    name: 'Arduino Nano Every',
    description: 'ATmega4809 • 20MHz • 48KB Flash • Nano 폼팩터',
    category: 'Arduino megaAVR',
  ),
  BoardInfo(
    fqbn: 'arduino:megaavr:uno2018',
    name: 'Arduino Uno WiFi Rev2',
    description: 'ATmega4809 • WiFi • u-blox NINA-W102',
    category: 'Arduino megaAVR',
  ),
  // ── Arduino ARM ───────────────────────────────────────────
  BoardInfo(
    fqbn: 'arduino:sam:arduino_due_x',
    name: 'Arduino Due',
    description: 'AT91SAM3X8E • 84MHz • 3.3V • 512KB Flash',
    category: 'Arduino ARM',
  ),
  BoardInfo(
    fqbn: 'arduino:samd:arduino_zero_native',
    name: 'Arduino Zero',
    description: 'ATSAMD21G18 • 48MHz • 256KB Flash • 3.3V',
    category: 'Arduino ARM',
  ),
  BoardInfo(
    fqbn: 'arduino:samd:mkrwifi1010',
    name: 'Arduino MKR WiFi 1010',
    description: 'SAMD21 • WiFi/BT • u-blox NINA-W102',
    category: 'Arduino ARM',
  ),
  BoardInfo(
    fqbn: 'arduino:samd:mkrzero',
    name: 'Arduino MKR Zero',
    description: 'SAMD21 • SD 카드 슬롯 내장 • I2S',
    category: 'Arduino ARM',
  ),
  BoardInfo(
    fqbn: 'arduino:samd:mkr1000',
    name: 'Arduino MKR1000',
    description: 'SAMD21 • WiFi • Winc1500',
    category: 'Arduino ARM',
  ),
  BoardInfo(
    fqbn: 'arduino:samd:mkrgsm1400',
    name: 'Arduino MKR GSM 1400',
    description: 'SAMD21 • GSM/GPRS • 글로벌 셀룰러',
    category: 'Arduino ARM',
  ),
  BoardInfo(
    fqbn: 'arduino:samd:nano_33_iot',
    name: 'Arduino Nano 33 IoT',
    description: 'SAMD21 • WiFi/BT • u-blox NINA-W102 • IMU',
    category: 'Arduino ARM',
  ),
  // ── Arduino Nano 33 ──────────────────────────────────────
  BoardInfo(
    fqbn: 'arduino:mbed_nano:nano33ble',
    name: 'Arduino Nano 33 BLE',
    description: 'nRF52840 • BLE 5.0 • 9축 IMU',
    category: 'Arduino Nano 33',
  ),
  BoardInfo(
    fqbn: 'arduino:mbed_nano:nano33ble_sense',
    name: 'Arduino Nano 33 BLE Sense',
    description: 'nRF52840 • BLE 5.0 • 온도/습도/기압/마이크/근접 센서',
    category: 'Arduino Nano 33',
  ),
  BoardInfo(
    fqbn: 'arduino:mbed_nano:nanorp2040connect',
    name: 'Arduino Nano RP2040 Connect',
    description: 'RP2040 • WiFi/BT • u-blox NINA-W102 • IMU/마이크',
    category: 'Arduino Nano 33',
  ),
  // ── RP2040 ───────────────────────────────────────────────
  BoardInfo(
    fqbn: 'rp2040:rp2040:rpipico',
    name: 'Raspberry Pi Pico',
    description: 'RP2040 • 133MHz • 2MB Flash • 26 GPIO • 저비용',
    category: 'RP2040',
  ),
  BoardInfo(
    fqbn: 'rp2040:rp2040:rpipicow',
    name: 'Raspberry Pi Pico W',
    description: 'RP2040 • WiFi/BT • CYW43439 • 2MB Flash',
    category: 'RP2040',
  ),
  BoardInfo(
    fqbn: 'rp2040:rp2040:rpipico2',
    name: 'Raspberry Pi Pico 2',
    description: 'RP2350 • 150MHz • ARM/RISC-V • 4MB Flash',
    category: 'RP2040',
  ),
  BoardInfo(
    fqbn: 'rp2040:rp2040:adafruit_feather_rp2040',
    name: 'Adafruit Feather RP2040',
    description: 'RP2040 • LiPo 충전 • Feather 폼팩터',
    category: 'RP2040',
  ),
  // ── ESP32 ────────────────────────────────────────────────
  BoardInfo(
    fqbn: 'esp32:esp32:esp32',
    name: 'ESP32',
    description: 'Xtensa LX6 듀얼코어 • 240MHz • WiFi/BT • 4MB Flash',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:esp32s2',
    name: 'ESP32-S2',
    description: 'Xtensa LX7 단일코어 • 240MHz • WiFi • USB OTG',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:esp32s3',
    name: 'ESP32-S3',
    description: 'Xtensa LX7 듀얼코어 • 240MHz • WiFi/BT5 • AI 가속',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:esp32c3',
    name: 'ESP32-C3',
    description: 'RISC-V 단일코어 • 160MHz • WiFi/BT5 • 저전력',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:esp32c6',
    name: 'ESP32-C6',
    description: 'RISC-V • WiFi 6 / BT 5 / Zigbee / Thread',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:esp32h2',
    name: 'ESP32-H2',
    description: 'RISC-V • BT 5 / Zigbee / Thread • 저전력 메시',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:nodemcu-32s',
    name: 'NodeMCU-32S',
    description: 'ESP32 • 개발 보드 • 38핀 • USB-TTL 내장',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:lolin32',
    name: 'WEMOS LOLIN32',
    description: 'ESP32 • LiPo 충전 • 4MB Flash',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:d32',
    name: 'WEMOS D32',
    description: 'ESP32 • LiPo 충전 • 배터리 모니터링',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:featheresp32',
    name: 'Adafruit Feather ESP32',
    description: 'ESP32 • LiPo 충전 • Feather 폼팩터',
    category: 'ESP32',
  ),
  BoardInfo(
    fqbn: 'esp32:esp32:esp32wrover',
    name: 'ESP32 WROVER',
    description: 'ESP32 • 8MB PSRAM • 카메라 인터페이스 지원',
    category: 'ESP32',
  ),
  // ── ESP8266 ──────────────────────────────────────────────
  BoardInfo(
    fqbn: 'esp8266:esp8266:generic',
    name: 'ESP8266 Generic',
    description: 'Xtensa LX106 • 80/160MHz • WiFi • 저비용 IoT',
    category: 'ESP8266',
  ),
  BoardInfo(
    fqbn: 'esp8266:esp8266:nodemcuv2',
    name: 'NodeMCU 1.0 (ESP-12E)',
    description: 'ESP8266 • 개발 보드 • 30핀 • USB 내장',
    category: 'ESP8266',
  ),
  BoardInfo(
    fqbn: 'esp8266:esp8266:nodemcu',
    name: 'NodeMCU 0.9 (ESP-12)',
    description: 'ESP8266 • 개발 보드 • 구형 NodeMCU',
    category: 'ESP8266',
  ),
  BoardInfo(
    fqbn: 'esp8266:esp8266:d1_mini',
    name: 'WEMOS D1 Mini',
    description: 'ESP8266 • 소형 • 11 GPIO • USB-C',
    category: 'ESP8266',
  ),
  BoardInfo(
    fqbn: 'esp8266:esp8266:d1_mini_pro',
    name: 'WEMOS D1 Mini Pro',
    description: 'ESP8266 • 외장 안테나 • 16MB Flash',
    category: 'ESP8266',
  ),
  BoardInfo(
    fqbn: 'esp8266:esp8266:huzzah',
    name: 'Adafruit Feather HUZZAH',
    description: 'ESP8266 • LiPo 충전 • Feather 폼팩터',
    category: 'ESP8266',
  ),
  BoardInfo(
    fqbn: 'esp8266:esp8266:esp01_1m',
    name: 'ESP-01 (1M)',
    description: 'ESP8266 • 초소형 • WiFi 모듈 • 2 GPIO',
    category: 'ESP8266',
  ),
  // ── STM32 ────────────────────────────────────────────────
  BoardInfo(
    fqbn: 'STMicroelectronics:stm32:GenF1',
    name: 'STM32 BluePill (F103C8)',
    description: 'STM32F103C8 • 72MHz • 64KB Flash • 저비용',
    category: 'STM32',
  ),
  BoardInfo(
    fqbn: 'STMicroelectronics:stm32:GenF4',
    name: 'STM32 BlackPill (F411CE)',
    description: 'STM32F411CE • 100MHz • 512KB Flash • USB',
    category: 'STM32',
  ),
  BoardInfo(
    fqbn: 'STMicroelectronics:stm32:Nucleo_64',
    name: 'STM32 Nucleo-64 (F401RE)',
    description: 'STM32F401RE • 84MHz • ST-LINK 내장 디버거',
    category: 'STM32',
  ),
  BoardInfo(
    fqbn: 'STMicroelectronics:stm32:Nucleo_144',
    name: 'STM32 Nucleo-144 (F429ZI)',
    description: 'STM32F429ZI • 180MHz • 이더넷 • 풀 피처',
    category: 'STM32',
  ),
  // ── Teensy ───────────────────────────────────────────────
  BoardInfo(
    fqbn: 'teensy:avr:teensy32',
    name: 'Teensy 3.2',
    description: 'MK20DX256 • 72MHz • 256KB Flash • USB',
    category: 'Teensy',
  ),
  BoardInfo(
    fqbn: 'teensy:avr:teensy40',
    name: 'Teensy 4.0',
    description: 'iMXRT1062 • 600MHz • 2MB Flash • 고성능',
    category: 'Teensy',
  ),
  BoardInfo(
    fqbn: 'teensy:avr:teensy41',
    name: 'Teensy 4.1',
    description: 'iMXRT1062 • 600MHz • SD 카드 • 이더넷',
    category: 'Teensy',
  ),
];
