import 'package:highlight/languages/arduino.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';

/// 코드 에디터 설정
class CodeEditorConfig {
  /// 기본 Arduino 스케치
  static const String defaultSketch = '''void setup() {
  // 초기화 코드 (한 번 실행)
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // 반복 실행되는 코드
  digitalWrite(LED_BUILTIN, HIGH);
  delay(1000);
  digitalWrite(LED_BUILTIN, LOW);
  delay(1000);
}''';

  /// Arduino 언어 정의
  static final language = arduino;

  /// 다크 모드 테마
  static final darkTheme = monokaiSublimeTheme;

  /// 라이트 모드 테마
  static final lightTheme = githubTheme;

  /// 에디터 폰트 크기
  static const double fontSize = 14.0;

  /// 에디터 폰트 패밀리
  static const String fontFamily = 'monospace';
}
