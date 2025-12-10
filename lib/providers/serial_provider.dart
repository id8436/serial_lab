import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/services/communication_service.dart';
import 'package:serial_lab/services/usb_serial_service.dart';
import 'package:serial_lab/services/bluetooth_serial_service.dart';
import 'package:serial_lab/services/classic_bluetooth_service.dart';
import 'package:serial_lab/services/wifi_serial_service.dart';

/// 시리얼 통신 상태 관리 Provider
class SerialProvider extends ChangeNotifier {
  CommunicationService? _service;
  DeviceInfo? _currentDevice;
  List<DeviceInfo> _availableDevices = [];
  final List<SerialData> _receivedData = [];
  final List<String> _rawTextData = []; // Raw text data storage
  final Map<String, ChartSeries> _chartData = {};
  bool _isScanning = false;
  bool _isConnected = false;
  String _rawBuffer = '';
  int _baudRate = 9600; // HC-06 기본값
  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;

  // Getters
  DeviceInfo? get currentDevice => _currentDevice;
  List<DeviceInfo> get availableDevices => _availableDevices;
  List<SerialData> get receivedData => _receivedData;
  List<String> get rawTextData => _rawTextData; // Raw text data getter
  Map<String, ChartSeries> get chartData => _chartData;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get rawBuffer => _rawBuffer;
  int get baudRate => _baudRate;

