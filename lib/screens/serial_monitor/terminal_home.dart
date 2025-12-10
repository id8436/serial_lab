import 'package:flutter/material.dart';
import 'package:serial_lab/screens/serial_monitor/terminal_screen.dart';
import 'package:serial_lab/screens/serial_monitor/bluetooth_serial_screen.dart';

/// 시리얼 모니터 홈 - 하단 네비게이션
class TerminalHome extends StatefulWidget {
  const TerminalHome({super.key});

  @override
  State<TerminalHome> createState() => _TerminalHomeState();
}

class _TerminalHomeState extends State<TerminalHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TerminalScreen(),
    const BluetoothSerialScreen(),
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
            icon: Icon(Icons.terminal),
            label: '시리얼',
            tooltip: 'Serial Terminal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: '블루투스 시리얼',
            tooltip: 'Bluetooth Serial',
          ),
        ],
      ),
    );
  }
}
