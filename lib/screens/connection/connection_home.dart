import 'package:flutter/material.dart';
import 'package:serial_lab/screens/connection/device_connection_screen.dart';
import 'package:serial_lab/screens/connection/device_info.dart';

/// 기기 연결 홈 - 하단 네비게이션
class ConnectionHome extends StatefulWidget {
  const ConnectionHome({super.key});

  @override
  State<ConnectionHome> createState() => _ConnectionHomeState();
}

class _ConnectionHomeState extends State<ConnectionHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeviceInfoScreen(),
    const DeviceConnectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: '연결 정보',
            tooltip: 'Connection Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: '기기 연결',
            tooltip: 'Device Connection',
          ),
        ],
      ),
    );
  }
}
