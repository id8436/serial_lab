class PeakDetectionResult {
  final List<int> peaks;
  final List<int> valleys;

  const PeakDetectionResult({
    required this.peaks,
    required this.valleys,
  });
}

class PeakDetectionService {
  static PeakDetectionResult detect(
    List<double> values, {
    int minDistance = 3,
    double minProminence = 0.0,
  }) {
    if (values.length < 3) {
      return const PeakDetectionResult(peaks: [], valleys: []);
    }

    final rawPeaks = <int>[];
    final rawValleys = <int>[];

    for (var i = 1; i < values.length - 1; i++) {
      final prev = values[i - 1];
      final current = values[i];
      final next = values[i + 1];

      final peakProminence = current - (prev > next ? prev : next);
      if (current > prev && current >= next && peakProminence >= minProminence) {
        rawPeaks.add(i);
      }

      final valleyProminence = (prev < next ? prev : next) - current;
      if (current < prev && current <= next && valleyProminence >= minProminence) {
        rawValleys.add(i);
      }
    }

    return PeakDetectionResult(
      peaks: _enforceDistance(rawPeaks, values, minDistance, isPeak: true),
      valleys: _enforceDistance(rawValleys, values, minDistance, isPeak: false),
    );
  }

  static List<int> _enforceDistance(
    List<int> candidates,
    List<double> values,
    int minDistance, {
    required bool isPeak,
  }) {
    if (candidates.length < 2 || minDistance <= 1) {
      return candidates;
    }

    final sorted = List<int>.from(candidates)
      ..sort((a, b) {
        final va = values[a];
        final vb = values[b];
        return isPeak ? vb.compareTo(va) : va.compareTo(vb);
      });

    final selected = <int>[];
    for (final idx in sorted) {
      final isFarEnough = selected.every((taken) => (taken - idx).abs() >= minDistance);
      if (isFarEnough) {
        selected.add(idx);
      }
    }

    selected.sort();
    return selected;
  }
}
