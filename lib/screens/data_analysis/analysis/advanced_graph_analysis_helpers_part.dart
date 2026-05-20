part of 'advanced_graph_analysis_screen.dart';



extension _AdvancedGraphAnalysisHelpersPart on _AdvancedGraphAnalysisScreenState {
  Widget _buildMeasurementSummary(AppLocalizations l10n, ChartSeries series) {
    final pointA = _measurementPoint(series, _cursorAIndex);
    final pointB = _measurementPoint(series, _cursorBIndex);

    final cards = <Widget>[
      SizedBox(
        width: 140,
        child: _statCard(l10n.advGraphCursorA, _measurementPointLabel(pointA)),
      ),
      SizedBox(
        width: 140,
        child: _statCard(l10n.advGraphCursorB, _measurementPointLabel(pointB)),
      ),
    ];

    if (pointA != null && pointB != null) {
      final deltaMs = pointB.time.millisecondsSinceEpoch - pointA.time.millisecondsSinceEpoch;
      final deltaSeconds = deltaMs / 1000;
      final deltaY = pointB.value - pointA.value;
      final slope = deltaSeconds == 0 ? null : deltaY / deltaSeconds;

      cards.addAll([
        SizedBox(
          width: 140,
          child: _statCard(l10n.advGraphDeltaX, _formatDurationSeconds(deltaSeconds)),
        ),
        SizedBox(
          width: 140,
          child: _statCard(l10n.advGraphDeltaY, _formatMetric(deltaY)),
        ),
        SizedBox(
          width: 140,
          child: _statCard(
            l10n.advGraphSlope,
            slope == null ? '-' : _formatMetric(slope),
          ),
        ),
      ]);
    } else {
      cards.add(
        SizedBox(
          width: 280,
          child: _statCard(l10n.advGraphMeasurementHintTitle, l10n.advGraphMeasurementHint),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards,
    );
  }

  ChartDataPoint? _measurementPoint(ChartSeries series, int? index) {
    if (index == null || index < 0 || index >= series.dataPoints.length) {
      return null;
    }
    return series.dataPoints[index];
  }

  String _measurementPointLabel(ChartDataPoint? point) {
    if (point == null) {
      return '-';
    }
    return _formatMetric(point.value);
  }

  String _formatDurationSeconds(double seconds) {
    final absolute = seconds.abs();
    if (absolute >= 1000 || (absolute > 0 && absolute < 0.001)) {
      return '${seconds.toStringAsExponential(3)} s';
    }
    return '${seconds.toStringAsFixed(3)} s';
  }

  String _errorValueLabel(AnalysisErrorBarConfig errorBarConfig) {
    return switch (errorBarConfig.yMode) {
      AnalysisErrorValueMode.none => '0',
      AnalysisErrorValueMode.fixedAbsolute => errorBarConfig.yValue.toStringAsFixed(2),
      AnalysisErrorValueMode.percentage => '${errorBarConfig.yValue.toStringAsFixed(1)}%',
    };
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

  String _derivedSeriesModeLabel(AppLocalizations l10n, DerivedSeriesMode mode) {
    switch (mode) {
      case DerivedSeriesMode.raw:
        return l10n.advGraphDerivedRaw;
      case DerivedSeriesMode.derivative:
        return l10n.advGraphDerivedDerivative;
      case DerivedSeriesMode.integral:
        return l10n.advGraphDerivedIntegral;
    }
  }

  String _binaryOperationLabel(AppLocalizations l10n, BinarySeriesOperation mode) {
    switch (mode) {
      case BinarySeriesOperation.none:
        return l10n.advGraphSeriesOperationNone;
      case BinarySeriesOperation.add:
        return l10n.advGraphSeriesOperationAdd;
      case BinarySeriesOperation.subtract:
        return l10n.advGraphSeriesOperationSubtract;
      case BinarySeriesOperation.multiply:
        return l10n.advGraphSeriesOperationMultiply;
      case BinarySeriesOperation.divide:
        return l10n.advGraphSeriesOperationDivide;
    }
  }

  String _formulaAlignmentModeLabel(
    AppLocalizations l10n,
    FormulaSecondaryAlignmentMode mode,
  ) {
    switch (mode) {
      case FormulaSecondaryAlignmentMode.byIndex:
        return l10n.advGraphFormulaAlignIndex;
      case FormulaSecondaryAlignmentMode.timeNearest:
        return l10n.advGraphFormulaAlignNearestTime;
    }
  }

  String _formulaOutOfRangeLabel(
    AppLocalizations l10n,
    FormulaOutOfRangePolicy policy,
  ) {
    switch (policy) {
      case FormulaOutOfRangePolicy.zero:
        return l10n.advGraphFormulaOutOfRangeZero;
      case FormulaOutOfRangePolicy.holdLast:
        return l10n.advGraphFormulaOutOfRangeHoldLast;
      case FormulaOutOfRangePolicy.interpolate:
        return l10n.advGraphFormulaOutOfRangeInterpolate;
    }
  }

  String _formulaInterpolationModeLabel(
    AppLocalizations l10n,
    FormulaInterpolationMode mode,
  ) {
    switch (mode) {
      case FormulaInterpolationMode.linear:
        return l10n.advGraphFormulaInterpolationLinear;
      case FormulaInterpolationMode.step:
        return l10n.advGraphFormulaInterpolationStep;
    }
  }

  String _errorModeLabel(AppLocalizations l10n, AnalysisErrorValueMode mode) {
    switch (mode) {
      case AnalysisErrorValueMode.none:
        return l10n.advGraphErrorModeNone;
      case AnalysisErrorValueMode.fixedAbsolute:
        return l10n.advGraphErrorModeAbsolute;
      case AnalysisErrorValueMode.percentage:
        return l10n.advGraphErrorModePercentage;
    }
  }

}