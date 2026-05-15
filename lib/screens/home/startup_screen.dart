import 'package:flutter/material.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/screens/home/home_screen.dart';

/// App launch screen shown briefly before entering HomeScreen.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _markReady();
  }

  Future<void> _markReady() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const HomeScreen();
    }

    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.developer_board,
                size: 72,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
