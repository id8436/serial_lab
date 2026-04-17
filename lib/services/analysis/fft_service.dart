import 'dart:math' as math;

import 'package:serial_lab/models/chart_data.dart';

class FftBin {
  final double frequencyHz;
  final double magnitude;

  const FftBin({required this.frequencyHz, required this.magnitude});
}

class FftResult {
  final int sampleCount;
  final double sampleRateHz;
  final List<FftBin> bins;

  const FftResult({
    required this.sampleCount,
    required this.sampleRateHz,
    required this.bins,
  });
}

class FftService {
  static FftResult? analyze(ChartSeries series, {int windowSize = 128}) {
    if (series.dataPoints.length < 8) {
      return null;
    }

    final size = _nearestPowerOfTwo(math.min(windowSize, series.dataPoints.length));
    if (size < 8) {
      return null;
    }

    final points = series.dataPoints.sublist(series.dataPoints.length - size);

    final dtMs = _averageDeltaMs(points);
    if (dtMs <= 0) {
      return null;
    }

    final sampleRateHz = 1000.0 / dtMs;
    final values = points.map((p) => p.value).toList();

    final real = List<double>.from(values);
    final imag = List<double>.filled(size, 0);
    _fft(real, imag);

    final half = size ~/ 2;
    final bins = <FftBin>[];
    for (var i = 1; i < half; i++) {
      final magnitude = math.sqrt(real[i] * real[i] + imag[i] * imag[i]) / size;
      final freq = i * sampleRateHz / size;
      bins.add(FftBin(frequencyHz: freq, magnitude: magnitude));
    }

    return FftResult(sampleCount: size, sampleRateHz: sampleRateHz, bins: bins);
  }

  static int _nearestPowerOfTwo(int value) {
    var p = 1;
    while (p * 2 <= value) {
      p *= 2;
    }
    return p;
  }

  static double _averageDeltaMs(List<ChartDataPoint> points) {
    if (points.length < 2) {
      return 0;
    }

    var total = 0.0;
    var count = 0;
    for (var i = 1; i < points.length; i++) {
      final dt = points[i].time.difference(points[i - 1].time).inMilliseconds;
      if (dt > 0) {
        total += dt;
        count++;
      }
    }

    if (count == 0) {
      return 0;
    }
    return total / count;
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
