part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisChartPart on _AdvancedGraphAnalysisScreenState {
  List<FlSpot> _buildLineSpots(
    ChartSeries series,
    AnalysisErrorBarConfig errorBarConfig,
    {
    List<int>? renderIndices,
  }
  ) {
    final spots = <FlSpot>[];
    final indices = renderIndices ?? _buildRenderableIndices(series.dataPoints.length);
    for (final i in indices) {
      final value = series.dataPoints[i].value;
      spots.add(
        FlSpot(
          i.toDouble(),
          value,
          yError: _buildYErrorRange(value, errorBarConfig),
        ),
      );
    }
    return spots;
  }

  List<FlSpot> _buildFormulaOverlaySpots(
    ChartSeries? series, {
    List<int>? renderIndices,
  }) {
    if (series == null || series.dataPoints.isEmpty) {
      return const <FlSpot>[];
    }
    final indices = renderIndices ?? _buildRenderableIndices(series.dataPoints.length);
    final spots = <FlSpot>[];
    for (final i in indices) {
      if (i < 0 || i >= series.dataPoints.length) {
        continue;
      }
      spots.add(FlSpot(i.toDouble(), series.dataPoints[i].value));
    }
    return spots;
  }

  List<ScatterSpot> _buildFormulaOverlayScatterSpots(
    ChartSeries? series, {
    List<int>? renderIndices,
  }) {
    if (series == null || series.dataPoints.isEmpty) {
      return const <ScatterSpot>[];
    }
    final indices = renderIndices ?? _buildRenderableIndices(series.dataPoints.length);
    final spots = <ScatterSpot>[];
    for (final i in indices) {
      if (i < 0 || i >= series.dataPoints.length) {
        continue;
      }
      spots.add(
        ScatterSpot(
          i.toDouble(),
          series.dataPoints[i].value,
          dotPainter: FlDotCirclePainter(
            radius: 2.5,
            color: Colors.purple,
            strokeWidth: 0,
          ),
        ),
      );
    }
    return spots;
  }

  List<int> _buildRenderableIndices(int length) {
    if (length <= 0) {
      return const <int>[];
    }

    const maxRenderablePoints = 480;
    if (length <= maxRenderablePoints) {
      return List<int>.generate(length, (index) => index, growable: false);
    }

    final last = length - 1;
    final denominator = maxRenderablePoints - 1;
    final indices = <int>{0, last};

    for (var i = 1; i < denominator; i++) {
      indices.add(((i * last) / denominator).round());
    }

    final sorted = indices.toList()..sort();
    return List<int>.unmodifiable(sorted);
  }

  FlErrorRange? _buildYErrorRange(
    double value,
    AnalysisErrorBarConfig errorBarConfig,
  ) {
    if (!_showsErrorBars(errorBarConfig)) {
      return null;
    }

    final magnitude = switch (errorBarConfig.yMode) {
      AnalysisErrorValueMode.none => 0.0,
      AnalysisErrorValueMode.fixedAbsolute => errorBarConfig.yValue,
      AnalysisErrorValueMode.percentage => value.abs() * (errorBarConfig.yValue / 100),
    };

    if (!magnitude.isFinite || magnitude <= 0) {
      return null;
    }

    return FlErrorRange.symmetric(magnitude);
  }

  bool _showsErrorBars(AnalysisErrorBarConfig errorBarConfig) {
    return errorBarConfig.enabled &&
        errorBarConfig.yMode != AnalysisErrorValueMode.none &&
        errorBarConfig.yValue > 0;
  }

  double _errorSliderValue(AnalysisErrorBarConfig errorBarConfig) {
    return switch (errorBarConfig.yMode) {
      AnalysisErrorValueMode.none => 0,
      AnalysisErrorValueMode.fixedAbsolute => errorBarConfig.yValue.clamp(0, double.infinity),
      AnalysisErrorValueMode.percentage => errorBarConfig.yValue.clamp(0, 100),
    };
  }

  double _errorSliderMax(
    AnalysisErrorBarConfig errorBarConfig,
    List<double> rawValues,
  ) {
    if (errorBarConfig.yMode == AnalysisErrorValueMode.percentage) {
      return 100;
    }

    final iterator = rawValues.where((value) => value.isFinite).map((value) => value.abs()).iterator;
    if (!iterator.moveNext()) {
      return 1;
    }

    var maxValue = iterator.current;
    while (iterator.moveNext()) {
      if (iterator.current > maxValue) {
        maxValue = iterator.current;
      }
    }
    return math.max(maxValue, 1);
  }

  List<LineChartBarData> _buildCursorLineSpots(ChartSeries series) {
    final cursorBars = <LineChartBarData>[];
    final spots = [
      (_cursorAIndex, Colors.amber),
      (_cursorBIndex, Colors.deepPurple),
    ];

    for (final (index, color) in spots) {
      if (index == null || index < 0 || index >= series.dataPoints.length) {
        continue;
      }
      cursorBars.add(
        LineChartBarData(
          spots: [FlSpot(index.toDouble(), series.dataPoints[index].value)],
          isCurved: false,
          color: color,
          barWidth: 0,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, spotIndex) => FlDotCirclePainter(
              radius: 5,
              color: color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        ),
      );
    }

    return cursorBars;
  }

  List<ScatterSpot> _buildCursorScatterSpots(List<double> values) {
    final cursorSpots = <ScatterSpot>[];
    final entries = [
      (_cursorAIndex, Colors.amber),
      (_cursorBIndex, Colors.deepPurple),
    ];
    for (final (index, color) in entries) {
      if (index == null || index < 0 || index >= values.length) {
        continue;
      }
      cursorSpots.add(
        ScatterSpot(
          index.toDouble(),
          values[index],
          renderPriority: 1,
          dotPainter: FlDotCirclePainter(
            radius: 6,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
        ),
      );
    }
    return cursorSpots;
  }

  Widget _buildBarChart(AppLocalizations l10n, ChartSeries series) {
    if (series.dataPoints.isEmpty) {
      return Center(child: Text(l10n.advGraphNoPoints));
    }

    final values = series.dataPoints.map((e) => e.value).toList(growable: false);
    final start = values.length > 80 ? values.length - 80 : 0;
    final cropped = values.sublist(start);

    var maxY = cropped.reduce(math.max);
    var minY = cropped.reduce(math.min);
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    final bars = <BarChartGroupData>[];
    for (var i = 0; i < cropped.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: cropped[i],
              width: 6,
              color: Colors.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        barGroups: bars,
        gridData: FlGridData(show: true),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
      transformationConfig: _chartTransformationConfig(),
    );
  }

  Widget _buildHistogram(AppLocalizations l10n, ChartSeries series) {
    final values = series.dataPoints
        .map((p) => p.value)
        .where((v) => v.isFinite)
        .toList(growable: false);

    if (values.length < 2) {
      return Center(child: Text(l10n.advGraphHistogramNeedPoints));
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      return Center(child: Text(l10n.advGraphHistogramConstantValues));
    }

    final binCount = _histogramBins;
    final width = (maxValue - minValue) / binCount;
    final counts = List<int>.filled(binCount, 0);

    for (final value in values) {
      var index = ((value - minValue) / width).floor();
      if (index >= binCount) {
        index = binCount - 1;
      }
      if (index < 0) {
        index = 0;
      }
      counts[index]++;
    }

    final maxCount = counts.reduce(math.max).toDouble();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < counts.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: counts[i].toDouble(),
              width: 10,
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxCount <= 0 ? 1 : maxCount * 1.1,
        barGroups: groups,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= binCount) {
                  return const SizedBox.shrink();
                }
                final start = minValue + (idx * width);
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(start.toStringAsFixed(1), style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
      ),
      transformationConfig: _chartTransformationConfig(),
    );
  }
}