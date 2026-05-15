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
  String get dashboardSpecComparisonTitle => '🧭 デバイス仕様チェック';

  @override
  String get dashboardSpecComparisonSubtitle => '推奨仕様と現在のデバイス仕様を比較します';

  @override
  String get dashboardSpecLoading => '現在のデバイス仕様を読み込み中...';

  @override
  String get dashboardSpecFailed =>
      'デバイス仕様を読み込めませんでした。権限またはプラットフォーム対応状況を確認してください。';

  @override
  String get dashboardSpecCurrentDevice => '現在のデバイス';

  @override
  String get dashboardSpecRecommended => '推奨基準';

  @override
  String get dashboardSpecItemOs => 'OS';

  @override
  String get dashboardSpecItemCpu => 'CPU コア';

  @override
  String get dashboardSpecItemMemory => 'メモリ';

  @override
  String get dashboardSpecReasonOs => '新しいOSほどBluetooth/USB権限処理と接続安定性が向上します。';

  @override
  String get dashboardSpecReasonCpu => 'コア数が多いほどリアルタイム解析・チャート・監視でのカクつきが減ります。';

  @override
  String get dashboardSpecReasonMemory =>
      '十分なメモリがあると複数チャートとログを同時表示してもフレーム落ちを抑えられます。';

  @override
  String get dashboardSpecReasonConnection => 'デバイス性能と同じくらい接続品質も重要です。';

  @override
  String get dashboardSpecConnectionTip =>
      '安定したUSBケーブル/OTGアダプタと信頼できるBluetoothペアリングを推奨します。';

  @override
  String get dashboardSpecStatusGood => '良好';

  @override
  String get dashboardSpecStatusNeedAttention => '要確認';

  @override
  String get dashboardSpecStatusUnknown => '不明';

  @override
  String get dashboardSpecUnknownValue => '取得不可';

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
  String get fftEmpty => 'データがありません。まず数値JSONを受信してください。';

  @override
  String get fftNotEnough => 'FFTに十分なサンプルがありません。';

  @override
  String get fftSeries => 'シリーズ';

  @override
  String get fftWindowSize => 'ウィンドウ';

  @override
  String get fftWindowFunction => '関数';

  @override
  String get fftWindowRectangular => '矩形';

  @override
  String get fftWindowHann => 'Hann';

  @override
  String fftSampleCount(int count) {
    return 'サンプル数: $count';
  }

  @override
  String fftSampleRate(String rate) {
    return 'サンプリングレート: $rate Hz';
  }

  @override
  String fftNyquist(String hz) {
    return '検出可能な上限: $hz Hz (Nyquist)';
  }

  @override
  String fftJitterWarning(String percent) {
    return 'サンプル間隔が不安定です (±$percent%)。周波数結果が不正確な可能性があります。';
  }

  @override
  String fftPeak(String freq, String mag) {
    return 'ピーク: $freq Hz ($mag)';
  }

  @override
  String get fftAxisFrequency => '周波数 (Hz)';

  @override
  String get fftAxisMagnitude => '振幅';

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
  String get sampleDiagCategory => '診断用';

  @override
  String get sampleGeneralCategory => 'サンプルコード';

  @override
  String get sampleDiagBlink => '[診断用] LED Blink';

  @override
  String get sampleDiagBlinkDesc => '配線不要でボードの動作確認。内蔵LEDを1秒ごとに点滅します。';

  @override
  String get sampleDiagJsonRandom => '[診断用] ランダムJSON送信';

  @override
  String get sampleDiagJsonRandomDesc =>
      '1秒ごとにa/b/cのランダム値をJSONで送信。シリアル受信・グラフ確認用。';

  @override
  String get sampleBlink => 'LED点滅';

  @override
  String get sampleBlinkDesc => '内蔵LEDを1秒ごとに点滅させます。';

  @override
  String get sampleBlinkMillis => 'ノンブロッキング点滅 (millis)';

  @override
  String get sampleBlinkMillisDesc => 'delay()を使わずmillis()でLEDを点滅し、ループを止めません。';

  @override
  String get sampleSerialHello => 'シリアル Hello';

  @override
  String get sampleSerialHelloDesc => 'シリアルへ挨拶文字列を定期送信します。';

  @override
  String get sampleAnalogRead => 'アナログ読み取り';

  @override
  String get sampleAnalogReadDesc => 'アナログ入力値を読み取って出力します。';

  @override
  String get samplePwmFade => 'PWM LEDフェード';

  @override
  String get samplePwmFadeDesc => 'PWM 9番ピンのLEDを暗→明→暗と繰り返します。';

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
  String get sampleButtonDebounce => 'ボタンデバウンストグル';

  @override
  String get sampleButtonDebounceDesc =>
      'INPUT_PULLUP方式のデバウンスボタンで内蔵LEDをトグルします。';

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

  @override
  String get statusConnected => '接続済み';

  @override
  String get statusDisconnected => '切断';

  @override
  String get tooltipDisconnect => '切断';

  @override
  String get tooltipClear => 'クリア';

  @override
  String get actionUndo => '元に戻す';

  @override
  String get confirmDisconnectTitle => 'デバイスを切断しますか？';

  @override
  String get confirmDisconnectMessage => '現在データを受信しています。\nそれでも切断しますか？';

  @override
  String get confirmClearTitle => 'データを消去しますか？';

  @override
  String get confirmClearMessage => '受信データとチャートがすべて削除されます。元に戻せません。';

  @override
  String get terminalNoData => '受信データがありません';

  @override
  String get terminalAutoScroll => '自動スクロール';

  @override
  String get terminalSend => '送信';

  @override
  String get terminalSendHint => '送信するデータを入力...';

  @override
  String terminalReceivedCount(int count) {
    return '受信: $count 件';
  }

  @override
  String get deviceListEmpty => 'デバイスが見つかりません。\n\"デバイス検索\"で検索してください。';

  @override
  String get connectionConnecting => '接続中...';

  @override
  String get connectionFailed => '接続に失敗しました';

  @override
  String get wifiDialogTitle => 'WiFi デバイス追加';

  @override
  String get wifiDialogNameLabel => 'デバイス名';

  @override
  String get wifiDialogAddressLabel => 'WebSocket アドレス';

  @override
  String get wifiDialogAddressHint => 'ws://192.168.0.10:81';

  @override
  String get wifiDialogNameEmpty => 'デバイス名を入力してください';

  @override
  String get wifiDialogAddressInvalid => 'ws:// または wss:// で始まる必要があります';

  @override
  String get commonAdd => '追加';

  @override
  String get commonOk => 'OK';

  @override
  String baudrateChanging(int rate) {
    return 'ボーレート変更中... ($rate bps)';
  }

  @override
  String baudrateChanged(int rate) {
    return 'ボーレート変更完了 ($rate bps)';
  }

  @override
  String get reconnectFailed => '再接続に失敗';

  @override
  String get codeSenderTitle => 'Code Sender';

  @override
  String get codeSenderTagline => 'コードの作成・検証・アップロードまで！';

  @override
  String get codeSenderTabGuide => 'ホーム';

  @override
  String get codeSenderTabWrite => '作成';

  @override
  String get codeSenderTabSamples => 'サンプル';

  @override
  String get codeSenderStepsTitle => '手順';

  @override
  String get codeSenderStepsSubtitle =>
      '1) サンプル選択またはコード作成\n2) Verify でコンパイル確認\n3) デバイス接続確認\n4) Upload で送信';

  @override
  String get codeSenderRequirementsTitle => '必要条件';

  @override
  String get codeSenderRequirementBoard =>
      '• ボード接続: アップロード前に対象ボード/ポートが接続されている必要があります。';

  @override
  String get codeSenderRequirementOnline =>
      '• オンライン: Android のサーバーコンパイルにはインターネット接続が必要です。';

  @override
  String get codeSenderRequirementOs =>
      '• 対応 OS: Write/Verify/Upload は Android/Windows で使用可能、HEX アップロードは Android 専用の高度な機能です。';

  @override
  String get codeSenderAndroidModeTitle => 'Android の動作';

  @override
  String get codeSenderAndroidModeSubtitle =>
      'コードはサーバーでコンパイルされ、USB(STK500) でアップロードされます。';

  @override
  String get codeSenderCautionTitle => '注意事項';

  @override
  String get codeSenderCautionLibs => '• サンプルにないライブラリは現在自動インストールされず、使用できません。';

  @override
  String get codeSenderCautionPort =>
      '• アップロード失敗時はポート占有(Serial Monitor 等) を解除して再試行してください。';

  @override
  String get codeSenderOverwriteTitle => 'エディタの内容を上書きしますか？';

  @override
  String get codeSenderOverwriteMessage =>
      'エディタにコードがあります。\nサンプルを読み込むと既存の内容が消えます。';

  @override
  String get codeSenderOverwrite => '上書き';

  @override
  String get codeSenderIosUnsupported =>
      'iOS ではコードアップロードは未対応です。\nPC または Android からアップロードしてください。';

  @override
  String codeSenderBoardUnsupported(String board) {
    return '$board ボードは Android USB アップロードに未対応です。\nPC からアップロードしてください。';
  }

  @override
  String get codeSenderPortNotAvailable => 'ポート情報を確認できません';

  @override
  String codeSenderSaveComplete(String path) {
    return '保存完了: $path';
  }

  @override
  String get codeSenderSaveDialogTitle => 'スケッチを保存';

  @override
  String get codeSenderNewSketchTitle => '新規スケッチの作成';

  @override
  String get codeSenderNewSketchMessage => '現在の作業内容が消えます。続けますか？';

  @override
  String get codeSenderNewSketchConfirm => '新規作成';

  @override
  String get codeSenderHexHelpTitle => 'HEX ファイルとは？';

  @override
  String get codeSenderHexHelpContent =>
      'HEX ファイルはコンパイル済みのファームウェアです。\n\nこれは Android 専用の高度なオプションで、ソースコードをコンパイルせずに既存の .hex をデバイスに直接アップロードする機能です。';

  @override
  String get codeSenderTooltipSave => '保存';

  @override
  String get codeSenderTooltipSaveAs => '別名で保存';

  @override
  String get codeSenderTooltipCopyOutput => '出力をコピー';

  @override
  String get codeSenderTooltipClearOutput => '出力をクリア';

  @override
  String get codeSenderTooltipHexHelp => 'HEX ファイルの説明';

  @override
  String get codeSenderAdvancedShow => '高度な設定を表示';

  @override
  String get codeSenderAdvancedHide => '高度な設定を非表示';

  @override
  String get codeSenderHexUpload => 'HEX アップロード';

  @override
  String get codeSenderConsoleLabel => '出力';

  @override
  String get codeSenderConsolePlaceholder => 'ここにコンパイル/アップロードの結果が表示されます。';

  @override
  String get codeSenderCopied => 'コピーしました';

  @override
  String get codeSenderReconnectWaiting => '再接続を待機中... (2.5s)';

  @override
  String get codeSenderReconnectAttempting => '再接続を試行中...';

  @override
  String get codeSenderReconnectSuccess => '✅ 再接続成功';

  @override
  String get codeSenderReconnectFailed => '⚠️ 再接続失敗 — デバイスタブから手動で接続してください';

  @override
  String get codeSenderReconnectComplete => '✅ 再接続完了';

  @override
  String get connectionTypeLabel => '接続方式';

  @override
  String get connectionScan => 'デバイス検索';

  @override
  String get connectionScanning => '検索中...';

  @override
  String get connectionConnect => '接続';

  @override
  String get connectionDeviceNameHint => 'Arduino WiFi';

  @override
  String get connectionConnectedChip => '接続済み';

  @override
  String connectionConnectedTo(String device) {
    return '$device に接続済み';
  }

  @override
  String get connectionNoDevices => 'デバイスが見つかりません';

  @override
  String get connectionNoDevicesHint => '\"デバイス検索\"で検索してください';

  @override
  String get connectionWarnUsbTitle => 'USB 接続';

  @override
  String get connectionWarnUsbBody =>
      '• Android のみ対応\n• ボーレートを Arduino コードと同じに設定してください。';

  @override
  String get connectionWarnBluetoothTitle => 'Bluetooth 接続';

  @override
  String get connectionWarnBluetoothBody =>
      '• 先にシステム設定でペアリングしてください\n• ボーレートを Arduino コードと同じに設定してください。';

  @override
  String get connectionWarnWifiTitle => 'WiFi 接続';

  @override
  String get connectionWarnWifiBody =>
      '• WebSocket アドレス: ws://IP:PORT\n• Arduino で WebSocket サーバーを起動してください';

  @override
  String get btProtocolTitle => 'Bluetooth プロトコル選択';

  @override
  String btProtocolChoose(String device) {
    return '$device のプロトコルを選択:';
  }

  @override
  String get btProtocolClassic => 'Classic Bluetooth';

  @override
  String get btProtocolClassicDesc => 'HC-05 / HC-06 など';

  @override
  String get btProtocolBle => 'Bluetooth Low Energy (BLE)';

  @override
  String get btProtocolBleDesc => '最新の BLE モジュール向け';

  @override
  String get deviceInfoDeviceName => 'デバイス名';

  @override
  String get deviceInfoAddress => 'アドレス';

  @override
  String get deviceInfoConnType => '接続方式';

  @override
  String get deviceInfoBaudRate => 'ボーレート';

  @override
  String get deviceInfoSelectedBoard => '選択中のボード';

  @override
  String get deviceInfoProtocol => 'プロトコル';

  @override
  String get deviceInfoBuffering => 'バッファリング';

  @override
  String get deviceInfoBufferingValue => '50ms timeout (Arduino 互換)';

  @override
  String get deviceInfoDataFormat => 'データ形式';

  @override
  String get deviceInfoDataFormatValue => 'Arduino BTSerial テキスト';

  @override
  String get deviceInfoJsonData => 'JSON データ';

  @override
  String get deviceInfoJsonSub => '構造化データ';

  @override
  String get deviceInfoTextData => 'テキストデータ';

  @override
  String get deviceInfoTextSub => '生データ';

  @override
  String get deviceInfoConnectFromTab => 'デバイス接続タブからデバイスを接続してください。';

  @override
  String get deviceInfoDeviceSettings => 'デバイス設定';

  @override
  String get deviceInfoArduinoBoard => 'Arduino ボード';

  @override
  String get deviceInfoAutoDetect => '自動検出';

  @override
  String deviceInfoDetected(String board) {
    return '検出されたボード: $board';
  }

  @override
  String get deviceInfoRecentUsed => '最近使用';

  @override
  String get deviceInfoBaudRateTooltip => 'デバイス接続タブで変更可能';

  @override
  String get dashboardSupported => '対応';

  @override
  String get dashboardUnsupported => '非対応';

  @override
  String get advGraphSeries => 'シリーズ';

  @override
  String get advGraphGraph => 'グラフ';

  @override
  String get advGraphBins => 'ビン';

  @override
  String get advGraphSmoothing => 'スムージング';

  @override
  String get advGraphWindow => 'ウィンドウ';

  @override
  String get advGraphFitLine => 'フィッティング';

  @override
  String get advGraphType => 'タイプ';

  @override
  String get advGraphPeakValley => 'ピーク/バレー';

  @override
  String get advGraphProminence => 'プロミネンス';

  @override
  String get advGraphNoPoints => 'ポイントなし';

  @override
  String get advGraphNoData => 'データがありません。データを読み込むか、数値JSONの受信を開始してください。';

  @override
  String get advGraphHistogramNeedPoints => 'ヒストグラムには最低2点が必要です。';

  @override
  String get advGraphHistogramConstantValues => '値が一定のため、ヒストグラムは意味を持ちません。';

  @override
  String get advGraphFit => 'フィット';

  @override
  String get advGraphEquation => '方程式';

  @override
  String get advGraphRSquared => 'R^2';

  @override
  String get advGraphCount => '件数';

  @override
  String get advGraphFitUnavailable => '現在のデータではフィットできません。';

  @override
  String get advGraphFitQuadraticNeedPoints => '二次フィットには少なくとも3つの有効な点が必要です。';

  @override
  String get advGraphFitExponentialNeedPoints => '指数フィットには少なくとも2つの正の点が必要です。';

  @override
  String get advGraphFitPowerNeedPoints => 'べき乗フィットには少なくとも2つの正の点が必要です。';

  @override
  String get advGraphFitLogarithmicNeedPoints => '対数フィットには少なくとも2つの有効な点が必要です。';

  @override
  String get advGraphModeLine => '線';

  @override
  String get advGraphModeScatter => '散布図';

  @override
  String get advGraphModeBar => '棒';

  @override
  String get advGraphModeArea => 'エリア';

  @override
  String get advGraphModeHistogram => 'ヒストグラム';

  @override
  String get advGraphRegressionLinear => '線形';

  @override
  String get advGraphRegressionQuadratic => '二次';

  @override
  String get advGraphRegressionExponential => '指数';

  @override
  String get advGraphRegressionPower => 'べき乗';

  @override
  String get advGraphRegressionLogarithmic => '対数';
}
