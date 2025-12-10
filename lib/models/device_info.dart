import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

/// 연결 타입
enum ConnectionType {
  usb,
  bluetooth,
  wifi,
}

/// 기기 정보 모델
@JsonSerializable()
class DeviceInfo {
  final String id;
  final String name;
  final ConnectionType connectionType;
  final String address; // USB 포트, Bluetooth MAC, WiFi IP
  final bool isConnected;
  final DateTime? lastConnected;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    this.isConnected = false,
    this.lastConnected,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  DeviceInfo copyWith({
    String? id,
    String? name,
    ConnectionType? connectionType,
    String? address,
    bool? isConnected,
    DateTime? lastConnected,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }
}
