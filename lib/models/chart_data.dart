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
class ChartSeries {
  final String name;
  final List<ChartDataPoint> _dataPoints;
  double? _minValue;
  double? _maxValue;

  ChartSeries({
    required this.name,
    List<ChartDataPoint>? dataPoints,
  }) : _dataPoints = dataPoints ?? [] {
    // 초기 데이터가 있으면 min/max 계산
    for (final p in _dataPoints) {
      _updateMinMax(p.value);
    }
  }

  List<ChartDataPoint> get dataPoints => _dataPoints;

  void _updateMinMax(double value) {
    if (_minValue == null || value < _minValue!) _minValue = value;
    if (_maxValue == null || value > _maxValue!) _maxValue = value;
  }

  /// 새 데이터 포인트 추가 (in-place, 복사 없음)
  void addDataPoint(ChartDataPoint point) {
    _dataPoints.add(point);
    _updateMinMax(point.value);
  }

  /// 데이터 초기화
  void clear() {
    _dataPoints.clear();
    _minValue = null;
    _maxValue = null;
  }

  /// 최솟값
  double? get minValue => _minValue;

  /// 최댓값
  double? get maxValue => _maxValue;
}
