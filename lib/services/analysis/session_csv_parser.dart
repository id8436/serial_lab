/// CSV import/export for analysis session data.
///
/// Handles:
/// - **Export**: [ChartSeries] map → CSV with columns `series,time,value`
/// - **Import**: Flexible CSV parsing with:
///   - Auto-detection of timestamp columns (`time`, `timestamp`, `date`, `datetime`)
///   - Multi-series support (each non-timestamp column becomes a series)
///   - Quoted field support (RFC 4180 compliant)
library;

import 'package:serial_lab/models/chart_data.dart';
import 'session_json_parser.dart'; // shared utilities

/// Parses and serializes chart session data in CSV format.
class SessionCsvParser {
  /// Serialize chart data to CSV string.
  ///
  /// Output columns: `series,time,value`
  static String toCsv(Map<String, ChartSeries> chartData) {
    final rows = <String>['series,time,value'];

    for (final entry in chartData.entries) {
      final seriesName = _escapeCsv(entry.key);
      for (final p in entry.value.dataPoints) {
        rows.add(
          '$seriesName,${p.time.toIso8601String()},${p.value.toStringAsFixed(6)}',
        );
      }
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
        .toList();
    if (lines.length < 2) {
      throw const FormatException('CSV must include a header and at least one row');
    }

    final headers = parseLine(lines.first);
    if (headers.isEmpty) {
      throw const FormatException('CSV header is empty');
    }

    final timeColumnIndex =
        headers.indexWhere(SessionJsonParser.isTimestampKey);
    final numericColumns = <int, String>{};
    for (var index = 0; index < headers.length; index++) {
      final header = headers[index].trim();
      if (header.isEmpty || index == timeColumnIndex) continue;
      numericColumns[index] = header;
    }

    final series = <String, List<ChartDataPoint>>{};
    final baseTime = DateTime.now();

    for (var rowIndex = 1; rowIndex < lines.length; rowIndex++) {
      final row = parseLine(lines[rowIndex]);
      final timestamp = timeColumnIndex >= 0 && timeColumnIndex < row.length
          ? SessionJsonParser.parseTimestamp(row[timeColumnIndex])
          : null;
      final resolvedTime =
          timestamp ?? baseTime.add(Duration(seconds: rowIndex - 1));

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
