import 'package:flutter/material.dart';

import 'package:serial_lab/screens/code_sender/code_sender_screen.dart';
import 'package:serial_lab/screens/code_sender/sample_code_tab.dart';
import 'package:serial_lab/models/sample_code.dart';
import 'package:serial_lab/screens/code_sender/config/code_editor_config.dart';

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
    final currentText = _editorKey.currentState?.currentCode ?? '';
    final isDefault = currentText.trim() == CodeEditorConfig.defaultSketch.trim();

    if (currentText.trim().isNotEmpty && !isDefault) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
          title: const Text('에디터 내용 덮어쓰기'),
          content: const Text(
            '에디터에 작성한 코드가 있습니다.\n'
            '샘플 코드를 불러오면 기존 내용이 사라집니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('덮어쓰기'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    _editorKey.currentState?.loadSampleToEditor(sample);
    setState(() => _currentIndex = 1);
  }

  Widget _buildGuidePage() {
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
                          'Code Sender',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '코드 작성, 검증, 업로드까지!',
                      style: TextStyle(color: scheme.onPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: cardColor,
                child: const ListTile(
                  leading: Icon(Icons.alt_route),
                  title: Text('절차'),
                  subtitle: Text('1) 샘플 선택 또는 코드 작성\n2) Verify로 컴파일 확인\n3) 장치 연결 확인\n4) Upload로 전송'),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.60), width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rule, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '필요 조건',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blue),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('• 보드 연결: 업로드 전 대상 보드/포트가 연결되어 있어야 합니다.'),
                      SizedBox(height: 6),
                      Text('• 기기 온라인 상태: Android에서 서버 컴파일을 사용할 때는 인터넷 연결이 필요합니다.'),
                      SizedBox(height: 6),
                      Text('• 가용 OS: Write/Verify/Upload는 Android/Windows에서 사용 가능하며, HEX 업로드는 Android 전용 고급 기능입니다.'),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                child: const ListTile(
                  leading: Icon(Icons.smartphone),
                  title: Text('Android 동작 방식'),
                  subtitle: Text('코드는 서버에서 컴파일되고, USB(STK500)로 업로드됩니다.'),
                ),
              ),
              Card(
                elevation: 0,
                color: cardColor,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.65), width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            '유의사항',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('• 샘플에 없는 라이브러리는 현재 앱에서 자동 설치되지 않아, 사용할 수 없습니다.'),
                      SizedBox(height: 6),
                      Text('• 업로드 실패 시 보드 포트 점유(Serial Monitor 등)를 해제하고 다시 시도하세요.'),
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit),
            label: 'Write',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: 'Samples',
          ),
        ],
      ),
    );
  }
}
