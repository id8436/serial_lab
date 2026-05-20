import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/analysis_metadata.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/services/analysis/derived_series_service.dart';
import 'package:serial_lab/services/analysis/formula_series_service.dart';
import 'package:serial_lab/services/analysis/peak_detection_service.dart';
import 'package:serial_lab/services/analysis/regression_service.dart';
import 'package:serial_lab/services/analysis/smoothing_service.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

part 'advanced_graph_analysis_chart_part.dart';
part 'advanced_graph_analysis_panel_part.dart';
part 'advanced_graph_analysis_controls_part.dart';
part 'advanced_graph_analysis_formula_controls_part.dart';
part 'advanced_graph_analysis_tool_controls_part.dart';
part 'advanced_graph_analysis_helpers_part.dart';
part 'advanced_graph_analysis_computation_part.dart';
part 'advanced_graph_analysis_line_chart_part.dart';
part 'advanced_graph_analysis_scatter_chart_part.dart';

enum GraphMode {
  line,
  scatter,
  bar,
  area,
  histogram,
}

enum MeasurementCursorSlot {
  a,
  b,
}

class AdvancedGraphAnalysisScreen extends StatefulWidget {
  const AdvancedGraphAnalysisScreen({super.key});

  @override
  State<AdvancedGraphAnalysisScreen> createState() => _AdvancedGraphAnalysisScreenState();
}

class _AdvancedGraphAnalysisScreenState extends State<AdvancedGraphAnalysisScreen> {
  static const double _kDefaultSettingsPanelMaxHeight = 300;
  static const double _kMinSettingsPanelMaxHeight = 132;
  static const double _kChartMinHeight = 220;
  static const double _kSettingsResizeHandleHeight = 20;

  String? _selectedSeries;
  GraphMode _mode = GraphMode.line;
  FlScaleAxis _zoomScaleAxis = FlScaleAxis.free;
  int _histogramBins = 12;
  bool _showFit = true;
  RegressionType _fitType = RegressionType.linear;
  bool _showSmoothing = false;
  int _smoothingWindow = 5;
  bool _showPeaks = false;
  double _peakProminenceRatio = 0.08;
  bool _showMeasurementTools = false;
  MeasurementCursorSlot _activeCursorSlot = MeasurementCursorSlot.a;
  int? _cursorAIndex;
  int? _cursorBIndex;
  DerivedSeriesMode _derivedSeriesMode = DerivedSeriesMode.raw;
  BinarySeriesOperation _binaryOperation = BinarySeriesOperation.none;
  String? _secondarySeriesName;
  bool _enableFormula = false;
  String _appliedFormula = 'x';
  String? _formulaDraftError;
  FormulaSecondaryAlignmentMode _formulaSecondaryAlignment =
      FormulaSecondaryAlignmentMode.byIndex;
  double _formulaNearestMaxDeltaMs = 250;
  FormulaOutOfRangePolicy _formulaOutOfRangePolicy = FormulaOutOfRangePolicy.zero;
  FormulaInterpolationMode _formulaInterpolationMode = FormulaInterpolationMode.linear;
  bool _showFormulaOverlayCompare = false;
  final TextEditingController _formulaController = TextEditingController(text: 'x');
  final TransformationController _chartTransformController =
      TransformationController();
  Object? _analysisComputationCacheKey;
  _AnalysisComputation? _analysisComputationCache;
  _AnalysisComputation? _displayedAnalysisComputation;
  Object? _displayedAnalysisComputationKey;
  Object? _pendingAnalysisComputationKey;
  Object? _queuedAnalysisComputationKey;
  int _analysisComputationRequestId = 0;
  double _settingsPanelMaxHeight = _kDefaultSettingsPanelMaxHeight;
  static const List<String> _formulaPresets = [
    'x',
    'x*2',
    'x+y',
    'x-y',
    'sin(x)',
    'sqrt(abs(x))',
  ];

  @override
  void dispose() {
    _formulaController.dispose();
    _chartTransformController.dispose();
    super.dispose();
  }

  void _resetChartZoom() {
    _chartTransformController.value = vm.Matrix4.identity();
  }

  void _updateState(VoidCallback updater) {
    setState(updater);
  }

  double _clampSettingsPanelMaxHeight(
    double viewportHeight, {
    double reservedHeight = 0,
  }) {
    final maxHeight = _maxSettingsPanelMaxHeight(
      viewportHeight,
      reservedHeight: reservedHeight,
    );
    return _settingsPanelMaxHeight.clamp(_kMinSettingsPanelMaxHeight, maxHeight).toDouble();
  }

  double _maxSettingsPanelMaxHeight(
    double viewportHeight, {
    double reservedHeight = 0,
  }) {
    if (!viewportHeight.isFinite || viewportHeight <= 0) {
      return _settingsPanelMaxHeight;
    }

    return math.max(
      _kMinSettingsPanelMaxHeight,
      viewportHeight - _kChartMinHeight - _kSettingsResizeHandleHeight - reservedHeight,
    );
  }

