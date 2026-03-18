// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Serial Lab';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get navHome => 'Home';

  @override
  String get navHomeSubtitle => 'App overview & quick launch';

  @override
  String get navDevice => 'Device';

  @override
  String get navDeviceSubtitle => 'Device connection & settings';

  @override
  String get navSerialMonitor => 'Serial Monitor';

  @override
  String get navSerialMonitorSubtitle => 'Real-time data monitoring';

  @override
  String get navDataAnalysis => 'Data Analysis';

  @override
  String get navDataAnalysisSubtitle => 'JSON data visualization';

  @override
  String get navCodeSend => 'Code Send';

  @override
  String get navCodeSendSubtitle => 'Arduino code compile & upload';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSettingsSubtitle => 'App preferences';

  @override
  String drawerConnectedTo(String device) {
    return 'Connected to $device';
  }

  @override
  String get drawerNoDevice => 'No device connected';

  @override
  String get drawerQuickActions => 'Quick Actions';

  @override
  String get drawerClearData => 'Clear Data';

  @override
  String get drawerDataCleared => 'Data cleared';

  @override
  String get drawerDisconnect => 'Disconnect';

  @override
  String get dashboardWelcome => 'Welcome to Serial Lab!';

  @override
  String get dashboardSubtitle =>
      'Data analysis platform for serial communication with Arduino';

  @override
  String get dashboardGettingStarted => '🚀 Getting Started';

  @override
  String get dashboardStep1Title => 'Connect Device';

  @override
  String get dashboardStep1Desc => 'Select \"Device\" from the left menu';

  @override
  String get dashboardStep2Title => 'Receive Data';

  @override
  String get dashboardStep2Desc =>
      'Automatically parsed when data is sent in JSON format';

  @override
  String get dashboardStep3Title => 'Real-time Analysis';

  @override
  String get dashboardStep3Desc => 'Visualize and analyze data in graphs';

  @override
  String get dashboardIntro => '📱 Introduction';

  @override
  String get dashboardIntroText =>
      'Serial Lab is an all-in-one tool for serial communication with Arduino and other microcontrollers, enabling real-time visualization and analysis of data.\n\nSupports various communication methods such as USB, Bluetooth, and WiFi, and automatically parses JSON format data for graph display.';

  @override
  String get dashboardMainFeatures => '✨ Main Features';

  @override
  String get dashboardUsbSerial => 'USB Serial Communication';

  @override
  String get dashboardBluetooth => 'Bluetooth Communication';

  @override
  String get dashboardWifi => 'WiFi (WebSocket) Communication';

  @override
  String get dashboardRealtimeViz => 'Real-time Data Visualization';

  @override
  String get dashboardSerialMonitor => 'Serial Monitor';

  @override
  String get dashboardDataAnalysis =>
      'Data Analysis (Statistics, Correlation, FFT)';

  @override
  String get dashboardCodeSnippet => 'Code Snippet Send';

  @override
  String get settingsTabSettings => 'Settings';

  @override
  String get settingsTabAbout => 'About';

  @override
  String get settingsTabLicense => 'License';

  @override
  String get generalSettingsTitle => 'General Settings';

  @override
  String get settingsDataSection => 'Data Settings';

  @override
  String get settingsAutoSave => 'Auto Data Save';

  @override
  String get settingsAutoSaveDesc => 'Automatically save received data to Hive';

  @override
  String get settingsAppSection => 'App Settings';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeDesc => 'Use dark theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsDataMgmt => 'Data Management';

  @override
  String get settingsSavedData => 'Saved Data';

  @override
  String get settingsSavedDataDesc => 'View saved data files (coming soon)';

  @override
  String get settingsDeleteAll => 'Delete All Data';

  @override
  String get settingsDeleteAllDesc => 'Delete all saved data';

  @override
  String get dialogDeleteTitle => 'Delete Data';

  @override
  String get dialogDeleteContent =>
      'Are you sure you want to delete all data?\nThis action cannot be undone.';

  @override
  String get snackbarDataDeleted => 'All data has been deleted';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get languageSelectTitle => 'Select Language';

  @override
  String get connectionInfoTab => 'Connection Info';

  @override
  String get deviceConnectionTab => 'Device Connection';

  @override
  String get serialTab => 'Serial';

  @override
  String get bluetoothSerialTab => 'Bluetooth Serial';

  @override
  String get realtimeGraph => 'Real-time Graph';

  @override
  String get statsAnalysis => 'Statistics';

  @override
  String get statsAnalysisDesc =>
      'Provides basic statistics such as mean, standard deviation, max/min values.';

  @override
  String get correlationAnalysis => 'Correlation';

  @override
  String get correlationAnalysisDesc =>
      'Analyzes and visualizes correlations between multiple data.';

  @override
  String get fftAnalysis => 'FFT Analysis';

  @override
  String get fftAnalysisDesc =>
      'Checks frequency components of signals through frequency domain analysis.';

  @override
  String get comingSoon => '🚧 Coming Soon 🚧';

  @override
  String get preparingMsg => 'In preparation';

  @override
  String get newSketch => 'New Sketch';

  @override
  String get openSketch => 'Open';

  @override
  String get verify => 'Verify';

  @override
  String get upload => 'Upload';

  @override
  String get connectDeviceFirst => 'Please connect a device first';

  @override
  String get aboutInfoComingSoon => 'App info will be updated later';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get licenseTitle => 'Open Source Licenses';

  @override
  String licensePackageCountDesc(int count) {
    return 'This app uses $count open source packages.\nCheck each package’s license below.';
  }

  @override
  String licenseLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get chartNoData => 'No chart data available';

  @override
  String get chartNoDataHint => 'Send numeric JSON data to see charts';

  @override
  String get chartDataSeries => 'Data Series';

  @override
  String get chartClearData => 'Clear Data';

  @override
  String get chartNoDataPoints => 'No data points';

  @override
  String get chartCurrent => 'Current';

  @override
  String get chartMin => 'Min';

  @override
  String get chartMax => 'Max';

  @override
  String get chartPoints => 'Points';
}
