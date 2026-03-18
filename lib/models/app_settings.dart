import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// 앱 설정 데이터 모델
@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  @HiveField(0)
  int baudRate;

  @HiveField(1)
  bool isDarkMode;

  @HiveField(2)
  String language;

  @HiveField(3)
  bool autoSaveData;

  AppSettings({
    this.baudRate = 115200,
    this.isDarkMode = false,
    this.language = 'ko',
    this.autoSaveData = false,
  });
}
