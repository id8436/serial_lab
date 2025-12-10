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
        print('WiFi received: $_buffer');
        _buffer = '';
      }
    });
  }

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
          _handleIncomingData(data.toString()); // 버퍼링 처리 사용
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
    _bufferTimer?.cancel();
    _subscription?.cancel();
    _dataController.close();
    _connectionController.close();
    _channel?.sink.close();
  }
}
