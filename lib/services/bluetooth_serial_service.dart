import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/communication_service.dart';

/// 블루투스 시리얼 통신 서비스
class BluetoothSerialService implements CommunicationService {
  BluetoothConnection? _connection;
  StreamSubscription? _subscription;
  final _dataController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;

  @override
  Future<List<DeviceInfo>> scanDevices() async {
    try {
      // 페어링된 기기 목록
      final bondedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();

      return bondedDevices.map((device) {
        return DeviceInfo(
          id: device.address,
          name: device.name ?? 'Unknown Bluetooth Device',
          connectionType: ConnectionType.bluetooth,
          address: device.address,
        );
      }).toList();
    } catch (e) {
      print('Bluetooth scan error: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(DeviceInfo device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);

      _subscription = _connection!.input!.listen(
        (Uint8List data) {
          final str = String.fromCharCodes(data);
          _dataController.add(str);
        },
        onError: (error) {
          print('Bluetooth read error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      print('Bluetooth connect error: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _connection?.close();
    _connection = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  @override
  Future<bool> sendData(String data) async {
    if (_connection == null || !_isConnected) return false;

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(data + '\n')));
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      print('Bluetooth send error: $e');
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
    _subscription?.cancel();
    _dataController.close();
    _connectionController.close();
    _connection?.close();
  }
}
