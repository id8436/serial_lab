import 'dart:math' as math;

import 'package:serial_lab/models/chart_data.dart';

enum RegressionType {
  linear,
  quadratic,
  exponential,
  power,
  logarithmic,
}

extension RegressionTypeLabel on RegressionType {
  String get label {
    switch (this) {
      case RegressionType.linear:
        return 'Linear';
      case RegressionType.quadratic:
        return 'Quadratic';
      case RegressionType.exponential:
        return 'Exponential';
      case RegressionType.power:
        return 'Power';
      case RegressionType.logarithmic:
        return 'Logarithmic';
    }
  }
}

class RegressionCoefficient {
  final String label;
  final double value;

  const RegressionCoefficient({
    required this.label,
    required this.value,
  });
}

class RegressionResult {
  final RegressionType type;
  final int count;
  final double rSquared;
  final List<double> predicted;
  final List<RegressionCoefficient> coefficients;

  const RegressionResult({
    required this.type,
    required this.count,
    required this.rSquared,
    required this.predicted,
    required this.coefficients,
  });

  String get label => type.label;

  String get equationText {
    switch (type) {
      case RegressionType.linear:
        final slope = coefficients[0].value;
        final intercept = coefficients[1].value;
        return 'y = ${_formatNumber(slope)}x ${_formatSignedTerm(intercept)}';
      case RegressionType.quadratic:
        final a = coefficients[0].value;
        final b = coefficients[1].value;
        final c = coefficients[2].value;
        return 'y = ${_formatNumber(a)}x^2 ${_formatSignedTerm(b, suffix: 'x')} ${_formatSignedTerm(c)}';
      case RegressionType.exponential:
        final a = coefficients[0].value;
        final b = coefficients[1].value;
        return 'y = ${_formatNumber(a)}e^(${_formatNumber(b)}x)';
      case RegressionType.power:
        final a = coefficients[0].value;
        final b = coefficients[1].value;
        return 'y = ${_formatNumber(a)}(x + 1)^${_formatNumber(b)}';
      case RegressionType.logarithmic:
        final intercept = coefficients[0].value;
        final slope = coefficients[1].value;
        return 'y = ${_formatNumber(intercept)} ${_formatSignedTerm(slope, suffix: 'ln(x + 1)')}';
    }
  }
}

class RegressionService {
  static RegressionResult? fit(ChartSeries series, RegressionType type) {
    switch (type) {
      case RegressionType.linear:
        return linear(series);
      case RegressionType.quadratic:
        return quadratic(series);
      case RegressionType.exponential:
        return exponential(series);
      case RegressionType.power:
        return power(series);
      case RegressionType.logarithmic:
        return logarithmic(series);
    }
  }

