import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/screens/data_analysis/analysis/realtime_table_analysis_screen.dart';
import 'package:serial_lab/screens/data_analysis/chart_screen.dart';
import 'package:serial_lab/services/analysis/session_io_service.dart';

class RealtimeDataHome extends StatefulWidget {
  const RealtimeDataHome({super.key});

  @override
  State<RealtimeDataHome> createState() => _RealtimeDataHomeState();
}

enum _DataSaveFormat { json, csv }

class _RealtimeDataHomeState extends State<RealtimeDataHome> {
  int _selectedIndex = 0;

  // 페이지는 고정 – IndexedStack이 상태를 보존
  final List<Widget> _pages = const [
    RealtimeTableAnalysisScreen(),
    ChartScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _saveData(_DataSaveFormat format) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();
    try {
      final path = switch (format) {
        _DataSaveFormat.json => await SessionIoService.saveJsonFile(provider.chartData),
        _DataSaveFormat.csv => await SessionIoService.saveCsvFile(provider.chartData),
      };
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            format == _DataSaveFormat.json
                ? l10n.chartSavedJson(path)
                : l10n.chartExportedCsv(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chartLoadFailed(e.toString()))),
      );
    }
  }

  void _clearData() {
    final l10n = AppLocalizations.of(context)!;
    context.read<SerialProvider>().clearChartData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.drawerDataCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // ─── 컨트롤 바 (Consumer 범위를 여기로 한정) ───
          Consumer<SerialProvider>(
            builder: (context, provider, _) {
              final hasData = provider.chartData.isNotEmpty ||
                  provider.receivedData.isNotEmpty;
              return Material(
                elevation: 1,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      // 수신 토글
                      _ReceiveToggle(
                        isReceiving: provider.isReceiving,
                        onChanged: provider.setReceiving,
                        l10n: l10n,
                      ),
                      const Spacer(),
                      // 저장 버튼
                      PopupMenuButton<_DataSaveFormat>(
                        icon: const Icon(Icons.save_alt),
                        tooltip: l10n.realtimeSaveData,
                        enabled: hasData,
                        onSelected: (fmt) => _saveData(fmt),
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
                      // 지우기 버튼
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: l10n.realtimeClearData,
                        onPressed: hasData ? _clearData : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // ─── 페이지 본문 (Consumer 바깥 – 불필요한 rebuild 방지) ───
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
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

/// 수신 상태 토글 칩
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
        color: isReceiving ? Colors.red : colorScheme.onSurfaceVariant,
      ),
      label: Text(isReceiving ? l10n.realtimeReceiving : l10n.realtimePaused),
      backgroundColor: isReceiving
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      onPressed: () => onChanged(!isReceiving),
    );
  }
}
