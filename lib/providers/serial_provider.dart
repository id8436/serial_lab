import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/services/communication_service.dart';
import 'package:serial_lab/services/usb_serial_service.dart';
import 'package:serial_lab/services/bluetooth_serial_service.dart';
import 'package:serial_lab/services/wifi_serial_service.dart';

/// 시리얼 통신 상태 관리 Provider
class SerialProvider extends ChangeNotifier {
  CommunicationService? _service;
  DeviceInfo? _currentDevice;
  List<DeviceInfo> _availableDevices = [];
  final List<SerialData> _receivedData = [];
  final Map<String, ChartSeries> _chartData = {};
  bool _isScanning = false;
  bool _isConnected = false;
  String _rawBuffer = '';
  int _baudRate = 115200;
  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;

  // Getters
  DeviceInfo? get currentDevice => _currentDevice;
  List<DeviceInfo> get availableDevices => _availableDevices;
  List<SerialData> get receivedData => _receivedData;
  Map<String, ChartSeries> get chartData => _chartData;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get rawBuffer => _rawBuffer;
  int get baudRate => _baudRate;

  /// 기기 스캔
  Future<void> scanDevices(ConnectionType type) async {
    _isScanning = true;
    notifyListeners();

    try {
      _service = _getServiceForType(type);
      _availableDevices = await _service!.scanDevices();
    } catch (e) {
      print('Scan error: $e');
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

  /// 기기 연결
  Future<bool> connect(DeviceInfo device) async {
    if (_service != null && _isConnected) {
      await disconnect();
    }

    _service = _getServiceForType(device.connectionType);
    final success = await _service!.connect(device, baudRate: _baudRate);

    if (success) {
      _currentDevice = device;
      _isConnected = true;

      // 데이터 수신 리스너
      _dataSubscription = _service!.dataStream.listen((data) {
        _handleReceivedData(data);
      });

      // 연결 상태 리스너
      _connectionSubscription = _service!.connectionStream.listen((connected) {
        _isConnected = connected;
        if (!connected) {
          _currentDevice = null;
        }
        notifyListeners();
      });

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
    _rawBuffer += data;
    
    // JSON 파싱 시도
    final lines = _rawBuffer.split('\n');
    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final json = jsonDecode(line);
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
      } catch (e) {
        print('JSON parse error: $e');
      }
    }

    _rawBuffer = lines.last;
    notifyListeners();
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
    notifyListeners();
  }

  /// 연결 타입에 따른 서비스 생성
  CommunicationService _getServiceForType(ConnectionType type) {
    switch (type) {
      case ConnectionType.usb:
        return UsbSerialService();
      case ConnectionType.bluetooth:
        return BluetoothSerialService();
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
