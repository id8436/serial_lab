import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/services/analysis/peak_detection_service.dart';
import 'package:serial_lab/services/analysis/regression_service.dart';
import 'package:serial_lab/services/analysis/smoothing_service.dart';

enum GraphMode {
  line,
  scatter,
  bar,
  area,
  histogram,
}

class AdvancedGraphAnalysisScreen extends StatefulWidget {
  const AdvancedGraphAnalysisScreen({super.key});

  @override
  State<AdvancedGraphAnalysisScreen> createState() => _AdvancedGraphAnalysisScreenState();
}

class _AdvancedGraphAnalysisScreenState extends State<AdvancedGraphAnalysisScreen> {
  String? _selectedSeries;
  GraphMode _mode = GraphMode.line;
  int _histogramBins = 12;
  bool _showFit = true;
  RegressionType _fitType = RegressionType.linear;
  bool _showSmoothing = false;
  int _smoothingWindow = 5;
  bool _showPeaks = false;
  double _peakProminenceRatio = 0.08;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AnalysisDataProvider>(
      builder: (context, analysisData, _) {
        final chartData = analysisData.chartData;
        if (chartData.isEmpty) {
          return Center(
            child: Text(l10n.advGraphNoData),
          );
        }

        if (_selectedSeries == null || !chartData.containsKey(_selectedSeries)) {
          _selectedSeries = chartData.keys.first;
        }

        final series = chartData[_selectedSeries]!;
    final supportsFit =
      _mode == GraphMode.line || _mode == GraphMode.scatter || _mode == GraphMode.area;
        final rawValues = series.dataPoints.map((p) => p.value).toList(growable: false);
        final smoothedValues = _showSmoothing
            ? SmoothingService.movingAverage(rawValues, window: _smoothingWindow)
            : null;

        final valuesForExtrema = smoothedValues ?? rawValues;
        final minValue = valuesForExtrema.isEmpty ? 0.0 : valuesForExtrema.reduce(math.min);
        final maxValue = valuesForExtrema.isEmpty ? 0.0 : valuesForExtrema.reduce(math.max);
        final valueRange = (maxValue - minValue).abs();
        final minProminence = valueRange * _peakProminenceRatio;

        final peakResult = _showPeaks
            ? PeakDetectionService.detect(
                valuesForExtrema,
                minDistance: 3,
                minProminence: minProminence,
              )
            : null;

        final regressionInput = smoothedValues == null
            ? series
            : _seriesWithReplacementValues(series, smoothedValues);
    final regression = supportsFit && _showFit
      ? RegressionService.fit(regressionInput, _fitType)
      : null;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(l10n.advGraphSeries),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedSeries,
                          isExpanded: true,
                          items: chartData.keys
                              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedSeries = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.advGraphGraph),
                      const SizedBox(width: 8),
                      DropdownButton<GraphMode>(
                        value: _mode,
                        items: GraphMode.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                  child: Text(_modeLabel(l10n, m)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _mode = value);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_mode == GraphMode.histogram)
                    Row(
                      children: [
                        Text(l10n.advGraphBins),
                        Expanded(
                          child: Slider(
                            value: _histogramBins.toDouble(),
                            min: 6,
                            max: 30,
                            divisions: 24,
                            label: '$_histogramBins',
                            onChanged: (value) {
                              setState(() {
                                _histogramBins = value.round();
                              });
                            },
                          ),
                        ),
                        Text('$_histogramBins'),
                      ],
                    ),
                  if (_mode == GraphMode.line ||
                      _mode == GraphMode.scatter ||
                      _mode == GraphMode.area) ...[
                    Row(
                      children: [
                        Switch(
                          value: _showSmoothing,
                          onChanged: (value) {
                            setState(() {
                              _showSmoothing = value;
                            });
                          },
                        ),
                        Text(l10n.advGraphSmoothing),
                        if (_showSmoothing) ...[
                          const SizedBox(width: 12),
                          Text(l10n.advGraphWindow),
                          Expanded(
                            child: Slider(
                              value: _smoothingWindow.toDouble(),
                              min: 3,
                              max: 21,
                              divisions: 9,
                              label: '$_smoothingWindow',
                              onChanged: (value) {
                                setState(() {
                                  _smoothingWindow = value.round();
                                });
                              },
                            ),
                          ),
                          Text('$_smoothingWindow'),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Switch(
                          value: _showFit,
                          onChanged: (value) {
                            setState(() {
                              _showFit = value;
                            });
                          },
                        ),
                        Text(l10n.advGraphFitLine),
                        if (_showFit) ...[
                          const SizedBox(width: 12),
                          Text(l10n.advGraphType),
                          const SizedBox(width: 8),
                          DropdownButton<RegressionType>(
                            value: _fitType,
                            items: RegressionType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(_fitTypeLabel(l10n, type)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _fitType = value;
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Switch(
                          value: _showPeaks,
                          onChanged: (value) {
                            setState(() {
                              _showPeaks = value;
                            });
                          },
                        ),
                        Text(l10n.advGraphPeakValley),
                        if (_showPeaks) ...[
                          const SizedBox(width: 12),
                          Text(l10n.advGraphProminence),
                          Expanded(
                            child: Slider(
                              value: _peakProminenceRatio,
                              min: 0,
                              max: 0.4,
                              divisions: 20,
                              label: _peakProminenceRatio.toStringAsFixed(2),
                              onChanged: (value) {
                                setState(() {
                                  _peakProminenceRatio = value;
                                });
                              },
                            ),
                          ),
                          Text(_peakProminenceRatio.toStringAsFixed(2)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (supportsFit && _showFit)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: regression == null
                    ? _buildFitUnavailable(l10n, _fitType)
                    : _buildFitSummary(l10n, regression),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildChart(
                  l10n,
                  series,
                  regression,
                  smoothedValues: smoothedValues,
                  peakResult: peakResult,
                  extremaSourceValues: valuesForExtrema,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart(
    AppLocalizations l10n,
    ChartSeries series,
    RegressionResult? regression, {
    List<double>? smoothedValues,
    PeakDetectionResult? peakResult,
    List<double>? extremaSourceValues,
  }) {
    switch (_mode) {
      case GraphMode.line:
        return _buildLineChart(
          l10n,
          series,
          regression,
          showArea: false,
          smoothedValues: smoothedValues,
          peakResult: peakResult,
          extremaSourceValues: extremaSourceValues,
        );
      case GraphMode.scatter:
        return _buildScatterChart(
          l10n,
          series,
          regression,
          smoothedValues: smoothedValues,
          peakResult: peakResult,
          extremaSourceValues: extremaSourceValues,
        );
      case GraphMode.bar:
        return _buildBarChart(l10n, series);
      case GraphMode.area:
        return _buildLineChart(
          l10n,
          series,
          regression,
          showArea: true,
          smoothedValues: smoothedValues,
          peakResult: peakResult,
          extremaSourceValues: extremaSourceValues,
        );
      case GraphMode.histogram:
        return _buildHistogram(l10n, series);
    }
  }

  Widget _buildLineChart(
    AppLocalizations l10n,
    ChartSeries series,
    RegressionResult? regression, {
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

    final spots = <FlSpot>[];
    for (var i = 0; i < series.dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), series.dataPoints[i].value));
    }

    final regressionSpots = <FlSpot>[];
    if (regression != null) {
      for (var i = 0; i < regression.predicted.length; i++) {
        regressionSpots.add(FlSpot(i.toDouble(), regression.predicted[i]));
      }
    }

    final smoothedSpots = <FlSpot>[];
    if (includeSmoothing && smoothedValues != null && smoothedValues.length == spots.length) {
      for (var i = 0; i < smoothedValues.length; i++) {
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
      yValues.addAll(spots.map((e) => e.y));
    }
    yValues.addAll(regressionSpots.map((e) => e.y));
    yValues.addAll(smoothedSpots.map((e) => e.y));
    yValues.addAll(peakSpots.map((e) => e.y));
    yValues.addAll(valleySpots.map((e) => e.y));

    if (yValues.isEmpty) {
      return Center(child: Text(l10n.advGraphNoPoints));
    }

    var minY = minYOverride ?? yValues.reduce(math.min);
    var maxY = maxYOverride ?? yValues.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(80),
      clipBehavior: Clip.none,
      child: LineChart(
        LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          if (includeRawSeries)
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 2.5,
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
        ],
        gridData: FlGridData(show: showGrid),
        titlesData: showTitles
            ? const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              )
            : const FlTitlesData(show: false),
        borderData: FlBorderData(show: showBorders),
        ),
      ),
    );
  }

  Widget _buildScatterChart(
    AppLocalizations l10n,
    ChartSeries series,
    RegressionResult? regression, {
    List<double>? smoothedValues,
    PeakDetectionResult? peakResult,
    List<double>? extremaSourceValues,
  }) {
    final values = (smoothedValues != null && smoothedValues.length == series.dataPoints.length)
        ? smoothedValues
        : series.dataPoints.map((e) => e.value).toList(growable: false);

    final peakSet = peakResult == null ? <int>{} : peakResult.peaks.toSet();
    final valleySet = peakResult == null ? <int>{} : peakResult.valleys.toSet();

    final spots = <ScatterSpot>[];
    for (var i = 0; i < values.length; i++) {
      final color = peakSet.contains(i)
          ? Colors.red
          : valleySet.contains(i)
              ? Colors.cyan
              : Colors.blue;

      spots.add(
        ScatterSpot(
          i.toDouble(),
          values[i],
          dotPainter: FlDotCirclePainter(
            radius: peakSet.contains(i) || valleySet.contains(i) ? 5 : 3,
            color: color,
            strokeWidth: 0,
          ),
        ),
      );
    }

    if (values.isEmpty) {
      return Center(child: Text(l10n.advGraphNoPoints));
    }

    final regressionSpots = <FlSpot>[];
    if (regression != null) {
      for (var i = 0; i < regression.predicted.length; i++) {
        regressionSpots.add(FlSpot(i.toDouble(), regression.predicted[i]));
      }
    }

    final yValues = values.toList(growable: true)..addAll(regressionSpots.map((e) => e.y));
    var minY = yValues.reduce(math.min);
    var maxY = yValues.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(80),
      clipBehavior: Clip.none,
      child: Stack(
        children: [
          ScatterChart(
            ScatterChartData(
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              scatterSpots: spots,
              gridData: FlGridData(show: true),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
          if (regression != null)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _buildLineChart(
                  l10n,
                  series,
                  regression,
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
      ),
    );
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

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(80),
      clipBehavior: Clip.none,
      child: BarChart(
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
      ),
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

    return InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 1.0,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(80),
      clipBehavior: Clip.none,
      child: BarChart(
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
      ),
    );
  }

  Widget _statCard(
    String label,
    String value, {
    double valueFontSize = 15,
    int valueMaxLines = 2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFitSummary(AppLocalizations l10n, RegressionResult regression) {
    final cards = <Widget>[
      SizedBox(
        width: 140,
        child: _statCard(l10n.advGraphFit, _fitTypeLabel(l10n, regression.type)),
      ),
      SizedBox(
        width: 260,
        child: _statCard(
          l10n.advGraphEquation,
          regression.equationText,
          valueFontSize: 13,
          valueMaxLines: 3,
        ),
      ),
      SizedBox(
        width: 120,
        child: _statCard(l10n.advGraphRSquared, regression.rSquared.toStringAsFixed(4)),
      ),
      SizedBox(
        width: 120,
        child: _statCard(l10n.advGraphCount, '${regression.count}'),
      ),
      ...regression.coefficients.map(
        (coefficient) => SizedBox(
          width: 140,
          child: _statCard(
            coefficient.label,
            _formatMetric(coefficient.value),
            valueFontSize: 13,
          ),
        ),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards,
    );
  }

  Widget _buildFitUnavailable(AppLocalizations l10n, RegressionType type) {
    String message;
    switch (type) {
      case RegressionType.linear:
        message = l10n.advGraphFitUnavailable;
      case RegressionType.quadratic:
        message = l10n.advGraphFitQuadraticNeedPoints;
      case RegressionType.exponential:
        message = l10n.advGraphFitExponentialNeedPoints;
      case RegressionType.power:
        message = l10n.advGraphFitPowerNeedPoints;
      case RegressionType.logarithmic:
        message = l10n.advGraphFitLogarithmicNeedPoints;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.orange.shade900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatMetric(double value) {
    final absolute = value.abs();
    if (absolute >= 1000 || (absolute > 0 && absolute < 0.001)) {
      return value.toStringAsExponential(3);
    }
    return value.toStringAsFixed(4);
  }

  String _modeLabel(AppLocalizations l10n, GraphMode mode) {
    switch (mode) {
      case GraphMode.line:
        return l10n.advGraphModeLine;
      case GraphMode.scatter:
        return l10n.advGraphModeScatter;
      case GraphMode.bar:
        return l10n.advGraphModeBar;
      case GraphMode.area:
        return l10n.advGraphModeArea;
      case GraphMode.histogram:
        return l10n.advGraphModeHistogram;
    }
  }

  String _fitTypeLabel(AppLocalizations l10n, RegressionType type) {
    switch (type) {
      case RegressionType.linear:
        return l10n.advGraphRegressionLinear;
      case RegressionType.quadratic:
        return l10n.advGraphRegressionQuadratic;
      case RegressionType.exponential:
        return l10n.advGraphRegressionExponential;
      case RegressionType.power:
        return l10n.advGraphRegressionPower;
      case RegressionType.logarithmic:
        return l10n.advGraphRegressionLogarithmic;
    }
  }

  ChartSeries _seriesWithReplacementValues(ChartSeries source, List<double> values) {
    final points = <ChartDataPoint>[];
    final length = values.length < source.dataPoints.length ? values.length : source.dataPoints.length;
    for (var i = 0; i < length; i++) {
      points.add(
        ChartDataPoint(
          time: source.dataPoints[i].time,
          value: values[i],
          label: source.dataPoints[i].label,
        ),
      );
    }

    return ChartSeries(
      name: source.name,
      dataPoints: points,
    );
  }
}
