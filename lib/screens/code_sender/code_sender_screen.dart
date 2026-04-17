import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/sample_code.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/services/arduino_cli_service.dart';
import 'package:serial_lab/services/cloud_compile_service.dart';
import 'package:serial_lab/services/upload/android_uploader.dart';
import 'package:serial_lab/services/upload/upload_orchestrator.dart';

import 'config/code_editor_config.dart';

/// 코드 전송 화면 - 하단 탭: 직접 작성 / 샘플 코드
class CodeSenderScreen extends StatefulWidget {
  const CodeSenderScreen({super.key});

  @override
  State<CodeSenderScreen> createState() => CodeSenderScreenState();
}

class CodeSenderScreenState extends State<CodeSenderScreen> {
  late CodeController _codeController;
  String? _currentSketchPath;
  String _compileOutput = '';
  bool _isCompiling = false;
  bool _isUploading = false;
  bool _showAdvancedAndroidTools = false;
  double _uploadProgress = 0.0;
  double _consoleHeightFraction = 0.3;

  // Android 전용
  Uint8List? _hexFileData;
  String _hexFileName = '';

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

  // ───────────────────────── Actions ─────────────────────────

  Future<void> _verifySketch() async {
    final provider = context.read<SerialProvider>();
    setState(() { _isCompiling = true; _compileOutput = ''; });
    try {
      if (Platform.isAndroid) {
        setState(() => _compileOutput = 'Compiling on server...\n');
        final result = await CloudCompileService.compile(
          code: _codeController.text,
          fqbn: provider.selectedBoard,
        );
        if (mounted) {
          setState(() => _compileOutput = result.output);
        }
      } else {
        final output = await ArduinoCliService.verifySketch(
          code: _codeController.text, fqbn: provider.selectedBoard);
        if (mounted) {
          setState(() => _compileOutput = output);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCompiling = false);
      }
    }
  }

