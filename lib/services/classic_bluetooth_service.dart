import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/communication_service.dart';

/// Classic Bluetooth 통신 서비스 (HC-05, HC-06 등)
class ClassicBluetoothService implements CommunicationService {
  BluetoothConnection? _connection;
  final StreamController<String> _dataController = StreamController<String>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;
  StreamSubscription? _dataSubscription;
  
  // 버퍼링을 위한 변수들
  List<int> _byteBuffer = []; // 바이트 단위 버퍼
  Timer? _bufferTimer;
  static const Duration _bufferTimeout = Duration(milliseconds: 50); // 아두이노와 맞춤

  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  @override
  bool get isConnected => _isConnected;

  // 데이터 버퍼링 처리 (바이트 단위)
  void _handleIncomingBytes(Uint8List bytes) {
    try {
      if (bytes.isEmpty) return;
      
      // 바이트 버퍼에 추가
      _byteBuffer.addAll(bytes);
      print('Classic BT byte buffer updated: ${_byteBuffer.length} bytes');
      
      // 기존 타이머 취소
      _bufferTimer?.cancel();
      
      // 새 타이머 시작 (50ms 후 버퍼 비우기)
      _bufferTimer = Timer(_bufferTimeout, () {
        try {
          if (_byteBuffer.isNotEmpty && !_dataController.isClosed) {
            // UTF-8 디코딩 시도
            String decodedString = _decodeUtf8Safely(_byteBuffer);
            if (decodedString.isNotEmpty) {
              print('Classic BT sending to provider: "$decodedString"');
              _dataController.add(decodedString);
            }
            _byteBuffer.clear();
          }
        } catch (e) {
          print('Classic BT: Error sending buffered data: $e');
        }
      });
    } catch (e) {
      print('Classic BT: Error in _handleIncomingBytes: $e');
    }
  }
  
  // 안전한 UTF-8 디코딩
  String _decodeUtf8Safely(List<int> bytes) {
    try {
      // 전체 바이트를 디코딩 시도
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      print('Classic BT: UTF-8 decode error: $e');
      // 실패시 Latin-1로 폴백
      return String.fromCharCodes(bytes);
    }
  }

  @override
  Future<List<DeviceInfo>> scanDevices() async {
    try {
      print('Classic BT: Starting device scan...');
      
      // 블루투스 활성화 확인
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        print('Classic BT: Bluetooth not enabled');
        return [];
      }

      // 페어링된 기기 목록 가져오기
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      List<DeviceInfo> devices = [];
      for (BluetoothDevice device in bondedDevices) {
        try {
          devices.add(DeviceInfo(
            id: device.address ?? 'unknown',
            name: device.name ?? 'Unknown Device',
            connectionType: ConnectionType.bluetooth,
            address: device.address,
          ));
        } catch (e) {
          print('Classic BT: Error processing device ${device.name}: $e');
        }
      }

      print('Classic BT: Found ${devices.length} bonded devices');
      return devices;
    } catch (e) {
      print('Classic BT: Scan error: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(DeviceInfo device, {int baudRate = 9600}) async {
    try {
      if (_isConnected) {
        print('Classic BT: Already connected, disconnecting first...');
        await disconnect();
      }

      if (device.address == null || device.address!.isEmpty) {
        print('Classic BT: Invalid device address');
        return false;
      }

      print('Classic BT: Connecting to ${device.name} (${device.address})');
      
      // 블루투스 기기에 연결 (시간 제한 추가)
      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timeout after 15 seconds');
        },
      );
      
      if (_connection != null && _connection!.isConnected) {
        _isConnected = true;
        
        // 데이터 수신 리스너 설정
        _dataSubscription = _connection!.input?.listen(
          (Uint8List data) {
            try {
              if (data.isNotEmpty) {
                print('Classic BT RAW received: ${data.length} bytes');
                // 바이트 단위로 처리
                _handleIncomingBytes(data);
              }
            } catch (e) {
              print('Classic BT: Error processing received data: $e');
            }
          },
          onDone: () {
            print('Classic BT: Connection closed by remote');
            _isConnected = false;
            if (!_connectionController.isClosed) {
              _connectionController.add(false);
            }
          },
          onError: (error) {
            print('Classic BT: Data stream error: $error');
            _isConnected = false;
            if (!_connectionController.isClosed) {
              _connectionController.add(false);
            }
          },
        );

        if (!_connectionController.isClosed) {
          _connectionController.add(true);
        }
        print('Classic BT: Connected successfully');
        return true;
      } else {
        print('Classic BT: Failed to establish connection');
        return false;
      }
    } on TimeoutException catch (e) {
      print('Classic BT: Connection timeout: $e');
      _isConnected = false;
      if (!_connectionController.isClosed) {
        _connectionController.add(false);
      }
      return false;
    } catch (e) {
      print('Classic BT: Connection error: $e');
      _isConnected = false;
      if (!_connectionController.isClosed) {
        _connectionController.add(false);
      }
      return false;
    }
  }

  @override
  Future<bool> sendData(String data) async {
    try {
      if (_connection != null && _connection!.isConnected) {
        // UTF-8 인코딩으로 한글 지원
        List<int> bytes = utf8.encode(data);
        _connection!.output.add(Uint8List.fromList(bytes));
        await _connection!.output.allSent;
        print('Classic BT sent: "$data" (${bytes.length} bytes)');
        return true;
      } else {
        print('Classic Bluetooth not connected');
        return false;
      }
    } catch (e) {
      print('Classic Bluetooth send error: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      print('Classic BT: Disconnecting...');
      _isConnected = false;
      
      // 버퍼 타이머 취소
      _bufferTimer?.cancel();
      _bufferTimer = null;
      
      // 데이터 리스너 취소
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      // 연결 종료
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }
      
      // 버퍼 정리
      _byteBuffer.clear();
      
      // 연결 상태 알림
      if (!_connectionController.isClosed) {
        _connectionController.add(false);
      }
      
      print('Classic BT: Disconnected successfully');
    } catch (e) {
      print('Classic BT: Disconnect error: $e');
    }
  }

  @override
  void dispose() {
    try {
      print('Classic BT: Disposing service...');
      
      // 비동기 작업을 대기하지 않고 즉시 정리
      _isConnected = false;
      _bufferTimer?.cancel();
      _bufferTimer = null;
      _dataSubscription?.cancel();
      _dataSubscription = null;
      _connection?.close();
      _connection = null;
      _buffer = '';
      
      // 스트림 컸트롤러 닫기
      if (!_dataController.isClosed) {
        _dataController.close();
      }
      if (!_connectionController.isClosed) {
        _connectionController.close();
      }
      
      print('Classic BT: Service disposed');
    } catch (e) {
      print('Classic BT: Error during dispose: $e');
    }
  }
}