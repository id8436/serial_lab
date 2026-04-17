/// Upload orchestrator — coordinates cloud compile + protocol-specific USB upload.
///
/// Encapsulates the complex branching logic for:
/// - Platform detection (Android vs PC)
/// - Protocol selection (STK500 / AVR109 / esptool / STM32 / BOSSA)
/// - Port management (reuse vs disconnect-reconnect)
/// - Caterina/SAMD 1200-baud-touch flow
///
/// Used by [CodeSenderScreen] to keep the Widget layer thin (UI only).
library;

import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:serial_lab/models/upload_protocol.dart';
import 'package:serial_lab/models/compile_result.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/services/arduino_cli_service.dart';
import 'package:serial_lab/services/cloud_compile_service.dart';
import 'android_uploader.dart';

/// Callback signatures used by [UploadOrchestrator].
typedef LogCallback = void Function(String message);
typedef ProgressCallback = void Function(double progress);

/// Result of an upload operation.
class UploadResult {
  /// Human-readable log output (compile + upload messages).
  final String output;

  /// Whether the upload completed successfully.
  final bool success;

  /// Whether a reconnection to the device is needed after upload.
  final bool needsReconnect;

  const UploadResult({
    required this.output,
    required this.success,
    this.needsReconnect = false,
  });
}

/// Orchestrates the full compile → upload → reconnect pipeline.
///
/// ### Android flow
/// 1. Cloud-compile the sketch (or use a pre-compiled .hex/.bin file)
/// 2. Determine upload protocol from FQBN
/// 3. Manage USB port lifecycle (pause / disconnect / 1200-baud-touch)
/// 4. Delegate to [AndroidUploader] for the actual flashing
///
/// ### PC flow
/// 1. Disconnect the serial port (arduino-cli needs exclusive access)
/// 2. Invoke `arduino-cli upload`
class UploadOrchestrator {
  // ─── Android: pre-compiled hex/bin file ────────────────────

  /// Upload an already-compiled binary file on Android.
  static Future<UploadResult> uploadPrecompiledAndroid({
    required Uint8List fileData,
    required String fqbn,
    required SerialProvider provider,
    LogCallback? onLog,
    ProgressCallback? onProgress,
  }) async {
    final log = onLog ?? (_) {};
    final protocol = AndroidUploader.getUploadProtocol(fqbn);
    final protocolName = protocol.name.toUpperCase();
    final needsDisconnect = protocol != UploadProtocol.stk500;
    final address = provider.currentDevice?.address ?? '';
    final buf = StringBuffer();

    void appendLog(String msg) {
      buf.writeln(msg);
      log(msg);
    }

    appendLog('[Board: $fqbn, Protocol: $protocolName]');
    appendLog('Uploading via USB ($protocolName)...');

    if (needsDisconnect) provider.uploadInProgress = true;

    try {
      final output = await _executeUpload(
        provider: provider,
        protocol: protocol,
        needsDisconnect: needsDisconnect,
        address: address,
        uploadFn: (port, touchPort, addr) => _doUpload(
          port: port,
          touchPort: touchPort,
          address: addr,
          binaryData: fileData,
          format: 'hex',
          fqbn: fqbn,
          onLog: appendLog,
          onProgress: onProgress,
        ),
        onLog: appendLog,
      );

      buf.writeln(output);
      final ok = _isSuccess(output);
      return UploadResult(
        output: buf.toString(),
        success: ok,
        needsReconnect: needsDisconnect || !ok,
      );
    } finally {
      provider.uploadInProgress = false;
    }
  }

  // ─── Android: compile + upload ─────────────────────────────

  /// Cloud-compile source code and upload the result on Android.
  static Future<UploadResult> compileAndUploadAndroid({
    required String code,
    required String fqbn,
    required SerialProvider provider,
    LogCallback? onLog,
    ProgressCallback? onProgress,
  }) async {
    final log = onLog ?? (_) {};
    final protocol = AndroidUploader.getUploadProtocol(fqbn);
    final needsDisconnect = protocol != UploadProtocol.stk500;
    final address = provider.currentDevice?.address ?? '';
    final compileFormat = AndroidUploader.getCompileFormat(fqbn);
    final buf = StringBuffer();

    void appendLog(String msg) {
      buf.writeln(msg);
      log(msg);
    }

    appendLog('Compiling on server...');
    if (needsDisconnect) provider.uploadInProgress = true;

    try {
      // Step 1: Cloud compile
      final result = await CloudCompileService.compile(
        code: code,
        fqbn: fqbn,
        format: compileFormat,
      );
      buf.writeln(result.output);
      if (result.requestId != null || result.compileMs != null) {
        buf.writeln(_compileMetaLine(result));
      }

      if (!result.success || result.binaryData == null) {
        final reason = result.errorCode == null
            ? 'Compile failed'
            : 'Compile failed (${result.errorCode})';
        buf.writeln(reason);
        return UploadResult(output: buf.toString(), success: false);
      }

      // Step 2: Upload binary
      appendLog('[Board: $fqbn, Protocol: ${protocol.name.toUpperCase()}, Format: ${result.format}]');
      appendLog('Uploading to device...');

      final output = await _executeUpload(
        provider: provider,
        protocol: protocol,
        needsDisconnect: needsDisconnect,
        address: address,
        uploadFn: (port, touchPort, addr) => _doUpload(
          port: port,
          touchPort: touchPort,
          address: addr,
          binaryData: result.binaryData!,
          format: result.format,
          fqbn: fqbn,
          onLog: appendLog,
          onProgress: onProgress,
        ),
        onLog: appendLog,
      );

      buf.writeln(output);
      final ok = _isSuccess(output);
      return UploadResult(
        output: buf.toString(),
        success: ok,
        needsReconnect: needsDisconnect || !ok,
      );
    } finally {
      provider.uploadInProgress = false;
    }
  }

