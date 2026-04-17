/// USB serial (CDC/ACM) transport — the primary connection method.
///
/// Uses usb_serial package for Android USB Host API access.
/// Handles DTR/RTS line control, baud rate changes, and raw byte I/O.
///
/// Implements [CommunicationService] — see that file for the interface contract.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/communication_service.dart';
import 'package:serial_lab/utils/app_logger.dart';

/// USB 시리얼 통신 서비스
class UsbSerialService implements CommunicationService {
  UsbPort? _port;
  StreamSubscription? _subscription;
  final _dataController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;
  
  // 버퍼링을 위한 변수들
  String _buffer = '';
  Timer? _bufferTimer;
  static const Duration _bufferTimeout = Duration(milliseconds: 50);

  // 데이터 버퍼링 처리
  void _handleIncomingData(String data) {
    _buffer += data;
    
    // 기존 타이머 취소
    _bufferTimer?.cancel();
    
    // 새 타이머 시작 (50ms 후 버퍼 비우기)
    _bufferTimer = Timer(_bufferTimeout, () {
      if (_buffer.isNotEmpty) {
        // 버퍼된 데이터를 한 번에 전송
        _dataController.add(_buffer);
        logger.d('USB received: $_buffer');
        _buffer = '';
      }
    });
  }

  @override
  Future<List<DeviceInfo>> scanDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      return devices.map((device) {
        return DeviceInfo(
          id: device.deviceId.toString(),
          name: _resolveDeviceName(device.productName, device.vid, device.pid),
          connectionType: ConnectionType.usb,
          address: 'USB:${device.vid}:${device.pid}',
        );
      }).toList();
    } catch (e) {
      logger.d('USB scan error: $e');
      return [];
    }
  }

  static const _genericNames = {
    'usb serial', 'usb serial device', 'usb2serial', 'usb-serial',
    'serial', 'cdc', 'cdc acm', 'composite gadget', 'unknown',
  };

  static String _resolveDeviceName(String? productName, int? vid, int? pid) {
    final name = productName?.trim() ?? '';
    if (name.isEmpty || _genericNames.contains(name.toLowerCase())) {
      final vidStr = vid != null ? vid.toRadixString(16).padLeft(4, '0') : '????';
      final pidStr = pid != null ? pid.toRadixString(16).padLeft(4, '0') : '????';
      return '알수없음 ($vidStr:$pidStr)';
    }
    return name;
  }

  @override
  Future<bool> connect(DeviceInfo device, {int baudRate = 115200}) async {
    try {
      final devices = await UsbSerial.listDevices();
      final usbDevice = devices.firstWhere(
        (d) => d.deviceId.toString() == device.id,
      );

      _port = await usbDevice.create();
      if (_port == null) return false;

      bool opened = await _port!.open();
      if (!opened) return false;

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _subscription = _port!.inputStream?.listen(
        (Uint8List data) {
          final str = String.fromCharCodes(data);
          _handleIncomingData(str); // 버퍼링 처리 사용
        },
        onError: (error) {
          logger.d('USB read error: $error');
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      logger.d('USB connect error: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _port?.close();
    _port = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// 업로드 전 수신 리스너만 중단 (포트는 열어둠)
  Future<UsbPort?> pauseForUpload() async {
    await _subscription?.cancel();
    _subscription = null;
    _bufferTimer?.cancel();
    _buffer = '';
    return _port;
  }

  /// 외부에서 포트를 닫은 뒤 내부 상태만 정리
  void markClosed() {
    _port = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// 업로드 후 수신 리스너 재개
  void resumeAfterUpload() {
    if (_port == null) return;
    _subscription = _port!.inputStream?.listen(
      (Uint8List data) {
        final str = String.fromCharCodes(data);
        _handleIncomingData(str);
      },
      onError: (error) {
        logger.d('USB read error: $error');
      },
    );
  }

  @override
  Future<bool> sendData(String data) async {
    if (_port == null || !_isConnected) return false;

    try {
      await _port!.write(Uint8List.fromList(utf8.encode('$data\n')));
      return true;
    } catch (e) {
      logger.d('USB send error: $e');
      return false;
    }
  }

  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  void dispose() {
    _bufferTimer?.cancel();
    _subscription?.cancel();
    _dataController.close();
    _connectionController.close();
    _port?.close();
  }
}
