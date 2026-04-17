import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/analysis_data_provider.dart';
import 'package:serial_lab/screens/data_analysis/analysis/analysis_data_screen.dart';
import 'package:serial_lab/screens/data_analysis/analysis/advanced_graph_analysis_screen.dart';
import 'package:serial_lab/screens/data_analysis/analysis/stats_analysis_screen.dart';
import 'package:serial_lab/screens/data_analysis/analysis/correlation_analysis_screen.dart';
import 'package:serial_lab/screens/data_analysis/analysis/fft_analysis_screen.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// BottomNavigationBar 탭 항목 구조
class TabItem {
  final String label;
  final IconData icon;
  final Widget page;

  TabItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}

/// 데이터 분석 홈 화면
class DataAnalysisHome extends StatefulWidget {
  const DataAnalysisHome({super.key});

  @override
  State<DataAnalysisHome> createState() => _DataAnalysisHomeState();
}

class _DataAnalysisHomeState extends State<DataAnalysisHome> {
  int _selectedIndex = 0;

  List<TabItem> _buildTabItems(AppLocalizations l10n) => [
    TabItem(
      label: l10n.analysisDataTab,
      icon: Icons.dataset,
      page: const AnalysisDataScreen(),
    ),
    TabItem(
      label: l10n.advancedGraphAnalysis,
      icon: Icons.multiline_chart,
      page: const AdvancedGraphAnalysisScreen(),
    ),
    TabItem(
      label: l10n.statsAnalysis,
      icon: Icons.bar_chart,
      page: const StatsAnalysisScreen(),
    ),
    TabItem(
      label: l10n.correlationAnalysis,
      icon: Icons.scatter_plot,
      page: const CorrelationAnalysisScreen(),
    ),
    TabItem(
      label: l10n.fftAnalysis,
      icon: Icons.graphic_eq,
      page: const FftAnalysisScreen(),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabItems = _buildTabItems(l10n);
    return ChangeNotifierProvider(
      create: (_) => AnalysisDataProvider(),
      child: Scaffold(
        body: tabItems[_selectedIndex].page,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: List.generate(tabItems.length, (index) {
            final item = tabItems[index];
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }),
        ),
      ),
    );
  }
}
