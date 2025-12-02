import 'dart:async';
import 'package:serial_lab/models/device_info.dart';

/// 통신 서비스 인터페이스
abstract class CommunicationService {
  /// 사용 가능한 기기 목록 스캔
  Future<List<DeviceInfo>> scanDevices();

  /// 기기에 연결
  Future<bool> connect(DeviceInfo device);

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
