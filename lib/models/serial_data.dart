import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'serial_data.g.dart';

/// 시리얼 통신으로 주고받는 데이터 모델
@JsonSerializable()
class SerialData {
  final String id;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? deviceId;
  
  SerialData({
    required this.id,
    required this.timestamp,
    required this.data,
    this.deviceId,
  });

  factory SerialData.fromJson(Map<String, dynamic> json) =>
      _$SerialDataFromJson(json);

  Map<String, dynamic> toJson() => _$SerialDataToJson(this);

  /// JSON 문자열에서 직접 파싱
  static SerialData? tryParse(String jsonString) {
    try {
      final Map<String, dynamic> json = 
          Map<String, dynamic>.from(jsonDecode(jsonString));
      return SerialData.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

/// 센서 데이터 (예시)
@JsonSerializable()
class SensorData {
  final double temperature;
  final double humidity;
  final double pressure;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) =>
      _$SensorDataFromJson(json);

  Map<String, dynamic> toJson() => _$SensorDataToJson(this);
}

