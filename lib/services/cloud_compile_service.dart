import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// 클라우드 컴파일 결과
class CompileResult {
  final bool success;
  final Uint8List? binaryData;
  final String output;
  final String format; // 'hex' or 'bin'

  const CompileResult({
    required this.success,
    this.binaryData,
    required this.output,
    this.format = 'hex',
  });
}

/// 원격 서버를 통한 Arduino 코드 컴파일 서비스
class CloudCompileService {
  static const String _serverUrl = 'https://jinhan.site';
  static const Duration _timeout = Duration(seconds: 60);

  /// 코드를 원격 서버에서 컴파일하고 바이너리를 반환합니다.
  ///
  /// [code] - Arduino 스케치 코드
  /// [fqbn] - 보드 FQBN (예: 'arduino:avr:uno')
  static Future<CompileResult> compile({
    required String code,
    required String fqbn,
  }) async {
    final url = _serverUrl.endsWith('/')
        ? '${_serverUrl}utility/compiler/compile/'
        : '$_serverUrl/utility/compiler/compile/';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'fqbn': fqbn}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final success = body['success'] as bool? ?? false;
        final output = body['output'] as String? ?? '';
        final format = body['format'] as String? ?? 'hex';
        final hexBase64 = body['hex'] as String?;

        Uint8List? binaryData;
        if (success && hexBase64 != null && hexBase64.isNotEmpty) {
          binaryData = base64Decode(hexBase64);
        }

        return CompileResult(
          success: success,
          binaryData: binaryData,
          output: output,
          format: format,
        );
      } else {
        return CompileResult(
          success: false,
          output: 'Server error (${response.statusCode}): ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      return CompileResult(
        success: false,
        output: 'Connection error: ${e.message}',
      );
    } catch (e) {
      return CompileResult(
        success: false,
        output: 'Error: $e',
      );
    }
  }
}
