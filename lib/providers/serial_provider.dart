/// Central state manager for serial communication.
///
/// Manages:
/// - **Device lifecycle**: scan, connect, disconnect, USB hot-plug events
/// - **Data flow**: raw text buffering, JSON parsing, chart series updates
/// - **Board detection**: delegates to [BoardDetectionService]
/// - **Auto-save**: persists chart data to Hive on disconnect
///
/// Consumed by the UI via `Provider<SerialProvider>`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:serial_lab/models/app_settings.dart';
import 'package:serial_lab/models/device_info.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/models/chart_data.dart';
import 'package:serial_lab/services/communication_service.dart';
import 'package:serial_lab/services/usb_serial_service.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:serial_lab/services/bluetooth_serial_service.dart';
import 'package:serial_lab/services/classic_bluetooth_service.dart';
import 'package:serial_lab/services/wifi_serial_service.dart';
import 'package:serial_lab/services/analysis/session_io_service.dart';
import 'package:serial_lab/services/arduino_cli_service.dart';
import 'package:serial_lab/services/board_detection_service.dart';
import 'package:serial_lab/utils/app_logger.dart';

/// 시리얼 통신 상태 관리 Provider
class SerialProvider extends ChangeNotifier {
  // --------------- limits & defaults ---------------
  static const int _kMaxDataEntries = 1000;
  static const int _kMaxRecentBoards = 5;
  static const int _kDefaultBaudRate = 9600;
  static const Duration _kUsbDriverInitDelay = Duration(milliseconds: 800);

  // UI 업데이트 throttle: 최대 60fps로 제한
  static const Duration _kUiUpdateInterval = Duration(milliseconds: 16);
  Timer? _uiUpdateTimer;
  bool _pendingNotify = false;

  CommunicationService? _service;
  DeviceInfo? _currentDevice;
  List<DeviceInfo> _availableDevices = [];
  final List<SerialData> _receivedData = [];
  final List<String> _rawTextData = []; // Raw text data storage
  final Map<String, ChartSeries> _chartData = {};
  bool _isScanning = false;
  bool _isConnected = false;
  String _rawBuffer = '';
  int _baudRate = _kDefaultBaudRate; // HC-06 기본값
  String _selectedBoard = 'arduino:avr:uno'; // 기본 보드
  final List<String> _recentBoards = []; // 최근 사용 보드
  bool _usbAutoConnect = true; // USB 자동 연결
  bool _uploadInProgress = false; // 업로드 중 auto-connect 방지
  bool _isReceiving = true; // 데이터 수신 활성화 여부
  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _usbEventSubscription;

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
  String get selectedBoard => _selectedBoard;
  List<String> get recentBoards => _recentBoards;
  bool get usbAutoConnect => _usbAutoConnect;
  bool get uploadInProgress => _uploadInProgress;
  bool get isReceiving => _isReceiving;

  /// 업로드 시작/종료 시 auto-connect 일시 잠금
  set uploadInProgress(bool value) {
    _uploadInProgress = value;
    if (value) {
      logger.d('Upload lock ON — USB auto-connect paused');
    } else {
      logger.d('Upload lock OFF — USB auto-connect resumed');
    }
  }

  SerialProvider() {
    _initUsbEventListener();
  }

  // ==================== USB hot-plug ====================

