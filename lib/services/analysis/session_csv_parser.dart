/// CSV import/export for analysis session data.
///
/// Handles:
/// - **Export**: [ChartSeries] map → CSV with columns `time,<series1>,<series2>,...`
/// - **Import**: Flexible CSV parsing with:
///   - Auto-detection of timestamp columns (`time`, `timestamp`, `date`, `datetime`)
///   - Multi-series support (each non-timestamp column becomes a series)
///   - Quoted field support (RFC 4180 compliant)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serial_lab/models/chart_data.dart';
import 'session_json_parser.dart'; // shared utilities

/// Parses and serializes chart session data in CSV format.
class SessionCsvParser {
  /// Serialize chart data to CSV string.
  ///
  /// Output columns: `time,<series1>,<series2>,...`
  static String toCsv(Map<String, ChartSeries> chartData) {
    if (chartData.isEmpty) return 'time';

    final orderedEntries = chartData.entries.toList(growable: false);
    final header = <String>['time'];
    header.addAll(orderedEntries.map((entry) => _escapeCsv(entry.key)));

    var maxRows = 0;
    for (final entry in orderedEntries) {
      final len = entry.value.dataPoints.length;
      if (len > maxRows) {
        maxRows = len;
      }
    }

    final rows = <String>[header.join(',')];
    for (var rowIndex = 0; rowIndex < maxRows; rowIndex++) {
      DateTime? rowTime;
      for (final entry in orderedEntries) {
        final points = entry.value.dataPoints;
        if (rowIndex < points.length) {
          rowTime = points[rowIndex].time;
          break;
        }
      }

      final cells = <String>[rowTime?.toIso8601String() ?? ''];
      for (final entry in orderedEntries) {
        final points = entry.value.dataPoints;
        if (rowIndex < points.length) {
          cells.add(points[rowIndex].value.toStringAsFixed(6));
        } else {
          cells.add('');
        }
      }

      rows.add(cells.join(','));
    }

    return rows.join('\n');
  }

  /// Parse CSV content into chart series.
  ///
  /// Expects a header row followed by data rows.
  /// Columns with numeric data become series; a timestamp column is optional.
  static Map<String, ChartSeries> parse(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return _parseFromLineIterable(lines);
  }

  /// Parse CSV from a file stream to reduce peak memory usage on large files.
  static Future<Map<String, ChartSeries>> parseFile(String filePath) async {
    final lineStream = File(filePath)
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return _parseFromLineStream(lineStream);
  }

  static bool _isLegacyLongFormat(List<String> headers) {
    if (headers.length != 3) return false;
    final normalized = headers.map((h) => h.trim().toLowerCase()).toList(growable: false);
    return normalized[0] == 'series' &&
        SessionJsonParser.isTimestampKey(normalized[1]) &&
        normalized[2] == 'value';
  }

  static Map<String, ChartSeries> _parseLegacyLongFormat(List<String> lines) {
    final series = <String, List<ChartDataPoint>>{};
    final baseTime = DateTime.now();

    for (var rowIndex = 1; rowIndex < lines.length; rowIndex++) {
      final row = parseLine(lines[rowIndex]);
      if (row.length < 3) continue;

      final seriesName = row[0].trim();
      if (seriesName.isEmpty) continue;

      final numericValue = SessionJsonParser.toDouble(row[2]);
      if (numericValue == null) continue;

      final timestamp = SessionJsonParser.parseTimestamp(row[1]);
      final resolvedTime =
          timestamp ?? baseTime.add(Duration(seconds: rowIndex - 1));

      series.putIfAbsent(seriesName, () => []).add(
            ChartDataPoint(
              time: resolvedTime,
              value: numericValue,
              label: seriesName,
            ),
          );
    }

    return SessionJsonParser.finalizeSeriesMap(series);
  }

  static Map<String, ChartSeries> _parseFromLineIterable(
    Iterable<String> lines,
  ) {
    final iterator = lines.iterator;
    if (!iterator.moveNext()) {
      throw const FormatException('CSV must include a header and at least one row');
    }

    final headers = parseLine(iterator.current);
    if (headers.isEmpty) {
      throw const FormatException('CSV header is empty');
    }

    final rows = <String>[];
    while (iterator.moveNext()) {
      rows.add(iterator.current);
    }
    if (rows.isEmpty) {
      throw const FormatException('CSV must include a header and at least one row');
    }

    if (_isLegacyLongFormat(headers)) {
      return _parseLegacyLongFormat(<String>[headers.join(','), ...rows]);
    }

    final timeColumnIndex = headers.indexWhere(SessionJsonParser.isTimestampKey);
    final numericColumns = <int, String>{};
    for (var index = 0; index < headers.length; index++) {
      final header = headers[index].trim();
      if (header.isEmpty || index == timeColumnIndex) continue;
      numericColumns[index] = header;
    }

    return _buildSeriesFromRows(rows, timeColumnIndex, numericColumns);
  }

