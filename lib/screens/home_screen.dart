import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/services/board_label_service.dart';
import 'package:serial_lab/screens/dashboard_screen.dart';
import 'package:serial_lab/screens/connection/connection_home.dart';
import 'package:serial_lab/screens/realtime_data/realtime_data_home.dart';
import 'package:serial_lab/screens/serial_monitor/terminal_home.dart';
import 'package:serial_lab/screens/code_sender/code_sender_home.dart';
import 'package:serial_lab/screens/settings/settings_home.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

import 'data_analysis/data_analysis_home.dart';

/// Drawer 메뉴 아이템 데이터 클래스
class MenuItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget page;

  MenuItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.page,
  });
}

/// 메인 홈 화면 - Drawer 네비게이션
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 페이지는 고정 - 언어 변경 시 상태 보존
  final List<Widget> _pages = [
    const DashboardScreen(),
    const ConnectionHome(),
    const TerminalHome(),
    const RealtimeDataHome(),
    const DataAnalysisHome(),
    const CodeSenderHome(),
    const SettingsHome(),
  ];

  List<MenuItem> _buildMenuItems(AppLocalizations l10n) => [
    MenuItem(title: l10n.navHome, 
        subtitle: l10n.navHomeSubtitle,
        icon: Icons.home, 
        page: _pages[0]),
    MenuItem(title: l10n.navDevice, subtitle: l10n.navDeviceSubtitle,
        icon: Icons.developer_board, page: _pages[1]),
    MenuItem(title: l10n.navSerialMonitor, subtitle: l10n.navSerialMonitorSubtitle,
        icon: Icons.terminal, page: _pages[2]),
    MenuItem(title: l10n.navRealtimeData, subtitle: l10n.navRealtimeDataSubtitle,
      icon: Icons.timeline, page: _pages[3]),
    MenuItem(title: l10n.navDataAnalysis, subtitle: l10n.navDataAnalysisSubtitle,
      icon: Icons.analytics, page: _pages[4]),
    MenuItem(title: l10n.navCodeSend, subtitle: l10n.navCodeSendSubtitle,
      icon: Icons.code, page: _pages[5]),
    MenuItem(title: l10n.navSettings, subtitle: l10n.navSettingsSubtitle,
      icon: Icons.settings, page: _pages[6]),
  ];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Drawer 닫기
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final menuItems = _buildMenuItems(l10n);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(menuItems[_selectedIndex].title),
        actions: [
          Consumer<SerialProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: provider.isConnected ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.isConnected
                          ? BoardLabelService.getLabel(provider.selectedBoard)
                          : 'Disconnected',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (provider.isConnected) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => provider.disconnect(),
                        tooltip: 'Disconnect',
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            _buildDrawerHeader(l10n),
            ...List.generate(menuItems.length, (index) {
              final item = menuItems[index];
              return ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                selected: _selectedIndex == index,
                onTap: () => _selectPage(index),
              );
            }),
            const Divider(),
            _buildDrawerFooter(l10n),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

  Widget _buildDrawerHeader(AppLocalizations l10n) {
    return Consumer<SerialProvider>(
      builder: (context, provider, _) {
        return DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.developer_board,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'Serial Lab',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.isConnected
                    ? l10n.drawerConnectedTo(provider.currentDevice?.name ?? 'device')
                    : l10n.drawerNoDevice,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerFooter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.drawerQuickActions,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Consumer<SerialProvider>(
            builder: (context, provider, _) {
              return Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.delete_sweep, size: 18),
                    label: Text(l10n.drawerClearData),
                    onPressed: () {
                      provider.clearChartData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.drawerDataCleared)),
                      );
                    },
                  ),
                  if (provider.isConnected)
                    ActionChip(
                      avatar: const Icon(Icons.link_off, size: 18),
                      label: Text(l10n.drawerDisconnect),
                      onPressed: () {
                        provider.disconnect();
                        Navigator.pop(context);
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
