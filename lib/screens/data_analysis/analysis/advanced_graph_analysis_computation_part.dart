part of 'advanced_graph_analysis_screen.dart';

// ---------------------------------------------------------------------------
// Isolate-safe parameter bundle for compute()
// ---------------------------------------------------------------------------
class _AnalysisComputationParams {
  const _AnalysisComputationParams({
    required this.sourceSeries,
    this.secondarySeries,
    required this.effectiveOperation,
    required this.derivedSeriesMode,
    required this.formulaAffectsComputation,
    required this.enableFormula,
    required this.appliedFormula,
    required this.formulaSecondaryAlignment,
    required this.formulaNearestMaxDeltaMs,
    required this.formulaOutOfRangePolicy,
    required this.formulaInterpolationMode,
    required this.showFormulaOverlayCompare,
    required this.mode,
    required this.showSmoothing,
    required this.smoothingWindow,
    required this.showPeaks,
    required this.peakProminenceRatio,
    required this.showFit,
    required this.fitType,
  });

  final ChartSeries sourceSeries;
  final ChartSeries? secondarySeries;
  final BinarySeriesOperation effectiveOperation;
  final DerivedSeriesMode derivedSeriesMode;
  final bool formulaAffectsComputation;
  final bool enableFormula;
  final String appliedFormula;
  final FormulaSecondaryAlignmentMode formulaSecondaryAlignment;
  final int formulaNearestMaxDeltaMs;
  final FormulaOutOfRangePolicy formulaOutOfRangePolicy;
  final FormulaInterpolationMode formulaInterpolationMode;
  final bool showFormulaOverlayCompare;
  final GraphMode mode;
  final bool showSmoothing;
  final int smoothingWindow;
  final bool showPeaks;
  final double peakProminenceRatio;
  final bool showFit;
  final RegressionType fitType;
}

