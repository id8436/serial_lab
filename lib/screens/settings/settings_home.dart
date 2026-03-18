import 'package:flutter/material.dart';
import 'package:serial_lab/screens/settings/general_settings_screen.dart';
import 'package:serial_lab/screens/settings/about_screen.dart';
import 'package:serial_lab/screens/settings/open_license_screen.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 탭 아이템 데이터 클래스
class TabItem {
  final String label;
  final IconData icon;
  final Widget page;
  final VoidCallback? onTap; // 특수 동작이 필요한 경우

  TabItem({
    required this.label,
    required this.icon,
    required this.page,
    this.onTap,
  });
}

/// 설정 홈 화면 - 하단 네비게이션으로 구성
class SettingsHome extends StatefulWidget {
  const SettingsHome({super.key});

  @override
  State<SettingsHome> createState() => _SettingsHomeState();
}

class _SettingsHomeState extends State<SettingsHome> {
  int _selectedIndex = 0;

  List<TabItem> _buildTabItems(AppLocalizations l10n) => [
    TabItem(
      label: l10n.settingsTabSettings,
      icon: Icons.settings,
      page: const GeneralSettingsScreen(),
    ),
    TabItem(
      label: l10n.settingsTabAbout,
      icon: Icons.info,
      page: const AboutScreen(),
    ),
    TabItem(
      label: l10n.settingsTabLicense,
      icon: Icons.description,
      page: const OpenLicenseScreen(),
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
