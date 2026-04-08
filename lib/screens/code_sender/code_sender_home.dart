import 'package:flutter/material.dart';

import 'package:serial_lab/screens/code_sender/code_sender_screen.dart';
import 'package:serial_lab/screens/code_sender/sample_code_tab.dart';
import 'package:serial_lab/screens/code_sender/funcs/sample_codes.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 코드 전송 홈 - 하단 탭(직접 작성/샘플 코드)
class CodeSenderHome extends StatefulWidget {
  const CodeSenderHome({super.key});

  @override
  State<CodeSenderHome> createState() => _CodeSenderHomeState();
}

class _CodeSenderHomeState extends State<CodeSenderHome> {
  int _currentIndex = 0;
  final _editorKey = GlobalKey<CodeSenderScreenState>();

  void _onLoadSample(SampleCode sample) {
    _editorKey.currentState?.loadSampleToEditor(sample);
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CodeSenderScreen(key: _editorKey),
          SampleCodeTab(onLoadSample: _onLoadSample),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit),
            label: l10n.tabDirectWrite,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: l10n.tabSampleCodes,
          ),
        ],
      ),
    );
  }
}
