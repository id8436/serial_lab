import 'dart:convert';

/// JSON 유틸리티
class JsonHelper {
  /// JSON 형식 검증
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// JSON 예쁘게 출력
  static String prettyPrint(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  /// 안전한 JSON 파싱
  static Map<String, dynamic>? safeDecode(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
