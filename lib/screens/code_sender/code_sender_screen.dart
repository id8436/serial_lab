import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'funcs/arduino_cli_helper.dart';
import 'funcs/code_editor_config.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 코드 전송 화면 - Arduino IDE처럼 코드 작성/검증/업로드
class CodeSenderScreen extends StatefulWidget {
  const CodeSenderScreen({super.key});

  @override
  State<CodeSenderScreen> createState() => _CodeSenderScreenState();
}

class _CodeSenderScreenState extends State<CodeSenderScreen> {
  late CodeController _codeController;
  String _compileOutput = '';
  bool _isCompiling = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: CodeEditorConfig.defaultSketch,
      language: CodeEditorConfig.language,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Arduino CLI로 스케치 검증
  Future<void> _verifySketch() async {
    final provider = context.read<SerialProvider>();
    final selectedBoard = provider.selectedBoard;
    
    setState(() {
      _isCompiling = true;
      _compileOutput = '';
    });

    try {
      final output = await ArduinoCliHelper.verifySketch(
        code: _codeController.text,
        fqbn: selectedBoard,
      );
      
      setState(() {
        _compileOutput = output;
      });
    } finally {
      setState(() {
        _isCompiling = false;
      });
    }
  }

  /// Arduino CLI로 스케치 업로드
  Future<void> _uploadSketch() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();
    final selectedBoard = provider.selectedBoard;
    
    if (!provider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.connectDeviceFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _compileOutput = '';
    });

    try {
      final port = provider.currentDevice?.address ?? 'COM3';
      final output = await ArduinoCliHelper.uploadSketch(
        code: _codeController.text,
        fqbn: selectedBoard,
        port: port,
      );
      
      setState(() {
        _compileOutput = output;
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// 파일에서 스케치 불러오기
  Future<void> _openSketch() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ino', 'cpp', 'c'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      setState(() {
        _codeController.text = content;
      });
    }
  }

  /// 새 스케치
  void _newSketch() {
    setState(() {
      _codeController.text = CodeEditorConfig.defaultSketch;
      _compileOutput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SerialProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 툴바
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 파일 조작
                  IconButton(
                    icon: const Icon(Icons.insert_drive_file),
                    tooltip: l10n.newSketch,
                    onPressed: _newSketch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: l10n.openSketch,
                    onPressed: _openSketch,
                  ),
                  const Spacer(),
                  
                  // 검증/업로드 버튼
                  FilledButton.tonalIcon(
                    onPressed: _isCompiling ? null : _verifySketch,
                    icon: _isCompiling 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(l10n.verify),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: (_isUploading || !provider.isConnected) 
                        ? null 
                        : _uploadSketch,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(l10n.upload),
                  ),
                ],
              ),
            ),

            // 코드 에디터
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF272822) // Monokai 배경색 (다크)
                      : const Color(0xFFF8F8F8), // 밝은 회색 (라이트)
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: CodeTheme(
                  data: CodeThemeData(
                    styles: Theme.of(context).brightness == Brightness.dark
                        ? CodeEditorConfig.darkTheme
                        : CodeEditorConfig.lightTheme,
                  ),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _codeController,
                      textStyle: TextStyle(
                        fontFamily: CodeEditorConfig.fontFamily,
                        fontSize: CodeEditorConfig.fontSize,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 출력 콘솔
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black87
                    : Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[200],
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.terminal,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '출력',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _compileOutput = '';
                              });
                            },
                            tooltip: '출력 지우기',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _compileOutput.isEmpty 
                              ? '여기에 컴파일/업로드 결과가 표시됩니다.'
                              : _compileOutput,
                          style: TextStyle(
                            fontFamily: CodeEditorConfig.fontFamily,
                            fontSize: 12,
                            color: _compileOutput.isEmpty
                                ? Theme.of(context).hintColor
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green[300]
                                    : Colors.green[700]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