  void _handleSettingsPanelDrag(
    double deltaDy,
    double viewportHeight, {
    double reservedHeight = 0,
  }) {
    final maxHeight = _maxSettingsPanelMaxHeight(
      viewportHeight,
      reservedHeight: reservedHeight,
    );
    final current = _settingsPanelMaxHeight.clamp(
      _kMinSettingsPanelMaxHeight,
      maxHeight,
    );
    final next = (current + deltaDy).clamp(_kMinSettingsPanelMaxHeight, maxHeight);
    final nextHeight = (next as num).toDouble();
    if ((nextHeight - _settingsPanelMaxHeight).abs() < 0.5) {
      return;
    }
    _updateState(() {
      _settingsPanelMaxHeight = nextHeight;
    });
  }

  void _handleZoomScaleAxisChanged(Set<FlScaleAxis> selection) {
    if (selection.isEmpty) {
      return;
    }

    final next = selection.first;
    if (next == _zoomScaleAxis) {
      return;
    }

    setState(() {
      _zoomScaleAxis = next;
      _resetChartZoom();
    });
  }

  void _handleSeriesChanged(String? value) {
    if (value == null || value == _selectedSeries) {
      return;
    }
    setState(() {
      _selectedSeries = value;
      _resetChartZoom();
      _resetMeasurementSelection();
    });
  }

  void _handleModeChanged(GraphMode? value) {
    if (value == null || value == _mode) {
      return;
    }
    setState(() {
      _mode = value;
      _resetChartZoom();
      _resetMeasurementSelection();
    });
  }

  void _handleDerivedSeriesModeChanged(DerivedSeriesMode? value) {
    if (value == null || value == _derivedSeriesMode) {
      return;
    }
    setState(() {
      _derivedSeriesMode = value;
      _resetMeasurementSelection();
    });
  }

  void _handleBinaryOperationChanged(BinarySeriesOperation? value) {
    if (value == null || value == _binaryOperation) {
      return;
    }
    setState(() {
      _binaryOperation = value;
      _resetMeasurementSelection();
    });
  }

  void _handleSecondarySeriesChanged(String? value) {
    if (value == null || value == _secondarySeriesName) {
      return;
    }
    setState(() {
      _secondarySeriesName = value;
      _resetMeasurementSelection();
    });
  }

  void _applyFormula() {
    final formula = _formulaController.text.trim();
    final validationError = FormulaSeriesService.validateFormula(formula);
    setState(() {
      _formulaDraftError = validationError;
      if (validationError == null) {
        _appliedFormula = formula;
        _resetMeasurementSelection();
      }
    });
  }

  void _handleFormulaChanged(String text) {
    if (!_enableFormula) {
      if (_formulaDraftError != null) {
        _updateState(() {
          _formulaDraftError = null;
        });
      }
      return;
    }
    _validateFormulaDraftAsync(text);
  }

  void _validateFormulaDraftAsync(String text) {
    Future<void>(() {
      final validationError = FormulaSeriesService.validateFormula(text.trim());
      if (!mounted || !_enableFormula) {
        return;
      }
      if (_formulaController.text != text) {
        return;
      }
      if (_formulaDraftError == validationError) {
        return;
      }
      _updateState(() {
        _formulaDraftError = validationError;
      });
    });
  }

  void _applyFormulaPreset(String formula) {
    _formulaController.text = formula;
    _applyFormula();
  }

  void _clearMeasurementSelection() {
    setState(_resetMeasurementSelection);
  }

  void _resetMeasurementSelection() {
    _cursorAIndex = null;
    _cursorBIndex = null;
    _activeCursorSlot = MeasurementCursorSlot.a;
  }

  void _handleMeasurementSpotSelected(int spotIndex) {
    if (!_showMeasurementTools) {
      return;
    }

    setState(() {
      if (_activeCursorSlot == MeasurementCursorSlot.a) {
        _cursorAIndex = spotIndex;
        if (_cursorBIndex == null && _cursorAIndex != null) {
          _activeCursorSlot = MeasurementCursorSlot.b;
        }
      } else {
        _cursorBIndex = spotIndex;
      }
    });
  }

  FlTransformationConfig _chartTransformationConfig({
    bool enableGestures = true,
  }) {
    return FlTransformationConfig(
      scaleAxis: enableGestures ? _zoomScaleAxis : FlScaleAxis.none,
      minScale: 1,
      maxScale: 10000,
      panEnabled: enableGestures,
      scaleEnabled: enableGestures,
      trackpadScrollCausesScale: true,
      transformationController: _chartTransformController,
    );
  }

  Widget _wrapZoomableChart(Widget chart) {
    final scheme = Theme.of(context).colorScheme;
    final toggleTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        );

