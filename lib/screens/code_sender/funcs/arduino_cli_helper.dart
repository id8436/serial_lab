import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

/// Arduino CLI 작업을 위한 헬퍼 클래스
class ArduinoCliHelper {
  /// 스케치를 검증 (컴파일만)
  static Future<String> verifySketch({
    required String code,
    required String fqbn,
  }) async {
    String output = 'Compiling...\n';

    try {
      // 임시 디렉토리에 .ino 파일 생성
      final tempDir = await Directory.systemTemp.createTemp('arduino_sketch_');
      final sketchDir = Directory(path.join(tempDir.path, 'sketch'));
      await sketchDir.create();
      
      final sketchFile = File(path.join(sketchDir.path, 'sketch.ino'));
      await sketchFile.writeAsString(code);

      // Arduino CLI 실행
      final shell = Shell();
      final result = await shell.run(
        'arduino-cli compile --fqbn $fqbn ${sketchDir.path}'
      ).catchError((e) {
        return <ProcessResult>[];
      });

      if (result.isEmpty) {
        output += '\n❌ Arduino CLI를 찾을 수 없습니다.\n';
        output += 'Arduino CLI를 설치해주세요: https://arduino.github.io/arduino-cli/';
      } else {
        final cliOutput = result.map((r) => r.stdout.toString() + r.stderr.toString()).join('\n');
        output += cliOutput;
        if (cliOutput.contains('error') || cliOutput.contains('Error')) {
          output += '\n\n❌ 컴파일 실패';
        } else {
          output += '\n\n✅ 검증 완료!';
        }
      }

      // 임시 파일 정리
      await tempDir.delete(recursive: true);
    } catch (e) {
      output += '\n\nError: $e';
    }

    return output;
  }

  /// 스케치를 보드에 업로드
  static Future<String> uploadSketch({
    required String code,
    required String fqbn,
    required String port,
  }) async {
    String output = 'Uploading...\n';

    try {
      // 임시 디렉토리에 .ino 파일 생성
      final tempDir = await Directory.systemTemp.createTemp('arduino_sketch_');
      final sketchDir = Directory(path.join(tempDir.path, 'sketch'));
      await sketchDir.create();
      
      final sketchFile = File(path.join(sketchDir.path, 'sketch.ino'));
      await sketchFile.writeAsString(code);

      // Arduino CLI 업로드 실행
      final shell = Shell();
      final result = await shell.run(
        'arduino-cli upload --fqbn $fqbn --port $port ${sketchDir.path}'
      ).catchError((e) {
        return <ProcessResult>[];
      });

      if (result.isEmpty) {
        output += '\n❌ Arduino CLI를 찾을 수 없습니다.';
      } else {
        final cliOutput = result.map((r) => r.stdout.toString() + r.stderr.toString()).join('\n');
        output += cliOutput;
        if (cliOutput.contains('error') || cliOutput.contains('Error')) {
          output += '\n\n❌ 업로드 실패';
        } else {
          output += '\n\n✅ 업로드 완료!';
        }
      }

      // 임시 파일 정리
      await tempDir.delete(recursive: true);
    } catch (e) {
      output += '\n\nError: $e';
    }

    return output;
  }
}
