/// Local Arduino CLI wrapper for desktop (Windows/macOS/Linux) compilation.
///
/// Shells out to `arduino-cli` to compile sketches and produce .hex/.bin
/// firmware. Used as an alternative to [CloudCompileService] when the CLI
/// is installed locally.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';

/// Arduino CLI 래퍼 서비스 (PC 전용)
class ArduinoCliService {

  /// arduino-cli board list 로 연결된 보드의 FQBN을 감지
  /// 성공 시 FQBN 문자열 반환, 실패 시 null
  static Future<String?> detectBoard(String port) async {
    try {
      final result = await runExecutableArguments(
        'arduino-cli',
        ['board', 'list', '--format', 'json'],
      );
      final json = jsonDecode(result.stdout.toString());
      final ports = (json['detected_ports'] as List?) ?? (json as List?) ?? [];
      for (final entry in ports) {
        final portInfo = entry['port'] as Map<String, dynamic>?;
        final addr = portInfo?['address'] as String? ?? '';
        if (addr.toLowerCase() == port.toLowerCase()) {
          final boards = entry['matching_boards'] as List?;
          if (boards != null && boards.isNotEmpty) {
            return boards[0]['fqbn'] as String?;
          }
        }
      }
    } catch (_) {
      // arduino-cli 미설치 또는 실행 실패 시 무시
    }
    return null;
  }

  /// 스케치를 검증 (컴파일만)
  static Future<String> verifySketch({
    required String code,
    required String fqbn,
  }) async {
    String output = 'Compiling...\n';

    try {
      final tempDir = await Directory.systemTemp.createTemp('arduino_sketch_');
      final sketchDir = Directory(path.join(tempDir.path, 'sketch'));
      await sketchDir.create();

      final sketchFile = File(path.join(sketchDir.path, 'sketch.ino'));
      await sketchFile.writeAsString(code);

      ProcessResult? result;
      try {
        result = await runExecutableArguments(
          'arduino-cli',
          ['compile', '--fqbn', fqbn, sketchDir.path],
        );
      } catch (_) {
        result = null;
      }

      if (result == null) {
        output += '\n❌ Arduino CLI를 찾을 수 없습니다.\n';
        output += 'Arduino CLI를 설치해주세요: https://arduino.github.io/arduino-cli/';
      } else {
        final cliOutput = result.stdout.toString() + result.stderr.toString();
        output += cliOutput;
        if (cliOutput.contains('error') || cliOutput.contains('Error')) {
          output += '\n\n❌ 컴파일 실패';
        } else {
          output += '\n\n✅ 검증 완료!';
        }
      }

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
      final tempDir = await Directory.systemTemp.createTemp('arduino_sketch_');
      final sketchDir = Directory(path.join(tempDir.path, 'sketch'));
      await sketchDir.create();

      final sketchFile = File(path.join(sketchDir.path, 'sketch.ino'));
      await sketchFile.writeAsString(code);

      ProcessResult? result;
      try {
        result = await runExecutableArguments(
          'arduino-cli',
          ['upload', '--fqbn', fqbn, '--port', port, sketchDir.path],
        );
      } catch (_) {
        result = null;
      }

      if (result == null) {
        output += '\n❌ Arduino CLI를 찾을 수 없습니다.';
      } else {
        final cliOutput = result.stdout.toString() + result.stderr.toString();
        output += cliOutput;
        if (cliOutput.contains('error') || cliOutput.contains('Error')) {
          output += '\n\n❌ 업로드 실패';
        } else {
          output += '\n\n✅ 업로드 완료!';
        }
      }

      await tempDir.delete(recursive: true);
    } catch (e) {
      output += '\n\nError: $e';
    }

    return output;
  }
}