  // ─── PC: arduino-cli upload ────────────────────────────────

  /// Upload via arduino-cli on desktop platforms.
  static Future<UploadResult> uploadPc({
    required String code,
    required String fqbn,
    required String port,
    required SerialProvider provider,
  }) async {
    // arduino-cli needs exclusive port access
    if (provider.isConnected) await provider.disconnect();

    final output = await ArduinoCliService.uploadSketch(
      code: code,
      fqbn: fqbn,
      port: port,
    );

    final ok = output.toLowerCase().contains('success') ||
        (!output.toLowerCase().contains('error') &&
            !output.toLowerCase().contains('failed'));

    return UploadResult(
      output: output,
      success: ok,
      needsReconnect: true,
    );
  }

  // ─── Internal helpers ──────────────────────────────────────

  /// Manages port lifecycle based on protocol, then invokes [uploadFn].
  ///
  /// - **STK500**: reuse the open port via [provider.pauseForUpload]
  /// - **AVR109 / BOSSA**: grab the existing port for 1200-baud-touch,
  ///   then let [AndroidUploader] close it and re-enumerate
  /// - **esptool / STM32**: simply disconnect first
  static Future<String> _executeUpload({
    required SerialProvider provider,
    required UploadProtocol protocol,
    required bool needsDisconnect,
    required String address,
    required Future<String> Function(UsbPort? port, UsbPort? touchPort, String address) uploadFn,
    required LogCallback onLog,
  }) async {
    if (!needsDisconnect) {
      // STK500: try reusing the open port
      final openPort = await provider.pauseForUpload();
      if (openPort != null) {
        final result = await uploadFn(openPort, null, address);
        if (_isSuccess(result)) {
          provider.resumeAfterUpload();
        }
        return result;
      }
      // Fallback: disconnect and open fresh
      if (provider.isConnected) await provider.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));
      return uploadFn(null, null, address);
    }

    // Protocols that need disconnect (AVR109, BOSSA, esptool, STM32)
    if (protocol == UploadProtocol.avr109 || protocol == UploadProtocol.bossa) {
      // Grab existing port for 1200-baud-touch (avoids permission dialog)
      final existingPort = await provider.pauseForUpload();
      provider.markDisconnected();
      await Future.delayed(const Duration(milliseconds: 300));
      return uploadFn(null, existingPort, address);
    }

    // esptool / STM32: simple disconnect
    if (provider.isConnected) await provider.disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    return uploadFn(null, null, address);
  }

  /// Delegates to [AndroidUploader.uploadBinary] with correct params.
  static Future<String> _doUpload({
    UsbPort? port,
    UsbPort? touchPort,
    required String address,
    required Uint8List binaryData,
    required String format,
    required String fqbn,
    LogCallback? onLog,
    ProgressCallback? onProgress,
  }) async {
    // If we have an open port (STK500 reuse path), use ViaPort variants
    if (port != null && format == 'hex') {
      return AndroidUploader.uploadHexViaPort(
        hexContent: String.fromCharCodes(binaryData),
        fqbn: fqbn,
        port: port,
        onLog: onLog,
        onProgress: onProgress,
      );
    }

    return AndroidUploader.uploadBinary(
      binaryData: binaryData,
      format: format,
      fqbn: fqbn,
      deviceAddress: address,
      touchPort: touchPort,
      onLog: onLog,
      onProgress: onProgress,
    );
  }

  static String _compileMetaLine(CompileResult result) {
    final parts = <String>[];
    if (result.requestId != null && result.requestId!.isNotEmpty) {
      parts.add('request_id=${result.requestId}');
    }
    if (result.compileMs != null) {
      parts.add('compile_ms=${result.compileMs}');
    }
    if (result.errorCode != null && result.errorCode!.isNotEmpty) {
      parts.add('error_code=${result.errorCode}');
    }
    return parts.isEmpty ? '' : '[${parts.join(', ')}]';
  }

  static bool _isSuccess(String output) {
    return output.contains('✅') || output.toLowerCase().contains('success');
  }
}
