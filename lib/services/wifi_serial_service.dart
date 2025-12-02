import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/communication_service.dart';

/// WiFi (WebSocket) 통신 서비스
class WifiSerialService implements CommunicationService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _dataController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;

  @override
  Future<List<DeviceInfo>> scanDevices() async {
    // WiFi 기기는 수동으로 추가하는 방식
    // 실제로는 mDNS 등을 사용할 수 있음
    return [];
  }

  @override
  Future<bool> connect(DeviceInfo device, {int baudRate = 115200}) async {
    try {
      // WebSocket 연결 (예: ws://192.168.1.100:8080)
      final uri = Uri.parse(device.address);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (data) {
          _dataController.add(data.toString());
        },
        onError: (error) {
          print('WiFi read error: $error');
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
      print('WiFi connect error: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  @override
  Future<bool> sendData(String data) async {
    if (_channel == null || !_isConnected) return false;

    try {
      _channel!.sink.add(data);
      return true;
    } catch (e) {
      print('WiFi send error: $e');
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
    _channel?.sink.close();
  }
}
