import 'dart:typed_data';

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
