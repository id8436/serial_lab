/// Signal smoothing utilities for chart data.
///
/// Provides moving-average filtering to reduce noise in time-series
/// sensor data before display.
library;

class SmoothingService {
  static List<double> movingAverage(List<double> values, {int window = 5}) {
    if (values.isEmpty) {
      return const [];
    }

    final safeWindow = window < 1 ? 1 : window;
    final result = List<double>.filled(values.length, 0);

    for (var i = 0; i < values.length; i++) {
      final start = i - safeWindow + 1;
      final from = start < 0 ? 0 : start;
      var sum = 0.0;
      var count = 0;

      for (var j = from; j <= i; j++) {
        sum += values[j];
        count++;
      }

      result[i] = count == 0 ? values[i] : sum / count;
    }

    return result;
  }

  static List<double> exponential(List<double> values, {double alpha = 0.25}) {
    if (values.isEmpty) {
      return const [];
    }

    final clampedAlpha = alpha.clamp(0.0, 1.0);
    final result = List<double>.filled(values.length, 0);
    result[0] = values[0];

    for (var i = 1; i < values.length; i++) {
      result[i] = (clampedAlpha * values[i]) + ((1 - clampedAlpha) * result[i - 1]);
    }

    return result;
  }
}
