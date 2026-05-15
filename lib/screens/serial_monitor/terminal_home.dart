import 'package:flutter/material.dart';
import 'package:serial_lab/screens/serial_monitor/terminal_screen.dart';
import 'package:serial_lab/screens/serial_monitor/bluetooth_serial_screen.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/widgets/page_visibility.dart';

/// 시리얼 모니터 홈 - 하단 네비게이션
class TerminalHome extends StatefulWidget {
  const TerminalHome({super.key});

  @override
  State<TerminalHome> createState() => _TerminalHomeState();
}

class _TerminalHomeState extends State<TerminalHome> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    TerminalScreen(),
    BluetoothSerialScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            PageVisibility(
              active: i == _currentIndex,
              child: _screens[i],
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.terminal),
            label: l10n.serialTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bluetooth),
            label: l10n.bluetoothSerialTab,
          ),
        ],
      ),
    );
  }
}
