import 'dart:math' as math;

import 'package:serial_lab/models/chart_data.dart';

class StatsResult {
  final int count;
  final double min;
  final double max;
  final double mean;
  final double median;
  final double standardDeviation;

  const StatsResult({
    required this.count,
    required this.min,
    required this.max,
    required this.mean,
    required this.median,
    required this.standardDeviation,
  });
}

class StatsService {
  static StatsResult? analyze(ChartSeries series) {
    if (series.dataPoints.isEmpty) {
      return null;
    }

    final values = series.dataPoints
        .map((p) => p.value)
        .where((v) => v.isFinite)
        .toList();

    if (values.isEmpty) {
      return null;
    }

    values.sort();
    final count = values.length;
    final min = values.first;
    final max = values.last;
    final sum = values.fold<double>(0.0, (acc, v) => acc + v);
    final mean = sum / count;

    final median = count.isOdd
        ? values[count ~/ 2]
        : (values[count ~/ 2 - 1] + values[count ~/ 2]) / 2.0;

    final variance = values
            .map((v) => math.pow(v - mean, 2).toDouble())
            .fold<double>(0.0, (acc, v) => acc + v) /
        count;
    final stddev = math.sqrt(variance);

    return StatsResult(
      count: count,
      min: min,
      max: max,
      mean: mean,
      median: median,
      standardDeviation: stddev,
    );
  }
}
