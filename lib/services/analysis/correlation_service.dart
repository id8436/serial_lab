import 'dart:math' as math;

import 'package:serial_lab/models/chart_data.dart';

class CorrelationResult {
  final String seriesX;
  final String seriesY;
  final int pairCount;
  final double coefficient;

  const CorrelationResult({
    required this.seriesX,
    required this.seriesY,
    required this.pairCount,
    required this.coefficient,
  });
}

class CorrelationService {
  static CorrelationResult? pearson(
    String xName,
    ChartSeries xSeries,
    String yName,
    ChartSeries ySeries,
  ) {
    final pairs = _alignPairs(xSeries, ySeries);
    if (pairs.length < 2) {
      return null;
    }

    final xs = pairs.map((p) => p.$1).toList();
    final ys = pairs.map((p) => p.$2).toList();

    final meanX = xs.reduce((a, b) => a + b) / xs.length;
    final meanY = ys.reduce((a, b) => a + b) / ys.length;

    double numerator = 0;
    double sumX = 0;
    double sumY = 0;
    for (var i = 0; i < pairs.length; i++) {
      final dx = xs[i] - meanX;
      final dy = ys[i] - meanY;
      numerator += dx * dy;
      sumX += dx * dx;
      sumY += dy * dy;
    }

    final denominator = math.sqrt(sumX * sumY);
    if (denominator == 0) {
      return null;
    }

    return CorrelationResult(
      seriesX: xName,
      seriesY: yName,
      pairCount: pairs.length,
      coefficient: numerator / denominator,
    );
  }

  /// 모든 시리즈 쌍의 상관계수 행렬을 계산합니다.
  /// keys 순서와 동일한 n×n 행렬을 반환합니다.
  static List<List<double?>> correlationMatrix(
    Map<String, ChartSeries> chartData,
  ) {
    final keys = chartData.keys.toList();
    final n = keys.length;
    return List.generate(n, (i) {
      return List.generate(n, (j) {
        if (i == j) return 1.0; // 자기 자신은 항상 1
        final result = pearson(
          keys[i], chartData[keys[i]]!,
          keys[j], chartData[keys[j]]!,
        );
        return result?.coefficient;
      });
    });
  }

  static List<(double, double)> _alignPairs(
    ChartSeries xSeries,
    ChartSeries ySeries,
  ) {
    final xByTime = <int, double>{
      for (final p in xSeries.dataPoints) p.time.millisecondsSinceEpoch: p.value,
    };
    final yByTime = <int, double>{
      for (final p in ySeries.dataPoints) p.time.millisecondsSinceEpoch: p.value,
    };

    final pairs = <(double, double)>[];
    for (final entry in xByTime.entries) {
      final y = yByTime[entry.key];
      if (y != null && entry.value.isFinite && y.isFinite) {
        pairs.add((entry.value, y));
      }
    }
    return pairs;
  }
}
