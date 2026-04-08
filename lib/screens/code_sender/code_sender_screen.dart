import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'funcs/arduino_cli_helper.dart';
import 'funcs/android_uploader.dart';
import 'funcs/code_editor_config.dart';
import 'funcs/sample_codes.dart';
import 'package:serial_lab/services/cloud_compile_service.dart';
import 'package:serial_lab/l10n/app_localizations.dart';

/// 코드 전송 화면 - 하단 탭: 직접 작성 / 샘플 코드
class CodeSenderScreen extends StatefulWidget {
  const CodeSenderScreen({super.key});

  @override
  State<CodeSenderScreen> createState() => CodeSenderScreenState();
}

class CodeSenderScreenState extends State<CodeSenderScreen> {
  late CodeController _codeController;
  String _compileOutput = '';
  bool _isCompiling = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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
        setState(() => _compileOutput = '${AppLocalizations.of(context)!.compilingOnServer}\n');
        final result = await CloudCompileService.compile(
          code: _codeController.text,
          fqbn: provider.selectedBoard,
        );
        setState(() => _compileOutput = result.output);
      } else {
        final output = await ArduinoCliHelper.verifySketch(
          code: _codeController.text, fqbn: provider.selectedBoard);
        setState(() => _compileOutput = output);
      }
    } finally {
      setState(() => _isCompiling = false);
    }
  }

  Future<void> _uploadSketch({String? codeOverride}) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SerialProvider>();

    if (!provider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.connectDeviceFirst), backgroundColor: Colors.red));
      return;
    }

    // Android: cloud compile + STK500 upload
    if (Platform.isAndroid) {
      // If a .hex file is selected and no code override, upload it directly
      if (_hexFileData != null && codeOverride == null) {
        setState(() { _isUploading = true; _uploadProgress = 0; _compileOutput = 'Uploading via USB (STK500)...\n'; });
        try {
          final port = provider.currentDevice?.address ?? '';
          if (provider.isConnected) await provider.disconnect();
          final output = await AndroidUploader.uploadHex(
            hexContent: String.fromCharCodes(_hexFileData!),
            fqbn: provider.selectedBoard, deviceAddress: port,
            onLog: (m) => setState(() => _compileOutput += '$m\n'),
            onProgress: (p) => setState(() { _uploadProgress = p; }),
          );
          setState(() => _compileOutput += '\n$output');
        } finally {
          setState(() { _isUploading = false; _uploadProgress = 0; });
        }
        return;
      }

      // Cloud compile then upload
      final code = codeOverride ?? _codeController.text;
      setState(() { _isUploading = true; _uploadProgress = 0; _compileOutput = '${l10n.compilingOnServer}\n'; });
      try {
        // Step 1: Compile on server
        final result = await CloudCompileService.compile(
          code: code, fqbn: provider.selectedBoard);
        setState(() => _compileOutput += '${result.output}\n');

        if (!result.success || result.binaryData == null) {
          setState(() => _compileOutput += '\n${l10n.compileFailed}');
          return;
        }

        // Step 2: Upload binary via USB
        setState(() => _compileOutput += '\n${l10n.uploadingToDevice}\n');
        final port = provider.currentDevice?.address ?? '';
        if (provider.isConnected) await provider.disconnect();
        final output = await AndroidUploader.uploadFromBytes(
          hexBytes: result.binaryData!,
          fqbn: provider.selectedBoard, deviceAddress: port,
          onLog: (m) => setState(() => _compileOutput += '$m\n'),
          onProgress: (p) => setState(() { _uploadProgress = p; }),
        );
        setState(() => _compileOutput += '\n$output');
      } finally {
        setState(() { _isUploading = false; _uploadProgress = 0; });
      }
      return;
    }

    // PC: arduino-cli
    final code = codeOverride ?? _codeController.text;
    setState(() { _isUploading = true; _compileOutput = ''; });
    try {
      final port = provider.currentDevice?.address ?? 'COM3';
      final output = await ArduinoCliHelper.uploadSketch(
        code: code, fqbn: provider.selectedBoard, port: port);
      setState(() => _compileOutput = output);
    } finally {
      setState(() => _isUploading = false);
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
      setState(() => _codeController.text = content);
    }
  }

  void _newSketch() {
    setState(() { _codeController.text = CodeEditorConfig.defaultSketch; _compileOutput = ''; });
  }

  /// 샘플 코드를 에디터에 로드 (탭 전환 없음)
  void loadSampleToEditor(SampleCode sample) {
    setState(() {
      _codeController.text = sample.code;
      _compileOutput = '';
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

            // Android 안내 배너
            if (isAndroid)
              _buildAndroidBanner(l10n),

            // 업로드 진행률
            if (isAndroid && _isUploading)
              LinearProgressIndicator(value: _uploadProgress),

            // 코드 에디터
            Expanded(
              flex: 3,
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

            // 출력 콘솔
            _buildConsole(),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(AppLocalizations l10n, SerialProvider provider, bool isAndroid) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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

          // Android .hex
          if (isAndroid) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.file_open),
              tooltip: l10n.androidSelectHex,
              onPressed: _isUploading ? null : _selectHexFile,
            ),
            if (_hexFileName.isNotEmpty)
              Flexible(
                child: Text(_hexFileName,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                    overflow: TextOverflow.ellipsis),
              ),
          ],

          const Spacer(),

          // Verify
          FilledButton.tonalIcon(
            onPressed: _isCompiling ? null : _verifySketch,
            icon: _isCompiling
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle),
            label: Text(l10n.verify),
          ),
          const SizedBox(width: 8),

          // Upload
          FilledButton.icon(
            onPressed: (_isUploading || !provider.isConnected) ? null : () => _uploadSketch(),
            icon: _isUploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload),
            label: Text(l10n.upload),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.androidCloudCompileDesc,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }



  // ───────── 공통: 출력 콘솔 ─────────

  Widget _buildConsole() {
    return Expanded(
      flex: 2,
      child: Container(
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
                    icon: Icon(Icons.clear, size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 : Colors.black54),
                    onPressed: () => setState(() => _compileOutput = ''),
                    tooltip: '출력 지우기',
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
      ),
    );
  }
}

