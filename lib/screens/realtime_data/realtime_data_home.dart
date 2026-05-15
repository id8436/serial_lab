import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/screens/data_analysis/analysis/realtime_table_analysis_screen.dart';
import 'package:serial_lab/screens/data_analysis/chart_screen.dart';
import 'package:serial_lab/services/analysis/session_io_service.dart';
import 'package:serial_lab/widgets/confirm_dialog.dart';
import 'package:serial_lab/widgets/page_visibility.dart';

/// ????щ㎎ ?좏깮??enum.
enum _DataSaveFormat { json, csv }

/// ?ㅼ떆媛??곗씠?????붾㈃.
///
/// 援ъ꽦:
/// - ?곷떒: [_ControlBar]  (?섏떊 ?좉?/???吏?곌린)
/// - ?섎떒: BottomNavigationBar 濡?[RealtimeTableAnalysisScreen] / [ChartScreen] ?꾪솚
/// - 蹂몃Ц? [IndexedStack] ?쇰줈 ???붾㈃ ?곹깭瑜?蹂댁〈?섎릺, [PageVisibility] 濡?
///   ?꾩옱 蹂댁씠??履쎈쭔 heavy rebuild 瑜??섑뻾?쒕떎.
class RealtimeDataHome extends StatefulWidget {
  const RealtimeDataHome({super.key});

  @override
  State<RealtimeDataHome> createState() => _RealtimeDataHomeState();
}

class _RealtimeDataHomeState extends State<RealtimeDataHome> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    RealtimeTableAnalysisScreen(),
    ChartScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          const _ControlBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  PageVisibility(
                    active: i == _selectedIndex,
                    child: _pages[i],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.table_chart),
            label: l10n.realtimeTable,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: l10n.realtimeGraph,
          ),
        ],
      ),
    );
  }
}

// ??????????????????????????????? Control bar ???????????????????????????????

/// ?ㅼ떆媛????곷떒 而⑦듃濡?諛?
///
/// ?섏떊 ?좉? / ???JSON쨌CSV) / 吏?곌린. SerialProvider ??`isReceiving` ?대굹
/// ?곗씠??議댁옱 ?щ?媛 諛붾??뚮쭔 rebuild (dataTick ?먮뒗 諛섏쓳?섏? ?딆쓬).
class _ControlBar extends StatelessWidget {
  const _ControlBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Selector<SerialProvider, ({bool isReceiving, bool hasData})>(
      selector: (_, p) => (
        isReceiving: p.isReceiving,
        hasData: p.chartData.isNotEmpty || p.receivedData.isNotEmpty,
      ),
      builder: (context, s, _) {
        return Material(
          elevation: 1,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _ReceiveToggle(
                  isReceiving: s.isReceiving,
                  onChanged: context.read<SerialProvider>().setReceiving,
                  l10n: l10n,
                ),
                const Spacer(),
                PopupMenuButton<_DataSaveFormat>(
                  icon: const Icon(Icons.save_alt),
                  tooltip: l10n.realtimeSaveData,
                  enabled: s.hasData,
                  onSelected: (fmt) => _saveData(context, fmt),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _DataSaveFormat.json,
                      child: Text(l10n.chartSaveAsJson),
                    ),
                    PopupMenuItem(
                      value: _DataSaveFormat.csv,
                      child: Text(l10n.chartSaveAsCsv),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: l10n.realtimeClearData,
                  onPressed: s.hasData ? () => _clearData(context) : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveData(BuildContext context, _DataSaveFormat format) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<SerialProvider>();
    try {
      final path = switch (format) {
        _DataSaveFormat.json =>
          await SessionIoService.saveJsonFile(provider.chartData),
        _DataSaveFormat.csv =>
          await SessionIoService.saveCsvFile(provider.chartData),
      };
      if (path == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            format == _DataSaveFormat.json
                ? l10n.chartSavedJson(path)
                : l10n.chartExportedCsv(path),
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.chartLoadFailed(e.toString()))),
      );
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<SerialProvider>();
    final ok = await showConfirmDialog(
      context: context,
      title: l10n.confirmClearTitle,
      message: l10n.confirmClearMessage,
      confirmLabel: l10n.realtimeClearData,
      icon: Icons.delete_sweep,
    );
    if (!ok) return;
    provider.clearChartData();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.drawerDataCleared)),
    );
  }
}

/// ?섏떊 ?곹깭 ?좉? 移?
class _ReceiveToggle extends StatelessWidget {
  const _ReceiveToggle({
    required this.isReceiving,
    required this.onChanged,
    required this.l10n,
  });

  final bool isReceiving;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(
        isReceiving ? Icons.fiber_manual_record : Icons.pause,
        size: 14,
        color: isReceiving ? Colors.green : colorScheme.onSurfaceVariant,
      ),
      label: Text(isReceiving ? l10n.realtimeReceiving : l10n.realtimePaused),
      backgroundColor: isReceiving
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      onPressed: () => onChanged(!isReceiving),
    );
  }
}
