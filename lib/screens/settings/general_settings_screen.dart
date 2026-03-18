import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/providers/settings_provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 일반 설정 화면
class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 제목
        Text(
          l10n.generalSettingsTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),

        // 데이터 설정
        _buildSectionTitle(context, l10n.settingsDataSection),
        Card(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.save),
                title: Text(l10n.settingsAutoSave),
                subtitle: Text(l10n.settingsAutoSaveDesc),
                value: settings.autoSaveData,
                onChanged: (value) => settings.setAutoSaveData(value),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 앱 설정
        _buildSectionTitle(context, l10n.settingsAppSection),
        Card(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: Text(l10n.settingsDarkMode),
                    subtitle: Text(l10n.settingsDarkModeDesc),
                    value: settings.isDarkMode,
                    onChanged: (value) => settings.setDarkMode(value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.settingsLanguage),
                    subtitle: Text(_currentLanguageName(settings.language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(context, settings),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 데이터 관리
        _buildSectionTitle(context, l10n.settingsDataMgmt),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(l10n.settingsSavedData),
                subtitle: Text(l10n.settingsSavedDataDesc),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  l10n.settingsDeleteAll,
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(l10n.settingsDeleteAllDesc),
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 현재 언어 코드에 해당하는 표시 이름 반환
  String _currentLanguageName(String langCode) {
    switch (langCode) {
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
      default:
        return '한국어';
    }
  }

  /// 언어 선택 다이얼로그
  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;

    final languages = [
      ('ko', l10n.langKorean),
      ('en', l10n.langEnglish),
      ('ja', l10n.langJapanese),
    ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.languageSelectTitle),
        children: languages.map((lang) {
          final (code, name) = lang;
          final isSelected = settings.language == code;
          return SimpleDialogOption(
            onPressed: () {
              settings.setLanguage(code);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogDeleteTitle),
        content: Text(l10n.dialogDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<SerialProvider>().clearChartData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.snackbarDataDeleted)),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
