import 'package:flutter/material.dart';

import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/screens/code_sender/code_sender_screen.dart';
import 'package:serial_lab/screens/code_sender/sample_code_tab.dart';
import 'package:serial_lab/models/sample_code.dart';
import 'package:serial_lab/screens/code_sender/config/code_editor_config.dart';
import 'package:serial_lab/widgets/confirm_dialog.dart';

/// 코드 전송 홈 - 하단 탭(Home/Write/Samples)
class CodeSenderHome extends StatefulWidget {
  const CodeSenderHome({super.key});

  @override
  State<CodeSenderHome> createState() => _CodeSenderHomeState();
}

class _CodeSenderHomeState extends State<CodeSenderHome> {
  int _currentIndex = 0;
  final _editorKey = GlobalKey<CodeSenderScreenState>();

  Future<void> _onLoadSample(SampleCode sample) async {
    final l10n = AppLocalizations.of(context)!;
    final currentText = _editorKey.currentState?.currentCode ?? '';
    final isDefault = currentText.trim() == CodeEditorConfig.defaultSketch.trim();

    if (currentText.trim().isNotEmpty && !isDefault) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: l10n.codeSenderOverwriteTitle,
        message: l10n.codeSenderOverwriteMessage,
        confirmLabel: l10n.codeSenderOverwrite,
        icon: Icons.warning_amber_rounded,
      );
      if (!confirmed) return;
    }

    _editorKey.currentState?.loadSampleToEditor(sample);
    setState(() => _currentIndex = 1);
  }

  Widget _buildGuidePage() {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final cardColor = scheme.surface.withValues(alpha: 0.88);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            scheme.tertiaryContainer.withValues(alpha: 0.28),
            scheme.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondary.withValues(alpha: 0.10),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      scheme.tertiary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: scheme.onPrimary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.codeSenderTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.codeSenderTagline,
                      style: TextStyle(color: scheme.onPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: cardColor,
                child: ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: Text(l10n.codeSenderStepsTitle),
                  subtitle: Text(l10n.codeSenderStepsSubtitle),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.05),
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.60), width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rule, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.codeSenderRequirementsTitle,
                            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(l10n.codeSenderRequirementBoard),
                      const SizedBox(height: 6),
                      Text(l10n.codeSenderRequirementOnline),
                      const SizedBox(height: 6),
                      Text(l10n.codeSenderRequirementOs),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                child: ListTile(
                  leading: const Icon(Icons.smartphone),
                  title: Text(l10n.codeSenderAndroidModeTitle),
                  subtitle: Text(l10n.codeSenderAndroidModeSubtitle),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.05),
                    border: Border.all(color: scheme.error.withValues(alpha: 0.65), width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: scheme.error),
                          const SizedBox(width: 8),
                          Text(
                            l10n.codeSenderCautionTitle,
                            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(l10n.codeSenderCautionLibs),
                      const SizedBox(height: 6),
                      Text(l10n.codeSenderCautionPort),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildGuidePage(),
          CodeSenderScreen(key: _editorKey),
          SampleCodeTab(onLoadSample: _onLoadSample),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: l10n.codeSenderTabGuide,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit),
            label: l10n.codeSenderTabWrite,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: l10n.codeSenderTabSamples,
          ),
        ],
      ),
    );
  }
}