  /// 업로드 후 자동 재연결 (Arduino 부팅 대기 후)
  Future<void> _reconnectAfterUpload(SerialProvider provider) async {
    final device = provider.currentDevice;
    final baudRate = provider.baudRate;
    if (!mounted || device == null) return;
    setState(() => _compileOutput += '\n재연결 대기 중... (2.5s)\n');
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _compileOutput += '재연결 시도 중...\n');
    provider.setBaudRate(baudRate);
    final ok = await provider.connect(device);
    if (!mounted) return;
    setState(() => _compileOutput += ok
        ? '✅ 재연결 성공\n'
        : '⚠️ 재연결 실패 — 장치 탭에서 수동으로 연결해 주세요\n');
  }

  Future<void> _uploadSketch({String? codeOverride}) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();

    // iOS는 USB 시리얼 접근 불가
    if (Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('iOS에서는 코드 업로드를 지원하지 않습니다.\nPC 또는 Android에서 업로드해 주세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!provider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.connectDeviceFirst), backgroundColor: Colors.red));
      return;
    }

    // Android 지원 보드 체크
    if (Platform.isAndroid && !AndroidUploader.isSupportedBoard(provider.selectedBoard)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.selectedBoard} 보드는 Android USB 업로드를 지원하지 않습니다.\nPC에서 업로드해 주세요.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 업로드 전 기기 정보 저장 (재연결용)
    final savedDevice = provider.currentDevice;
    final savedBaudRate = provider.baudRate;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _compileOutput = '';
    });

    try {
      final UploadResult result;

      if (Platform.isAndroid) {
        if (_hexFileData != null && codeOverride == null) {
          // Pre-compiled hex/bin file
          result = await UploadOrchestrator.uploadPrecompiledAndroid(
            fileData: _hexFileData!,
            fqbn: provider.selectedBoard,
            provider: provider,
            onLog: (m) { if (mounted) setState(() => _compileOutput += '$m\n'); },
            onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
          );
        } else {
          // Cloud compile + upload
          result = await UploadOrchestrator.compileAndUploadAndroid(
            code: codeOverride ?? _codeController.text,
            fqbn: provider.selectedBoard,
            provider: provider,
            onLog: (m) { if (mounted) setState(() => _compileOutput += '$m\n'); },
            onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
          );
        }
      } else {
        // PC: arduino-cli
        final port = provider.currentDevice?.address;
        if (port == null || port.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('포트 정보를 확인할 수 없습니다'), backgroundColor: Colors.red));
          return;
        }
        result = await UploadOrchestrator.uploadPc(
          code: codeOverride ?? _codeController.text,
          fqbn: provider.selectedBoard,
          port: port,
          provider: provider,
        );
      }

      if (mounted) setState(() => _compileOutput += result.output);

      // 재연결 처리
      if (result.needsReconnect && savedDevice != null) {
        provider.setBaudRate(savedBaudRate);
        await _reconnectAfterUpload(provider);
      } else if (result.success) {
        provider.resumeAfterUpload();
        if (mounted) setState(() => _compileOutput += '\n✅ 재연결 완료\n');
      }
    } finally {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0; });
    }
  }

  Future<void> _selectHexFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['hex']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final data = await file.readAsBytes();
      setState(() { _hexFileData = data; _hexFileName = result.files.single.name; _compileOutput = ''; });
    }
  }

  Future<void> _openSketch() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['ino', 'cpp', 'c']);
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      _codeController.fullText = content;
      setState(() {
        _currentSketchPath = file.path;
      });
    }
  }

  Future<void> _saveSketchAs() async {
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: '스케치 저장',
      fileName: 'sketch.ino',
      type: FileType.custom,
      allowedExtensions: ['ino', 'cpp', 'c'],
    );

    if (filePath == null || filePath.isEmpty) {
      return;
    }

    final savePath = filePath.toLowerCase().endsWith('.ino') ||
            filePath.toLowerCase().endsWith('.cpp') ||
            filePath.toLowerCase().endsWith('.c')
        ? filePath
        : '$filePath.ino';

    await File(savePath).writeAsString(_codeController.text);
    _currentSketchPath = savePath;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 완료: $savePath')),
      );
    }
  }

  Future<void> _saveSketch() async {
    if (_currentSketchPath == null || _currentSketchPath!.isEmpty) {
      await _saveSketchAs();
      return;
    }

    await File(_currentSketchPath!).writeAsString(_codeController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 완료: ${_currentSketchPath!}')),
      );
    }
  }

  Future<void> _newSketch() async {
    final hasChanges = _codeController.text.trim() != CodeEditorConfig.defaultSketch.trim();
    if (hasChanges) {
      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('새 스케치 만들기'),
          content: const Text('기존 작업 내용이 지워집니다. 계속할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('새로 만들기'),
            ),
          ],
        ),
      );

      if (shouldCreate != true) {
        return;
      }
    }

    _codeController.fullText = CodeEditorConfig.defaultSketch;
    setState(() {
      _compileOutput = '';
      _currentSketchPath = null;
    });
  }

  Future<void> _showHexHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HEX 파일이란?'),
        content: const Text(
          'HEX 파일은 이미 컴파일된 펌웨어 파일입니다.\n\n'
          '이 기능은 Android 전용 고급 옵션입니다. 소스코드 컴파일 없이, 기존 .hex를 장치에 바로 업로드할 때 사용합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 현재 에디터 내용 반환
  String get currentCode => _codeController.text;

  /// 샘플 코드를 에디터에 로드 (탭 전환 없음)
  void loadSampleToEditor(SampleCode sample) {
    // fullText를 사용해야 코드 접기(folding) 내부 상태와 충돌하지 않음
    _codeController.fullText = sample.code;
    setState(() {
      _compileOutput = '';
      _currentSketchPath = null;
    });
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildEditorTab(l10n);
  }

  // ───────── Tab 1: 직접 작성 ─────────

  Widget _buildEditorTab(AppLocalizations l10n) {
    final isAndroid = Platform.isAndroid;
    return Consumer<SerialProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 툴바
            _buildToolbar(l10n, provider, isAndroid),

            // 업로드 진행률
            if (isAndroid && _isUploading)
              LinearProgressIndicator(value: _uploadProgress),

            // 코드 에디터 + 드래그 분리선 + 출력 콘솔
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalHeight = constraints.maxHeight;
                  final consoleHeight = (totalHeight * _consoleHeightFraction).clamp(60.0, totalHeight - 80.0);
                  final editorHeight = totalHeight - consoleHeight - 6.0;
                  return Column(
                    children: [
                      SizedBox(
                        height: editorHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF272822)
                                : const Color(0xFFF8F8F8),
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
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
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeRow,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (details) {
                            setState(() {
                              final delta = details.delta.dy / totalHeight;
                              _consoleHeightFraction = (_consoleHeightFraction - delta).clamp(0.1, 0.85);
                            });
                          },
                          child: Container(
                            height: 6,
                            color: Theme.of(context).dividerColor,
                            child: Center(
                              child: Container(
                                width: 32, height: 3,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[600] : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: consoleHeight,
                        child: _buildConsole(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(AppLocalizations l10n, SerialProvider provider, bool isAndroid) {
    final fileActions = <Widget>[
      IconButton(
        onPressed: _newSketch,
        icon: const Icon(Icons.insert_drive_file),
        tooltip: l10n.newSketch,
      ),
      IconButton(
        onPressed: _openSketch,
        icon: const Icon(Icons.folder_open),
        tooltip: l10n.openSketch,
      ),
      IconButton(
        onPressed: _saveSketch,
        icon: const Icon(Icons.save),
        tooltip: '저장',
      ),
      IconButton(
        onPressed: _saveSketchAs,
        icon: const Icon(Icons.save_as),
        tooltip: '다른 이름으로 저장',
      ),
      if (isAndroid)
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showAdvancedAndroidTools = !_showAdvancedAndroidTools;
            });
          },
          icon: Icon(
            _showAdvancedAndroidTools
                ? Icons.tune
                : Icons.tune_outlined,
          ),
          label: Text(
            _showAdvancedAndroidTools
                ? '고급 숨기기'
                : '고급 보기',
          ),
        ),
      if (isAndroid && _showAdvancedAndroidTools)
        TextButton.icon(
          onPressed: _isUploading ? null : _selectHexFile,
          icon: const Icon(Icons.file_open),
          label: const Text('HEX 업로드'),
        ),
      if (isAndroid && _showAdvancedAndroidTools)
        IconButton(
          tooltip: 'HEX 파일 안내',
          onPressed: _showHexHelp,
          icon: const Icon(Icons.help_outline),
        ),
      if (isAndroid && _showAdvancedAndroidTools && _hexFileName.isNotEmpty)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            _hexFileName,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];

    final actionButtons = <Widget>[
      FilledButton.tonalIcon(
        onPressed: _isCompiling ? null : _verifySketch,
        icon: _isCompiling
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.check_circle),
        label: Text(l10n.verify),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        onPressed: (_isUploading || !provider.isConnected) ? null : () => _uploadSketch(),
        icon: _isUploading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload),
        label: Text(l10n.upload),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: fileActions),
            ),
          ),
          ...actionButtons,
        ],
      ),
    );
  }



  // ───────── 공통: 출력 콘솔 ─────────

  Widget _buildConsole() {
    return Container(
        width: double.infinity,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.grey[50],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850] : Colors.grey[200],
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal, size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 8),
                  Text('출력',
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70 : Colors.black87,
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 : Colors.black54),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _compileOutput));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('복사되었습니다'), duration: Duration(seconds: 1)),
                      );
                    },
                    tooltip: '출력 복사',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 : Colors.black54),
                    onPressed: () => setState(() => _compileOutput = ''),
                    tooltip: '출력 지우기',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _compileOutput.isEmpty ? '여기에 컴파일/업로드 결과가 표시됩니다.' : _compileOutput,
                  style: TextStyle(
                    fontFamily: CodeEditorConfig.fontFamily, fontSize: 12,
                    color: _compileOutput.isEmpty
                        ? Theme.of(context).hintColor
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.green[300] : Colors.green[700]),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

