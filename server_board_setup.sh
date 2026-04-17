#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Serial Lab 컴파일 서버 보드 설치 스크립트
# 실행: bash server_board_setup.sh
# ═══════════════════════════════════════════════════════════════

set -e

echo "=== 1. 서드파티 보드 매니저 URL 등록 ==="
arduino-cli config init --overwrite 2>/dev/null || true
arduino-cli config add board_manager.additional_urls \
  "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json" \
  "https://arduino.esp8266.com/stable/package_esp8266com_index.json" \
  "https://github.com/stm32duino/BoardManagerFiles/raw/main/package_stmicroelectronics_index.json" \
  "https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json" \
  "https://adafruit.github.io/arduino-board-index/package_adafruit_index.json" \
  "https://files.seeedstudio.com/arduino/package_seeeduino_boards_index.json"

echo "=== 2. 보드 인덱스 업데이트 ==="
arduino-cli core update-index

echo "=== 3. 코어 설치 ==="

# ─── Arduino 공식 ───
echo "[1/10] arduino:avr (Uno, Nano, Mega, Leonardo, Micro ...)"
arduino-cli core install arduino:avr

echo "[2/10] arduino:megaavr (Nano Every)"
arduino-cli core install arduino:megaavr

echo "[3/10] arduino:samd (MKR, Nano 33 IoT ...)"
arduino-cli core install arduino:samd

echo "[4/10] arduino:renesas_uno (UNO R4 WiFi, R4 Minima)"
arduino-cli core install arduino:renesas_uno

# ─── ESP ───
echo "[5/10] esp32:esp32 (ESP32, S2, S3, C3, C6, H2 ...)"
arduino-cli core install esp32:esp32

echo "[6/10] esp8266:esp8266 (D1 Mini, NodeMCU, Generic ...)"
arduino-cli core install esp8266:esp8266

# ─── STM32 ───
echo "[7/10] STMicroelectronics:stm32"
arduino-cli core install STMicroelectronics:stm32

# ─── RP2040 (Raspberry Pi Pico) ───
echo "[8/10] rp2040:rp2040 (Pico, Pico W)"
arduino-cli core install rp2040:rp2040

# ─── Adafruit ───
echo "[9/10] adafruit:samd (Feather M0, ItsyBitsy M0/M4 ...)"
arduino-cli core install adafruit:samd

echo "[10/10] adafruit:nrf52 (Feather nRF52840 ...)"
arduino-cli core install adafruit:nrf52

echo ""
echo "=== 4. 설치 확인 ==="
arduino-cli core list

echo ""
echo "=== 5. 서버에서 지원해야 할 주요 FQBN 목록 ==="
cat << 'EOF'
────────────────────────────────────────────
 플랫폼              │ FQBN                                  │ 대표 보드
────────────────────────────────────────────
 arduino:avr         │ arduino:avr:uno                       │ Uno R3
                     │ arduino:avr:nano                      │ Nano
                     │ arduino:avr:mega                      │ Mega 2560
                     │ arduino:avr:leonardo                  │ Leonardo
                     │ arduino:avr:micro                     │ Micro
                     │ arduino:avr:pro                       │ Pro Mini
                     │ arduino:avr:mini                      │ Mini
                     │ arduino:avr:diecimila                 │ Diecimila
                     │ arduino:avr:megaADK                   │ Mega ADK
                     │ arduino:avr:esplora                   │ Esplora
                     │ arduino:avr:yun                       │ Yun
                     │ arduino:avr:lilypad                   │ LilyPad
                     │ arduino:avr:LilyPadUSB                │ LilyPad USB
────────────────────────────────────────────
 arduino:megaavr     │ arduino:megaavr:nanoevery             │ Nano Every