    return Stack(
      children: [
        Positioned.fill(child: chart),
        Positioned(
          top: 8,
          right: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SegmentedButton<FlScaleAxis>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(28, 24),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                textStyle: toggleTextStyle,
                side: BorderSide(color: scheme.outlineVariant, width: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              segments: const [
                ButtonSegment<FlScaleAxis>(
                  value: FlScaleAxis.horizontal,
                  label: Text('X'),
                ),
                ButtonSegment<FlScaleAxis>(
                  value: FlScaleAxis.vertical,
                  label: Text('Y'),
                ),
                ButtonSegment<FlScaleAxis>(
                  value: FlScaleAxis.free,
                  label: Text('XY'),
                ),
              ],
              selected: {_zoomScaleAxis},
              onSelectionChanged: _handleZoomScaleAxisChanged,
            ),
          ),
        ),
      ],
    );
  }

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
          _resetChartZoom();
        }

        final secondarySeriesCandidates = chartData.keys
            .where((seriesName) => seriesName != _selectedSeries)
            .toList(growable: false);
        if (_secondarySeriesName == null ||
            !secondarySeriesCandidates.contains(_secondarySeriesName)) {
          _secondarySeriesName =
              secondarySeriesCandidates.isEmpty ? null : secondarySeriesCandidates.first;
        }
        final effectiveOperation = secondarySeriesCandidates.isEmpty
            ? BinarySeriesOperation.none
            : _binaryOperation;

        final sourceSeries = chartData[_selectedSeries]!;
        final secondarySeries = _secondarySeriesName == null
            ? null
            : chartData[_secondarySeriesName!];
        final computed = _resolveAnalysisComputationForBuild(
          sourceSeries,
          secondarySeries: secondarySeries,
          effectiveOperation: effectiveOperation,
        );
        final formulaSeries = computed.formulaSeries;
        final useFormulaOverlay = computed.useFormulaOverlay;
        final analysisSeries = computed.analysisSeries;
        final formulaError = computed.formulaError;
        final supportsFit = computed.supportsFit;
        final supportsErrorBars = computed.supportsErrorBars;
        final supportsMeasurement = computed.supportsMeasurement;
        final errorBarConfig = analysisData.metadataFor(_selectedSeries!).errorBars;
        final rawValues = computed.rawValues;
        final smoothedValues = computed.smoothedValues;
        final peakResult = computed.peakResult;
        final regression = computed.regression;

        return LayoutBuilder(
          builder: (context, constraints) {
            final reservedHeight =
                (supportsFit && _showFit ? 92.0 : 0.0) + (_showMeasurementTools ? 92.0 : 0.0);
            final settingsPanelMaxHeight = _clampSettingsPanelMaxHeight(
              constraints.maxHeight,
              reservedHeight: reservedHeight,
            );

            return Column(
              children: [
                _buildControlsPanel(
                  context,
                  l10n,
                  analysisData,
                  chartData: chartData,
                  secondarySeriesCandidates: secondarySeriesCandidates,
                  effectiveOperation: effectiveOperation,
                  supportsFit: supportsFit,
                  supportsErrorBars: supportsErrorBars,
                  supportsMeasurement: supportsMeasurement,
                  errorBarConfig: errorBarConfig,
                  rawValues: rawValues,
                  formulaError: formulaError,
                  settingsPanelMaxHeight: settingsPanelMaxHeight,
                ),
                if (supportsFit && _showFit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: regression == null
                        ? _buildFitUnavailable(l10n, _fitType)
                        : _buildFitSummary(l10n, regression),
                  ),
                if (_showMeasurementTools)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildMeasurementSummary(l10n, analysisSeries),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        _handleSettingsPanelDrag(
                          details.delta.dy,
                          constraints.maxHeight,
                          reservedHeight: reservedHeight,
                        );
                      },
                      child: SizedBox(
                        height: _kSettingsResizeHandleHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildChart(
                      l10n,
                      analysisSeries,
                      regression,
                      formulaOverlaySeries: useFormulaOverlay ? formulaSeries : null,
                      errorBarConfig: errorBarConfig,
                      measurementEnabled: _showMeasurementTools && supportsMeasurement,
                      smoothedValues: smoothedValues,
                      peakResult: peakResult,
                      extremaSourceValues: smoothedValues ?? rawValues,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChart(
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
    final chart = switch (_mode) {
      GraphMode.line => _buildLineChart(
          l10n,
          series,
          regression,
          formulaOverlaySeries: formulaOverlaySeries,
          errorBarConfig: errorBarConfig,
          measurementEnabled: measurementEnabled,
          showArea: false,
          smoothedValues: smoothedValues,
          peakResult: peakResult,
          extremaSourceValues: extremaSourceValues,
        ),
      GraphMode.scatter => _buildScatterChart(
          l10n,
          series,
          regression,
          formulaOverlaySeries: formulaOverlaySeries,
          errorBarConfig: errorBarConfig,
          measurementEnabled: measurementEnabled,
          smoothedValues: smoothedValues,
          peakResult: peakResult,
          extremaSourceValues: extremaSourceValues,
        ),
      GraphMode.bar => _buildBarChart(l10n, series),
      GraphMode.area => _buildLineChart(
          l10n,
          series,
          regression,
          formulaOverlaySeries: formulaOverlaySeries,
          errorBarConfig: errorBarConfig,
          measurementEnabled: measurementEnabled,
          showArea: true,
          smoothedValues: smoothedValues,
          peakResult: peakResult,
          extremaSourceValues: extremaSourceValues,
        ),
      GraphMode.histogram => _buildHistogram(l10n, series),
    };

    return _wrapZoomableChart(chart);
  }
}
