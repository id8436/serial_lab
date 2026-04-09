import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// 클라우드 컴파일 결과
class CompileResult {
  final bool success;
  final Uint8List? binaryData;
  final String output;
  final String format; // 'hex' or 'bin'
  final String? requestId;
  final String? errorCode;
  final int? compileMs;
  final int? statusCode;

  const CompileResult({
    required this.success,
    this.binaryData,
    required this.output,
    this.format = 'hex',
    this.requestId,
    this.errorCode,
    this.compileMs,
    this.statusCode,
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
    String? format,
  }) async {
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
              'fqbn': fqbn,
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
