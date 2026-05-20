/// Snapshot-based data provider for the Data Analysis section.
///
/// The analysis screens do NOT auto-refresh from live serial data.
/// The user must explicitly press "실시간 데이터 불러오기" to copy the
/// current [SerialProvider] state into this snapshot.
library;

import 'dart:async';
import 'dart:collection';

import 'package:serial_lab/models/analysis_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/utils/app_logger.dart';

class AnalysisDataProvider extends ChangeNotifier {
  Map<String, ChartSeries> _chartData = {};
  Map<String, ChartSeries> _deferredChartData = {};
  Map<String, AnalysisSeriesMetadata> _seriesMetadata = {};
  List<SerialData> _receivedData = [];
  int _loadGeneration = 0;
  static const int _kPreviewMaxRows = 80;
  static const int _kRealtimeMaxRows = 1000; // 실시간 경로: 테이블/그래프 모두 최대 1000행
  static const int _kPreviewMaxSeries = 8;
  static const int _kPreviewRowBatchSize = 200;

  bool _isHydratingImportedData = false;
  double _hydrationProgress = 0;
  int _hydratedSeriesCount = 0;
  int _totalSeriesCount = 0;
  int _pointCount = 0;

  Map<String, ChartSeries> get chartData =>
      _chartData.isNotEmpty ? _chartData : _deferredChartData;
  Map<String, AnalysisSeriesMetadata> get seriesMetadata =>
      UnmodifiableMapView(_seriesMetadata);
  List<SerialData> get receivedData => _receivedData;
  bool get hasData => _chartData.isNotEmpty || _receivedData.isNotEmpty;
  bool get isHydratingImportedData => _isHydratingImportedData;
  double get hydrationProgress => _hydrationProgress;
  int get hydratedSeriesCount => _hydratedSeriesCount;
  int get totalSeriesCount => _totalSeriesCount;
  int get seriesCount => _totalSeriesCount;
  int get pointCount => _pointCount;

  AnalysisSeriesMetadata metadataFor(String seriesName) {
    return _seriesMetadata[seriesName] ?? AnalysisSeriesMetadata.empty;
  }

  void updateSeriesMetadata(String seriesName, AnalysisSeriesMetadata metadata) {
    _seriesMetadata = Map<String, AnalysisSeriesMetadata>.from(_seriesMetadata)
      ..[seriesName] = metadata;
    notifyListeners();
  }

  void updateErrorBarConfig(String seriesName, AnalysisErrorBarConfig errorBars) {
    updateSeriesMetadata(
      seriesName,
      metadataFor(seriesName).copyWith(errorBars: errorBars),
    );
  }

  /// 실시간 SerialProvider로부터 현재 데이터를 스냅샷으로 복사
  ///
  /// ChartSeries.dataPoints 는 mutable list 이므로 loadFromProvider 가
  /// 동기적으로 복사 작업을 수행하면 양이 많을 경우 ANR이 발생할 수 있습니다.
  /// 비동기로 나누어서 복사(deep copy)한 뒤 preview 및 hydration을 진행합니다.
  void loadFromProvider(SerialProvider provider) {
    final analysisRows = provider.analysisSnapshotData;

    if (provider.chartData.isEmpty && analysisRows.isEmpty && provider.receivedData.isEmpty) {
      clear();
      return;
    }

    final loadGeneration = ++_loadGeneration;

    _chartData = const {};
    _deferredChartData = const {};
    _isHydratingImportedData = true;
    _hydrationProgress = 0;
    _hydratedSeriesCount = 0;
    _totalSeriesCount = provider.chartData.length > 64 ? 64 : provider.chartData.length;
    _pointCount = 0;
    _seriesMetadata = _synchronizedMetadata(provider.chartData.keys.take(64));
    _receivedData = const [];
    notifyListeners();

    unawaited(_asyncCopyAndHydrate(provider, analysisRows, loadGeneration));
  }

  Future<void> _asyncCopyAndHydrate(
    SerialProvider provider,
    List<SerialData> analysisRows,
    int loadGeneration,
  ) async {
    try {
      final snapshot = analysisRows.isNotEmpty
          ? await _buildSnapshotFromReceivedData(analysisRows, loadGeneration)
          : provider.receivedData.isNotEmpty
              ? await _buildSnapshotFromReceivedData(provider.receivedData, loadGeneration)
              : await _copySnapshotFromChartData(provider, loadGeneration);

      if (!_isCurrentLoad(loadGeneration)) {
        return;
      }

      await _buildPreviewAndHydrateAsync(
        snapshot,
        maxRows: _kRealtimeMaxRows, // 실시간: 테이블도 전체 행 표시 (그래프와 일치)
        maxSeries: _kPreviewMaxSeries,
        loadGeneration: loadGeneration,
      );
    } catch (e, st) {
      if (!_isCurrentLoad(loadGeneration)) {
        return;
      }
      logger.e('AnalysisDataProvider: realtime snapshot copy failed', error: e, stackTrace: st);
      _isHydratingImportedData = false;
      notifyListeners();
    }
  }

