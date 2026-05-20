part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisToolControlsPart on _AdvancedGraphAnalysisScreenState {
  List<Widget> _buildAnalysisControls(
    AppLocalizations l10n,
    AnalysisDataProvider analysisData, {
    required bool supportsFit,
    required bool supportsErrorBars,
    required bool supportsMeasurement,
    required AnalysisErrorBarConfig errorBarConfig,
    required List<double> rawValues,
  }) {
    return [
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
                  _updateState(() {
                    _histogramBins = value.round();
                  });
                },
              ),
            ),
            Text('$_histogramBins'),
          ],
        ),
      if (supportsFit) ...[
        Row(
          children: [
            Switch(
              value: _showSmoothing,
              onChanged: (value) {
                _updateState(() {
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
                    _updateState(() {
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
                _updateState(() {
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
                    _updateState(() {
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
                _updateState(() {
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
                    _updateState(() {
                      _peakProminenceRatio = value;
                    });
                  },
                ),
              ),
              Text(_peakProminenceRatio.toStringAsFixed(2)),
            ],
          ],
        ),
        Row(
          children: [
            Switch(
              value: errorBarConfig.enabled,
              onChanged: supportsErrorBars
                  ? (value) {
                      analysisData.updateErrorBarConfig(
                        _selectedSeries!,
                        errorBarConfig.copyWith(enabled: value),
                      );
                    }
                  : null,
            ),
            Text(l10n.advGraphErrorBars),
            if (supportsErrorBars && errorBarConfig.enabled) ...[
              const SizedBox(width: 12),
              Text(l10n.advGraphErrorMode),
              const SizedBox(width: 8),
              DropdownButton<AnalysisErrorValueMode>(
                value: errorBarConfig.yMode,
                items: AnalysisErrorValueMode.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(_errorModeLabel(l10n, mode)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  analysisData.updateErrorBarConfig(
                    _selectedSeries!,
                    errorBarConfig.copyWith(yMode: value),
                  );
                },
              ),
              if (errorBarConfig.yMode != AnalysisErrorValueMode.none) ...[
                const SizedBox(width: 12),
                Text(
                  errorBarConfig.yMode == AnalysisErrorValueMode.percentage
                      ? l10n.advGraphErrorPercent
                      : l10n.advGraphErrorValue,
                ),
                Expanded(
                  child: Slider(
                    value: _errorSliderValue(errorBarConfig),
                    min: 0,
                    max: _errorSliderMax(errorBarConfig, rawValues),
                    divisions: 40,
                    label: _errorValueLabel(errorBarConfig),
                    onChanged: (value) {
                      analysisData.updateErrorBarConfig(
                        _selectedSeries!,
                        errorBarConfig.copyWith(yValue: value),
                      );
                    },
                  ),
                ),
                Text(_errorValueLabel(errorBarConfig)),
              ],
            ],
          ],
        ),
        Row(
          children: [
            Switch(
              value: _showMeasurementTools,
              onChanged: supportsMeasurement
                  ? (value) {
                      _updateState(() {
                        _showMeasurementTools = value;
                        if (!value) {
                          _resetMeasurementSelection();
                        }
                      });
                    }
                  : null,
            ),
            Text(l10n.advGraphMeasurementTools),
            if (_showMeasurementTools && supportsMeasurement) ...[
              const SizedBox(width: 12),
              SegmentedButton<MeasurementCursorSlot>(
                segments: [
                  ButtonSegment<MeasurementCursorSlot>(
                    value: MeasurementCursorSlot.a,
                    label: Text(l10n.advGraphCursorA),
                  ),
                  ButtonSegment<MeasurementCursorSlot>(
                    value: MeasurementCursorSlot.b,
                    label: Text(l10n.advGraphCursorB),
                  ),
                ],
                selected: {_activeCursorSlot},
                onSelectionChanged: (selection) {
                  final next = selection.firstOrNull;
                  if (next == null) {
                    return;
                  }
                  _updateState(() {
                    _activeCursorSlot = next;
                  });
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _clearMeasurementSelection,
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.advGraphClearCursors),
              ),
            ],
          ],
        ),
      ],
    ];
  }
}