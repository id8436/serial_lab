import 'package:serial_lab/models/chart_data.dart';

class RegressionResult {
  final int count;
  final double slope;
  final double intercept;
  final double rSquared;
  final List<double> predicted;

  const RegressionResult({
    required this.count,
    required this.slope,
    required this.intercept,
    required this.rSquared,
    required this.predicted,
  });
}

class RegressionService {
  static RegressionResult? linear(ChartSeries series) {
    final values = series.dataPoints
        .map((p) => p.value)
        .where((v) => v.isFinite)
        .toList(growable: false);

    if (values.length < 2) {
      return null;
    }

    final n = values.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXX = 0.0;
    var sumXY = 0.0;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXX += x * x;
      sumXY += x * y;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) {
      return null;
    }

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumX)) / n;

    final predicted = List<double>.generate(
      n,
      (index) => (slope * index) + intercept,
      growable: false,
    );

    final meanY = sumY / n;
    var ssRes = 0.0;
    var ssTot = 0.0;
    for (var i = 0; i < n; i++) {
      final error = values[i] - predicted[i];
      ssRes += error * error;

      final delta = values[i] - meanY;
      ssTot += delta * delta;
    }

    final rSquared = ssTot == 0 ? 1.0 : (1.0 - (ssRes / ssTot));

    return RegressionResult(
      count: n,
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
      predicted: predicted,
    );
  }
}
