import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/models/sample_code.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/services/arduino_cli_service.dart';
import 'package:serial_lab/services/cloud_compile_service.dart';
import 'package:serial_lab/services/upload/android_uploader.dart';
import 'package:serial_lab/services/upload/upload_orchestrator.dart';
import 'package:serial_lab/widgets/confirm_dialog.dart';

import 'config/code_editor_config.dart';

/// Hive 에디터 박스 키
const _kEditorBox = 'editor';
const _kCodeKey = 'saved_code';

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

  Box get _editorBox => Hive.box(_kEditorBox);

  @override
  void initState() {
    super.initState();
    final String initialCode =
        _editorBox.get(_kCodeKey, defaultValue: CodeEditorConfig.defaultSketch) as String;
    _codeController = CodeController(
      text: initialCode,
      language: CodeEditorConfig.language,
    );
  }

  @override
  void dispose() {
    _editorBox.put(_kCodeKey, _codeController.text);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _compileOutput += '\n${l10n.codeSenderReconnectWaiting}\n');
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _compileOutput += '${l10n.codeSenderReconnectAttempting}\n');
    provider.setBaudRate(baudRate);
    final ok = await provider.connect(device);
    if (!mounted) return;
    setState(() => _compileOutput += ok
        ? '${l10n.codeSenderReconnectSuccess}\n'
        : '${l10n.codeSenderReconnectFailed}\n');
  }

  Future<void> _uploadSketch({String? codeOverride}) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();

    // iOS는 USB 시리얼 접근 불가
    if (Platform.isIOS) {
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.codeSenderIosUnsupported),
          backgroundColor: scheme.tertiary,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!provider.isConnected) {
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.connectDeviceFirst),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    // Android 지원 보드 체크
    if (Platform.isAndroid && !AndroidUploader.isSupportedBoard(provider.selectedBoard)) {
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.codeSenderBoardUnsupported(provider.selectedBoard)),
          backgroundColor: scheme.tertiary,
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
          final scheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.codeSenderPortNotAvailable),
              backgroundColor: scheme.error,
            ),
          );
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
        if (mounted) setState(() => _compileOutput += '\n${l10n.codeSenderReconnectComplete}\n');
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
    final l10n = AppLocalizations.of(context)!;
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.codeSenderSaveDialogTitle,
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeSenderSaveComplete(savePath))),
      );
    }
  }

  Future<void> _saveSketch() async {
    if (_currentSketchPath == null || _currentSketchPath!.isEmpty) {
      await _saveSketchAs();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    await File(_currentSketchPath!).writeAsString(_codeController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeSenderSaveComplete(_currentSketchPath!))),
      );
    }
  }

  Future<void> _newSketch() async {
    final l10n = AppLocalizations.of(context)!;
    final hasChanges = _codeController.text.trim() != CodeEditorConfig.defaultSketch.trim();
    if (hasChanges) {
      final shouldCreate = await showConfirmDialog(
        context: context,
        title: l10n.codeSenderNewSketchTitle,
        message: l10n.codeSenderNewSketchMessage,
        confirmLabel: l10n.codeSenderNewSketchConfirm,
        icon: Icons.insert_drive_file,
      );
      if (!shouldCreate) return;
    }

    _codeController.fullText = CodeEditorConfig.defaultSketch;
    setState(() {
      _compileOutput = '';
      _currentSketchPath = null;
    });
    _editorBox.put(_kCodeKey, CodeEditorConfig.defaultSketch);
  }

  Future<void> _showHexHelp() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.codeSenderHexHelpTitle),
        content: Text(l10n.codeSenderHexHelpContent),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonOk),
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
    _editorBox.put(_kCodeKey, sample.code);
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
                                  color: Theme.of(context).colorScheme.onSurface,
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
        tooltip: l10n.codeSenderTooltipSave,
      ),
      IconButton(
        onPressed: _saveSketchAs,
        icon: const Icon(Icons.save_as),
        tooltip: l10n.codeSenderTooltipSaveAs,
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
                ? l10n.codeSenderAdvancedHide
                : l10n.codeSenderAdvancedShow,
          ),
        ),
      if (isAndroid && _showAdvancedAndroidTools)
        TextButton.icon(
          onPressed: _isUploading ? null : _selectHexFile,
          icon: const Icon(Icons.file_open),
          label: Text(l10n.codeSenderHexUpload),
        ),
      if (isAndroid && _showAdvancedAndroidTools)
        IconButton(
          tooltip: l10n.codeSenderTooltipHexHelp,
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final consoleBg = isDark ? scheme.surface : scheme.surfaceContainerLowest;
    final headerBg = scheme.surfaceContainerHighest;
    final headerText = scheme.onSurfaceVariant;
    final outputColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    return Container(
        width: double.infinity,
        color: consoleBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal, size: 16, color: headerText),
                  const SizedBox(width: 8),
                  Text(l10n.codeSenderConsoleLabel,
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16, color: headerText),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _compileOutput));
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.codeSenderCopied), duration: const Duration(seconds: 1)),
                      );
                    },
                    tooltip: l10n.codeSenderTooltipCopyOutput,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: headerText),
                    onPressed: () => setState(() => _compileOutput = ''),
                    tooltip: l10n.codeSenderTooltipClearOutput,
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
                  _compileOutput.isEmpty ? l10n.codeSenderConsolePlaceholder : _compileOutput,
                  style: TextStyle(
                    fontFamily: CodeEditorConfig.fontFamily, fontSize: 12,
                    color: _compileOutput.isEmpty
                        ? Theme.of(context).hintColor
                        : outputColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

