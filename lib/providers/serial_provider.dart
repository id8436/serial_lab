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
import 'dart:collection';
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
  /// receivedData 최대 보관 개수 (메모리 상한)
  static const int _kMaxReceivedEntries = 1000;
  /// rawTextData 최대 보관 개수
  static const int _kMaxRawTextEntries = 1000;
  static const int _kMaxRecentBoards = 5;
  static const int _kDefaultBaudRate = 9600;
  static const Duration _kUsbDriverInitDelay = Duration(milliseconds: 800);

  /// 데이터 수신 tick 간격. 10fps로 제한 — Table/Chart UI는 이보다 빠르게
  /// 업데이트해도 사람이 체감할 수 없고, off-stage 페이지 rebuild 비용만 커진다.
  static const Duration _kDataTickInterval = Duration(milliseconds: 100);
  static const int _kDataParseYieldBatchSize = 80;
  Timer? _dataTickTimer;
  bool _dataTickPending = false;
  Timer? _liveSessionSaveTimer;
  final Queue<String> _incomingChunks = Queue<String>();
  bool _isDrainingIncoming = false;

  /// 고빈도 데이터 수신 전용 notifier.
  /// 차트/테이블 등 무거운 위젯은 이 notifier만 listen하고,
  /// 연결/설정 변경 같은 저빈도 이벤트에는 [notifyListeners]를 사용한다.
  final ValueNotifier<int> _dataTick = ValueNotifier<int>(0);
  ValueListenable<int> get dataTick => _dataTick;

  /// 최근 발생한 사용자 대상 오류 메시지. 연결 실패, 스캔 실패 등
  /// SnackBar로 노출할 가치가 있는 이벤트를 담는다.
  /// 읽은 뒤에는 [clearLastError]로 초기화해야 같은 오류가 다시 방출될 수 있다.
  final ValueNotifier<String?> _lastError = ValueNotifier<String?>(null);
  ValueListenable<String?> get lastError => _lastError;

  void _emitError(String message) {
    logger.d('SerialProvider: ERROR — $message');
    // 동일 메시지라도 재방출되도록 null을 먼저 끼워 넣는다.
    if (_lastError.value == message) {
      _lastError.value = null;
    }
    _lastError.value = message;
  }

  void clearLastError() {
    if (_lastError.value != null) {
      _lastError.value = null;
    }
  }

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
  DateTime? _analysisSnapshotStartAt;
  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _usbEventSubscription;

  // Getters
  DeviceInfo? get currentDevice => _currentDevice;
  List<DeviceInfo> get availableDevices => _availableDevices;
  List<SerialData> get receivedData => _receivedData;
  List<SerialData> get analysisSnapshotData {
    final startAt = _analysisSnapshotStartAt;
    if (startAt == null || _receivedData.isEmpty) {
      return _receivedData;
    }

    final startIndex = _receivedData.indexWhere(
      (row) => !row.timestamp.isBefore(startAt),
    );
    if (startIndex == -1) {
      return const <SerialData>[];
    }
    if (startIndex == 0) {
      return _receivedData;
    }
    return List<SerialData>.unmodifiable(_receivedData.sublist(startIndex));
  }
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
  bool get hasRealtimeAnalysisSource =>
      analysisSnapshotData.isNotEmpty || _receivedData.isNotEmpty;

  void _markAnalysisSnapshotBoundary() {
    _analysisSnapshotStartAt = DateTime.now();
  }

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
    unawaited(_restorePersistedSession());
  }

  // ==================== USB hot-plug ====================

  /// USB 연결/해제 이벤트 감지 (Android 전용)
  void _initUsbEventListener() {
    if (kIsWeb) return;
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
      _emitError('Scan failed: $e');
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
        _markAnalysisSnapshotBoundary();
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
      _emitError('Connection error: $e');
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
          _emitError('Data stream error: $error');
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
          _emitError('Connection stream error: $error');
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
      _markAnalysisSnapshotBoundary();
      _setupDataListeners();

      // USB 연결 시 보드 자동 감지
      if (device.connectionType == ConnectionType.usb) {
        String? detected;
        // PC: arduino-cli board list 로 정확한 FQBN 감지 시도
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
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
    if (value && !_isReceiving) {
      _markAnalysisSnapshotBoundary();
    }
    _isReceiving = value;
    notifyListeners();
  }

  /// 수신 데이터 처리
  ///
  /// Provider 차원의 [notifyListeners]는 호출하지 않는다. 대신
  /// - 새 시리즈 key가 생겼을 때만 [notifyListeners] (구조 변경)
  /// - 매 포인트 추가에는 [_scheduleDataTick] (throttled [_dataTick] bump)
  ///
  /// 이렇게 해서 설정·연결 상태만 보는 위젯(AppBar, Drawer, 컨트롤 바 등)은
  /// 데이터 흐름 동안 rebuild되지 않는다.
  void _handleReceivedData(String data) {
    if (!_isReceiving || data.isEmpty) return;
    _incomingChunks.add(data);
    if (_isDrainingIncoming) return;

    _isDrainingIncoming = true;
    unawaited(_drainIncomingChunks());
  }

  Future<void> _drainIncomingChunks() async {
    try {
      while (_incomingChunks.isNotEmpty) {
        _rawBuffer += _incomingChunks.removeFirst();
        final lines = _rawBuffer.split('\n');
        if (lines.length <= 1) {
          continue;
        }

        bool seriesKeysChanged = false;
        var processed = 0;
        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          if (_processIncomingLine(line)) {
            seriesKeysChanged = true;
          }
          processed++;
          if (processed % _kDataParseYieldBatchSize == 0) {
            // 대량 파싱 시 프레임에 제어권을 잠깐 양보해 ANR 위험을 줄인다.
            await Future<void>.delayed(Duration.zero);
          }
        }

        _rawBuffer = lines.last;
        if (seriesKeysChanged) {
          // 키 집합 변화는 저빈도 이벤트 → 전체 Provider notify
          notifyListeners();
        }
        _scheduleLiveSessionSave();
        _scheduleDataTick();

        // 청크 단위 처리 후에도 한 번 더 양보해서 입력/렌더링 지연을 줄인다.
        await Future<void>.delayed(Duration.zero);
      }
    } catch (e) {
      logger.d('SerialProvider: Error in _drainIncomingChunks: $e');
    } finally {
      _isDrainingIncoming = false;
      if (_incomingChunks.isNotEmpty) {
        _isDrainingIncoming = true;
        unawaited(_drainIncomingChunks());
      }
    }
  }

  bool _processIncomingLine(String line) {
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
        if (_receivedData.length > _kMaxReceivedEntries) {
          _receivedData.removeAt(0);
        }
        return _updateChartData(serialData);
      }

      // JSON이지만 Map이 아닌 경우 텍스트로 처리
      _addRawTextData(line);
      return false;
    } catch (_) {
      // JSON 파싱 실패 시 일반 텍스트로 저장
      _addRawTextData(line);
      return false;
    }
  }

  /// 고빈도 데이터 tick을 throttle (기본 10fps).
  /// [_dataTick]을 listen하는 위젯만 rebuild되므로 off-stage 페이지와
  /// 설정 위젯은 영향을 받지 않는다.
  void _scheduleDataTick() {
    if (_dataTickTimer?.isActive ?? false) {
      _dataTickPending = true;
      return;
    }
    _dataTick.value++;
    _dataTickTimer = Timer(_kDataTickInterval, () {
      if (_dataTickPending) {
        _dataTickPending = false;
        _dataTick.value++;
      }
    });
  }
  
  /// 원시 텍스트 데이터 추가 (안전한 방식)
  void _addRawTextData(String line) {
    try {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _rawTextData.add('[$timestamp] $line');
      if (_rawTextData.length > _kMaxRawTextEntries) {
        _rawTextData.removeAt(0);
      }
    } catch (e) {
      logger.d('SerialProvider: Error adding raw text data: $e');
    }
  }

  // ==================== chart state ====================

  /// 차트 데이터 업데이트. 새 시리즈 키가 생겼으면 `true` 반환.
  bool _updateChartData(SerialData data) {
    bool newKey = false;
    data.data.forEach((key, value) {
      if (value is num) {
        final dataPoint = ChartDataPoint(
          time: data.timestamp,
          value: value.toDouble(),
          label: key,
        );

        final series = _chartData[key];
        if (series != null) {
          series.addDataPoint(dataPoint);
        } else {
          // OOM 방지 및 성능 유지를 위해 최대 64개의 시리즈(컬럼)까지만 허용
          if (_chartData.length < 64) {
            _chartData[key] = ChartSeries(name: key, dataPoints: [dataPoint]);
            newKey = true;
          }
        }
      }
    });
    return newKey;
  }

  /// 차트 데이터 초기화
  void clearChartData() {
    _liveSessionSaveTimer?.cancel();
    _chartData.clear();
    _receivedData.clear();
    _rawTextData.clear(); // Clear raw text data too
    _analysisSnapshotStartAt = null;
    unawaited(SessionIoService.clearLiveSession());
    notifyListeners();
  }

  /// 외부에서 불러온 차트 데이터 적용
  void loadChartData(Map<String, ChartSeries> loadedData) {
    _liveSessionSaveTimer?.cancel();
    _chartData
      ..clear()
      ..addAll(loadedData);
    _receivedData.clear();
    _rawTextData.clear();
    _analysisSnapshotStartAt = null;
    _scheduleLiveSessionSave();
    notifyListeners();
  }

  // ==================== lifecycle ====================

  void _scheduleLiveSessionSave() {
    if (_chartData.isEmpty) return;

    try {
      final settingsBox = Hive.box<AppSettings>('settings');
      final settings = settingsBox.get('app_settings');
      if (settings?.autoSaveData != true) {
        return;
      }
    } catch (e) {
      logger.d('SerialProvider: Live session save skipped: $e');
      return;
    }

    _liveSessionSaveTimer?.cancel();
    _liveSessionSaveTimer = Timer(const Duration(seconds: 1), () {
      unawaited(_saveLiveSessionNow());
    });
  }

  Future<void> _saveLiveSessionNow() async {
    try {
      if (_chartData.isEmpty) return;
      final settingsBox = Hive.box<AppSettings>('settings');
      final settings = settingsBox.get('app_settings');
      if (settings?.autoSaveData != true) {
        return;
      }

      await SessionIoService.saveLiveSessionToHive(_chartData);
      logger.d('SerialProvider: Live session saved to Hive');
    } catch (e) {
      logger.d('SerialProvider: Live session save failed: $e');
      _emitError('Live session save failed: $e');
    }
  }

  Future<void> _restorePersistedSession() async {
    try {
      final settingsBox = Hive.box<AppSettings>('settings');
      final settings = settingsBox.get('app_settings');
      if (settings?.autoSaveData != true) {
        return;
      }

      if (_chartData.isNotEmpty || _receivedData.isNotEmpty) {
        return;
      }

      final restored = await SessionIoService.loadLatestPersistedSession();
      if (restored == null || restored.isEmpty) {
        return;
      }

      _chartData
        ..clear()
        ..addAll(restored);
      _analysisSnapshotStartAt = null;
      notifyListeners();
      logger.d('SerialProvider: Restored persisted chart data from Hive');
    } catch (e) {
      logger.d('SerialProvider: Restore failed: $e');
    }
  }

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
      _emitError('Auto-save failed: $e');
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
    _dataTickTimer?.cancel();
    _liveSessionSaveTimer?.cancel();
    _dataTick.dispose();
    _usbEventSubscription?.cancel();
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _service?.dispose();
    super.dispose();
  }
}
