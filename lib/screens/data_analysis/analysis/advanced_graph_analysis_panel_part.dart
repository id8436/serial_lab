part of 'advanced_graph_analysis_screen.dart';

extension _AdvancedGraphAnalysisPanelPart on _AdvancedGraphAnalysisScreenState {
  Widget _buildCollapsibleControlsShell(
    BuildContext context,
    AppLocalizations l10n, {
    required double expandedContentMaxHeight,
    required List<Widget> Function() primaryControlsBuilder,
    required List<Widget> Function() formulaControlsBuilder,
    required List<Widget> Function() analysisControlsBuilder,
  }) {
    return _CollapsibleControlsShell(
      headerTitle: l10n.settingsTabSettings,
      headerSummary: _controlsSummaryText(l10n),
      formulaTitle: l10n.advGraphFormula,
      analysisTitle: l10n.advancedGraphAnalysis,
      expandedContentMaxHeight: expandedContentMaxHeight,
      primaryControlsBuilder: primaryControlsBuilder,
      formulaControlsBuilder: formulaControlsBuilder,
      analysisControlsBuilder: analysisControlsBuilder,
    );
  }

  String _controlsSummaryText(AppLocalizations l10n) {
    final summary = <String>[
      _selectedSeries ?? '-',
      _modeLabel(l10n, _mode),
      _derivedSeriesModeLabel(l10n, _derivedSeriesMode),
      if (_enableFormula) l10n.advGraphFormula,
      if (_showMeasurementTools) l10n.advGraphMeasurementTools,
    ];
    return summary.join(' • ');
  }
}

class _CollapsibleControlsShell extends StatefulWidget {
  const _CollapsibleControlsShell({
    required this.headerTitle,
    required this.headerSummary,
    required this.formulaTitle,
    required this.analysisTitle,
    required this.expandedContentMaxHeight,
    required this.primaryControlsBuilder,
    required this.formulaControlsBuilder,
    required this.analysisControlsBuilder,
  });

  final String headerTitle;
  final String headerSummary;
  final String formulaTitle;
  final String analysisTitle;
  final double expandedContentMaxHeight;
  final List<Widget> Function() primaryControlsBuilder;
  final List<Widget> Function() formulaControlsBuilder;
  final List<Widget> Function() analysisControlsBuilder;

  @override
  State<_CollapsibleControlsShell> createState() => _CollapsibleControlsShellState();
}

class _CollapsibleControlsShellState extends State<_CollapsibleControlsShell> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      color: scheme.surfaceContainerHighest,
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.headerTitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          widget.headerSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleExpanded,
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                    tooltip: widget.headerTitle,
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: widget.expandedContentMaxHeight),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildControlsCard(
                              context,
                              child: _buildControlsColumn(widget.primaryControlsBuilder()),
                            ),
                            const SizedBox(height: 6),
                            _buildExpandableControlsSection(
                              context,
                              key: const PageStorageKey<String>('adv_graph_formula_controls'),
                              icon: Icons.functions,
                              title: widget.formulaTitle,
                              initiallyExpanded: false,
                              children: widget.formulaControlsBuilder(),
                            ),
                            const SizedBox(height: 6),
                            _buildExpandableControlsSection(
                              context,
                              key: const PageStorageKey<String>('adv_graph_analysis_controls'),
                              icon: Icons.analytics_outlined,
                              title: widget.analysisTitle,
                              initiallyExpanded: false,
                              children: widget.analysisControlsBuilder(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard(
    BuildContext context, {
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _buildExpandableControlsSection(
    BuildContext context, {
    required PageStorageKey<String> key,
    required IconData icon,
    required String title,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: key,
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, size: 16, color: scheme.primary),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          children: [_buildControlsColumn(children)],
        ),
      ),
    );
  }

  Widget _buildControlsColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}