────────────────────────────────────────────
 arduino:samd        │ arduino:samd:mkrzero                  │ MKR Zero
                     │ arduino:samd:mkr1000                  │ MKR 1000
                     │ arduino:samd:mkrwifi1010              │ MKR WiFi 1010
                     │ arduino:samd:nano_33_iot              │ Nano 33 IoT
                     │ arduino:samd:mkrfox1200               │ MKR FOX 1200
                     │ arduino:samd:mkrwan1300               │ MKR WAN 1300
                     │ arduino:samd:mkrwan1310               │ MKR WAN 1310
                     │ arduino:samd:mkrgsm1400               │ MKR GSM 1400
                     │ arduino:samd:mkrnb1500                │ MKR NB 1500
                     │ arduino:samd:mkrvidor4000             │ MKR Vidor 4000
────────────────────────────────────────────
 arduino:renesas_uno │ arduino:renesas_uno:unor4wifi         │ UNO R4 WiFi
                     │ arduino:renesas_uno:unor4minima       │ UNO R4 Minima
────────────────────────────────────────────
 esp32:esp32         │ esp32:esp32:esp32                     │ ESP32 DevKit
                     │ esp32:esp32:esp32s2                   │ ESP32-S2
                     │ esp32:esp32:esp32s3                   │ ESP32-S3
                     │ esp32:esp32:esp32c3                   │ ESP32-C3
                     │ esp32:esp32:esp32c6                   │ ESP32-C6
                     │ esp32:esp32:esp32h2                   │ ESP32-H2
────────────────────────────────────────────
 esp8266:esp8266     │ esp8266:esp8266:generic               │ Generic ESP8266
                     │ esp8266:esp8266:d1_mini               │ D1 Mini
                     │ esp8266:esp8266:d1_mini_pro           │ D1 Mini Pro
                     │ esp8266:esp8266:d1_mini_lite          │ D1 Mini Lite
                     │ esp8266:esp8266:d1_mini_clone         │ D1 Mini Clone
                     │ esp8266:esp8266:d1                    │ D1 R1
                     │ esp8266:esp8266:d1_wroom_02           │ D1 ESP-WROOM-02
                     │ esp8266:esp8266:nodemcuv2             │ NodeMCU 1.0
                     │ esp8266:esp8266:nodemcu               │ NodeMCU 0.9
                     │ esp8266:esp8266:esp8285               │ ESP8285
────────────────────────────────────────────
 STM:stm32           │ STMicroelectronics:stm32:GenF4        │ Generic F4
                     │ STMicroelectronics:stm32:GenF1        │ Generic F1
                     │ STMicroelectronics:stm32:GenF0        │ Generic F0
                     │ STMicroelectronics:stm32:GenF3        │ Generic F3
                     │ STMicroelectronics:stm32:GenL4        │ Generic L4
                     │ STMicroelectronics:stm32:Nucleo_64    │ Nucleo 64
                     │ STMicroelectronics:stm32:Nucleo_144   │ Nucleo 144
                     │ STMicroelectronics:stm32:Disco        │ Discovery
                     │ STMicroelectronics:stm32:Maple        │ Maple Mini
────────────────────────────────────────────
 rp2040:rp2040       │ rp2040:rp2040:rpipico                 │ Pico
                     │ rp2040:rp2040:rpipicow                │ Pico W
                     │ rp2040:rp2040:rpipico2                │ Pico 2
────────────────────────────────────────────
 adafruit:samd       │ adafruit:samd:adafruit_feather_m0     │ Feather M0
                     │ adafruit:samd:adafruit_itsybitsy_m0   │ ItsyBitsy M0
                     │ adafruit:samd:adafruit_itsybitsy_m4   │ ItsyBitsy M4
                     │ adafruit:samd:adafruit_metro_m4       │ Metro M4
                     │ adafruit:samd:adafruit_qtpy_m0        │ QT Py SAMD21
────────────────────────────────────────────
 adafruit:nrf52      │ adafruit:nrf52:feather52840           │ Feather nRF52840
────────────────────────────────────────────
EOF

echo ""
echo "=== 완료! ==="
echo "서버의 compile endpoint에서 위 FQBN들을 허용리스트에 추가하세요."