// ---------------------------------------------------------------------------
// Top-level entry point for compute() — runs in a separate isolate
// ---------------------------------------------------------------------------
_AnalysisComputation _computeAnalysisSync(_AnalysisComputationParams p) {
  // 1. Build primary (derived) series
  final primary = p.derivedSeriesMode == DerivedSeriesMode.raw
      ? p.sourceSeries
      : DerivedSeriesService.buildSeries(p.sourceSeries, p.derivedSeriesMode);

  // 2. Apply binary operation with secondary
  final ChartSeries series;
  if (p.effectiveOperation == BinarySeriesOperation.none || p.secondarySeries == null) {
    series = primary;
  } else {
    final secondary = p.derivedSeriesMode == DerivedSeriesMode.raw
        ? p.secondarySeries!
        : DerivedSeriesService.buildSeries(p.secondarySeries!, p.derivedSeriesMode);
    series = DerivedSeriesService.applyBinaryOperation(primary, secondary, p.effectiveOperation);
  }

  // 3. Build formula secondary (derived)
  ChartSeries? derivedSecondaryForFormula;
  if (p.formulaAffectsComputation && p.secondarySeries != null) {
    final sec = p.secondarySeries!;
    derivedSecondaryForFormula = p.derivedSeriesMode == DerivedSeriesMode.raw
        ? sec
        : DerivedSeriesService.buildSeries(sec, p.derivedSeriesMode);
  }

  // 4. Apply formula
  final FormulaSeriesResult formulaResult;
  if (!p.formulaAffectsComputation) {
    formulaResult = FormulaSeriesResult(series: series);
  } else {
    final normalized = p.appliedFormula.replaceAll(' ', '').toLowerCase();
    if (normalized == 'x') {
      formulaResult = FormulaSeriesResult(series: series);
    } else {
      formulaResult = FormulaSeriesService.applyFormula(
        series,
        p.appliedFormula,
        derivedSecondaryForFormula,
        p.formulaSecondaryAlignment,
        p.formulaNearestMaxDeltaMs,
        p.formulaOutOfRangePolicy,
        p.formulaInterpolationMode,
      );
    }
  }

  final formulaSeries = formulaResult.error == null ? formulaResult.series : null;
  final useFormulaOverlay =
      p.enableFormula && p.showFormulaOverlayCompare && formulaSeries != null;
  final analysisSeries = useFormulaOverlay ? series : (formulaSeries ?? series);

  // 5. Stats & smoothing
  final supportsFit =
      p.mode == GraphMode.line || p.mode == GraphMode.scatter || p.mode == GraphMode.area;
  final rawValues =
      analysisSeries.dataPoints.map((pt) => pt.value).toList(growable: false);
  final smoothedValues = p.showSmoothing
      ? SmoothingService.movingAverage(rawValues, window: p.smoothingWindow)
      : null;
  final valuesForExtrema = smoothedValues ?? rawValues;
  final minValue = valuesForExtrema.isEmpty ? 0.0 : valuesForExtrema.reduce(math.min);
  final maxValue = valuesForExtrema.isEmpty ? 0.0 : valuesForExtrema.reduce(math.max);
  final minProminence = (maxValue - minValue).abs() * p.peakProminenceRatio;

  // 6. Peak detection
  final peakResult = p.showPeaks
      ? PeakDetectionService.detect(
          valuesForExtrema,
          minDistance: 3,
          minProminence: minProminence,
        )
      : null;

  // 7. Regression
  final ChartSeries regressionInput;
  if (smoothedValues == null) {
    regressionInput = analysisSeries;
  } else {
    final len = smoothedValues.length < analysisSeries.dataPoints.length
        ? smoothedValues.length
        : analysisSeries.dataPoints.length;
    regressionInput = ChartSeries(
      name: analysisSeries.name,
      dataPoints: List<ChartDataPoint>.generate(
        len,
        (i) => ChartDataPoint(
          time: analysisSeries.dataPoints[i].time,
          value: smoothedValues[i],
          label: analysisSeries.dataPoints[i].label,
        ),
      ),
    );
  }
  final regression =
      supportsFit && p.showFit ? RegressionService.fit(regressionInput, p.fitType) : null;

  return _AnalysisComputation(
    formulaSeries: formulaSeries,
    useFormulaOverlay: useFormulaOverlay,
    analysisSeries: analysisSeries,
    formulaError: formulaResult.error,
    supportsFit: supportsFit,
    supportsErrorBars: supportsFit,
    supportsMeasurement: supportsFit,
    rawValues: rawValues,
    smoothedValues: smoothedValues,
    peakResult: peakResult,
    regression: regression,
  );
}

// ---------------------------------------------------------------------------

class _AnalysisComputation {
  const _AnalysisComputation({
    required this.formulaSeries,
    required this.useFormulaOverlay,
    required this.analysisSeries,
    required this.formulaError,
    required this.supportsFit,
    required this.supportsErrorBars,
    required this.supportsMeasurement,
    required this.rawValues,
    required this.smoothedValues,
    required this.peakResult,
    required this.regression,
  });

  final ChartSeries? formulaSeries;
  final bool useFormulaOverlay;
  final ChartSeries analysisSeries;
  final String? formulaError;
  final bool supportsFit;
  final bool supportsErrorBars;
  final bool supportsMeasurement;
  final List<double> rawValues;
  final List<double>? smoothedValues;
  final PeakDetectionResult? peakResult;
  final RegressionResult? regression;
}

// ---------------------------------------------------------------------------
// Cache / scheduling / pending placeholder
// ---------------------------------------------------------------------------
extension _AdvancedGraphAnalysisComputationPart on _AdvancedGraphAnalysisScreenState {
  Object _analysisComputationKey(
    ChartSeries sourceSeries, {
    required ChartSeries? secondarySeries,
    required BinarySeriesOperation effectiveOperation,
  }) {
    final formulaAffectsComputation = _formulaAffectsComputation();

    return (
      _selectedSeries,
      _secondarySeriesName,
      identityHashCode(sourceSeries),
      identityHashCode(secondarySeries),
      _derivedSeriesMode,
      effectiveOperation,
      formulaAffectsComputation,
      formulaAffectsComputation ? _appliedFormula : 'x',
      formulaAffectsComputation
          ? _formulaSecondaryAlignment
          : FormulaSecondaryAlignmentMode.byIndex,
      formulaAffectsComputation ? _formulaNearestMaxDeltaMs.round() : 250,
      formulaAffectsComputation
          ? _formulaOutOfRangePolicy
          : FormulaOutOfRangePolicy.zero,
      formulaAffectsComputation
          ? _formulaInterpolationMode
          : FormulaInterpolationMode.linear,
      formulaAffectsComputation ? _showFormulaOverlayCompare : false,
      _mode,
      _showSmoothing,
      _smoothingWindow,
      _showPeaks,
      _peakProminenceRatio,
      _showFit,
      _fitType,
    );
  }

