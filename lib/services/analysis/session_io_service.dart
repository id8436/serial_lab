/// File I/O facade for analysis session save/load.
///
/// Delegates parsing to [SessionJsonParser] and [SessionCsvParser].
/// This class only handles file picking, Hive auto-save, and byte decoding.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'session_json_parser.dart';
import 'session_csv_parser.dart';

/// High-level session I/O: save/load JSON or CSV files, Hive auto-save.
class SessionIoService {
  static const String _kLiveSessionBoxName = 'analysis_sessions';
  static const String _kLiveSessionKey = 'live_current_session';
  static const int kLargeFileWarningBytes = 20 * 1024 * 1024;
  static const int _kModelBuildYieldBatchSize = 250;
  static const int _kMaxImportedSeries = 64;
  static const int _kMaxImportedPointsPerSeries = ChartSeries.defaultMaxPoints;

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
    final pickedFile = await pickJsonFile();
    if (pickedFile == null) return null;

    return parsePickedDataFile(pickedFile);
  }

  /// Pick a JSON file.
  static Future<PlatformFile?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
      withReadStream: true,
    );
    return result?.files.single;
  }

  /// Pick a JSON or CSV file (auto-detect format).
  static Future<PlatformFile?> pickDataFile({
    Future<bool> Function(String fileName, int fileSizeBytes)? onLargeFileWarning,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
      withData: false,
      withReadStream: true,
    );
    final pickedFile = result?.files.single;
    if (pickedFile == null) return null;

    final fileSize = await _resolvePickedFileSize(pickedFile);
    if (fileSize >= kLargeFileWarningBytes && onLargeFileWarning != null) {
      final proceed = await onLargeFileWarning(pickedFile.name, fileSize);
      if (!proceed) return null;
    }

    debugPrint(
      '[_pickDataFile] selected ${pickedFile.name} '
      '(size=$fileSize, hasPath=${pickedFile.path?.isNotEmpty == true}, '
      'hasStream=${pickedFile.readStream != null})',
    );

    return pickedFile;
  }

  /// Pick and load a JSON or CSV file (auto-detect format).
  static Future<Map<String, ChartSeries>?> loadDataFile({
    Future<bool> Function(String fileName, int fileSizeBytes)? onLargeFileWarning,
  }) async {
    final pickedFile = await pickDataFile(onLargeFileWarning: onLargeFileWarning);
    if (pickedFile == null) return null;

    return parsePickedDataFile(pickedFile);
  }

  /// Parse a file previously selected from the picker.
  static Future<Map<String, ChartSeries>> parsePickedDataFile(
    PlatformFile pickedFile,
  ) async {
    final stopwatch = Stopwatch()..start();

    final normalizedName = pickedFile.name.toLowerCase();
    final filePath = pickedFile.path;
    if (normalizedName.endsWith('.csv') && filePath != null && filePath.isNotEmpty) {
      final parsed = await _parseCsvFileInBackground(filePath);
      debugPrint(
        '[_parsePickedDataFile] parsed ${pickedFile.name} via path in '
        '${stopwatch.elapsedMilliseconds} ms → ${parsed.length} series',
      );
      return parsed;
    }

    final parsed = await _parsePickedFileInBackground(pickedFile);
    debugPrint(
      '[_parsePickedDataFile] parsed ${pickedFile.name} in '
      '${stopwatch.elapsedMilliseconds} ms → ${parsed.length} series',
    );
    return parsed;
  }

  /// Parse imported content in a background isolate and convert back.
  ///
  /// Uses a flat binary [Uint8List] transfer format so the main isolate does
  /// zero JSON parsing.  The only main-thread work is sequential byte reads
  /// (ByteData.getInt64/getFloat64) plus ChartDataPoint allocations, which
  /// are co-operatively yielded every [_kModelBuildYieldBatchSize] points.
  static Future<Map<String, ChartSeries>> parseImportedDataInBackground(
    String content, {
    String? fileName,
  }) async {
    final binary = await Isolate.run<Uint8List>(() {
      final parsed = parseImportedData(content, fileName: fileName);
      final limited = _trimSeriesMap(parsed);
      return _encodeBinary(limited);
    });
    return _fromBinaryData(binary);
  }

  /// Parse CSV file in a background isolate to keep UI isolate responsive.
  static Future<Map<String, ChartSeries>> _parseCsvFileInBackground(
    String filePath,
  ) async {
    final binary = await Isolate.run<Uint8List>(() async {
      final parsed = await SessionCsvParser.parseFile(filePath);
      final limited = _trimSeriesMap(parsed);
      return _encodeBinary(limited);
    });
    return _fromBinaryData(binary);
  }

  /// Parse a picked file using its cached path when available.
  ///
  /// Avoids eager `PlatformFile.bytes` loading on Android, which can stall the
  /// UI thread when returning from the system picker with large files.
  static Future<Map<String, ChartSeries>> _parsePickedFileInBackground(
    PlatformFile pickedFile,
  ) async {
    final filePath = pickedFile.path;
    if (filePath != null && filePath.isNotEmpty) {
      final normalizedName = pickedFile.name.toLowerCase();
      if (normalizedName.endsWith('.csv')) {
        return _parseCsvFileInBackground(filePath);
      }
      return _parseFileInBackground(filePath, fileName: pickedFile.name);
    }

    final stagedFile = await _stagePickedFileToTemp(pickedFile);
    try {
      final normalizedName = pickedFile.name.toLowerCase();
      if (normalizedName.endsWith('.csv')) {
        return _parseCsvFileInBackground(stagedFile.path);
      }
      return _parseFileInBackground(stagedFile.path, fileName: pickedFile.name);
    } finally {
      unawaited(_deleteFileQuietly(stagedFile));
    }
  }

  static Future<Map<String, ChartSeries>> _parseFileInBackground(
    String filePath, {
    String? fileName,
  }) async {
    final binary = await Isolate.run<Uint8List>(() async {
      final bytes = await File(filePath).readAsBytes();
      final content = _decodeBytes(bytes);
      final parsed = parseImportedData(content, fileName: fileName);
      final limited = _trimSeriesMap(parsed);
      return _encodeBinary(limited);
    });
    return _fromBinaryData(binary);
  }

  /// Applies series/point caps before the data leaves the isolate.
  ///
  /// Keeping the map small reduces both JSON string size and the number of
  /// objects that [_fromJsonMapChunked] must process on the main isolate.
  static Map<String, ChartSeries> _trimSeriesMap(Map<String, ChartSeries> src) {
    final needsSeriesTrim = src.length > _kMaxImportedSeries;
    final needsPointTrim =
        src.values.any((s) => s.dataPoints.length > _kMaxImportedPointsPerSeries);
    if (!needsSeriesTrim && !needsPointTrim) return src;

    return Map.fromEntries(
      src.entries.take(_kMaxImportedSeries).map((e) {
        final pts = e.value.dataPoints;
        if (pts.length <= _kMaxImportedPointsPerSeries) return e;
        return MapEntry(
          e.key,
          ChartSeries(
            name: e.key,
            dataPoints: pts.sublist(pts.length - _kMaxImportedPointsPerSeries),
          ),
        );
      }),
    );
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

    final box = await Hive.openBox<String>(_kLiveSessionBoxName);
    final now = DateTime.now();
    final key = 'auto_${now.toIso8601String()}';
    
    // ANR 방지: 백그라운드 아이솔레이트에서 JSON 직렬화 수행
    final payload = await Isolate.run(() {
      return jsonEncode(SessionJsonParser.toJsonMap(chartData, name: key));
    });
    
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

  /// Continuously persist the latest live chart data under a fixed key.
  static Future<void> saveLiveSessionToHive(Map<String, ChartSeries> chartData) async {
    if (chartData.isEmpty) return;

    final box = await Hive.openBox<String>(_kLiveSessionBoxName);
    
    // ANR 방지: 백그라운드 아이솔레이트에서 JSON 직렬화 수행
    final payload = await Isolate.run(() {
      return jsonEncode(SessionJsonParser.toJsonMap(chartData, name: _kLiveSessionKey));
    });
    
    await box.put(_kLiveSessionKey, payload);
  }

  /// Load the latest persisted live session, falling back to the newest history session.
  static Future<Map<String, ChartSeries>?> loadLatestPersistedSession() async {
    final box = await Hive.openBox<String>(_kLiveSessionBoxName);

    final livePayload = box.get(_kLiveSessionKey);
    final liveSession = await _decodeSessionPayloadAsync(livePayload);
    if (liveSession.isNotEmpty) {
      return liveSession;
    }

    final historyKeys = box.keys
        .cast<String>()
        .where((key) => key.startsWith('auto_'))
        .toList(growable: false)
      ..sort();

    for (var i = historyKeys.length - 1; i >= 0; i--) {
      final session = await _decodeSessionPayloadAsync(box.get(historyKeys[i]));
      if (session.isNotEmpty) {
        return session;
      }
    }

    return null;
  }

  /// Remove the live snapshot so it does not come back after restart.
  static Future<void> clearLiveSession() async {
    final box = await Hive.openBox<String>(_kLiveSessionBoxName);
    await box.delete(_kLiveSessionKey);
  }

  // ─── Private helpers ───────────────────────────────────────

  static Future<Map<String, ChartSeries>> _decodeSessionPayloadAsync(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return {};
    }

    // ANR 방지: 백그라운드 아이솔레이트에서 JSON 파싱 후 バイ너리로 반환 (O(1) 전송 보장)
    final binary = await Isolate.run<Uint8List?>(() {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          final parsedMap = SessionJsonParser.fromJsonMap(decoded);
          final limited = _trimSeriesMap(parsedMap); // 최대 포인트 및 시리즈 제한
          return _encodeBinary(limited);
        }
      } catch (_) {
        // Ignore corrupt entries and continue to older sessions.
      }
      return null;
    });

    if (binary == null) return {};

    // 메인 스레드에서 양보(yield)하며 ChartSeries 객체 재조립
    return _fromBinaryData(binary);
  }

  static Future<File> _stagePickedFileToTemp(PlatformFile pickedFile) async {
    final extension = _normalizedExtension(pickedFile.name);
    final tempFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'serial_lab_import_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    final sink = tempFile.openWrite();

    try {
      final readStream = pickedFile.readStream;
      if (readStream != null) {
        await for (final chunk in readStream.timeout(const Duration(seconds: 20))) {
          sink.add(chunk);
        }
      } else {
        final bytes = pickedFile.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw const FormatException('Could not read selected file');
        }
        sink.add(bytes);
      }
    } on TimeoutException {
      throw const FormatException('Reading the selected file timed out');
    } finally {
      await sink.close();
    }

    return tempFile;
  }

  static String _normalizedExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '.tmp';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  static Future<void> _deleteFileQuietly(File file) async {
    try {
      await file.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  static Future<int> _resolvePickedFileSize(PlatformFile pickedFile) async {
    if (pickedFile.size > 0) {
      return pickedFile.size;
    }
    final filePath = pickedFile.path;
    if (filePath != null && filePath.isNotEmpty) {
      try {
        return await File(filePath).length();
      } catch (_) {
        // Ignore and return 0.
      }
    }
    return 0;
  }

  /// Binary isolate-transfer format (little-endian):
  ///   [uint32: num_series]
  ///   For each series:
  ///     [uint16: name_byte_len]  [N bytes: UTF-8 name]
  ///     [uint32: num_points]
  ///     For each point: [int64: timestamp_ms]  [float64: value]
  ///
  /// Benefits over JSON string transfer:
  /// - No jsonDecode on the main thread (was synchronous/blocking)
  /// - No intermediate `List&lt;dynamic&gt;` objects → less GC pressure
  /// - Pure byte reads in [_fromBinaryData] → ~200× faster than DateTime.tryParse
  static Uint8List _encodeBinary(Map<String, ChartSeries> data) {
    // Pre-compute total buffer size to avoid reallocation.
    var size = 4; // series count
    final encodedNames = <List<int>>[];
    for (final entry in data.entries) {
      final nameBytes = utf8.encode(entry.key);
      encodedNames.add(nameBytes);
      size += 2 + nameBytes.length + 4 + entry.value.dataPoints.length * 16;
    }

    final buf = Uint8List(size);
    final bd = ByteData.sublistView(buf);
    var off = 0;

    bd.setUint32(off, data.length, Endian.little);
    off += 4;

    var nameIdx = 0;
    for (final entry in data.entries) {
      final nameBytes = encodedNames[nameIdx++];
      bd.setUint16(off, nameBytes.length, Endian.little);
      off += 2;
      buf.setRange(off, off + nameBytes.length, nameBytes);
      off += nameBytes.length;

      final pts = entry.value.dataPoints;
      bd.setUint32(off, pts.length, Endian.little);
      off += 4;
      for (final p in pts) {
        bd.setInt64(off, p.time.millisecondsSinceEpoch, Endian.little);
        off += 8;
        bd.setFloat64(off, p.value, Endian.little);
        off += 8;
      }
    }

    return buf;
  }

  /// Decode binary data produced by [_encodeBinary] on the main isolate.
  ///
  /// Yields every [_kModelBuildYieldBatchSize] points so the event loop can
  /// process frames and keep the UI responsive during large imports.
  static Future<Map<String, ChartSeries>> _fromBinaryData(Uint8List data) async {
    final result = <String, ChartSeries>{};
    try {
      final bd = ByteData.sublistView(data);
      var off = 0;

      final numSeries = bd.getUint32(off, Endian.little);
      off += 4;

      var totalPoints = 0;
      for (var s = 0; s < numSeries; s++) {
        final nameLen = bd.getUint16(off, Endian.little);
        off += 2;
        final name = utf8.decode(data.sublist(off, off + nameLen));
        off += nameLen;

        final numPoints = bd.getUint32(off, Endian.little);
        off += 4;

        final points = <ChartDataPoint>[];
        for (var p = 0; p < numPoints; p++) {
          final ms = bd.getInt64(off, Endian.little);
          off += 8;
          final value = bd.getFloat64(off, Endian.little);
          off += 8;
          points.add(ChartDataPoint(
            time: DateTime.fromMillisecondsSinceEpoch(ms),
            value: value,
            label: name,
          ));
          totalPoints++;
          if (totalPoints % _kModelBuildYieldBatchSize == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }

        if (points.isNotEmpty) {
          result[name] = ChartSeries(name: name, dataPoints: points);
        }
      }
    } catch (e, st) {
      // Return whatever was decoded before the error.
      debugPrint('[_fromBinaryData] SILENT CATCH – decoded ${result.length} series before error: $e\n$st');
    }
    debugPrint('[_fromBinaryData] returning ${result.length} series');
    return result;
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

    // 일부 플랫폼/버전에서는 saveFile이 경로만 반환하거나,
    // 기존 파일 선택 시 내용 갱신이 보장되지 않으므로 항상 최종 바이트를 덮어쓴다.
    final file = File(outputPath);
    await file.writeAsBytes(bytes, flush: true);

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
