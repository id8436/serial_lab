import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/services/board_label_service.dart';
import 'package:serial_lab/screens/home/dashboard_screen.dart';
import 'package:serial_lab/screens/connection/connection_home.dart';
import 'package:serial_lab/screens/realtime_data/realtime_data_home.dart';
import 'package:serial_lab/screens/serial_monitor/terminal_home.dart';
import 'package:serial_lab/screens/code_sender/code_sender_home.dart';
import 'package:serial_lab/screens/settings/settings_home.dart';
import 'package:serial_lab/screens/data_analysis/data_analysis_home.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/widgets/confirm_dialog.dart';

/// Drawer 硫붾돱 ?꾩씠???곗씠???대옒??
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

/// 메인 화면 - Drawer 내비게이션.
///
/// 과거에는 모든 최상위 페이지를 [IndexedStack]으로 유지했지만,
/// off-stage 페이지의 TextField/Consumer가 계속 살아 있어 데이터 로드와
/// 겹칠 때 ANR을 유발할 수 있었다. 현재는 선택된 페이지만 mount한다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  VoidCallback? _errorListener;
  SerialProvider? _providerRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<SerialProvider>();
    if (!identical(_providerRef, provider)) {
      _detachErrorListener();
      _providerRef = provider;
      _errorListener = () {
        final msg = provider.lastError.value;
        if (msg == null || !mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        provider.clearLastError();
      };
      provider.lastError.addListener(_errorListener!);
    }
  }

  void _detachErrorListener() {
    if (_errorListener != null && _providerRef != null) {
      _providerRef!.lastError.removeListener(_errorListener!);
    }
    _errorListener = null;
  }

  @override
  void dispose() {
    _detachErrorListener();
    super.dispose();
  }

  static const List<Widget> _pages = [
    DashboardScreen(),
    ConnectionHome(),
    TerminalHome(),
    RealtimeDataHome(),
    DataAnalysisHome(),
    CodeSenderHome(),
    SettingsHome(),
  ];

  List<MenuItem> _buildMenuItems(AppLocalizations l10n) => [
        MenuItem(
            title: l10n.navHome,
            subtitle: l10n.navHomeSubtitle,
            icon: Icons.home,
            page: _pages[0]),
        MenuItem(
            title: l10n.navDevice,
            subtitle: l10n.navDeviceSubtitle,
            icon: Icons.developer_board,
            page: _pages[1]),
        MenuItem(
            title: l10n.navSerialMonitor,
            subtitle: l10n.navSerialMonitorSubtitle,
            icon: Icons.terminal,
            page: _pages[2]),
        MenuItem(
            title: l10n.navRealtimeData,
            subtitle: l10n.navRealtimeDataSubtitle,
            icon: Icons.timeline,
            page: _pages[3]),
        MenuItem(
            title: l10n.navDataAnalysis,
            subtitle: l10n.navDataAnalysisSubtitle,
            icon: Icons.analytics,
            page: _pages[4]),
        MenuItem(
            title: l10n.navCodeSend,
            subtitle: l10n.navCodeSendSubtitle,
            icon: Icons.code,
            page: _pages[5]),
        MenuItem(
            title: l10n.navSettings,
            subtitle: l10n.navSettingsSubtitle,
            icon: Icons.settings,
            page: _pages[6]),
      ];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final menuItems = _buildMenuItems(l10n);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(menuItems[_selectedIndex].title),
        actions: const [_AppBarConnectionStatus()],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            _DrawerHeader(l10n: l10n),
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
            _DrawerFooter(l10n: l10n),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

// ????????????????????????? AppBar / Drawer 議곌컖???????????????????????????

/// AppBar ?ㅻⅨ履??곌껐 ?곹깭. ?곌껐 ?곹깭/蹂대뱶 蹂寃??쒖뿉留?rebuild (dataTick 臾댁떆).
class _AppBarConnectionStatus extends StatelessWidget {
  const _AppBarConnectionStatus();

  @override
  Widget build(BuildContext context) {
    return Selector<SerialProvider, ({bool isConnected, String board})>(
      selector: (_, p) => (isConnected: p.isConnected, board: p.selectedBoard),
      builder: (context, s, _) {
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                color: s.isConnected ? scheme.primary : scheme.error,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                s.isConnected
                    ? BoardLabelService.getLabel(s.board)
                    : l10n.statusDisconnected,
                style: const TextStyle(fontSize: 14),
              ),
              if (s.isConnected) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _confirmDisconnect(context),
                  tooltip: l10n.tooltipDisconnect,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();
    // 데이터 수신 중일 때만 확인 다이얼로그; 그외엔 즉시 끊는다.
    if (provider.isReceiving) {
      final ok = await showConfirmDialog(
        context: context,
        title: l10n.confirmDisconnectTitle,
        message: l10n.confirmDisconnectMessage,
        confirmLabel: l10n.tooltipDisconnect,
        icon: Icons.link_off,
      );
      if (!ok) return;
    }
    await provider.disconnect();
  }
}

class _DrawerHeader extends StatelessWidget {
  final AppLocalizations l10n;
  const _DrawerHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Selector<SerialProvider, ({bool isConnected, String? name})>(
      selector: (_, p) => (
        isConnected: p.isConnected,
        name: p.currentDevice?.name,
      ),
      builder: (context, s, _) {
        final onPrimary = Theme.of(context).colorScheme.onPrimary;
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
              Icon(Icons.developer_board, size: 48, color: onPrimary),
              const SizedBox(height: 12),
              Text(
                'Serial Lab',
                style: TextStyle(
                  color: onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.isConnected
                    ? l10n.drawerConnectedTo(s.name ?? 'device')
                    : l10n.drawerNoDevice,
                style: TextStyle(color: onPrimary.withValues(alpha: 0.8), fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final AppLocalizations l10n;
  const _DrawerFooter({required this.l10n});

  @override
  Widget build(BuildContext context) {
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
          Selector<SerialProvider, bool>(
            selector: (_, p) => p.isConnected,
            builder: (context, isConnected, _) {
              return Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.delete_sweep, size: 18),
                    label: Text(l10n.drawerClearData),
                    onPressed: () => _confirmClear(context),
                  ),
                  if (isConnected)
                    ActionChip(
                      avatar: const Icon(Icons.link_off, size: 18),
                      label: Text(l10n.drawerDisconnect),
                      onPressed: () => _confirmDisconnectFromDrawer(context),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<SerialProvider>();
    final ok = await showConfirmDialog(
      context: context,
      title: l10n.confirmClearTitle,
      message: l10n.confirmClearMessage,
      confirmLabel: l10n.drawerClearData,
      icon: Icons.delete_sweep,
    );
    if (!ok) return;
    provider.clearChartData();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.drawerDataCleared)),
    );
  }

  Future<void> _confirmDisconnectFromDrawer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final provider = context.read<SerialProvider>();
    if (provider.isReceiving) {
      final ok = await showConfirmDialog(
        context: context,
        title: l10n.confirmDisconnectTitle,
        message: l10n.confirmDisconnectMessage,
        confirmLabel: l10n.tooltipDisconnect,
        icon: Icons.link_off,
      );
      if (!ok) return;
    }
    await provider.disconnect();
    if (navigator.canPop()) navigator.pop();
  }
}
