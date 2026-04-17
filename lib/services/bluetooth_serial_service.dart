/// BLE (Bluetooth Low Energy) serial transport.
///
/// Uses flutter_blue_plus to connect to BLE peripherals with a Nordic UART
/// Service (NUS) or similar TX/RX characteristic pair.
///
/// Implements [CommunicationService] — see that file for the interface contract.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/services/communication_service.dart';
import 'package:serial_lab/utils/app_logger.dart';

/// 블루투스 시리얼 통신 서비스
class BluetoothSerialService implements CommunicationService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription? _subscription;
  final _dataController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;
  
  // 버퍼링을 위한 변수들
  String _buffer = '';
  Timer? _bufferTimer;
  static const Duration _bufferTimeout = Duration(milliseconds: 10); // 50ms → 10ms로 단축

  // 데이터 버퍼링 처리
  void _handleIncomingData(String data) {
    _buffer += data;
    logger.d('BT raw data: "$data" (${data.codeUnits})');
    
    // 기존 타이머 취소
    _bufferTimer?.cancel();
    
    // 새 타이머 시작 (10ms 후 버퍼 비우기)
    _bufferTimer = Timer(_bufferTimeout, () {
      if (_buffer.isNotEmpty) {
        // 버퍼된 데이터를 한 번에 전송
        _dataController.add(_buffer);
        logger.d('BT received complete: "$_buffer"');
        logger.d('BT sending to SerialProvider: "$_buffer"');
        _buffer = '';
      }
    });
  }

  @override
  Future<List<DeviceInfo>> scanDevices() async {
    try {
      // 블루투스가 지원되는지 확인
      if (await FlutterBluePlus.isSupported == false) {
        logger.d('Bluetooth not supported by this device');
        return [];
      }

      // 블루투스 어댑터 상태 확인
      BluetoothAdapterState adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        logger.d('Bluetooth is not turned on');
        return [];
      }

      // 권한 확인 및 요청
      await FlutterBluePlus.turnOn();

      // 스캔 시작 (짧은 시간)
      List<ScanResult> scanResults = [];
      
      // 스캔 결과를 수집하는 구독 시작
      late StreamSubscription subscription;
      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          // 중복 제거
          if (!scanResults.any((r) => r.device.remoteId == result.device.remoteId)) {
            scanResults.add(result);
          }
        }
      });
      
      // 스캔 시작
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      
      // 스캔 완료 대기
      await Future.delayed(Duration(seconds: 5));
      
      // 스캔 중지 및 구독 취소
      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      // 결과 변환
      List<DeviceInfo> devices = [];
      Set<String> deviceAddresses = {};

      // 스캔 결과 추가
      for (ScanResult result in scanResults) {
        if (deviceAddresses.add(result.device.remoteId.toString())) {
          devices.add(DeviceInfo(
            id: result.device.remoteId.toString(),
            name: result.device.platformName.isNotEmpty 
                ? result.device.platformName 
                : result.advertisementData.advName.isNotEmpty
                    ? result.advertisementData.advName
                    : 'Unknown Bluetooth Device',
            connectionType: ConnectionType.bluetooth,
            address: result.device.remoteId.toString(),
          ));
        }
      }

      return devices;
    } catch (e) {
      logger.d('Bluetooth scan error: $e');
      return [];
    }
  }

  @override
  Future<bool> connect(DeviceInfo device, {int baudRate = 115200}) async {
    try {
      // 기존 연결이 있다면 정리
      if (_device != null) {
        await disconnect();
      }

      // 기기 찾기
      _device = BluetoothDevice.fromId(device.address);
      
      // 연결 (재시도 로직 포함)
      int maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
          await _device!.connect(
            license: License.free,
            timeout: const Duration(seconds: 10),
            autoConnect: false, // 자동 재연결 비활성화 (수동 관리)
          );
          break;
        } catch (e) {
          if (i == maxRetries - 1) {
            rethrow;
          }
          await Future.delayed(const Duration(seconds: 1));
          logger.d('Connection attempt ${i + 1} failed, retrying...');
        }
      }
      
      // 서비스 검색
      List<BluetoothService> services = await _device!.discoverServices();
      
      // 시리얼 통신용 특성 찾기 (더 많은 UUID 확인)
      BluetoothCharacteristic? writeChar;
      
      for (BluetoothService service in services) {
        logger.d('Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          logger.d('  Characteristic UUID: ${characteristic.uuid}');
          logger.d('  Properties: write=${characteristic.properties.write}, '
                'writeWithoutResponse=${characteristic.properties.writeWithoutResponse}, '
                'notify=${characteristic.properties.notify}, '
                'indicate=${characteristic.properties.indicate}');
          
          // 쓰기 가능한 특성 찾기
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writeChar = characteristic;
            logger.d('  -> Found write characteristic');
            
            // 같은 특성이 알림도 지원하면 이것을 우선 선택
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              _characteristic = characteristic;
              logger.d('  -> This characteristic supports both write and notify!');
              break;
            }
          }
        }
        if (_characteristic != null) break;
      }
      
      // 하나의 특성이 읽기/쓰기를 모두 지원하지 않는 경우, 쓰기 우선 선택
      if (_characteristic == null && writeChar != null) {
        _characteristic = writeChar;
        logger.d('Using write-only characteristic: ${_characteristic!.uuid}');
      }

      if (_characteristic == null) {
        logger.d('No suitable characteristic found');
        await _device!.disconnect();
        return false;
      }

      // 알림 구독 (가능한 경우만)
      if (_characteristic!.properties.notify || _characteristic!.properties.indicate) {
        await _characteristic!.setNotifyValue(true);
        
        _subscription = _characteristic!.lastValueStream.listen(
          (List<int> data) {
            final str = String.fromCharCodes(data);
            _handleIncomingData(str); // 버퍼링 처리 사용
          },
          onError: (error) {
            logger.d('Bluetooth read error: $error');
            _handleConnectionLoss();
          },
        );
      }

      // 연결 상태 모니터링
      _device!.connectionState.listen((BluetoothConnectionState state) {
        bool connected = state == BluetoothConnectionState.connected;
        if (_isConnected != connected) {
          _isConnected = connected;
          _connectionController.add(connected);
          
          if (!connected) {
            logger.d('Connection lost, device state: $state');
            _handleConnectionLoss();
          }
        }
      });

      _isConnected = true;
      _connectionController.add(true);
      logger.d('Successfully connected to ${device.name}');
      return true;
    } catch (e) {
      logger.d('Bluetooth connect error: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  // 연결 끊김 처리
  void _handleConnectionLoss() {
    _isConnected = false;
    _connectionController.add(false);
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      if (_characteristic != null) {
        await _characteristic!.setNotifyValue(false);
      }
      if (_device != null) {
        await _device!.disconnect();
      }
      _device = null;
      _characteristic = null;
      _isConnected = false;
      _connectionController.add(false);
    } catch (e) {
      logger.d('Disconnect error: $e');
    }
  }

  @override
  Future<bool> sendData(String data) async {
    if (_characteristic == null || !_isConnected) {
      logger.d('Cannot send: characteristic is null or not connected');
      return false;
    }

    try {
      logger.d('Attempting to send: "$data"');
      
      // 특성의 쓰기 속성 확인
      if (!_characteristic!.properties.write && !_characteristic!.properties.writeWithoutResponse) {
        logger.d('Characteristic does not support write operations');
        return false;
      }

      // 데이터 전송 (여러 방법 시도)
      List<int> bytes = utf8.encode('$data\n');
      logger.d('Sending bytes: $bytes');
      
      if (_characteristic!.properties.writeWithoutResponse) {
        // WriteWithoutResponse 시도
        await _characteristic!.write(bytes, withoutResponse: true);
        logger.d('Sent with writeWithoutResponse');
      } else if (_characteristic!.properties.write) {
        // Write 시도
        await _characteristic!.write(bytes, withoutResponse: false);
        logger.d('Sent with write');
      }
      
      return true;
    } catch (e) {
      logger.d('Bluetooth send error: $e');
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
    _device?.disconnect();
  }
}
