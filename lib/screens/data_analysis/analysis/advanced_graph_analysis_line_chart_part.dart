part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisLineChartPart on _AdvancedGraphAnalysisScreenState {
  Widget _buildLineChart(
    AppLocalizations l10n,
    ChartSeries series,
    RegressionResult? regression, {
    required ChartSeries? formulaOverlaySeries,
    required AnalysisErrorBarConfig errorBarConfig,
    required bool measurementEnabled,
    required bool showArea,
    List<double>? smoothedValues,
    PeakDetectionResult? peakResult,
    List<double>? extremaSourceValues,
    bool includeRawSeries = true,
    bool includeSmoothing = true,
    bool includePeaks = true,
    bool showGrid = true,
    bool showTitles = true,
    bool showBorders = true,
    double? minYOverride,
    double? maxYOverride,
  }) {
    if (series.dataPoints.isEmpty) {
      return Center(child: Text(l10n.advGraphNoPoints));
    }

    final renderIndices = _buildRenderableIndices(series.dataPoints.length);
    final spots = _buildLineSpots(series, errorBarConfig, renderIndices: renderIndices);
    final formulaOverlaySpots =
        _buildFormulaOverlaySpots(formulaOverlaySeries, renderIndices: renderIndices);
    final cursorSpots = _buildCursorLineSpots(series);

    final regressionSpots = <FlSpot>[];
    if (regression != null) {
      for (final i in renderIndices) {
        if (i >= 0 && i < regression.predicted.length) {
          regressionSpots.add(FlSpot(i.toDouble(), regression.predicted[i]));
        }
      }
    }

    final smoothedSpots = <FlSpot>[];
    if (includeSmoothing &&
        smoothedValues != null &&
        smoothedValues.length == series.dataPoints.length) {
      for (final i in renderIndices) {
        smoothedSpots.add(FlSpot(i.toDouble(), smoothedValues[i]));
      }
    }

    final peakSpots = <FlSpot>[];
    final valleySpots = <FlSpot>[];
    if (includePeaks && peakResult != null && extremaSourceValues != null) {
      for (final idx in peakResult.peaks) {
        if (idx >= 0 && idx < extremaSourceValues.length) {
          peakSpots.add(FlSpot(idx.toDouble(), extremaSourceValues[idx]));
        }
      }
      for (final idx in peakResult.valleys) {
        if (idx >= 0 && idx < extremaSourceValues.length) {
          valleySpots.add(FlSpot(idx.toDouble(), extremaSourceValues[idx]));
        }
      }
    }

    final yValues = <double>[];
    if (includeRawSeries) {
      for (var i = 0; i < series.dataPoints.length; i++) {
        final value = series.dataPoints[i].value;
        final range = _buildYErrorRange(value, errorBarConfig);
        yValues.add(value - (range?.lowerBy ?? 0));
        yValues.add(value + (range?.upperBy ?? 0));
      }
    }
    yValues.addAll(regressionSpots.map((e) => e.y));
    yValues.addAll(smoothedSpots.map((e) => e.y));
    yValues.addAll(peakSpots.map((e) => e.y));
    yValues.addAll(valleySpots.map((e) => e.y));
    yValues.addAll(formulaOverlaySpots.map((e) => e.y));

    if (yValues.isEmpty) {
      return Center(child: Text(l10n.advGraphNoPoints));
    }

    var minY = minYOverride ?? yValues.reduce(math.min);
    var maxY = maxYOverride ?? yValues.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.dataPoints.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          if (includeRawSeries)
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 2.5,
              errorIndicatorData: FlErrorIndicatorData(
                show: _showsErrorBars(errorBarConfig),
                painter: (_) => FlSimpleErrorPainter(lineColor: Colors.blue),
              ),
              dotData: FlDotData(show: spots.length < 80),
              belowBarData: BarAreaData(
                show: showArea,
                color: Colors.blue.withValues(alpha: 0.12),
              ),
            ),
          if (smoothedSpots.isNotEmpty)
            LineChartBarData(
              spots: smoothedSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          if (regressionSpots.isNotEmpty)
            LineChartBarData(
              spots: regressionSpots,
              isCurved: false,
              color: Colors.deepOrange,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              dashArray: [8, 6],
            ),
          if (formulaOverlaySpots.isNotEmpty)
            LineChartBarData(
              spots: formulaOverlaySpots,
              isCurved: false,
              color: Colors.purple,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              dashArray: [4, 4],
            ),
          if (peakSpots.isNotEmpty)
            LineChartBarData(
              spots: peakSpots,
              isCurved: false,
              color: Colors.red,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.red,
                  strokeColor: Colors.white,
                  strokeWidth: 1,
                ),
              ),
            ),
          if (valleySpots.isNotEmpty)
            LineChartBarData(
              spots: valleySpots,
              isCurved: false,
              color: Colors.cyan,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.cyan,
                  strokeColor: Colors.white,
                  strokeWidth: 1,
                ),
              ),
            ),
          ...cursorSpots,
        ],
        lineTouchData: LineTouchData(
          enabled: measurementEnabled && includeRawSeries,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (!measurementEnabled || !includeRawSeries || event is! FlTapUpEvent) {
              return;
            }
            final touched = response?.lineBarSpots;
            if (touched == null || touched.isEmpty) {
              return;
            }
            final touchedIndex = touched.first.x.round();
            if (touchedIndex < 0 || touchedIndex >= series.dataPoints.length) {
              return;
            }
            _handleMeasurementSpotSelected(touchedIndex);
          },
        ),
        gridData: FlGridData(show: showGrid),
        titlesData: showTitles
            ? const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              )
            : const FlTitlesData(show: false),
        borderData: FlBorderData(show: showBorders),
      ),
      duration: Duration.zero,
      transformationConfig: _chartTransformationConfig(enableGestures: includeRawSeries),
    );
  }
}
