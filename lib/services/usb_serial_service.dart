import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/communication_service.dart';

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
        print('USB received: $_buffer');
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
          name: device.productName ?? 'Unknown USB Device',
          connectionType: ConnectionType.usb,
          address: 'USB:${device.vid}:${device.pid}',
        );
      }).toList();
    } catch (e) {
      print('USB scan error: $e');
      return [];
    }
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
          print('USB read error: $error');
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      print('USB connect error: $e');
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

  @override
  Future<bool> sendData(String data) async {
    if (_port == null || !_isConnected) return false;

    try {
      await _port!.write(Uint8List.fromList(utf8.encode('$data\n')));
      return true;
    } catch (e) {
      print('USB send error: $e');
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
