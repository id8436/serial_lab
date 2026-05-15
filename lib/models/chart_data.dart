/// 차트에 표시할 데이터 포인트
class ChartDataPoint {
  final DateTime time;
  final double value;
  final String? label;

  ChartDataPoint({
    required this.time,
    required this.value,
    this.label,
  });

  /// X축 값 (시간을 milliseconds로)
  double get x => time.millisecondsSinceEpoch.toDouble();
  
  /// Y축 값
  double get y => value;
}

/// 차트 시리즈 (여러 데이터 세트)
///
/// 메모리 누수 방지를 위해 [maxPoints]를 초과하면 링버퍼처럼 가장 오래된
/// 포인트를 제거합니다. 기본값은 [defaultMaxPoints] (2000).
class ChartSeries {
  /// 시리즈 하나당 기본 최대 포인트 수
  static const int defaultMaxPoints = 2000;

  final String name;
  final int maxPoints;
  final List<ChartDataPoint> _dataPoints;
  double? _minValue;
  double? _maxValue;
  bool _statsDirty = false;

  ChartSeries({
    required this.name,
    List<ChartDataPoint>? dataPoints,
    this.maxPoints = defaultMaxPoints,
  }) : _dataPoints = dataPoints ?? [] {
    for (final p in _dataPoints) {
      _updateMinMax(p.value);
    }
    if (_dataPoints.length > maxPoints) {
      _dataPoints.removeRange(0, _dataPoints.length - maxPoints);
      _statsDirty = true;
    }
  }

  List<ChartDataPoint> get dataPoints => _dataPoints;

  void _updateMinMax(double value) {
    if (_minValue == null || value < _minValue!) _minValue = value;
    if (_maxValue == null || value > _maxValue!) _maxValue = value;
  }

  /// 새 데이터 포인트 추가 (in-place). [maxPoints] 초과 시 가장 오래된 포인트 제거.
  void addDataPoint(ChartDataPoint point) {
    _dataPoints.add(point);
    _updateMinMax(point.value);
    if (_dataPoints.length > maxPoints) {
      final removed = _dataPoints.removeAt(0);
      if (removed.value == _minValue || removed.value == _maxValue) {
        _statsDirty = true;
      }
    }
  }

  /// 데이터 초기화
  void clear() {
    _dataPoints.clear();
    _minValue = null;
    _maxValue = null;
    _statsDirty = false;
  }

  void _recomputeStatsIfNeeded() {
    if (!_statsDirty) return;
    _statsDirty = false;
    _minValue = null;
    _maxValue = null;
    for (final p in _dataPoints) {
      _updateMinMax(p.value);
    }
  }

  /// 최솟값
  double? get minValue {
    _recomputeStatsIfNeeded();
    return _minValue;
  }

  /// 최댓값
  double? get maxValue {
    _recomputeStatsIfNeeded();
    return _maxValue;
  }
}
