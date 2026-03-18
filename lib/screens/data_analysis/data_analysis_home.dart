import 'package:flutter/material.dart';
import 'package:serial_lab/screens/data_analysis/chart_screen.dart';
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
      label: l10n.realtimeGraph,
      icon: Icons.show_chart,
      page: const ChartScreen(),
    ),
    TabItem(
      label: l10n.statsAnalysis,
      icon: Icons.bar_chart,
      page: ComingSoonScreen(
        title: l10n.statsAnalysis,
        description: l10n.statsAnalysisDesc,
        icon: Icons.bar_chart,
      ),
    ),
    TabItem(
      label: l10n.correlationAnalysis,
      icon: Icons.scatter_plot,
      page: ComingSoonScreen(
        title: l10n.correlationAnalysis,
        description: l10n.correlationAnalysisDesc,
        icon: Icons.scatter_plot,
      ),
    ),
    TabItem(
      label: l10n.fftAnalysis,
      icon: Icons.graphic_eq,
      page: ComingSoonScreen(
        title: l10n.fftAnalysis,
        description: l10n.fftAnalysisDesc,
        icon: Icons.graphic_eq,
      ),
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
    return Scaffold(
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
    );
  }
}

/// 미구현 기능 표시 화면
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.construction),
              label: Text(l10n.preparingMsg),
            ),
          ],
        ),
      ),
    );
  }
}