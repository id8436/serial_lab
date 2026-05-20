part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisScatterChartPart on _AdvancedGraphAnalysisScreenState {
  Widget _buildScatterChart(
    AppLocalizations l10n,
    ChartSeries series,
    RegressionResult? regression, {
    required ChartSeries? formulaOverlaySeries,
    required AnalysisErrorBarConfig errorBarConfig,
    required bool measurementEnabled,
    List<double>? smoothedValues,
    PeakDetectionResult? peakResult,
    List<double>? extremaSourceValues,
  }) {
    final values = (smoothedValues != null && smoothedValues.length == series.dataPoints.length)
        ? smoothedValues
        : series.dataPoints.map((e) => e.value).toList(growable: false);
    final renderIndices = _buildRenderableIndices(values.length);

    final peakSet = peakResult == null ? <int>{} : peakResult.peaks.toSet();
    final valleySet = peakResult == null ? <int>{} : peakResult.valleys.toSet();

    final spots = <ScatterSpot>[];
    for (final i in renderIndices) {
      final isPeak = peakSet.contains(i);
      final isValley = valleySet.contains(i);

      final (radius, color) = isPeak
          ? (5.0, Colors.red)
          : isValley
              ? (5.0, Colors.cyan)
              : (3.0, Colors.blue);

      spots.add(
        ScatterSpot(
          i.toDouble(),
          values[i],
          yError: _buildYErrorRange(values[i], errorBarConfig),
          dotPainter: FlDotCirclePainter(
            radius: radius,
            color: color,
            strokeWidth: 0,
          ),
        ),
      );
    }

    final cursorSpots = _buildCursorScatterSpots(values);
    final formulaOverlayScatterSpots =
        _buildFormulaOverlayScatterSpots(formulaOverlaySeries, renderIndices: renderIndices);
    final allScatterSpots = <ScatterSpot>[
      ...spots,
      ...formulaOverlayScatterSpots,
      ...cursorSpots,
    ];

    if (values.isEmpty) {
      return Center(child: Text(l10n.advGraphNoPoints));
    }

    final regressionSpots = <FlSpot>[];
    if (regression != null) {
      for (final i in renderIndices) {
        if (i >= 0 && i < regression.predicted.length) {
          regressionSpots.add(FlSpot(i.toDouble(), regression.predicted[i]));
        }
      }
    }

    final yValues = <double>[];
    for (final value in values) {
      final range = _buildYErrorRange(value, errorBarConfig);
      yValues.add(value - (range?.lowerBy ?? 0));
      yValues.add(value + (range?.upperBy ?? 0));
    }
    yValues.addAll(regressionSpots.map((e) => e.y));
    yValues.addAll(formulaOverlayScatterSpots.map((e) => e.y));
    var minY = yValues.reduce(math.min);
    var maxY = yValues.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return Stack(
      children: [
        ScatterChart(
          ScatterChartData(
            minX: 0,
            maxX: (values.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            scatterSpots: allScatterSpots,
            errorIndicatorData: FlErrorIndicatorData(
              show: _showsErrorBars(errorBarConfig),
              painter: (_) => FlSimpleErrorPainter(lineColor: Colors.blue),
            ),
            scatterTouchData: ScatterTouchData(
              enabled: measurementEnabled,
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                if (!measurementEnabled || event is! FlTapUpEvent) {
                  return;
                }
                final touched = response?.touchedSpot;
                if (touched == null) {
                  return;
                }
                final touchedIndex = touched.spot.x.round();
                if (touchedIndex < 0 || touchedIndex >= values.length) {
                  return;
                }
                _handleMeasurementSpotSelected(touchedIndex);
              },
            ),
            gridData: FlGridData(show: true),
            titlesData: const FlTitlesData(
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
          duration: Duration.zero,
          transformationConfig: _chartTransformationConfig(),
        ),
        if (regression != null)
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _buildLineChart(
                l10n,
                series,
                regression,
                formulaOverlaySeries: formulaOverlaySeries,
                errorBarConfig: errorBarConfig,
                measurementEnabled: false,
                showArea: false,
                includeRawSeries: false,
                includeSmoothing: false,
                includePeaks: false,
                showGrid: false,
                showTitles: false,
                showBorders: false,
                minYOverride: minY,
                maxYOverride: maxY,
              ),
            ),
          ),
      ],
    );
  }
}
