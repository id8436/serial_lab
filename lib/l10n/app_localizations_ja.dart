// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Serial Lab';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get navHome => 'ホーム';

  @override
  String get navHomeSubtitle => 'アプリ概要とクイック起動';

  @override
  String get navDevice => 'デバイス';

  @override
  String get navDeviceSubtitle => '機器接続と設定';

  @override
  String get navSerialMonitor => 'シリアルモニター';

  @override
  String get navSerialMonitorSubtitle => 'リアルタイムデータモニタリング';

  @override
  String get navRealtimeData => 'リアルタイムデータ';

  @override
  String get navRealtimeDataSubtitle => 'リアルタイム表とグラフ';

  @override
  String get navDataAnalysis => 'データ分析';

  @override
  String get navDataAnalysisSubtitle => 'JSONデータ可視化';

  @override
  String get navCodeSend => 'コード送信';

  @override
  String get navCodeSendSubtitle => 'Arduinoコードコンパイル＆アップロード';

  @override
  String get navSettings => '設定';

  @override
  String get navSettingsSubtitle => 'アプリ環境設定';

  @override
  String drawerConnectedTo(String device) {
    return '$device に接続中';
  }

  @override
  String get drawerNoDevice => 'デバイス未接続';

  @override
  String get drawerQuickActions => 'クイックアクション';

  @override
  String get drawerClearData => 'データ消去';

  @override
  String get drawerDataCleared => 'データが消去されました';

  @override
  String get drawerDisconnect => '接続解除';

  @override
  String get dashboardWelcome => 'Serial Lab へようこそ！';

  @override
  String get dashboardSubtitle => 'Arduinoとシリアル通信するデータ分析プラットフォーム';

  @override
  String get dashboardGettingStarted => '🚀 はじめに';

  @override
  String get dashboardStep1Title => '機器接続';

  @override
  String get dashboardStep1Desc => '左側メニューから「機器接続」を選択してください';

  @override
  String get dashboardStep2Title => 'データ受信';

  @override
  String get dashboardStep2Desc => 'JSON形式でデータを送信すると自動でパース';

  @override
  String get dashboardStep3Title => 'リアルタイム分析';

  @override
  String get dashboardStep3Desc => 'グラフでデータを可視化して分析';

  @override
  String get dashboardIntro => '📱 紹介';

  @override
  String get dashboardIntroText =>
      'Serial LabはArduinoなどのマイクロコントローラーとシリアル通信を行い、リアルタイムでデータを可視化・分析できるオールインワンツールです。\n\nUSB、Bluetooth、WiFiなど様々な通信方式をサポートし、JSON形式のデータを自動でパースしてグラフ表示します。';

  @override
  String get dashboardMainFeatures => '✨ 主な機能';

  @override
  String get dashboardUsbSerial => 'USBシリアル通信';

  @override
  String get dashboardBluetooth => 'Bluetooth通信';

  @override
  String get dashboardWifi => 'WiFi (WebSocket) 通信';

  @override
  String get dashboardRealtimeViz => 'リアルタイムデータ可視化';

  @override
  String get dashboardSerialMonitor => 'シリアルモニター';

  @override
  String get dashboardDataAnalysis => 'データ分析（統計、相関、FFT）';

  @override
  String get dashboardCodeSnippet => 'コードスニペット送信';

  @override
  String get dashboardIosNoticeTitle => 'iPhone / iPad ユーザーへのご案内';

  @override
  String get dashboardIosAvailable =>
      'BLE · WiFi シリアル通信 ✓\nリアルタイムデータ可視化 ✓\nシリアルモニター ✓\nデータ分析 ✓';

  @override
  String get dashboardIosUnavailable =>
      'USB接続 ✗\nClassic Bluetooth (HC-05/06) ✗\nコードアップロード ✗\n(iOSシステムポリシーの制限)';

  @override
  String get settingsTabSettings => '設定';

  @override
  String get settingsTabAbout => '情報';

  @override
  String get settingsTabLicense => 'ライセンス';

  @override
  String get generalSettingsTitle => '一般設定';

  @override
  String get settingsDataSection => 'データ設定';

  @override
  String get settingsAutoSave => '自動データ保存';

  @override
  String get settingsAutoSaveDesc => '受信したデータを自動でHiveに保存';

  @override
  String get settingsAppSection => 'アプリ設定';

  @override
  String get settingsDarkMode => 'ダークモード';

  @override
  String get settingsDarkModeDesc => 'ダークテーマを使用';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsDataMgmt => 'データ管理';

  @override
  String get settingsSavedData => '保存済みデータ';

  @override
  String get settingsSavedDataDesc => '保存済みデータファイルを表示（開発予定）';

  @override
  String get settingsDeleteAll => '全データ削除';

  @override
  String get settingsDeleteAllDesc => '保存済みの全データを削除します';

  @override
  String get dialogDeleteTitle => 'データ削除';

  @override
  String get dialogDeleteContent => '全データを削除しますか？\nこの操作は元に戻せません。';

  @override
  String get snackbarDataDeleted => '全データが削除されました';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get languageSelectTitle => '言語選択';

  @override
  String get connectionInfoTab => '接続情報';

  @override
  String get deviceConnectionTab => '機器接続';

  @override
  String get serialTab => 'シリアル';

  @override
  String get bluetoothSerialTab => 'Bluetoothシリアル';

  @override
  String get realtimeTable => 'リアルタイム表';

  @override
  String get realtimeGraph => 'リアルタイムグラフ';

  @override
  String get analysisTableNoData => '表示するリアルタイムデータがありません';

  @override
  String get analysisTableNoDataHint => 'JSON形式のデータを受信すると表に自動で追加されます';

  @override
  String get analysisTableTime => '時刻';

  @override
  String analysisTableRows(int count) {
    return '行数: $count';
  }

  @override
  String analysisTableShowingRecent(int shown, int total) {
    return '最新 $shown / 全体 $total 行を表示中';
  }

  @override
  String get analysisDataTab => '基本データ';

  @override
  String get advancedGraphAnalysis => 'グラフ分析';

  @override
  String analysisDataSeriesCount(int count) {
    return 'シリーズ: $count';
  }

  @override
  String analysisDataPointsCount(int count) {
    return 'ポイント: $count';
  }

  @override
  String get statsAnalysis => '統計分析';

  @override
  String get statsAnalysisDesc => '平均、標準偏差、最大/最小値などの基本統計情報を提供します。';

  @override
  String get correlationAnalysis => '相関分析';

  @override
  String get correlationAnalysisDesc => '複数データ間の相関関係を分析・可視化します。';

  @override
  String get fftAnalysis => 'FFT分析';

  @override
  String get fftAnalysisDesc => '周波数領域解析で信号の周波数成分を確認します。';

  @override
  String get comingSoon => '🚧 Coming Soon 🚧';

  @override
  String get preparingMsg => '準備中です';

  @override
  String get newSketch => '新規スケッチ';

  @override
  String get openSketch => '開く';

  @override
  String get verify => '検証';

  @override
  String get upload => 'アップロード';

  @override
  String get connectDeviceFirst => '先に機器を接続してください';

  @override
  String get aboutInfoComingSoon => 'アプリ情報は後日更新予定です';

  @override
  String appVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get licenseTitle => 'オープンソースライセンス';

  @override
  String licensePackageCountDesc(int count) {
    return 'このアプリは$count個のオープンソースパッケージを使用しています。\n以下で各パッケージのライセンスをご確認ください。';
  }

  @override
  String licenseLoadError(String error) {
    return 'エラー: $error';
  }

  @override
  String get chartNoData => 'チャートデータがありません';

  @override
  String get chartNoDataHint => '数値JSONデータを送信するか、CSV/JSONファイルを読み込むとチャートが表示されます';

  @override
  String get chartDataSeries => 'データシリーズ';

  @override
  String get chartClearData => 'データ消去';

  @override
  String get chartNoDataPoints => 'データポイントなし';

  @override
  String get chartCurrent => '現在値';

  @override
  String get chartMin => '最小値';

  @override
  String get chartMax => '最大値';

  @override
  String get chartPoints => 'ポイント数';

  @override
  String get chartImportData => 'データ読み込み';

  @override
  String get chartSaveData => 'データ保存';

  @override
  String get chartSaveAsJson => 'JSONで保存';

  @override
  String get chartSaveAsCsv => 'CSVで保存';

  @override
  String get chartLoadData => 'データ読み込み';

  @override
  String chartSavedJson(String path) {
    return 'JSONを保存しました: $path';
  }

  @override
  String chartLoadedSeries(int count) {
    return '$count件のシリーズを読み込みました';
  }

  @override
  String chartExportedCsv(String path) {
    return 'CSVを書き出しました: $path';
  }

  @override
  String get analysisLoadRealtime => 'リアルタイムデータを読み込む';

  @override
  String get analysisLoadRealtimeTooltip => '現在の受信データを分析画面に適用します';

  @override
  String analysisLoadedPoints(int count) {
    return '$count個のシリーズを読み込みました';
  }

  @override
  String get analysisClearConfirmTitle => 'データを削除';

  @override
  String get analysisClearConfirmMessage =>
      '削除する前に保存しますか？\n保存しないとデータは永久に失われます。';

  @override
  String get analysisClearSaveAndDelete => '保存してから削除';

  @override
  String get analysisClearDeleteOnly => '保存せずに削除';

  @override
  String chartLoadFailed(String error) {
    return 'データを読み込めませんでした: $error';
  }

  @override
  String get tabDirectWrite => '直接作成';

  @override
  String get tabSampleCodes => 'サンプルコード';

  @override
  String get compilingOnServer => 'サーバーでコンパイル中...';

  @override
  String get compileFailed => 'コンパイル失敗';

  @override
  String get uploadingToDevice => 'デバイスへアップロード中...';

  @override
  String get androidSelectHex => 'HEXファイルを選択';

  @override
  String get androidCloudCompileDesc =>
      'Androidではスケッチをクラウドでコンパイルし、USB STK500で書き込みます。';

  @override
  String get sampleEditButton => 'エディタに読み込む';

  @override
  String get sampleBlink => 'LED点滅';

  @override
  String get sampleBlinkDesc => '内蔵LEDを1秒ごとに点滅させます。';

  @override
  String get sampleSerialHello => 'シリアル Hello';

  @override
  String get sampleSerialHelloDesc => 'シリアルへ挨拶文字列を定期送信します。';

  @override
  String get sampleSerialJson => 'シリアル JSON';

  @override
  String get sampleSerialJsonDesc => '温湿度データをJSONで送信します。';

  @override
  String get sampleAnalogRead => 'アナログ読み取り';

  @override
  String get sampleAnalogReadDesc => 'アナログ入力値を読み取って出力します。';

  @override
  String get sampleServoSweep => 'サーボスイープ';

  @override
  String get sampleServoSweepDesc => 'サーボを往復で滑らかに動かします。';

  @override
  String get sampleTempDht => 'DHT 温度';

  @override
  String get sampleTempDhtDesc => 'DHTセンサー値を読み取って出力します。';

  @override
  String get sampleLedControl => 'LED制御';

  @override
  String get sampleLedControlDesc => 'シリアルコマンドでLEDをON/OFFします。';

  @override
  String get sampleUltrasonic => '超音波距離';

  @override
  String get sampleUltrasonicDesc => 'HC-SR04で距離を測定します。';

  @override
  String get realtimeReceiving => '受信中';

  @override
  String get realtimePaused => '一時停止';

  @override
  String get realtimeSaveData => '保存';

  @override
  String get realtimeClearData => 'クリア';
}
