part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisFormulaControlsPart on _AdvancedGraphAnalysisScreenState {
  List<Widget> _buildFormulaControls(
    BuildContext context,
    AppLocalizations l10n, {
    required String? formulaError,
  }) {
    return [
      Row(
        children: [
          Switch(
            value: _enableFormula,
            onChanged: (value) {
              FocusManager.instance.primaryFocus?.unfocus();
              _updateState(() {
                _enableFormula = value;
                _formulaDraftError = null;
                _resetMeasurementSelection();
              });
              if (value) {
                _validateFormulaDraftAsync(_formulaController.text);
              }
            },
          ),
          Text(l10n.advGraphFormula),
          if (_enableFormula) ...[
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _formulaController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.advGraphFormulaHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _handleFormulaChanged,
                onSubmitted: (_) => _applyFormula(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _applyFormula,
              child: Text(l10n.advGraphFormulaApply),
            ),
          ],
        ],
      ),
      if (_enableFormula)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.advGraphFormulaVariables,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ),
      if (_enableFormula)
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                l10n.advGraphFormulaPresets,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              ..._AdvancedGraphAnalysisScreenState._formulaPresets.map(
                (formula) => ActionChip(
                  label: Text(formula),
                  onPressed: () => _applyFormulaPreset(formula),
                ),
              ),
            ],
          ),
        ),
      if (_enableFormula)
        Row(
          children: [
            Text(l10n.advGraphFormulaSecondaryAlignment),
            const SizedBox(width: 8),
            DropdownButton<FormulaSecondaryAlignmentMode>(
              value: _formulaSecondaryAlignment,
              items: FormulaSecondaryAlignmentMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(_formulaAlignmentModeLabel(l10n, mode)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _updateState(() {
                  _formulaSecondaryAlignment = value;
                  _resetMeasurementSelection();
                });
              },
            ),
            const SizedBox(width: 12),
            Switch(
              value: _showFormulaOverlayCompare,
              onChanged: (value) {
                _updateState(() {
                  _showFormulaOverlayCompare = value;
                  _resetMeasurementSelection();
                });
              },
            ),
            Text(l10n.advGraphFormulaOverlayCompare),
          ],
        ),
      if (_enableFormula &&
          _formulaSecondaryAlignment == FormulaSecondaryAlignmentMode.timeNearest)
        Row(
          children: [
            Text(l10n.advGraphFormulaNearestTolerance),
            Expanded(
              child: Slider(
                value: _formulaNearestMaxDeltaMs,
                min: 10,
                max: 5000,
                divisions: 99,
                label: '${_formulaNearestMaxDeltaMs.round()} ms',
                onChanged: (value) {
                  _updateState(() {
                    _formulaNearestMaxDeltaMs = value;
                  });
                },
              ),
            ),
            Text('${_formulaNearestMaxDeltaMs.round()} ms'),
          ],
        ),
      if (_enableFormula)
        Row(
          children: [
            Text(l10n.advGraphFormulaOutOfRange),
            const SizedBox(width: 8),
            DropdownButton<FormulaOutOfRangePolicy>(
              value: _formulaOutOfRangePolicy,
              items: FormulaOutOfRangePolicy.values
                  .map(
                    (policy) => DropdownMenuItem(
                      value: policy,
                      child: Text(_formulaOutOfRangeLabel(l10n, policy)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _updateState(() {
                  _formulaOutOfRangePolicy = value;
                  _resetMeasurementSelection();
                });
              },
            ),
          ],
        ),
      if (_enableFormula &&
          _formulaOutOfRangePolicy == FormulaOutOfRangePolicy.interpolate)
        Row(
          children: [
            Text(l10n.advGraphFormulaInterpolationMode),
            const SizedBox(width: 8),
            DropdownButton<FormulaInterpolationMode>(
              value: _formulaInterpolationMode,
              items: FormulaInterpolationMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(_formulaInterpolationModeLabel(l10n, mode)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _updateState(() {
                  _formulaInterpolationMode = value;
                  _resetMeasurementSelection();
                });
              },
            ),
          ],
        ),
      if (_enableFormula && _formulaDraftError != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.advGraphFormulaInvalid(_formulaDraftError!),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ),
      if (_enableFormula && formulaError != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.advGraphFormulaInvalid(formulaError),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ),
    ];
  }
}