  _AnalysisComputation _resolveAnalysisComputationForBuild(
    ChartSeries sourceSeries, {
    required ChartSeries? secondarySeries,
    required BinarySeriesOperation effectiveOperation,
  }) {
    final key = _analysisComputationKey(
      sourceSeries,
      secondarySeries: secondarySeries,
      effectiveOperation: effectiveOperation,
    );

    final cached = _analysisComputationCache;
    if (cached != null && _analysisComputationCacheKey == key) {
      _displayedAnalysisComputation = cached;
      _displayedAnalysisComputationKey = key;
      _pendingAnalysisComputationKey = null;
      _queuedAnalysisComputationKey = null;
      return cached;
    }

    final displayed = _displayedAnalysisComputation;
    if (displayed != null) {
      if (_displayedAnalysisComputationKey != key) {
        _queueDeferredAnalysisComputation(
          sourceSeries,
          secondarySeries: secondarySeries,
          effectiveOperation: effectiveOperation,
          key: key,
        );
      }
      return displayed;
    }

    _queueDeferredAnalysisComputation(
      sourceSeries,
      secondarySeries: secondarySeries,
      effectiveOperation: effectiveOperation,
      key: key,
    );

    final computed = _buildPendingAnalysisComputation(
      sourceSeries,
      secondarySeries: secondarySeries,
      effectiveOperation: effectiveOperation,
    );
    _displayedAnalysisComputation = computed;
    _displayedAnalysisComputationKey = key;
    return computed;
  }

  _AnalysisComputation _buildPendingAnalysisComputation(
    ChartSeries sourceSeries, {
    required ChartSeries? secondarySeries,
    required BinarySeriesOperation effectiveOperation,
  }) {
    final analysisSeries = sourceSeries;
    final supportsFit =
        _mode == GraphMode.line || _mode == GraphMode.scatter || _mode == GraphMode.area;

    return _AnalysisComputation(
      formulaSeries: null,
      useFormulaOverlay: false,
      analysisSeries: analysisSeries,
      formulaError: null,
      supportsFit: supportsFit,
      supportsErrorBars: supportsFit,
      supportsMeasurement: supportsFit,
      rawValues: analysisSeries.dataPoints.map((p) => p.value).toList(growable: false),
      smoothedValues: null,
      peakResult: null,
      regression: null,
    );
  }

