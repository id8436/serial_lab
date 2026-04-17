/// Snapshot-based data provider for the Data Analysis section.
///
/// The analysis screens do NOT auto-refresh from live serial data.
/// The user must explicitly press "실시간 데이터 불러오기" to copy the
/// current [SerialProvider] state into this snapshot.
library;

import 'package:flutter/foundation.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/providers/serial_provider.dart';

class AnalysisDataProvider extends ChangeNotifier {
  Map<String, ChartSeries> _chartData = {};
  List<SerialData> _receivedData = [];

  Map<String, ChartSeries> get chartData => _chartData;
  List<SerialData> get receivedData => _receivedData;
  bool get hasData => _chartData.isNotEmpty || _receivedData.isNotEmpty;

  /// 실시간 SerialProvider로부터 현재 데이터를 스냅샷으로 복사
  void loadFromProvider(SerialProvider provider) {
    _chartData = Map.unmodifiable(Map.fromEntries(
      provider.chartData.entries,
    ));
    _receivedData = List.unmodifiable(List.from(provider.receivedData));
    notifyListeners();
  }

  /// 파일에서 불러온 데이터 적용
  void loadData(Map<String, ChartSeries> chartData, List<SerialData> receivedData) {
    _chartData = Map.unmodifiable(Map.fromEntries(chartData.entries));
    _receivedData = List.unmodifiable(List.from(receivedData));
    notifyListeners();
  }

  /// 스냅샷 초기화
  void clear() {
    _chartData = {};
    _receivedData = [];
    notifyListeners();
  }
}
