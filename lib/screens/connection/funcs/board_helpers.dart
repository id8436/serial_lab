import 'package:flutter/material.dart';

/// 보드 관련 유틸리티 함수들
class BoardHelpers {
  /// FQBN을 보드 이름으로 변환
  static String getBoardName(String fqbn) {
    const boardMap = {
      'arduino:avr:uno': 'Arduino Uno',
      'arduino:avr:nano': 'Arduino Nano',
      'arduino:avr:mega': 'Arduino Mega',
      'esp32:esp32:esp32': 'ESP32',
      'esp8266:esp8266:generic': 'ESP8266',
    };
    return boardMap[fqbn] ?? fqbn;
  }

  /// 보드 상세 설명
  static String getBoardDescription(String fqbn) {
    const descMap = {
      'arduino:avr:uno': 'ATmega328P • 16MHz • 32KB Flash • 가장 표준적인 보드',
      'arduino:avr:nano': 'ATmega328P • 16MHz • 작은 크기 • 브레드보드 친화적',
      'arduino:avr:mega': 'ATmega2560 • 16MHz • 256KB Flash • 대형 프로젝트용',
      'esp32:esp32:esp32': 'Xtensa 32-bit • WiFi/BT • 4MB Flash • IoT 프로젝트',
      'esp8266:esp8266:generic': 'Xtensa 32-bit • WiFi • 저렴한 IoT 솔루션',
    };
    return descMap[fqbn] ?? 'Arduino 호환 보드';
  }

  /// 드롭다운 메뉴 아이템 생성 (툴팁 포함)
  static List<DropdownMenuItem<String>> buildBoardMenuItems() {
    final boards = {
      'arduino:avr:uno': 'Arduino Uno',
      'arduino:avr:nano': 'Arduino Nano',
      'arduino:avr:mega': 'Arduino Mega',
      'esp32:esp32:esp32': 'ESP32',
      'esp8266:esp8266:generic': 'ESP8266',
    };

    return boards.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Tooltip(
          message: getBoardDescription(entry.key),
          child: Text(entry.value),
        ),
      );
    }).toList();
  }
}
