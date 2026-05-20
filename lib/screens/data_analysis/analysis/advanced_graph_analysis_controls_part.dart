part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisControlsPart on _AdvancedGraphAnalysisScreenState {
  Widget _buildControlsPanel(
    BuildContext context,
    AppLocalizations l10n,
    AnalysisDataProvider analysisData, {
    required Map<String, ChartSeries> chartData,
    required List<String> secondarySeriesCandidates,
    required BinarySeriesOperation effectiveOperation,
    required bool supportsFit,
    required bool supportsErrorBars,
    required bool supportsMeasurement,
    required AnalysisErrorBarConfig errorBarConfig,
    required List<double> rawValues,
    required String? formulaError,
    required double settingsPanelMaxHeight,
  }) {
    return _buildCollapsibleControlsShell(
      context,
      l10n,
      expandedContentMaxHeight: settingsPanelMaxHeight,
      primaryControlsBuilder: () => [
        _buildSeriesAndModeRow(l10n, chartData),
        _buildDerivedSeriesRow(l10n),
        _buildSeriesOperationRow(
          l10n,
          effectiveOperation,
          secondarySeriesCandidates,
        ),
      ],
      formulaControlsBuilder: () => _buildFormulaControls(
        context,
        l10n,
        formulaError: formulaError,
      ),
      analysisControlsBuilder: () => _buildAnalysisControls(
        l10n,
        analysisData,
        supportsFit: supportsFit,
        supportsErrorBars: supportsErrorBars,
        supportsMeasurement: supportsMeasurement,
        errorBarConfig: errorBarConfig,
        rawValues: rawValues,
      ),
    );
  }

  Widget _buildSeriesAndModeRow(
    AppLocalizations l10n,
    Map<String, ChartSeries> chartData,
  ) {
    return Row(
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
            onChanged: _handleSeriesChanged,
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
          onChanged: _handleModeChanged,
        ),
      ],
    );
  }

  Widget _buildDerivedSeriesRow(AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.advGraphDerivedSeries),
        const SizedBox(width: 8),
        DropdownButton<DerivedSeriesMode>(
          value: _derivedSeriesMode,
          items: DerivedSeriesMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(_derivedSeriesModeLabel(l10n, mode)),
                ),
              )
              .toList(),
          onChanged: _handleDerivedSeriesModeChanged,
        ),
      ],
    );
  }

  Widget _buildSeriesOperationRow(
    AppLocalizations l10n,
    BinarySeriesOperation effectiveOperation,
    List<String> secondarySeriesCandidates,
  ) {
    return Row(
      children: [
        Text(l10n.advGraphSeriesOperation),
        const SizedBox(width: 8),
        DropdownButton<BinarySeriesOperation>(
          value: effectiveOperation,
          items: BinarySeriesOperation.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(_binaryOperationLabel(l10n, mode)),
                ),
              )
              .toList(),
          onChanged: secondarySeriesCandidates.isEmpty
              ? null
              : _handleBinaryOperationChanged,
        ),
        if (effectiveOperation != BinarySeriesOperation.none) ...[
          const SizedBox(width: 12),
          Text(l10n.advGraphSecondarySeries),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _secondarySeriesName,
            items: secondarySeriesCandidates
                .map(
                  (seriesName) => DropdownMenuItem(
                    value: seriesName,
                    child: Text(seriesName),
                  ),
                )
                .toList(),
            onChanged: _handleSecondarySeriesChanged,
          ),
        ],
      ],
    );
  }
}