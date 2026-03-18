import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:serial_lab/models/app_settings.dart';

/// 앱 설정 관리 Provider
class SettingsProvider extends ChangeNotifier {
  late Box<AppSettings> _settingsBox;
  AppSettings? _settings;

  // Getters
  int get baudRate => _settings?.baudRate ?? 115200;
  bool get isDarkMode => _settings?.isDarkMode ?? false;
  String get language => _settings?.language ?? 'ko';
  Locale get locale => Locale(_settings?.language ?? 'ko');
  bool get autoSaveData => _settings?.autoSaveData ?? false;

  /// 초기화
  Future<void> init() async {
    _settingsBox = Hive.box<AppSettings>('settings');
    
    // 기존 설정 로드 또는 새로 생성
    if (_settingsBox.isEmpty) {
      _settings = AppSettings();
      await _settingsBox.put('app_settings', _settings!);
    } else {
      _settings = _settingsBox.get('app_settings');
    }
    
    notifyListeners();
  }

  /// 보드레이트 설정
  Future<void> setBaudRate(int rate) async {
    _settings?.baudRate = rate;
    await _settings?.save();
    notifyListeners();
  }

  /// 다크모드 설정
  Future<void> setDarkMode(bool enabled) async {
    _settings?.isDarkMode = enabled;
    await _settings?.save();
    notifyListeners();
  }

  /// 언어 설정
  Future<void> setLanguage(String lang) async {
    _settings?.language = lang;
    await _settings?.save();
    notifyListeners();
  }

  /// 자동 저장 설정
  Future<void> setAutoSaveData(bool enabled) async {
    _settings?.autoSaveData = enabled;
    await _settings?.save();
    notifyListeners();
  }

  /// 모든 설정 초기화
  Future<void> resetSettings() async {
    _settings = AppSettings();
    await _settingsBox.put('app_settings', _settings!);
    notifyListeners();
  }
}
