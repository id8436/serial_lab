/// JSON import/export for analysis session data.
///
/// Handles two serialization directions:
/// - **Export**: [ChartSeries] map → JSON with `{version, name, savedAt, series}` envelope
/// - **Import**: Flexible JSON parsing supporting:
///   - Own format (series map with time/value arrays)
///   - Array-of-objects format (each object has timestamp + numeric fields)
///   - Flat key→array format (each key maps to a list of numbers or objects)
library;

import 'dart:convert';
import 'package:serial_lab/models/chart_data.dart';

/// Parses and serializes chart session data in JSON format.
class SessionJsonParser {
  /// Serialize chart data to the canonical JSON map structure.
  ///
  /// Output schema:
  /// ```json
  /// { "version": 1, "name": "...", "savedAt": "ISO8601", "series": { ... } }
  /// ```
  static Map<String, dynamic> toJsonMap(
    Map<String, ChartSeries> chartData, {
    String? name,
  }) {
    final now = DateTime.now();
    return {
      'version': 1,
      'name': name ?? 'session_${now.toIso8601String()}',
      'savedAt': now.toIso8601String(),
      'series': chartData.map((key, series) {
        return MapEntry(
          key,
          series.dataPoints
              .map((p) => {
                    'time': p.time.toIso8601String(),
                    'value': p.value,
                    if (p.label != null) 'label': p.label,
                  })
              .toList(),
        );
      }),
    };
  }

  /// Deserialize from the canonical JSON map structure.
  static Map<String, ChartSeries> fromJsonMap(Map<String, dynamic> map) {
    final seriesMap = <String, ChartSeries>{};
    final rawSeries = map['series'];
    if (rawSeries is! Map<String, dynamic>) return seriesMap;

    rawSeries.forEach((name, value) {
      if (value is! List) return;

      final points = <ChartDataPoint>[];
      for (final row in value) {
        if (row is! Map<String, dynamic>) continue;
        final timeStr = row['time'];
        final valueNum = row['value'];
        if (timeStr is! String || valueNum is! num) continue;
        final parsed = DateTime.tryParse(timeStr);
        if (parsed == null) continue;

        points.add(ChartDataPoint(
          time: parsed,
          value: valueNum.toDouble(),
          label: row['label'] as String?,
        ));
      }

      seriesMap[name] = ChartSeries(
        name: name,
        dataPoints: points,
      );
    });

    return seriesMap;
  }

  /// Parse arbitrary JSON content into chart series.
  ///
  /// Tries multiple strategies in order:
  /// 1. Own canonical format (has `series` key)
  /// 2. Object with `data` array
  /// 3. Key→value-list map
  /// 4. Top-level array of row objects
  static Map<String, ChartSeries> parse(String content) {
    final decoded = jsonDecode(content);

    if (decoded is Map<String, dynamic>) {
      // Strategy 1: canonical format
      if (decoded['series'] is Map<String, dynamic>) {
        final sessionData = fromJsonMap(decoded);
        if (sessionData.isNotEmpty) return sessionData;
      }

      // Strategy 2: { "data": [ ... ] }
      if (decoded['data'] is List) {
        return _buildSeriesFromRows(decoded['data'] as List);
      }

      // Strategy 3: { "seriesA": [...], "seriesB": [...] }
      return _buildSeriesFromJsonMap(decoded);
    }

    // Strategy 4: top-level array
    if (decoded is List) {
      return _buildSeriesFromRows(decoded);
    }

    throw const FormatException('Unsupported JSON structure');
  }

  // ─── Internal helpers ──────────────────────────────────────

  static Map<String, ChartSeries> _buildSeriesFromJsonMap(
    Map<String, dynamic> map,
  ) {
    final data = <String, List<ChartDataPoint>>{};
    var hasSeries = false;

    map.forEach((key, value) {
      if (value is List) {
        final points = _pointsFromSeriesList(key, value);
        if (points.isNotEmpty) {
          data[key] = points;
          hasSeries = true;
        }
      }
    });

    if (hasSeries) return finalizeSeriesMap(data);
    throw const FormatException('Could not find numeric series in JSON');
  }

  static Map<String, ChartSeries> _buildSeriesFromRows(List rows) {
    final series = <String, List<ChartDataPoint>>{};
    final baseTime = DateTime.now();

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final timestamp =
          extractTimestamp(map) ?? baseTime.add(Duration(seconds: index));

      map.forEach((key, value) {
        if (isTimestampKey(key)) return;
        final numericValue = toDouble(value);
        if (numericValue == null) return;

        series
            .putIfAbsent(key, () => [])
            .add(ChartDataPoint(time: timestamp, value: numericValue, label: key));
      });
    }

    return finalizeSeriesMap(series);
  }

  static List<ChartDataPoint> _pointsFromSeriesList(String key, List values) {
    final points = <ChartDataPoint>[];
    final baseTime = DateTime.now();

    for (var index = 0; index < values.length; index++) {
      final entry = values[index];
      if (entry is num || entry is String) {
        final numericValue = toDouble(entry);
        if (numericValue == null) continue;
        points.add(ChartDataPoint(
          time: baseTime.add(Duration(seconds: index)),
          value: numericValue,
          label: key,
        ));
        continue;
      }

      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final timestamp =
          extractTimestamp(map) ?? baseTime.add(Duration(seconds: index));
      final numericValue = toDouble(map['value'] ?? map[key]);
      if (numericValue == null) continue;

      points.add(ChartDataPoint(
        time: timestamp,
        value: numericValue,
        label: key,
      ));
    }

    return points;
  }

  // ─── Shared utilities (also used by SessionCsvParser) ──────

  /// Build [ChartSeries] map from collected data point lists.
  static Map<String, ChartSeries> finalizeSeriesMap(
    Map<String, List<ChartDataPoint>> series,
  ) {
    final result = <String, ChartSeries>{};
    series.forEach((name, points) {
      if (points.isEmpty) return;
      result[name] = ChartSeries(
        name: name,
        dataPoints: points,
      );
    });
    if (result.isEmpty) {
      throw const FormatException('No numeric data could be imported');
    }
    return result;
  }

  /// Check if a column/key name represents a timestamp field.
  static bool isTimestampKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized == 'time' ||
        normalized == 'timestamp' ||
        normalized == 'date' ||
        normalized == 'datetime';
  }

  /// Extract timestamp from a row object by checking known keys.
  static DateTime? extractTimestamp(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      if (isTimestampKey(entry.key)) return parseTimestamp(entry.value);
    }
    return null;
  }

  /// Parse a value (DateTime, num, or String) into a DateTime.
  static DateTime? parseTimestamp(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;

    if (raw is num) {
      final value = raw.toInt();
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final parsedDate = DateTime.tryParse(trimmed);
      if (parsedDate != null) return parsedDate;
      final parsedNumber = int.tryParse(trimmed);
      if (parsedNumber != null) return parseTimestamp(parsedNumber);
    }

    return null;
  }

  /// Attempt to convert any value to double.
  static double? toDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final normalized = raw.trim();
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    return null;
  }
}
