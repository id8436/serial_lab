/// Abstract interface for serial communication backends.
///
/// Implementations:
/// - [UsbSerialService]  — USB OTG via `usb_serial` package (Android)
/// - [BluetoothSerialService] — BLE via `flutter_blue_plus`
/// - [ClassicBluetoothService] — Classic BT SPP (HC-06 등)
/// - [WifiSerialService] — TCP socket
library;

import 'dart:async';
import 'package:serial_lab/models/device_info.dart';

/// Scan → Connect → Send/Receive → Disconnect lifecycle.
abstract class CommunicationService {
  /// 사용 가능한 기기 목록 스캔
  Future<List<DeviceInfo>> scanDevices();

  /// 기기에 연결
  Future<bool> connect(DeviceInfo device, {int baudRate = 115200});

  /// 연결 해제
  Future<void> disconnect();

  /// 데이터 전송
  Future<bool> sendData(String data);

  /// 데이터 수신 스트림
  Stream<String> get dataStream;

  /// 연결 상태 스트림
  Stream<bool> get connectionStream;

  /// 현재 연결 상태
  bool get isConnected;

  /// 리소스 정리
  void dispose();
}
