import 'dart:math' as math;

import 'package:serial_lab/models/chart_data.dart';

enum FftWindow { rectangular, hann }

class FftBin {
  final double frequencyHz;
  final double magnitude;

  const FftBin({required this.frequencyHz, required this.magnitude});
}

class FftResult {
  final int sampleCount;
  final double sampleRateHz;
  final List<FftBin> bins;
  final FftWindow window;

  /// Coefficient of variation of the inter-sample interval
  /// (stddev / mean). 0 means perfectly periodic; > ~0.1 means the
  /// reported sample rate is unreliable and FFT results should be
  /// taken with a grain of salt.
  final double jitterRatio;

  const FftResult({
    required this.sampleCount,
    required this.sampleRateHz,
    required this.bins,
    required this.window,
    required this.jitterRatio,
  });

  double get nyquistHz => sampleRateHz / 2;

  /// Bin with the largest magnitude. Null if no bins.
  FftBin? get peak {
    if (bins.isEmpty) return null;
    var best = bins.first;
    for (final b in bins) {
      if (b.magnitude > best.magnitude) best = b;
    }
    return best;
  }
}

class FftService {
  static FftResult? analyze(
    ChartSeries series, {
    int windowSize = 128,
    FftWindow window = FftWindow.hann,
  }) {
    if (series.dataPoints.length < 8) {
      return null;
    }

    final size = _nearestPowerOfTwo(math.min(windowSize, series.dataPoints.length));
    if (size < 8) {
      return null;
    }

    final points = series.dataPoints.sublist(series.dataPoints.length - size);

    final stats = _intervalStats(points);
    if (stats == null || stats.meanMs <= 0) {
      return null;
    }

    final sampleRateHz = 1000.0 / stats.meanMs;
    final jitterRatio = stats.meanMs > 0 ? stats.stdDevMs / stats.meanMs : 0.0;

    // Remove DC offset, then apply window function. Both reduce spectral
    // leakage and stop the DC component from drowning out real peaks.
    final values = points.map((p) => p.value).toList();
    final mean = values.reduce((a, b) => a + b) / size;

    final coherentGain = _coherentGain(window, size); // Σ w[n] / N
    final real = List<double>.generate(size, (i) {
      final w = _windowCoeff(window, i, size);
      return (values[i] - mean) * w;
    });
    final imag = List<double>.filled(size, 0);
    _fft(real, imag);

    // Normalize so a unit sinusoid -> magnitude == its amplitude.
    // Single-sided spectrum: factor of 2 (DC bin is dropped below).
    final scale = (size * coherentGain) == 0
        ? 0.0
        : 2.0 / (size * coherentGain);

    final half = size ~/ 2;
    final bins = <FftBin>[];
    for (var i = 1; i < half; i++) {
      final magnitude = math.sqrt(real[i] * real[i] + imag[i] * imag[i]) * scale;
      final freq = i * sampleRateHz / size;
      bins.add(FftBin(frequencyHz: freq, magnitude: magnitude));
    }

    return FftResult(
      sampleCount: size,
      sampleRateHz: sampleRateHz,
      bins: bins,
      window: window,
      jitterRatio: jitterRatio,
    );
  }

  static double _windowCoeff(FftWindow window, int n, int size) {
    switch (window) {
      case FftWindow.rectangular:
        return 1.0;
      case FftWindow.hann:
        return 0.5 * (1 - math.cos(2 * math.pi * n / (size - 1)));
    }
  }

  static double _coherentGain(FftWindow window, int size) {
    switch (window) {
      case FftWindow.rectangular:
        return 1.0;
      case FftWindow.hann:
        var sum = 0.0;
        for (var i = 0; i < size; i++) {
          sum += _windowCoeff(window, i, size);
        }
        return sum / size;
    }
  }

  static int _nearestPowerOfTwo(int value) {
    var p = 1;
    while (p * 2 <= value) {
      p *= 2;
    }
    return p;
  }

  static _IntervalStats? _intervalStats(List<ChartDataPoint> points) {
    if (points.length < 2) return null;

    final deltas = <double>[];
    for (var i = 1; i < points.length; i++) {
      final dt = points[i].time.difference(points[i - 1].time).inMilliseconds;
      if (dt > 0) deltas.add(dt.toDouble());
    }
    if (deltas.isEmpty) return null;

    final mean = deltas.reduce((a, b) => a + b) / deltas.length;
    if (deltas.length == 1) {
      return _IntervalStats(meanMs: mean, stdDevMs: 0);
    }
    var sqSum = 0.0;
    for (final d in deltas) {
      final diff = d - mean;
      sqSum += diff * diff;
    }
    final stdDev = math.sqrt(sqSum / deltas.length);
    return _IntervalStats(meanMs: mean, stdDevMs: stdDev);
  }

  static void _fft(List<double> real, List<double> imag) {
    final n = real.length;
    var j = 0;

    for (var i = 1; i < n; i++) {
      var bit = n >> 1;
      while ((j & bit) != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        final tr = real[i];
        real[i] = real[j];
        real[j] = tr;

        final ti = imag[i];
        imag[i] = imag[j];
        imag[j] = ti;
      }
    }

    for (var len = 2; len <= n; len <<= 1) {
      final angle = -2 * math.pi / len;
      final wLenR = math.cos(angle);
      final wLenI = math.sin(angle);

      for (var i = 0; i < n; i += len) {
        var wR = 1.0;
        var wI = 0.0;

        for (var k = 0; k < len ~/ 2; k++) {
          final uR = real[i + k];
          final uI = imag[i + k];
          final vR = real[i + k + len ~/ 2] * wR - imag[i + k + len ~/ 2] * wI;
          final vI = real[i + k + len ~/ 2] * wI + imag[i + k + len ~/ 2] * wR;

          real[i + k] = uR + vR;
          imag[i + k] = uI + vI;
          real[i + k + len ~/ 2] = uR - vR;
          imag[i + k + len ~/ 2] = uI - vI;

          final nextWR = wR * wLenR - wI * wLenI;
          final nextWI = wR * wLenI + wI * wLenR;
          wR = nextWR;
          wI = nextWI;
        }
      }
    }
  }
}

class _IntervalStats {
  final double meanMs;
  final double stdDevMs;
  const _IntervalStats({required this.meanMs, required this.stdDevMs});
}