  void _queueDeferredAnalysisComputation(
    ChartSeries sourceSeries, {
    required ChartSeries? secondarySeries,
    required BinarySeriesOperation effectiveOperation,
    required Object key,
  }) {
    if (_pendingAnalysisComputationKey == key || _queuedAnalysisComputationKey == key) {
      return;
    }

    _queuedAnalysisComputationKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _queuedAnalysisComputationKey != key) {
        return;
      }
      _queuedAnalysisComputationKey = null;
      _scheduleDeferredAnalysisComputation(
        sourceSeries,
        secondarySeries: secondarySeries,
        effectiveOperation: effectiveOperation,
        key: key,
      );
    });
  }

  void _scheduleDeferredAnalysisComputation(
    ChartSeries sourceSeries, {
    required ChartSeries? secondarySeries,
    required BinarySeriesOperation effectiveOperation,
    required Object key,
  }) {
    if (_pendingAnalysisComputationKey == key) {
      return;
    }

    _pendingAnalysisComputationKey = key;
    if (_queuedAnalysisComputationKey == key) {
      _queuedAnalysisComputationKey = null;
    }
    final requestId = ++_analysisComputationRequestId;

    // Capture all state now so the isolate receives a consistent snapshot.
    final formulaAffectsComputation = _formulaAffectsComputation();
    final params = _AnalysisComputationParams(
      sourceSeries: sourceSeries,
      secondarySeries: secondarySeries,
      effectiveOperation: effectiveOperation,
      derivedSeriesMode: _derivedSeriesMode,
      formulaAffectsComputation: formulaAffectsComputation,
      enableFormula: _enableFormula,
      appliedFormula: formulaAffectsComputation ? _appliedFormula : 'x',
      formulaSecondaryAlignment: _formulaSecondaryAlignment,
      formulaNearestMaxDeltaMs: _formulaNearestMaxDeltaMs.round(),
      formulaOutOfRangePolicy: _formulaOutOfRangePolicy,
      formulaInterpolationMode: _formulaInterpolationMode,
      showFormulaOverlayCompare:
          formulaAffectsComputation ? _showFormulaOverlayCompare : false,
      mode: _mode,
      showSmoothing: _showSmoothing,
      smoothingWindow: _smoothingWindow,
      showPeaks: _showPeaks,
      peakProminenceRatio: _peakProminenceRatio,
      showFit: _showFit,
      fitType: _fitType,
    );

    // compute() runs _computeAnalysisSync in a separate isolate — completely
    // off the UI thread, so formula/regression/smoothing work cannot block rendering.
    Future<_AnalysisComputation> computationFuture;
    try {
      computationFuture = compute(_computeAnalysisSync, params);
    } catch (error, stackTrace) {
      debugPrint(
        '[_scheduleDeferredAnalysisComputation] compute dispatch failed, '
        'falling back to async local compute: $error\n$stackTrace',
      );
      computationFuture = Future<_AnalysisComputation>(() => _computeAnalysisSync(params));
    }

    computationFuture.then((computed) {
      if (!mounted || requestId != _analysisComputationRequestId) {
        return;
      }
      _updateState(() {
        _displayedAnalysisComputation = computed;
        _analysisComputationCache = computed;
        _analysisComputationCacheKey = key;
        _displayedAnalysisComputationKey = key;
        if (_pendingAnalysisComputationKey == key) {
          _pendingAnalysisComputationKey = null;
        }
      });
    }).catchError((Object error, StackTrace stackTrace) {
      if (!mounted || requestId != _analysisComputationRequestId) {
        return;
      }

      debugPrint(
        '[_scheduleDeferredAnalysisComputation] compute failed: $error\n$stackTrace',
      );

      final fallback = _analysisComputationWithFormulaError(
        _displayedAnalysisComputation ??
            _buildPendingAnalysisComputation(
              sourceSeries,
              secondarySeries: secondarySeries,
              effectiveOperation: effectiveOperation,
            ),
        error.toString(),
      );

      _updateState(() {
        _displayedAnalysisComputation = fallback;
        _displayedAnalysisComputationKey = key;
        if (_pendingAnalysisComputationKey == key) {
          _pendingAnalysisComputationKey = null;
        }
      });
    });
  }

  _AnalysisComputation _analysisComputationWithFormulaError(
    _AnalysisComputation base,
    String errorText,
  ) {
    return _AnalysisComputation(
      formulaSeries: base.formulaSeries,
      useFormulaOverlay: base.useFormulaOverlay,
      analysisSeries: base.analysisSeries,
      formulaError: errorText,
      supportsFit: base.supportsFit,
      supportsErrorBars: base.supportsErrorBars,
      supportsMeasurement: base.supportsMeasurement,
      rawValues: base.rawValues,
      smoothedValues: base.smoothedValues,
      peakResult: base.peakResult,
      regression: base.regression,
    );
  }

  // ---------------------------------------------------------------------------
  // Series helpers
  // ---------------------------------------------------------------------------

  bool _formulaAffectsComputation() {
    if (!_enableFormula) {
      return false;
    }
    final normalizedFormula = _appliedFormula.replaceAll(' ', '').toLowerCase();
    if (normalizedFormula == 'x' && !_showFormulaOverlayCompare) {
      return false;
    }
    return true;
  }

}
