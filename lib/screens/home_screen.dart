import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/screens/dashboard_screen.dart';
import 'package:serial_lab/screens/device_connection_screen.dart';
import 'package:serial_lab/screens/terminal_screen.dart';
import 'package:serial_lab/screens/code_sender_screen.dart';

import 'data_analysis/data_analysis_home.dart';

/// 메인 홈 화면 - Drawer 네비게이션
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_DrawerMenuItem> _menuItems = [
    _DrawerMenuItem(
      icon: Icons.home,
      title: '홈',
      subtitle: 'Dashboard & Guide',
    ),
    _DrawerMenuItem(
      icon: Icons.devices,
      title: '기기 연결',
      subtitle: 'Connect to devices',
    ),
    _DrawerMenuItem(
      icon: Icons.terminal,
      title: '시리얼 모니터',
      subtitle: 'Send and receive data',
    ),
    _DrawerMenuItem(
      icon: Icons.analytics,
      title: '데이터 분석',
      subtitle: 'Visualize data',
    ),
    _DrawerMenuItem(
      icon: Icons.code,
      title: '코드 전송',
      subtitle: 'Send code snippets',
    ),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DeviceConnectionScreen(),
    const TerminalScreen(),
    const DataAnalysisHome(),
    const CodeSenderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex].title),
        actions: [
          Consumer<SerialProvider>(
            builder: (context, provider, child) {
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
                          ? provider.currentDevice?.name ?? 'Connected'
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
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  return _buildDrawerItem(index);
                },
              ),
            ),
            const Divider(),
            _buildDrawerFooter(),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawerHeader() {
    return Consumer<SerialProvider>(
      builder: (context, provider, child) {
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
                    ? 'Connected to ${provider.currentDevice?.name ?? 'device'}'
                    : 'No device connected',
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

  Widget _buildDrawerItem(int index) {
    final item = _menuItems[index];
    final isSelected = _selectedIndex == index;

    return ListTile(
      selected: isSelected,
      leading: Icon(item.icon),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Drawer 닫기
      },
    );
  }

  Widget _buildDrawerFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Consumer<SerialProvider>(
            builder: (context, provider, child) {
              return Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Clear Data'),
                    onPressed: () {
                      provider.clearChartData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data cleared')),
                      );
                    },
                  ),
                  if (provider.isConnected)
                    ActionChip(
                      avatar: const Icon(Icons.link_off, size: 18),
                      label: const Text('Disconnect'),
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

class _DrawerMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