  /// 기기 스캔 (BLE 전용)
  Future<void> scanDevices(ConnectionType type) async {
    if (_isScanning) {
      print('SerialProvider: Scan already in progress');
      return;
    }
    
    _isScanning = true;
    notifyListeners();

    try {
      _service = _getServiceForType(type);
      if (_service != null) {
        _availableDevices = await _service!.scanDevices();
        print('SerialProvider: Found ${_availableDevices.length} devices');
      } else {
        print('SerialProvider: Service creation failed');
        _availableDevices = [];
      }
    } catch (e) {
      print('SerialProvider: Scan error: $e');
      _availableDevices = [];
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// WiFi 기기 수동 추가
  void addWifiDevice(String name, String address) {
    final device = DeviceInfo(
      id: address,
      name: name,
      connectionType: ConnectionType.wifi,
      address: address,
    );
    _availableDevices.add(device);
    notifyListeners();
  }

  /// 보드레이트 설정
  void setBaudRate(int baudRate) {
    _baudRate = baudRate;
    notifyListeners();
  }

  /// 프로토콜을 지정하여 기기 연결
  Future<bool> connectWithProtocol(DeviceInfo device, String protocol) async {
    try {
      if (_service != null && _isConnected) {
        await disconnect();
      }

      // 사용자가 선택한 프로토콜에 따라 서비스 선택
      if (device.connectionType == ConnectionType.bluetooth) {
        if (protocol == 'Classic') {
          _service = ClassicBluetoothService();
          print('SerialProvider: Using Classic Bluetooth service (user selected)');
        } else if (protocol == 'BLE') {
          _service = BluetoothSerialService();
          print('SerialProvider: Using BLE service (user selected)');
        } else {
          _service = ClassicBluetoothService(); // HC-06은 기본적으로 Classic
          print('SerialProvider: Using default Classic Bluetooth service');
        }
      } else {
        _service = _getServiceForType(device.connectionType);
      }
      
      if (_service == null) {
        print('SerialProvider: Failed to create service for ${device.connectionType}');
        return false;
      }
      
      print('SerialProvider: Connecting with baudrate: $_baudRate');
      final success = await _service!.connect(device, baudRate: _baudRate);

      if (success) {
        _currentDevice = device;
        _isConnected = true;
        _setupDataListeners();
        print('SerialProvider: Successfully connected to ${device.name}');
      } else {
        print('SerialProvider: Failed to connect to ${device.name}');
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      print('SerialProvider: Connection error: $e');
      _isConnected = false;
      _currentDevice = null;
      notifyListeners();
      return false;
    }
  }

  /// 데이터 수신 리스너 설정
  void _setupDataListeners() {
    try {
      // 기존 리스너 정리
      _dataSubscription?.cancel();
      _connectionSubscription?.cancel();

      if (_service == null) {
        print('SerialProvider: Cannot setup listeners - service is null');
        return;
      }

      // 데이터 수신 리스너
      _dataSubscription = _service!.dataStream.listen(
        (data) {
          try {
            _handleReceivedData(data);
          } catch (e) {
            print('SerialProvider: Error handling received data: $e');
          }
        },
        onError: (error) {
          print('SerialProvider: Data stream error: $error');
        },
      );

      // 연결 상태 리스너
      _connectionSubscription = _service!.connectionStream.listen(
        (connected) {
          _isConnected = connected;
          if (!connected) {
            _currentDevice = null;
            print('SerialProvider: Device disconnected');
          }
          notifyListeners();
        },
        onError: (error) {
          print('SerialProvider: Connection stream error: $error');
        },
      );
    } catch (e) {
      print('SerialProvider: Error setting up listeners: $e');
    }
  }

  /// 기기 연결 (기본 - 하위 호환용)
  Future<bool> connect(DeviceInfo device) async {
    // 블루투스는 기본적으로 Classic 사용 (HC-06용)
    if (device.connectionType == ConnectionType.bluetooth) {
      return connectWithProtocol(device, 'Classic');
    }
    
    if (_service != null && _isConnected) {
      await disconnect();
    }

    _service = _getServiceForType(device.connectionType);
    final success = await _service!.connect(device, baudRate: _baudRate);

    if (success) {
      _currentDevice = device;
      _isConnected = true;
      _setupDataListeners();
      notifyListeners();
    }

    return success;
  }

  /// 연결 해제
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _service?.disconnect();
    
    _currentDevice = null;
    _isConnected = false;
    _rawBuffer = '';
    notifyListeners();
  }

  /// 데이터 전송
  Future<bool> sendData(Map<String, dynamic> data) async {
    if (_service == null || !_isConnected) return false;
    
    final jsonString = jsonEncode(data);
    return await _service!.sendData(jsonString);
  }

  /// 문자열 데이터 전송
  Future<bool> sendString(String data) async {
    if (_service == null || !_isConnected) return false;
    return await _service!.sendData(data);
  }

  /// 수신 데이터 처리
  void _handleReceivedData(String data) {
    try {
      if (data.isEmpty) return;
      
      _rawBuffer += data;
      
      // 줄 단위로 처리
      final lines = _rawBuffer.split('\n');
      if (lines.isEmpty) return;
      
      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // JSON 파싱 시도
        try {
          final json = jsonDecode(line);
          if (json is Map<String, dynamic>) {
            final serialData = SerialData(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              timestamp: DateTime.now(),
              data: json,
              deviceId: _currentDevice?.id,
            );

            _receivedData.add(serialData);
            _updateChartData(serialData);

            // 최대 1000개 데이터 유지
            if (_receivedData.length > 1000) {
              _receivedData.removeAt(0);
            }
          } else {
            // JSON이지만 Map이 아닌 경우 텍스트로 처리
            _addRawTextData(line);
          }
        } catch (e) {
          // JSON 파싱 실패 시 일반 텍스트로 저장
          _addRawTextData(line);
        }
      }

      _rawBuffer = lines.isNotEmpty ? lines.last : '';
      notifyListeners();
    } catch (e) {
      print('SerialProvider: Error in _handleReceivedData: $e');
    }
  }
  
  /// 원시 텍스트 데이터 추가 (안전한 방식)
  void _addRawTextData(String line) {
    try {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _rawTextData.add('[$timestamp] $line');
      
      // 최대 1000개 텍스트 데이터 유지
      if (_rawTextData.length > 1000) {
        _rawTextData.removeAt(0);
      }
    } catch (e) {
      print('SerialProvider: Error adding raw text data: $e');
    }
  }

  /// 차트 데이터 업데이트
  void _updateChartData(SerialData data) {
    data.data.forEach((key, value) {
      if (value is num) {
        final dataPoint = ChartDataPoint(
          time: data.timestamp,
          value: value.toDouble(),
          label: key,
        );

        if (_chartData.containsKey(key)) {
          _chartData[key] = _chartData[key]!.addDataPoint(dataPoint);
        } else {
          _chartData[key] = ChartSeries(
            name: key,
            dataPoints: [dataPoint],
            maxDataPoints: 100,
          );
        }
      }
    });
  }

  /// 차트 데이터 초기화
  void clearChartData() {
    _chartData.clear();
    _receivedData.clear();
    _rawTextData.clear(); // Clear raw text data too
    notifyListeners();
  }

  /// 연결 타입에 따른 서비스 생성
  CommunicationService _getServiceForType(ConnectionType type) {
    switch (type) {
      case ConnectionType.usb:
        return UsbSerialService();
      case ConnectionType.bluetooth:
        return BluetoothSerialService(); // BLE 전용
      case ConnectionType.wifi:
        return WifiSerialService();
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _service?.dispose();
    super.dispose();
  }
}
