import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/screens/device_list_screen.dart';
import 'package:serial_lab/screens/terminal_screen.dart';
import 'package:serial_lab/screens/chart_screen.dart';

/// 메인 홈 화면 - 탭 네비게이션
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeviceListScreen(),
    const TerminalScreen(),
    const ChartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial Lab'),
        actions: [
          Consumer<SerialProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  if (provider.isConnected)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.green, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            provider.currentDevice?.name ?? 'Connected',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 4),
                          Text('Disconnected', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  if (provider.isConnected)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => provider.disconnect(),
                      tooltip: 'Disconnect',
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.terminal),
            label: 'Terminal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
        ],
      ),
    );
  }
}