  static Future<Map<String, ChartSeries>> _parseFromLineStream(
    Stream<String> lines,
  ) async {
    final iterator = StreamIterator<String>(lines);
    if (!await iterator.moveNext()) {
      throw const FormatException('CSV must include a header and at least one row');
    }

    final headers = parseLine(iterator.current);
    if (headers.isEmpty) {
      throw const FormatException('CSV header is empty');
    }

    final legacy = _isLegacyLongFormat(headers);
    final timeColumnIndex = legacy ? -1 : headers.indexWhere(SessionJsonParser.isTimestampKey);
    final numericColumns = <int, String>{};
    if (!legacy) {
      for (var index = 0; index < headers.length; index++) {
        final header = headers[index].trim();
        if (header.isEmpty || index == timeColumnIndex) continue;
        numericColumns[index] = header;
      }
    }

    final series = <String, List<ChartDataPoint>>{};
    final baseTime = DateTime.now();
    var rowIndex = 1;

    while (await iterator.moveNext()) {
      final row = parseLine(iterator.current);
      if (legacy) {
        if (row.length >= 3) {
          final seriesName = row[0].trim();
          final numericValue = SessionJsonParser.toDouble(row[2]);
          if (seriesName.isNotEmpty && numericValue != null) {
            final timestamp = SessionJsonParser.parseTimestamp(row[1]);
            final resolvedTime =
                timestamp ?? baseTime.add(Duration(seconds: rowIndex - 1));
            series.putIfAbsent(seriesName, () => []).add(
                  ChartDataPoint(
                    time: resolvedTime,
                    value: numericValue,
                    label: seriesName,
                  ),
                );
          }
        }
      } else {
        final timestamp = timeColumnIndex >= 0 && timeColumnIndex < row.length
            ? SessionJsonParser.parseTimestamp(row[timeColumnIndex])
            : null;
        final resolvedTime = timestamp ?? baseTime.add(Duration(seconds: rowIndex - 1));

        numericColumns.forEach((columnIndex, seriesName) {
          if (columnIndex >= row.length) return;
          final numericValue = SessionJsonParser.toDouble(row[columnIndex]);
          if (numericValue == null) return;

          series.putIfAbsent(seriesName, () => []).add(
                ChartDataPoint(
                  time: resolvedTime,
                  value: numericValue,
                  label: seriesName,
                ),
              );
        });
      }
      rowIndex++;
    }

    if (rowIndex == 1) {
      throw const FormatException('CSV must include a header and at least one row');
    }

    return SessionJsonParser.finalizeSeriesMap(series);
  }

  static Map<String, ChartSeries> _buildSeriesFromRows(
    List<String> rows,
    int timeColumnIndex,
    Map<int, String> numericColumns,
  ) {
    final series = <String, List<ChartDataPoint>>{};
    final baseTime = DateTime.now();

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = parseLine(rows[rowIndex]);
      final timestamp = timeColumnIndex >= 0 && timeColumnIndex < row.length
          ? SessionJsonParser.parseTimestamp(row[timeColumnIndex])
          : null;
      final resolvedTime = timestamp ?? baseTime.add(Duration(seconds: rowIndex));

      numericColumns.forEach((columnIndex, seriesName) {
        if (columnIndex >= row.length) return;
        final numericValue = SessionJsonParser.toDouble(row[columnIndex]);
        if (numericValue == null) return;

        series.putIfAbsent(seriesName, () => []).add(
              ChartDataPoint(
                time: resolvedTime,
                value: numericValue,
                label: seriesName,
              ),
            );
      });
    }

    return SessionJsonParser.finalizeSeriesMap(series);
  }

  // ─── RFC 4180 CSV line parser ──────────────────────────────

  /// Parse a single CSV line respecting quoted fields.
  static List<String> parseLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        final hasEscapedQuote =
            inQuotes && index + 1 < line.length && line[index + 1] == '"';
        if (hasEscapedQuote) {
          buffer.write('"');
          index++;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (char == ',' && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }

  static String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