  /// USB 연결/해제 이벤트 감지 (Android 전용)
  void _initUsbEventListener() {
    if (!Platform.isAndroid) return;
    _usbEventSubscription = UsbSerial.usbEventStream?.listen((UsbEvent event) {
      logger.d('USB event: ${event.event} device=${event.device?.productName}');
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        _onUsbAttached(event.device);
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        _onUsbDetached(event.device);
      }
    });
  }

  Future<void> _onUsbAttached(UsbDevice? device) async {
    // 장치 목록 갱신
    final usbService = UsbSerialService();
    _availableDevices = await usbService.scanDevices();
    notifyListeners();

    if (!_usbAutoConnect || _isConnected || _uploadInProgress || device == null) return;

    // 연결된 USB 장치 정보로 DeviceInfo 생성
    final deviceInfo = DeviceInfo(
      id: device.deviceId.toString(),
      name: device.productName ?? '알수없음',
      connectionType: ConnectionType.usb,
      address: 'USB:${device.vid}:${device.pid}',
    );

    // 약간의 지연 후 연결 (드라이버 초기화 대기)
    await Future.delayed(_kUsbDriverInitDelay);
    logger.d('USB auto-connect: ${deviceInfo.name} (${deviceInfo.address})');
    final ok = await connect(deviceInfo);
    if (ok) {
      // 연결 성공 시 보드 자동 감지
      final detected = detectBoardFromDevice();
      if (detected != _selectedBoard) {
        logger.d('USB auto-detect board: $detected');
        setBoard(detected);
      }
    }
  }

  void _onUsbDetached(UsbDevice? device) {
    // 업로드 중에는 detach 이벤트 무시 (1200 baud touch 후 재열거)
    if (_uploadInProgress) {
      logger.d('USB detached during upload — ignored');
      // 장치 목록만 갱신
      UsbSerialService().scanDevices().then((devices) {
        _availableDevices = devices;
        notifyListeners();
      });
      return;
    }
    // 현재 연결 중인 장치가 분리된 경우
    if (_isConnected && _currentDevice?.connectionType == ConnectionType.usb) {
      final currentVidPid = _currentDevice?.address ?? '';
      final detachedVidPid = 'USB:${device?.vid}:${device?.pid}';
      if (currentVidPid == detachedVidPid || device == null) {
        logger.d('USB auto-disconnect: device detached');
        disconnect();
      }
    }
  }

  /// USB 자동 연결 설정
  void setUsbAutoConnect(bool value) {
    _usbAutoConnect = value;
    notifyListeners();
  }

  // ==================== scanning & connection ====================

  /// 기기 스캔 (BLE 전용)
  Future<void> scanDevices(ConnectionType type) async {
    if (_isScanning) {
      logger.d('SerialProvider: Scan already in progress');
      return;
    }
    
    _isScanning = true;
    notifyListeners();

    try {
      final oldService = _service;
      _service = _getServiceForType(type);
      if (!identical(oldService, _service)) {
        oldService?.dispose();
      }
      if (_service != null) {
        _availableDevices = await _service!.scanDevices();
        logger.d('SerialProvider: Found ${_availableDevices.length} devices');
      } else {
        logger.d('SerialProvider: Service creation failed');
        _availableDevices = [];
      }
    } catch (e) {
      logger.d('SerialProvider: Scan error: $e');
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

  /// 보드 선택 설정
  void setBoard(String board) {
    _selectedBoard = board;
    
    // 최근 사용 목록에 추가 (중복 제거 및 최대 _kMaxRecentBoards개)
    _recentBoards.remove(board); // 기존 항목 제거
    _recentBoards.insert(0, board); // 맨 앞에 추가
    if (_recentBoards.length > _kMaxRecentBoards) {
      _recentBoards.removeLast();
    }
    
    notifyListeners();
  }
  
  /// 연결된 기기로부터 보드 자동 감지
  String detectBoardFromDevice() {
    if (_currentDevice == null) return _selectedBoard;
    return BoardDetectionService.detect(
      _currentDevice!,
      fallback: _selectedBoard,
    );
  }

  /// 주소(USB:vid:pid)로 보드 이름 추정 (static, UI 표시용)
  static String boardDisplayNameFromAddress(String address) {
    return BoardDetectionService.displayNameFromAddress(address);
  }

  /// 프로토콜을 지정하여 기기 연결
  Future<bool> connectWithProtocol(DeviceInfo device, String protocol) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      final oldService = _service;

      // 사용자가 선택한 프로토콜에 따라 서비스 선택
      if (device.connectionType == ConnectionType.bluetooth) {
        if (protocol == 'Classic') {
          _service = ClassicBluetoothService();
          logger.d('SerialProvider: Using Classic Bluetooth service (user selected)');
        } else if (protocol == 'BLE') {
          _service = BluetoothSerialService();
          logger.d('SerialProvider: Using BLE service (user selected)');
        } else {
          _service = ClassicBluetoothService(); // HC-06은 기본적으로 Classic
          logger.d('SerialProvider: Using default Classic Bluetooth service');
        }
      } else {
        _service = _getServiceForType(device.connectionType);
      }

      if (!identical(oldService, _service)) {
        oldService?.dispose();
      }
      
      if (_service == null) {
        logger.d('SerialProvider: Failed to create service for ${device.connectionType}');
        return false;
      }
      
      logger.d('SerialProvider: Connecting with baudrate: $_baudRate');
      final success = await _service!.connect(device, baudRate: _baudRate);

      if (success) {
        _currentDevice = device;
        _isConnected = true;
        _setupDataListeners();
        logger.d('SerialProvider: Successfully connected to ${device.name}');
      } else {
        logger.d('SerialProvider: Failed to connect to ${device.name}');
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      logger.d('SerialProvider: Connection error: $e');
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
        logger.d('SerialProvider: Cannot setup listeners - service is null');
        return;
      }

      // 데이터 수신 리스너
      _dataSubscription = _service!.dataStream.listen(
        (data) {
          try {
            _handleReceivedData(data);
          } catch (e) {
            logger.d('SerialProvider: Error handling received data: $e');
          }
        },
        onError: (error) {
          logger.d('SerialProvider: Data stream error: $error');
        },
      );

      // 연결 상태 리스너
      _connectionSubscription = _service!.connectionStream.listen(
        (connected) {
          _isConnected = connected;
          if (!connected) {
            _currentDevice = null;
            logger.d('SerialProvider: Device disconnected');
          }
          notifyListeners();
        },
        onError: (error) {
          logger.d('SerialProvider: Connection stream error: $error');
        },
      );
    } catch (e) {
      logger.d('SerialProvider: Error setting up listeners: $e');
    }
  }

  /// 기기 연결 (기본 - 하위 호환용)
  Future<bool> connect(DeviceInfo device) async {
    // 블루투스는 기본적으로 Classic 사용 (HC-06용)
    if (device.connectionType == ConnectionType.bluetooth) {
      return connectWithProtocol(device, 'Classic');
    }
    
    if (_isConnected) {
      await disconnect();
    }

    final oldService = _service;
    _service = _getServiceForType(device.connectionType);
    oldService?.dispose();

    final success = await _service!.connect(device, baudRate: _baudRate);

    if (success) {
      _currentDevice = device;
      _isConnected = true;
      _setupDataListeners();

      // USB 연결 시 보드 자동 감지
      if (device.connectionType == ConnectionType.usb) {
        String? detected;
        // PC: arduino-cli board list 로 정확한 FQBN 감지 시도
        if (!Platform.isAndroid && !Platform.isIOS) {
          detected = await ArduinoCliService.detectBoard(device.address);
          if (detected != null) {
            logger.d('SerialProvider: arduino-cli detected board: $detected');
          }
        }
        // fallback: VID/PID + 이름 기반 감지
        detected ??= detectBoardFromDevice();
        if (detected != _selectedBoard) {
          logger.d('SerialProvider: Auto-detected board: $detected');
          _selectedBoard = detected;
          _recentBoards.remove(detected);
          _recentBoards.insert(0, detected);
          if (_recentBoards.length > _kMaxRecentBoards) _recentBoards.removeLast();
        }
      }

      notifyListeners();
    }

    return success;
  }

  /// 연결 해제
  Future<void> disconnect() async {
    final shouldAutoSave = _isConnected && _chartData.isNotEmpty;
    await _dataSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _service?.disconnect();

    if (shouldAutoSave) {
      await _tryAutoSaveSession();
    }
    
    _currentDevice = null;
    _isConnected = false;
    _rawBuffer = '';
    notifyListeners();
  }

  /// USB 업로드용: 수신만 중단하고 포트는 열어둔 채로 반환
  /// USB 장치가 아니거나 서비스가 없으면 null 반환
  Future<UsbPort?> pauseForUpload() async {
    if (_service is UsbSerialService) {
      await _dataSubscription?.cancel();
      await _connectionSubscription?.cancel();
      _dataSubscription = null;
      _connectionSubscription = null;
      return await (_service as UsbSerialService).pauseForUpload();
    }
    return null;
  }

  /// 포트를 외부에서 이미 닫은 후 provider 상태만 정리
  /// (Caterina/SAMD 업로드에서 기존 포트를 1200 baud touch에 사용 후 호출)
  void markDisconnected() {
    _currentDevice = null;
    _isConnected = false;
    _rawBuffer = '';
    if (_service is UsbSerialService) {
      (_service as UsbSerialService).markClosed();
    }
    notifyListeners();
  }

  /// USB 업로드 완료 후 수신 재개
  void resumeAfterUpload() {
    if (_service is UsbSerialService) {
      (_service as UsbSerialService).resumeAfterUpload();
      _setupDataListeners();
    }
  }

  // ==================== data I/O ====================

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

  /// 데이터 수신 토글
  void setReceiving(bool value) {
    _isReceiving = value;
    notifyListeners();
  }

  /// 수신 데이터 처리
  void _handleReceivedData(String data) {
    if (!_isReceiving) return;
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
      _scheduleNotify();
    } catch (e) {
      logger.d('SerialProvider: Error in _handleReceivedData: $e');
    }
  }

  /// 데이터 수신 시 UI 업데이트를 throttle하여 과도한 rebuild 방지
  void _scheduleNotify() {
    if (_uiUpdateTimer?.isActive ?? false) {
      _pendingNotify = true;
      return;
    }
    notifyListeners();
    _uiUpdateTimer = Timer(_kUiUpdateInterval, () {
      if (_pendingNotify) {
        _pendingNotify = false;
        notifyListeners();
      }
    });
  }
  
  /// 원시 텍스트 데이터 추가 (안전한 방식)
  void _addRawTextData(String line) {
    try {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _rawTextData.add('[$timestamp] $line');
      
      // 최대 _kMaxDataEntries개 텍스트 데이터 유지
      if (_rawTextData.length > _kMaxDataEntries) {
        _rawTextData.removeAt(0);
      }
    } catch (e) {
      logger.d('SerialProvider: Error adding raw text data: $e');
    }
  }

  // ==================== chart state ====================

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
          _chartData[key]!.addDataPoint(dataPoint);
        } else {
          _chartData[key] = ChartSeries(
            name: key,
            dataPoints: [dataPoint],
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

  /// 외부에서 불러온 차트 데이터 적용
  void loadChartData(Map<String, ChartSeries> loadedData) {
    _chartData
      ..clear()
      ..addAll(loadedData);
    _receivedData.clear();
    _rawTextData.clear();
    notifyListeners();
  }

  // ==================== lifecycle ====================

  Future<void> _tryAutoSaveSession() async {
    try {
      final settingsBox = Hive.box<AppSettings>('settings');
      final settings = settingsBox.get('app_settings');
      if (settings?.autoSaveData != true) {
        return;
      }

      await SessionIoService.saveAutoSessionToHive(_chartData);
      logger.d('SerialProvider: Auto-saved analysis session on disconnect');
    } catch (e) {
      logger.d('SerialProvider: Auto-save failed: $e');
    }
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
    _uiUpdateTimer?.cancel();
    _usbEventSubscription?.cancel();
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _service?.dispose();
    super.dispose();
  }
}