  Future<Map<String, ChartSeries>> _buildSnapshotFromReceivedData(
    List<SerialData> rows,
    int loadGeneration,
  ) async {
    // 실시간 데이터는 chartData가 계속 변하는 동안 시리즈별로 따로 복사하면
    // 서로 다른 시점의 포인트가 섞일 수 있다. 행 단위 스냅샷을 우선 사용해
    // 동일한 수신 시점 기준으로 차트 시리즈를 재구성한다.
    final copiedRows = rows
        .map(
          (entry) => SerialData(
            id: entry.id,
            timestamp: entry.timestamp,
            data: Map<String, dynamic>.from(entry.data),
            deviceId: entry.deviceId,
          ),
        )
        .toList(growable: false);

    final snapshot = <String, ChartSeries>{};
    var processedRows = 0;

    for (final row in copiedRows) {
      for (final entry in row.data.entries) {
        final value = entry.value;
        if (value is! num) {
          continue;
        }

        final dataPoint = ChartDataPoint(
          time: row.timestamp,
          value: value.toDouble(),
          label: entry.key,
        );

        final series = snapshot[entry.key];
        if (series != null) {
          series.addDataPoint(dataPoint);
          continue;
        }

        if (snapshot.length < 64) {
          snapshot[entry.key] = ChartSeries(
            name: entry.key,
            dataPoints: [dataPoint],
          );
        }
      }

      processedRows++;
      if (processedRows % _kPreviewRowBatchSize == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      if (!_isCurrentLoad(loadGeneration)) {
        return const <String, ChartSeries>{};
      }
    }

    return snapshot;
  }

  Future<Map<String, ChartSeries>> _copySnapshotFromChartData(
    SerialProvider provider,
    int loadGeneration,
  ) async {
    final snapshot = <String, ChartSeries>{};
    var count = 0;

    // 행 스냅샷이 없을 때만 series 기반 복사를 fallback 으로 사용한다.
    final entries = provider.chartData.entries.take(64).toList(growable: false);

    for (final entry in entries) {
      snapshot[entry.key] = ChartSeries(
        name: entry.key,
        dataPoints: List<ChartDataPoint>.from(entry.value.dataPoints),
      );
      count++;

      if (count % 4 == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      if (!_isCurrentLoad(loadGeneration)) {
        return const <String, ChartSeries>{};
      }
    }

    return snapshot;
  }

  /// 파일에서 불러온 데이터 적용
  void loadData(Map<String, ChartSeries> chartData, List<SerialData> receivedData) {
    _loadGeneration++;
    _chartData = Map.unmodifiable(Map.fromEntries(chartData.entries));
    _deferredChartData = _chartData;
    _seriesMetadata = _synchronizedMetadata(chartData.keys);
    _receivedData = List.unmodifiable(List.from(receivedData));
    _isHydratingImportedData = false;
    _hydrationProgress = 1;
    _hydratedSeriesCount = _chartData.length;
    _totalSeriesCount = _chartData.length;
    _pointCount = _countPoints(_chartData);
    notifyListeners();
  }

  /// 파일에서 불러온 데이터 적용 + 테이블 미리보기 행 생성
  ///
  /// 차트 원본은 그대로 보존하고, 테이블은 최근 일부 행만 사용해
  /// 대용량 데이터에서도 첫 렌더를 가볍게 유지한다.
  void loadDataWithPreview(
    Map<String, ChartSeries> chartData, {
    int maxRows = _kPreviewMaxRows,
    int maxSeries = _kPreviewMaxSeries,
  }) {
    final loadGeneration = ++_loadGeneration;

    _chartData = const {};
    _deferredChartData = const {};
    _isHydratingImportedData = true;
    _hydrationProgress = 0;
    _hydratedSeriesCount = 0;
    _totalSeriesCount = chartData.length;
    _pointCount = 0;
    _seriesMetadata = _synchronizedMetadata(chartData.keys);
    _receivedData = const [];
    notifyListeners();

    unawaited(
      _buildPreviewAndHydrateAsync(
        chartData,
        maxRows: maxRows,
        maxSeries: maxSeries,
        loadGeneration: loadGeneration,
      ),
    );
  }

  /// 스냅샷 초기화
  void clear() {
    _loadGeneration++;
    _chartData = {};
    _deferredChartData = {};
    _seriesMetadata = {};
    _receivedData = [];
    _isHydratingImportedData = false;
    _hydrationProgress = 0;
    _hydratedSeriesCount = 0;
    _totalSeriesCount = 0;
    _pointCount = 0;
    notifyListeners();
  }

  int _countPoints(Map<String, ChartSeries> chartData) {
    return chartData.values.fold<int>(
      0,
      (sum, series) => sum + series.dataPoints.length,
    );
  }

  Map<String, AnalysisSeriesMetadata> _synchronizedMetadata(
    Iterable<String> seriesNames,
  ) {
    final next = <String, AnalysisSeriesMetadata>{};
    for (final seriesName in seriesNames) {
      next[seriesName] = _seriesMetadata[seriesName] ?? AnalysisSeriesMetadata.empty;
    }
    return next;
  }

  Future<void> _buildPreviewAndHydrateAsync(
    Map<String, ChartSeries> chartData, {
    required int maxRows,
    required int maxSeries,
    required int loadGeneration,
  }) async {
    logger.d('[_buildPreviewAndHydrateAsync] start: chartData.length=${chartData.length}, '
        'loadGeneration=$loadGeneration, _loadGeneration=$_loadGeneration');
    try {
      if (!_isCurrentLoad(loadGeneration)) {
        logger.w('[_buildPreviewAndHydrateAsync] stale load at start: '
            'expected=$loadGeneration, current=$_loadGeneration');
        return;
      }

      if (chartData.isEmpty) {
        logger.w('[_buildPreviewAndHydrateAsync] chartData is EMPTY → nothing to show');
        if (!_isCurrentLoad(loadGeneration)) {
          return;
        }
        _chartData = const {};
        _deferredChartData = const {};
        _receivedData = const [];
        _hydratedSeriesCount = 0;
        _totalSeriesCount = 0;
        _pointCount = 0;
        _hydrationProgress = 0;
        _isHydratingImportedData = false;
        notifyListeners();
        return;
      }

      final selectedSeries = chartData.entries
          .where((e) => e.value.dataPoints.isNotEmpty)
          .take(maxSeries)
          .toList(growable: false);
      logger.d('[_buildPreviewAndHydrateAsync] selectedSeries count=${selectedSeries.length}');

      final rowMap = <int, Map<String, dynamic>>{};
      final timeMap = <int, DateTime>{};

      var totalPointsProcessed = 0;
      for (var i = 0; i < selectedSeries.length; i++) {
        final entry = selectedSeries[i];
        final points = entry.value.dataPoints;
        final start = points.length > maxRows ? points.length - maxRows : 0;
        for (var j = start; j < points.length; j++) {
          final p = points[j];
          final ms = p.time.millisecondsSinceEpoch;
          rowMap.putIfAbsent(ms, () => <String, dynamic>{});
          rowMap[ms]![entry.key] = p.value;
          timeMap.putIfAbsent(ms, () => p.time);

          totalPointsProcessed++;
          if (totalPointsProcessed % _kPreviewRowBatchSize == 0) {
            await Future<void>.delayed(Duration.zero);
          }

          if (!_isCurrentLoad(loadGeneration)) {
            return;
          }
        }
      }

      var previewRows = const <SerialData>[];
      if (rowMap.isNotEmpty) {
        final sortedKeys = rowMap.keys.toList()..sort();
        final startIndex = sortedKeys.length > maxRows ? sortedKeys.length - maxRows : 0;
        final recentKeys = sortedKeys.sublist(startIndex);

        previewRows = List<SerialData>.unmodifiable(
          recentKeys.map((ms) {
            return SerialData(
              id: ms.toString(),
              timestamp: timeMap[ms]!,
              data: rowMap[ms]!,
            );
          }),
        );
      }

      if (!_isCurrentLoad(loadGeneration)) {
        logger.w('[_buildPreviewAndHydrateAsync] stale load before commit: '
            'expected=$loadGeneration, current=$_loadGeneration');
        return;
      }

      logger.d('[_buildPreviewAndHydrateAsync] committing: previewRows=${previewRows.length}, '
          'deferredChartData.length=${chartData.length}');
      _receivedData = previewRows;
      _chartData = const {};
      _deferredChartData = Map.unmodifiable(Map<String, ChartSeries>.from(chartData));
      _hydratedSeriesCount = chartData.length;
      _totalSeriesCount = chartData.length;
      _pointCount = _countPoints(chartData);
      _hydrationProgress = 1;
      _isHydratingImportedData = false;
      notifyListeners();
      logger.d('[_buildPreviewAndHydrateAsync] notifyListeners called ✓');
    } catch (e, st) {
      if (!_isCurrentLoad(loadGeneration)) {
        return;
      }
      logger.e('AnalysisDataProvider: preview build failed', error: e, stackTrace: st);
      _isHydratingImportedData = false;
      notifyListeners();
    }
  }

  bool _isCurrentLoad(int loadGeneration) {
    return loadGeneration == _loadGeneration;
  }
}
