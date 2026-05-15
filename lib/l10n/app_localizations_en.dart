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
  String get navRealtimeData => 'Realtime Data';

  @override
  String get navRealtimeDataSubtitle => 'View live table and graph';

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
  String get dashboardIosNoticeTitle => 'iPhone / iPad Users';

  @override
  String get dashboardIosAvailable =>
      'BLE · WiFi serial communication ✓\nReal-time data visualization ✓\nSerial monitor ✓\nData analysis ✓';

  @override
  String get dashboardIosUnavailable =>
      'USB connection ✗\nClassic Bluetooth (HC-05/06) ✗\nCode upload ✗\n(iOS system policy restriction)';

  @override
  String get dashboardSpecComparisonTitle => '🧭 Device Spec Check';

  @override
  String get dashboardSpecComparisonSubtitle =>
      'Compare recommended specs with your current device';

  @override
  String get dashboardSpecLoading => 'Reading current device specs...';

  @override
  String get dashboardSpecFailed =>
      'Could not load device specs. Please check permissions or platform support.';

  @override
  String get dashboardSpecCurrentDevice => 'Current Device';

  @override
  String get dashboardSpecRecommended => 'Recommended';

  @override
  String get dashboardSpecItemOs => 'Operating System';

  @override
  String get dashboardSpecItemCpu => 'CPU Cores';

  @override
  String get dashboardSpecItemMemory => 'Memory';

  @override
  String get dashboardSpecReasonOs =>
      'Newer OS versions improve Bluetooth/USB permission handling and connection stability.';

  @override
  String get dashboardSpecReasonCpu =>
      'More cores reduce UI stutter during real-time parsing, charts, and monitoring.';

  @override
  String get dashboardSpecReasonMemory =>
      'Enough memory prevents frame drops when running multiple charts and logs together.';

  @override
  String get dashboardSpecReasonConnection =>
      'Connection quality matters as much as device specs.';

  @override
  String get dashboardSpecConnectionTip =>
      'Use a stable USB cable/OTG adapter and reliable Bluetooth pairing for the best result.';

  @override
  String get dashboardSpecStatusGood => 'Good';

  @override
  String get dashboardSpecStatusNeedAttention => 'Check';

  @override
  String get dashboardSpecStatusUnknown => 'Unknown';

  @override
  String get dashboardSpecUnknownValue => 'Unavailable';

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
  String get realtimeTable => 'Real-time Table';

  @override
  String get realtimeGraph => 'Real-time Graph';

  @override
  String get analysisTableNoData => 'No real-time data to display';

  @override
  String get analysisTableNoDataHint =>
      'Rows will appear automatically when JSON data is received';

  @override
  String get analysisTableTime => 'Time';

  @override
  String analysisTableRows(int count) {
    return 'Rows: $count';
  }

  @override
  String analysisTableShowingRecent(int shown, int total) {
    return 'Showing latest $shown of $total rows';
  }

  @override
  String get analysisDataTab => 'Raw Data';

  @override
  String get advancedGraphAnalysis => 'Graph Analysis';

  @override
  String analysisDataSeriesCount(int count) {
    return 'Series: $count';
  }

  @override
  String analysisDataPointsCount(int count) {
    return 'Points: $count';
  }

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
  String get fftEmpty => 'No data. Start receiving numeric JSON first.';

  @override
  String get fftNotEnough => 'Not enough samples for FFT.';

  @override
  String get fftSeries => 'Series';

  @override
  String get fftWindowSize => 'Window';

  @override
  String get fftWindowFunction => 'Function';

  @override
  String get fftWindowRectangular => 'Rectangular';

  @override
  String get fftWindowHann => 'Hann';

  @override
  String fftSampleCount(int count) {
    return 'Samples: $count';
  }

  @override
  String fftSampleRate(String rate) {
    return 'Sample rate: $rate Hz';
  }

  @override
  String fftNyquist(String hz) {
    return 'Max detectable: $hz Hz (Nyquist)';
  }

  @override
  String fftJitterWarning(String percent) {
    return 'Sample interval is unstable (±$percent%). Frequency results may be inaccurate.';
  }

  @override
  String fftPeak(String freq, String mag) {
    return 'Peak: $freq Hz ($mag)';
  }

  @override
  String get fftAxisFrequency => 'Frequency (Hz)';

  @override
  String get fftAxisMagnitude => 'Magnitude';

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
  String get chartNoDataHint =>
      'Send numeric JSON data or import CSV/JSON files to see charts';

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

  @override
  String get chartImportData => 'Import Data';

  @override
  String get chartSaveData => 'Save Data';

  @override
  String get chartSaveAsJson => 'Save as JSON';

  @override
  String get chartSaveAsCsv => 'Save as CSV';

  @override
  String get chartLoadData => 'Load Data';

  @override
  String chartSavedJson(String path) {
    return 'Saved JSON: $path';
  }

  @override
  String chartLoadedSeries(int count) {
    return 'Loaded $count series';
  }

  @override
  String chartExportedCsv(String path) {
    return 'Exported CSV: $path';
  }

  @override
  String get analysisLoadRealtime => 'Load Realtime Data';

  @override
  String get analysisLoadRealtimeTooltip =>
      'Apply current live data to the analysis view';

  @override
  String analysisLoadedPoints(int count) {
    return 'Loaded $count series';
  }

  @override
  String get analysisClearConfirmTitle => 'Clear Data';

  @override
  String get analysisClearConfirmMessage =>
      'Do you want to save before clearing?\nData will be permanently lost if not saved.';

  @override
  String get analysisClearSaveAndDelete => 'Save then Clear';

  @override
  String get analysisClearDeleteOnly => 'Clear without Saving';

  @override
  String chartLoadFailed(String error) {
    return 'Failed to load data: $error';
  }

  @override
  String get tabDirectWrite => 'Write';

  @override
  String get tabSampleCodes => 'Samples';

  @override
  String get compilingOnServer => 'Compiling on server...';

  @override
  String get compileFailed => 'Compile failed';

  @override
  String get uploadingToDevice => 'Uploading to device...';

  @override
  String get androidSelectHex => 'Select HEX file';

  @override
  String get androidCloudCompileDesc =>
      'On Android, sketches are compiled in the cloud and uploaded with STK500 over USB.';

  @override
  String get sampleEditButton => 'Load into editor';

  @override
  String get sampleDiagCategory => 'Diagnostics';

  @override
  String get sampleGeneralCategory => 'Sample Code';

  @override
  String get sampleDiagBlink => '[Diag] LED Blink';

  @override
  String get sampleDiagBlinkDesc =>
      'No wiring needed. Blink the built-in LED to verify board upload.';

  @override
  String get sampleDiagJsonRandom => '[Diag] Random JSON';

  @override
  String get sampleDiagJsonRandomDesc =>
      'Send random a/b/c values as JSON every second. Use to verify serial receive and charts.';

  @override
  String get sampleBlink => 'Blink LED';

  @override
  String get sampleBlinkDesc => 'Blink the built-in LED every second.';

  @override
  String get sampleBlinkMillis => 'Non-blocking Blink (millis)';

  @override
  String get sampleBlinkMillisDesc =>
      'Blink the built-in LED without delay() to keep loop responsive.';

  @override
  String get sampleSerialHello => 'Serial Hello';

  @override
  String get sampleSerialHelloDesc =>
      'Send greeting text periodically over serial.';

  @override
  String get sampleAnalogRead => 'Analog Read';

  @override
  String get sampleAnalogReadDesc => 'Read analog input and print the value.';

  @override
  String get samplePwmFade => 'PWM LED Fade';

  @override
  String get samplePwmFadeDesc =>
      'Fade an LED on PWM pin 9 from dark to bright and back.';

  @override
  String get sampleServoSweep => 'Servo Sweep';

  @override
  String get sampleServoSweepDesc => 'Move a servo back and forth smoothly.';

  @override
  String get sampleTempDht => 'DHT Temperature';

  @override
  String get sampleTempDhtDesc => 'Read DHT sensor values and print them.';

  @override
  String get sampleLedControl => 'LED Control';

  @override
  String get sampleLedControlDesc => 'Turn LED on/off by serial command.';

  @override
  String get sampleButtonDebounce => 'Button Debounce Toggle';

  @override
  String get sampleButtonDebounceDesc =>
      'Toggle built-in LED with a debounced INPUT_PULLUP button.';

  @override
  String get sampleUltrasonic => 'Ultrasonic Distance';

  @override
  String get sampleUltrasonicDesc => 'Measure distance with an HC-SR04 sensor.';

  @override
  String get realtimeReceiving => 'Receiving';

  @override
  String get realtimePaused => 'Paused';

  @override
  String get realtimeSaveData => 'Save';

  @override
  String get realtimeClearData => 'Clear';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get tooltipDisconnect => 'Disconnect';

  @override
  String get tooltipClear => 'Clear';

  @override
  String get actionUndo => 'Undo';

  @override
  String get confirmDisconnectTitle => 'Disconnect device?';

  @override
  String get confirmDisconnectMessage =>
      'Data is currently being received.\nDisconnect anyway?';

  @override
  String get confirmClearTitle => 'Clear data?';

  @override
  String get confirmClearMessage =>
      'All received and chart data will be removed. This cannot be undone.';

  @override
  String get terminalNoData => 'No data received yet';

  @override
  String get terminalAutoScroll => 'Auto-scroll';

  @override
  String get terminalSend => 'Send';

  @override
  String get terminalSendHint => 'Enter data to send...';

  @override
  String terminalReceivedCount(int count) {
    return 'Received: $count messages';
  }

  @override
  String get deviceListEmpty =>
      'No devices found.\nTap \"Scan Devices\" to search.';

  @override
  String get connectionConnecting => 'Connecting...';

  @override
  String get connectionFailed => 'Failed to connect';

  @override
  String get wifiDialogTitle => 'Add WiFi Device';

  @override
  String get wifiDialogNameLabel => 'Device Name';

  @override
  String get wifiDialogAddressLabel => 'WebSocket Address';

  @override
  String get wifiDialogAddressHint => 'ws://192.168.0.10:81';

  @override
  String get wifiDialogNameEmpty => 'Enter a device name';

  @override
  String get wifiDialogAddressInvalid => 'Must start with ws:// or wss://';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonOk => 'OK';

  @override
  String baudrateChanging(int rate) {
    return 'Changing baud rate... ($rate bps)';
  }

  @override
  String baudrateChanged(int rate) {
    return 'Baud rate changed ($rate bps)';
  }

  @override
  String get reconnectFailed => 'Reconnection failed';

  @override
  String get codeSenderTitle => 'Code Sender';

  @override
  String get codeSenderTagline =>
      'Write, verify, and upload code — all in one place!';

  @override
  String get codeSenderTabGuide => 'Home';

  @override
  String get codeSenderTabWrite => 'Write';

  @override
  String get codeSenderTabSamples => 'Samples';

  @override
  String get codeSenderStepsTitle => 'Procedure';

  @override
  String get codeSenderStepsSubtitle =>
      '1) Pick a sample or write code\n2) Verify to compile\n3) Make sure the device is connected\n4) Upload to send';

  @override
  String get codeSenderRequirementsTitle => 'Requirements';

  @override
  String get codeSenderRequirementBoard =>
      '• Board connected: The target board/port must be connected before upload.';

  @override
  String get codeSenderRequirementOnline =>
      '• Online: Android cloud compile needs an internet connection.';

  @override
  String get codeSenderRequirementOs =>
      '• Supported OS: Write/Verify/Upload works on Android/Windows. HEX upload is Android-only advanced.';

  @override
  String get codeSenderAndroidModeTitle => 'Android behavior';

  @override
  String get codeSenderAndroidModeSubtitle =>
      'Code is compiled on the server and uploaded over USB (STK500).';

  @override
  String get codeSenderCautionTitle => 'Caveats';

  @override
  String get codeSenderCautionLibs =>
      '• Libraries not bundled with samples cannot be auto-installed yet.';

  @override
  String get codeSenderCautionPort =>
      '• On upload failure, release the port (Serial Monitor etc.) and retry.';

  @override
  String get codeSenderOverwriteTitle => 'Overwrite editor?';

  @override
  String get codeSenderOverwriteMessage =>
      'You have code in the editor.\nLoading a sample will discard it.';

  @override
  String get codeSenderOverwrite => 'Overwrite';

  @override
  String get codeSenderIosUnsupported =>
      'Code upload is not supported on iOS.\nPlease upload from PC or Android.';

  @override
  String codeSenderBoardUnsupported(String board) {
    return 'The $board board does not support Android USB upload.\nPlease upload from PC.';
  }

  @override
  String get codeSenderPortNotAvailable => 'Port information is not available';

  @override
  String codeSenderSaveComplete(String path) {
    return 'Saved: $path';
  }

  @override
  String get codeSenderSaveDialogTitle => 'Save sketch';

  @override
  String get codeSenderNewSketchTitle => 'Create new sketch';

  @override
  String get codeSenderNewSketchMessage =>
      'Existing code in the editor will be discarded. Continue?';

  @override
  String get codeSenderNewSketchConfirm => 'Create';

  @override
  String get codeSenderHexHelpTitle => 'What is a HEX file?';

  @override
  String get codeSenderHexHelpContent =>
      'A HEX file is pre-compiled firmware.\n\nThis is an Android-only advanced option for uploading an existing .hex directly, without source compilation.';

  @override
  String get codeSenderTooltipSave => 'Save';

  @override
  String get codeSenderTooltipSaveAs => 'Save as';

  @override
  String get codeSenderTooltipCopyOutput => 'Copy output';

  @override
  String get codeSenderTooltipClearOutput => 'Clear output';

  @override
  String get codeSenderTooltipHexHelp => 'About HEX files';

  @override
  String get codeSenderAdvancedShow => 'Show advanced';

  @override
  String get codeSenderAdvancedHide => 'Hide advanced';

  @override
  String get codeSenderHexUpload => 'HEX upload';

  @override
  String get codeSenderConsoleLabel => 'Output';

  @override
  String get codeSenderConsolePlaceholder =>
      'Compile / upload output will appear here.';

  @override
  String get codeSenderCopied => 'Copied';

  @override
  String get codeSenderReconnectWaiting => 'Waiting for reconnection... (2.5s)';

  @override
  String get codeSenderReconnectAttempting => 'Attempting reconnection...';

  @override
  String get codeSenderReconnectSuccess => '✅ Reconnected';

  @override
  String get codeSenderReconnectFailed =>
      '⚠️ Reconnect failed — connect manually from the Device tab';

  @override
  String get codeSenderReconnectComplete => '✅ Reconnect complete';

  @override
  String get connectionTypeLabel => 'Connection Type';

  @override
  String get connectionScan => 'Scan Devices';

  @override
  String get connectionScanning => 'Scanning...';

  @override
  String get connectionConnect => 'Connect';

  @override
  String get connectionDeviceNameHint => 'Arduino WiFi';

  @override
  String get connectionConnectedChip => 'Connected';

  @override
  String connectionConnectedTo(String device) {
    return 'Connected to $device';
  }

  @override
  String get connectionNoDevices => 'No devices found';

  @override
  String get connectionNoDevicesHint => 'Click \"Scan Devices\" to search';

  @override
  String get connectionWarnUsbTitle => 'USB Connection';

  @override
  String get connectionWarnUsbBody =>
      '• Supported on Android only\n• Match the baud rate to your Arduino sketch.';

  @override
  String get connectionWarnBluetoothTitle => 'Bluetooth Connection';

  @override
  String get connectionWarnBluetoothBody =>
      '• Pair the device in system settings first\n• Match the baud rate to your Arduino sketch.';

  @override
  String get connectionWarnWifiTitle => 'WiFi Connection';

  @override
  String get connectionWarnWifiBody =>
      '• WebSocket address format: ws://IP:PORT\n• The Arduino must run a WebSocket server.';

  @override
  String get btProtocolTitle => 'Select Bluetooth Protocol';

  @override
  String btProtocolChoose(String device) {
    return 'Choose the protocol for $device:';
  }

  @override
  String get btProtocolClassic => 'Classic Bluetooth';

  @override
  String get btProtocolClassicDesc => 'For HC-05, HC-06, etc.';

  @override
  String get btProtocolBle => 'Bluetooth Low Energy (BLE)';

  @override
  String get btProtocolBleDesc => 'For modern BLE modules';

  @override
  String get deviceInfoDeviceName => 'Device Name';

  @override
  String get deviceInfoAddress => 'Address';

  @override
  String get deviceInfoConnType => 'Connection Type';

  @override
  String get deviceInfoBaudRate => 'Baud Rate';

  @override
  String get deviceInfoSelectedBoard => 'Selected Board';

  @override
  String get deviceInfoProtocol => 'Protocol';

  @override
  String get deviceInfoBuffering => 'Buffering';

  @override
  String get deviceInfoBufferingValue => '50ms timeout (Arduino compatible)';

  @override
  String get deviceInfoDataFormat => 'Data Format';

  @override
  String get deviceInfoDataFormatValue => 'Arduino BTSerial text';

  @override
  String get deviceInfoJsonData => 'JSON Data';

  @override
  String get deviceInfoJsonSub => 'Structured data';

  @override
  String get deviceInfoTextData => 'Text Data';

  @override
  String get deviceInfoTextSub => 'Raw data';

  @override
  String get deviceInfoConnectFromTab =>
      'Please connect a device from the Device Connection tab.';

  @override
  String get deviceInfoDeviceSettings => 'Device Settings';

  @override
  String get deviceInfoArduinoBoard => 'Arduino Board';

  @override
  String get deviceInfoAutoDetect => 'Auto Detect';

  @override
  String deviceInfoDetected(String board) {
    return 'Detected board: $board';
  }

  @override
  String get deviceInfoRecentUsed => 'Recently used';

  @override
  String get deviceInfoBaudRateTooltip =>
      'Change it in the Device Connection tab';

  @override
  String get dashboardSupported => 'Supported';

  @override
  String get dashboardUnsupported => 'Unsupported';

  @override
  String get advGraphSeries => 'Series';

  @override
  String get advGraphGraph => 'Graph';

  @override
  String get advGraphBins => 'Bins';

  @override
  String get advGraphSmoothing => 'Smoothing';

  @override
  String get advGraphWindow => 'Window';

  @override
  String get advGraphFitLine => 'Fit line';

  @override
  String get advGraphType => 'Type';

  @override
  String get advGraphPeakValley => 'Peak/Valley';

  @override
  String get advGraphProminence => 'Prominence';

  @override
  String get advGraphNoPoints => 'No points';

  @override
  String get advGraphNoData =>
      'No data. Load data or start receiving numeric JSON first.';

  @override
  String get advGraphHistogramNeedPoints =>
      'Need at least 2 points for histogram.';

  @override
  String get advGraphHistogramConstantValues =>
      'Values are constant. Histogram is not meaningful.';

  @override
  String get advGraphFit => 'Fit';

  @override
  String get advGraphEquation => 'Equation';

  @override
  String get advGraphRSquared => 'R^2';

  @override
  String get advGraphCount => 'Count';

  @override
  String get advGraphFitUnavailable => 'Fit unavailable for current data.';

  @override
  String get advGraphFitQuadraticNeedPoints =>
      'Quadratic fit needs at least 3 valid points.';

  @override
  String get advGraphFitExponentialNeedPoints =>
      'Exponential fit needs at least 2 positive points.';

  @override
  String get advGraphFitPowerNeedPoints =>
      'Power fit needs at least 2 positive points.';

  @override
  String get advGraphFitLogarithmicNeedPoints =>
      'Logarithmic fit needs at least 2 valid points.';

  @override
  String get advGraphModeLine => 'Line';

  @override
  String get advGraphModeScatter => 'Scatter';

  @override
  String get advGraphModeBar => 'Bar';

  @override
  String get advGraphModeArea => 'Area';

  @override
  String get advGraphModeHistogram => 'Histogram';

  @override
  String get advGraphRegressionLinear => 'Linear';

  @override
  String get advGraphRegressionQuadratic => 'Quadratic';

  @override
  String get advGraphRegressionExponential => 'Exponential';

  @override
  String get advGraphRegressionPower => 'Power';

  @override
  String get advGraphRegressionLogarithmic => 'Logarithmic';
}