  static RegressionResult? linear(ChartSeries series) {
    final samples = _finiteSamples(series);

    if (samples.length < 2) {
      return null;
    }

    final n = samples.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXX = 0.0;
    var sumXY = 0.0;

    for (final sample in samples) {
      sumX += sample.x;
      sumY += sample.y;
      sumXX += sample.x * sample.x;
      sumXY += sample.x * sample.y;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) {
      return null;
    }

    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumX)) / n;
    final predicted = _predictedForSeries(
      series,
      (x) => (slope * x) + intercept,
    );

    if (predicted == null) {
      return null;
    }

    return RegressionResult(
      type: RegressionType.linear,
      count: n,
      rSquared: _calculateRSquared(samples, (x) => (slope * x) + intercept),
      predicted: predicted,
      coefficients: [
        RegressionCoefficient(label: 'Slope', value: slope),
        RegressionCoefficient(label: 'Intercept', value: intercept),
      ],
    );
  }

  static RegressionResult? quadratic(ChartSeries series) {
    final samples = _finiteSamples(series);

    if (samples.length < 3) {
      return null;
    }

    final n = samples.length.toDouble();
    var sumX = 0.0;
    var sumX2 = 0.0;
    var sumX3 = 0.0;
    var sumX4 = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumX2Y = 0.0;

    for (final sample in samples) {
      final x = sample.x;
      final y = sample.y;
      final x2 = x * x;
      sumX += x;
      sumX2 += x2;
      sumX3 += x2 * x;
      sumX4 += x2 * x2;
      sumY += y;
      sumXY += x * y;
      sumX2Y += x2 * y;
    }

    final solution = _solve3x3(
      [
        [sumX4, sumX3, sumX2],
        [sumX3, sumX2, sumX],
        [sumX2, sumX, n],
      ],
      [sumX2Y, sumXY, sumY],
    );

    if (solution == null) {
      return null;
    }

    final a = solution[0];
    final b = solution[1];
    final c = solution[2];
    final predicted = _predictedForSeries(
      series,
      (x) => (a * x * x) + (b * x) + c,
    );

    if (predicted == null) {
      return null;
    }

    return RegressionResult(
      type: RegressionType.quadratic,
      count: samples.length,
      rSquared: _calculateRSquared(samples, (x) => (a * x * x) + (b * x) + c),
      predicted: predicted,
      coefficients: [
        RegressionCoefficient(label: 'a', value: a),
        RegressionCoefficient(label: 'b', value: b),
        RegressionCoefficient(label: 'c', value: c),
      ],
    );
  }

  static RegressionResult? exponential(ChartSeries series) {
    final samples = _finiteSamples(series).where((sample) => sample.y > 0).toList(growable: false);

    if (samples.length < 2) {
      return null;
    }

    final n = samples.length;
    var sumX = 0.0;
    var sumLogY = 0.0;
    var sumXX = 0.0;
    var sumXLogY = 0.0;

    for (final sample in samples) {
      final logY = math.log(sample.y);
      sumX += sample.x;
      sumLogY += logY;
      sumXX += sample.x * sample.x;
      sumXLogY += sample.x * logY;
    }

    final denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) {
      return null;
    }

    final b = ((n * sumXLogY) - (sumX * sumLogY)) / denominator;
    final logA = (sumLogY - (b * sumX)) / n;
    final a = math.exp(logA);
    final predicted = _predictedForSeries(
      series,
      (x) => a * math.exp(b * x),
    );

    if (predicted == null) {
      return null;
    }

    return RegressionResult(
      type: RegressionType.exponential,
      count: n,
      rSquared: _calculateRSquared(samples, (x) => a * math.exp(b * x)),
      predicted: predicted,
      coefficients: [
        RegressionCoefficient(label: 'a', value: a),
        RegressionCoefficient(label: 'b', value: b),
      ],
    );
  }

  static RegressionResult? power(ChartSeries series) {
    final samples = _finiteSamples(series).where((sample) => sample.y > 0).toList(growable: false);

    if (samples.length < 2) {
      return null;
    }

    final n = samples.length;
    var sumLogX = 0.0;
    var sumLogY = 0.0;
    var sumLogXLogX = 0.0;
    var sumLogXLogY = 0.0;

    for (final sample in samples) {
      final domainX = sample.x + 1;
      final logX = math.log(domainX);
      final logY = math.log(sample.y);
      sumLogX += logX;
      sumLogY += logY;
      sumLogXLogX += logX * logX;
      sumLogXLogY += logX * logY;
    }

    final denominator = (n * sumLogXLogX) - (sumLogX * sumLogX);
    if (denominator == 0) {
      return null;
    }

    final b = ((n * sumLogXLogY) - (sumLogX * sumLogY)) / denominator;
    final logA = (sumLogY - (b * sumLogX)) / n;
    final a = math.exp(logA);
    final predicted = _predictedForSeries(
      series,
      (x) => a * math.pow(x + 1, b).toDouble(),
    );

    if (predicted == null) {
      return null;
    }

    return RegressionResult(
      type: RegressionType.power,
      count: n,
      rSquared: _calculateRSquared(samples, (x) => a * math.pow(x + 1, b).toDouble()),
      predicted: predicted,
      coefficients: [
        RegressionCoefficient(label: 'a', value: a),
        RegressionCoefficient(label: 'b', value: b),
      ],
    );
  }

  static RegressionResult? logarithmic(ChartSeries series) {
    final samples = _finiteSamples(series);

    if (samples.length < 2) {
      return null;
    }

    final n = samples.length;
    var sumLogX = 0.0;
    var sumY = 0.0;
    var sumLogXLogX = 0.0;
    var sumLogXY = 0.0;

    for (final sample in samples) {
      final logX = math.log(sample.x + 1);
      sumLogX += logX;
      sumY += sample.y;
      sumLogXLogX += logX * logX;
      sumLogXY += logX * sample.y;
    }

    final denominator = (n * sumLogXLogX) - (sumLogX * sumLogX);
    if (denominator == 0) {
      return null;
    }

    final slope = ((n * sumLogXY) - (sumLogX * sumY)) / denominator;
    final intercept = (sumY - (slope * sumLogX)) / n;
    final predicted = _predictedForSeries(
      series,
      (x) => intercept + (slope * math.log(x + 1)),
    );

    if (predicted == null) {
      return null;
    }

    return RegressionResult(
      type: RegressionType.logarithmic,
      count: n,
      rSquared: _calculateRSquared(samples, (x) => intercept + (slope * math.log(x + 1))),
      predicted: predicted,
      coefficients: [
        RegressionCoefficient(label: 'Intercept', value: intercept),
        RegressionCoefficient(label: 'Slope', value: slope),
      ],
    );
  }

  static List<_RegressionSample> _finiteSamples(ChartSeries series) {
    final samples = <_RegressionSample>[];
    for (var i = 0; i < series.dataPoints.length; i++) {
      final value = series.dataPoints[i].value;
      if (value.isFinite) {
        samples.add(_RegressionSample(x: i.toDouble(), y: value));
      }
    }
    return samples;
  }

  static List<double>? _predictedForSeries(
    ChartSeries series,
    double Function(double x) evaluator,
  ) {
    final predicted = <double>[];
    for (var i = 0; i < series.dataPoints.length; i++) {
      final value = evaluator(i.toDouble());
      if (!value.isFinite) {
        return null;
      }
      predicted.add(value);
    }
    return predicted;
  }

  static double _calculateRSquared(
    List<_RegressionSample> samples,
    double Function(double x) evaluator,
  ) {
    final meanY = samples.fold<double>(0.0, (acc, sample) => acc + sample.y) / samples.length;
    var ssRes = 0.0;
    var ssTot = 0.0;

    for (final sample in samples) {
      final predicted = evaluator(sample.x);
      final error = sample.y - predicted;
      ssRes += error * error;

      final delta = sample.y - meanY;
      ssTot += delta * delta;
    }

    return ssTot == 0 ? 1.0 : (1.0 - (ssRes / ssTot));
  }

  static List<double>? _solve3x3(List<List<double>> matrix, List<double> rhs) {
    final augmented = List<List<double>>.generate(
      3,
      (row) => [...matrix[row], rhs[row]],
      growable: false,
    );

    for (var pivot = 0; pivot < 3; pivot++) {
      var maxRow = pivot;
      var maxValue = augmented[pivot][pivot].abs();
      for (var row = pivot + 1; row < 3; row++) {
        final candidate = augmented[row][pivot].abs();
        if (candidate > maxValue) {
          maxValue = candidate;
          maxRow = row;
        }
      }

      if (maxValue < 1e-12) {
        return null;
      }

      if (maxRow != pivot) {
        final tmp = augmented[pivot];
        augmented[pivot] = augmented[maxRow];
        augmented[maxRow] = tmp;
      }

      final pivotValue = augmented[pivot][pivot];
      for (var col = pivot; col < 4; col++) {
        augmented[pivot][col] /= pivotValue;
      }

      for (var row = 0; row < 3; row++) {
        if (row == pivot) {
          continue;
        }

        final factor = augmented[row][pivot];
        if (factor == 0) {
          continue;
        }

        for (var col = pivot; col < 4; col++) {
          augmented[row][col] -= factor * augmented[pivot][col];
        }
      }
    }

    return [augmented[0][3], augmented[1][3], augmented[2][3]];
  }
}

class _RegressionSample {
  final double x;
  final double y;

  const _RegressionSample({
    required this.x,
    required this.y,
  });
}

String _formatNumber(double value) {
  final absolute = value.abs();
  if (absolute >= 1000 || (absolute > 0 && absolute < 0.001)) {
    return value.toStringAsExponential(3);
  }
  return value.toStringAsFixed(4);
}

String _formatSignedTerm(double value, {String suffix = ''}) {
  final sign = value >= 0 ? '+ ' : '- ';
  return '$sign${_formatNumber(value.abs())}$suffix';
}
