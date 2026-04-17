/// File I/O facade for analysis session save/load.
///
/// Delegates parsing to [SessionJsonParser] and [SessionCsvParser].
/// This class only handles file picking, Hive auto-save, and byte decoding.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'session_json_parser.dart';
import 'session_csv_parser.dart';

/// High-level session I/O: save/load JSON or CSV files, Hive auto-save.
class SessionIoService {
  // ─── Delegation to parsers (preserves public API) ──────────

  /// Serialize chart data to canonical JSON map.
  static Map<String, dynamic> toJsonMap(
    Map<String, ChartSeries> chartData, {
    String? name,
  }) =>
      SessionJsonParser.toJsonMap(chartData, name: name);

  /// Deserialize from canonical JSON map.
  static Map<String, ChartSeries> fromJsonMap(Map<String, dynamic> map) =>
      SessionJsonParser.fromJsonMap(map);

  /// Serialize chart data to CSV string.
  static String toCsv(Map<String, ChartSeries> chartData) =>
      SessionCsvParser.toCsv(chartData);

  // ─── File save ─────────────────────────────────────────────

  /// Save chart data as a JSON file (user picks destination folder).
  static Future<String?> saveJsonFile(Map<String, ChartSeries> chartData) async {
    final content = const JsonEncoder.withIndent('  ').convert(toJsonMap(chartData));
    return _saveTextFile(
      content: content,
      extension: 'json',
      defaultBaseName: 'analysis_data',
    );
  }

  /// Save chart data as a CSV file (user picks destination folder).
  static Future<String?> saveCsvFile(Map<String, ChartSeries> chartData) async {
    return _saveTextFile(
      content: toCsv(chartData),
      extension: 'csv',
      defaultBaseName: 'analysis_data',
    );
  }

  // ─── File load ─────────────────────────────────────────────

  /// Pick and load a JSON file.
  static Future<Map<String, ChartSeries>?> loadJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final pickedFile = result?.files.single;
    if (pickedFile == null) return null;

    final content = await _readPickedFileAsString(pickedFile);
    final map = jsonDecode(content);
    if (map is! Map<String, dynamic>) return null;
    return fromJsonMap(map);
  }

  /// Pick and load a JSON or CSV file (auto-detect format).
  static Future<Map<String, ChartSeries>?> loadDataFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
      withData: true,
    );
    final pickedFile = result?.files.single;
    if (pickedFile == null) return null;

    final content = await _readPickedFileAsString(pickedFile);
    return parseImportedData(content, fileName: pickedFile.name);
  }

  /// Parse imported data string, detecting format from filename or content.
  static Map<String, ChartSeries> parseImportedData(
    String content, {
    String? fileName,
  }) {
    final normalizedName = fileName?.toLowerCase() ?? '';
    if (normalizedName.endsWith('.csv')) return SessionCsvParser.parse(content);
    if (normalizedName.endsWith('.json')) return SessionJsonParser.parse(content);

    // Heuristic: JSON starts with { or [
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return SessionJsonParser.parse(content);
    }
    return SessionCsvParser.parse(content);
  }

  // ─── Hive auto-save ────────────────────────────────────────

  /// Auto-save chart data to Hive (max 30 sessions retained).
  static Future<void> saveAutoSessionToHive(Map<String, ChartSeries> chartData) async {
    if (chartData.isEmpty) return;

    final box = await Hive.openBox<String>('analysis_sessions');
    final now = DateTime.now();
    final key = 'auto_${now.toIso8601String()}';
    final payload = jsonEncode(toJsonMap(chartData, name: key));
    await box.put(key, payload);

    // Evict oldest sessions beyond limit
    const maxSessions = 30;
    if (box.length > maxSessions) {
      final keys = box.keys.cast<String>().toList()..sort();
      final removeCount = box.length - maxSessions;
      for (var i = 0; i < removeCount; i++) {
        await box.delete(keys[i]);
      }
    }
  }

  // ─── Private helpers ───────────────────────────────────────

  static Future<String> _readPickedFileAsString(PlatformFile pickedFile) async {
    final bytes = pickedFile.bytes;
    if (bytes != null && bytes.isNotEmpty) return _decodeBytes(bytes);
    final filePath = pickedFile.path;
    if (filePath != null && filePath.isNotEmpty) return File(filePath).readAsString();
    throw const FormatException('Could not read selected file');
  }

  static String _decodeBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  static Future<String?> _saveTextFile({
    required String content,
    required String extension,
    required String defaultBaseName,
  }) async {
    final fileName = '${defaultBaseName}_${_timestampForFileName()}.${extension.toLowerCase()}';
    final bytes = Uint8List.fromList(utf8.encode(content));

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save analysis data',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension.toLowerCase()],
      bytes: bytes,
    );

    if (outputPath == null) return null;

    // Desktop(Windows/macOS/Linux)에서는 saveFile이 경로만 반환하고
    // 파일을 직접 쓰지 않으므로 수동으로 작성
    final file = File(outputPath);
    if (!file.existsSync()) {
      await file.writeAsBytes(bytes, flush: true);
    }

    return outputPath;
  }

  static String _timestampForFileName() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '${now.year}$month${day}_$hour$minute$second';
  }
}
