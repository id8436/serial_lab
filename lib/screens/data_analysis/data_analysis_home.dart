import 'package:flutter/material.dart';
import 'package:serial_lab/screens/data_analysis/chart_screen.dart';

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

  late final List<TabItem> tabItems = [
    TabItem(
      label: "실시간 그래프",
      icon: Icons.show_chart,
      page: const ChartScreen(),
    ),
    TabItem(
      label: "통계 분석",
      icon: Icons.bar_chart,
      page: const ComingSoonScreen(
        title: '통계 분석',
        description: '평균, 표준편차, 최대/최소값 등 기본 통계 정보를 제공합니다.',
        icon: Icons.bar_chart,
      ),
    ),
    TabItem(
      label: "상관도 분석",
      icon: Icons.scatter_plot,
      page: const ComingSoonScreen(
        title: '상관도 분석',
        description: '여러 데이터 간의 상관관계를 분석하고 시각화합니다.',
        icon: Icons.scatter_plot,
      ),
    ),
    TabItem(
      label: "FFT 분석",
      icon: Icons.graphic_eq,
      page: const ComingSoonScreen(
        title: 'FFT 분석',
        description: '주파수 영역 분석으로 신호의 주파수 성분을 확인합니다.',
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
              '🚧 Coming Soon 🚧',
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
              label: const Text('준비 중입니다'),
            ),
          ],
        ),
      ),
    );
  }
}