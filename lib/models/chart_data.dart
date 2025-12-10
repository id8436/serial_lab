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
  final List<ChartDataPoint> dataPoints;
  final int maxDataPoints;

  ChartSeries({
    required this.name,
    this.dataPoints = const [],
    this.maxDataPoints = 100,
  });

  /// 새 데이터 포인트 추가
  ChartSeries addDataPoint(ChartDataPoint point) {
    final newPoints = List<ChartDataPoint>.from(dataPoints)..add(point);
    
    // 최대 데이터 포인트 수 제한
    if (newPoints.length > maxDataPoints) {
      newPoints.removeAt(0);
    }

    return ChartSeries(
      name: name,
      dataPoints: newPoints,
      maxDataPoints: maxDataPoints,
    );
  }

  /// 데이터 초기화
  ChartSeries clear() {
    return ChartSeries(
      name: name,
      dataPoints: [],
      maxDataPoints: maxDataPoints,
    );
  }

  /// 최솟값
  double? get minValue {
    if (dataPoints.isEmpty) return null;
    return dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  /// 최댓값
  double? get maxValue {
    if (dataPoints.isEmpty) return null;
    return dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }
}
