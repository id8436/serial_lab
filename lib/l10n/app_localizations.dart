import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Serial Lab'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App overview & quick launch'**
  String get navHomeSubtitle;

  /// No description provided for @navDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get navDevice;

  /// No description provided for @navDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device connection & settings'**
  String get navDeviceSubtitle;

  /// No description provided for @navSerialMonitor.
  ///
  /// In en, this message translates to:
  /// **'Serial Monitor'**
  String get navSerialMonitor;

  /// No description provided for @navSerialMonitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time data monitoring'**
  String get navSerialMonitorSubtitle;

  /// No description provided for @navRealtimeData.
  ///
  /// In en, this message translates to:
  /// **'Realtime Data'**
  String get navRealtimeData;

  /// No description provided for @navRealtimeDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View live table and graph'**
  String get navRealtimeDataSubtitle;

  /// No description provided for @navDataAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Data Analysis'**
  String get navDataAnalysis;

  /// No description provided for @navDataAnalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'JSON data visualization'**
  String get navDataAnalysisSubtitle;

  /// No description provided for @navCodeSend.
  ///
  /// In en, this message translates to:
  /// **'Code Send'**
  String get navCodeSend;

  /// No description provided for @navCodeSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arduino code compile & upload'**
  String get navCodeSendSubtitle;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get navSettingsSubtitle;

  /// No description provided for @drawerConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String drawerConnectedTo(String device);

  /// No description provided for @drawerNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No device connected'**
  String get drawerNoDevice;

  /// No description provided for @drawerQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get drawerQuickActions;

  /// No description provided for @drawerClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get drawerClearData;

  /// No description provided for @drawerDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Data cleared'**
  String get drawerDataCleared;

  /// No description provided for @drawerDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get drawerDisconnect;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Serial Lab!'**
  String get dashboardWelcome;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data analysis platform for serial communication with Arduino'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'🚀 Getting Started'**
  String get dashboardGettingStarted;

  /// No description provided for @dashboardStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get dashboardStep1Title;

  /// No description provided for @dashboardStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Select \"Device\" from the left menu'**
  String get dashboardStep1Desc;

  /// No description provided for @dashboardStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Receive Data'**
  String get dashboardStep2Title;

  /// No description provided for @dashboardStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Automatically parsed when data is sent in JSON format'**
  String get dashboardStep2Desc;

  /// No description provided for @dashboardStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Real-time Analysis'**
  String get dashboardStep3Title;

  /// No description provided for @dashboardStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Visualize and analyze data in graphs'**
  String get dashboardStep3Desc;

  /// No description provided for @dashboardIntro.
  ///
  /// In en, this message translates to:
  /// **'📱 Introduction'**
  String get dashboardIntro;

  /// No description provided for @dashboardIntroText.
  ///
  /// In en, this message translates to:
  /// **'Serial Lab is an all-in-one tool for serial communication with Arduino and other microcontrollers, enabling real-time visualization and analysis of data.\n\nSupports various communication methods such as USB, Bluetooth, and WiFi, and automatically parses JSON format data for graph display.'**
  String get dashboardIntroText;

  /// No description provided for @dashboardMainFeatures.
  ///
  /// In en, this message translates to:
  /// **'✨ Main Features'**
  String get dashboardMainFeatures;

  /// No description provided for @dashboardUsbSerial.
  ///
  /// In en, this message translates to:
  /// **'USB Serial Communication'**
  String get dashboardUsbSerial;

  /// No description provided for @dashboardBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Communication'**
  String get dashboardBluetooth;

  /// No description provided for @dashboardWifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi (WebSocket) Communication'**
  String get dashboardWifi;

  /// No description provided for @dashboardRealtimeViz.
  ///
  /// In en, this message translates to:
  /// **'Real-time Data Visualization'**
  String get dashboardRealtimeViz;

  /// No description provided for @dashboardSerialMonitor.
  ///
  /// In en, this message translates to:
  /// **'Serial Monitor'**
  String get dashboardSerialMonitor;

  /// No description provided for @dashboardDataAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Data Analysis (Statistics, Correlation, FFT)'**
  String get dashboardDataAnalysis;

  /// No description provided for @dashboardCodeSnippet.
  ///
  /// In en, this message translates to:
  /// **'Code Snippet Send'**
  String get dashboardCodeSnippet;

  /// No description provided for @dashboardIosNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'iPhone / iPad Users'**
  String get dashboardIosNoticeTitle;

  /// No description provided for @dashboardIosAvailable.
  ///
  /// In en, this message translates to:
  /// **'BLE · WiFi serial communication ✓\nReal-time data visualization ✓\nSerial monitor ✓\nData analysis ✓'**
  String get dashboardIosAvailable;

  /// No description provided for @dashboardIosUnavailable.
  ///
  /// In en, this message translates to:
  /// **'USB connection ✗\nClassic Bluetooth (HC-05/06) ✗\nCode upload ✗\n(iOS system policy restriction)'**
  String get dashboardIosUnavailable;

  /// No description provided for @dashboardSpecComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'🧭 Device Spec Check'**
  String get dashboardSpecComparisonTitle;

  /// No description provided for @dashboardSpecComparisonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare recommended specs with your current device'**
  String get dashboardSpecComparisonSubtitle;

  /// No description provided for @dashboardSpecLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading current device specs...'**
  String get dashboardSpecLoading;

  /// No description provided for @dashboardSpecFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load device specs. Please check permissions or platform support.'**
  String get dashboardSpecFailed;

  /// No description provided for @dashboardSpecCurrentDevice.
  ///
  /// In en, this message translates to:
  /// **'Current Device'**
  String get dashboardSpecCurrentDevice;

  /// No description provided for @dashboardSpecRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get dashboardSpecRecommended;

  /// No description provided for @dashboardSpecItemOs.
  ///
  /// In en, this message translates to:
  /// **'Operating System'**
  String get dashboardSpecItemOs;

  /// No description provided for @dashboardSpecItemCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU Cores'**
  String get dashboardSpecItemCpu;

  /// No description provided for @dashboardSpecItemMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get dashboardSpecItemMemory;

  /// No description provided for @dashboardSpecReasonOs.
  ///
  /// In en, this message translates to:
  /// **'Newer OS versions improve Bluetooth/USB permission handling and connection stability.'**
  String get dashboardSpecReasonOs;

  /// No description provided for @dashboardSpecReasonCpu.
  ///
  /// In en, this message translates to:
  /// **'More cores reduce UI stutter during real-time parsing, charts, and monitoring.'**
  String get dashboardSpecReasonCpu;

  /// No description provided for @dashboardSpecReasonMemory.
  ///
  /// In en, this message translates to:
  /// **'Enough memory prevents frame drops when running multiple charts and logs together.'**
  String get dashboardSpecReasonMemory;

  /// No description provided for @dashboardSpecReasonConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection quality matters as much as device specs.'**
  String get dashboardSpecReasonConnection;

  /// No description provided for @dashboardSpecConnectionTip.
  ///
  /// In en, this message translates to:
  /// **'Use a stable USB cable/OTG adapter and reliable Bluetooth pairing for the best result.'**
  String get dashboardSpecConnectionTip;

  /// No description provided for @dashboardSpecStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get dashboardSpecStatusGood;

  /// No description provided for @dashboardSpecStatusNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get dashboardSpecStatusNeedAttention;

  /// No description provided for @dashboardSpecStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get dashboardSpecStatusUnknown;

  /// No description provided for @dashboardSpecUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get dashboardSpecUnknownValue;

  /// No description provided for @settingsTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTabSettings;

  /// No description provided for @settingsTabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsTabAbout;

  /// No description provided for @settingsTabLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get settingsTabLicense;

  /// No description provided for @generalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettingsTitle;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data Settings'**
  String get settingsDataSection;

  /// No description provided for @settingsAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto Data Save'**
  String get settingsAutoSave;

  /// No description provided for @settingsAutoSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically save received data to Hive'**
  String get settingsAutoSaveDesc;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppSection;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get settingsDarkModeDesc;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDataMgmt.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataMgmt;

  /// No description provided for @settingsSavedData.
  ///
  /// In en, this message translates to:
  /// **'Saved Data'**
  String get settingsSavedData;

  /// No description provided for @settingsSavedDataDesc.
  ///
  /// In en, this message translates to:
  /// **'View saved data files (coming soon)'**
  String get settingsSavedDataDesc;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved data'**
  String get settingsDeleteAllDesc;

  /// No description provided for @dialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Data'**
  String get dialogDeleteTitle;

  /// No description provided for @dialogDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all data?\nThis action cannot be undone.'**
  String get dialogDeleteContent;

  /// No description provided for @snackbarDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted'**
  String get snackbarDataDeleted;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get langKorean;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get langJapanese;

  /// No description provided for @languageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageSelectTitle;

  /// No description provided for @connectionInfoTab.
  ///
  /// In en, this message translates to:
  /// **'Connection Info'**
  String get connectionInfoTab;

  /// No description provided for @deviceConnectionTab.
  ///
  /// In en, this message translates to:
  /// **'Device Connection'**
  String get deviceConnectionTab;

  /// No description provided for @serialTab.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serialTab;

  /// No description provided for @bluetoothSerialTab.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Serial'**
  String get bluetoothSerialTab;

  /// No description provided for @realtimeTable.
  ///
  /// In en, this message translates to:
  /// **'Real-time Table'**
  String get realtimeTable;

  /// No description provided for @realtimeGraph.
  ///
  /// In en, this message translates to:
  /// **'Real-time Graph'**
  String get realtimeGraph;

  /// No description provided for @analysisTableNoData.
  ///
  /// In en, this message translates to:
  /// **'No real-time data to display'**
  String get analysisTableNoData;

  /// No description provided for @analysisTableNoDataHint.
  ///
  /// In en, this message translates to:
  /// **'Rows will appear automatically when JSON data is received'**
  String get analysisTableNoDataHint;

  /// No description provided for @analysisTableTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get analysisTableTime;

  /// No description provided for @analysisTableRows.
  ///
  /// In en, this message translates to:
  /// **'Rows: {count}'**
  String analysisTableRows(int count);

  /// No description provided for @analysisTableShowingRecent.
  ///
  /// In en, this message translates to:
  /// **'Showing latest {shown} of {total} rows'**
  String analysisTableShowingRecent(int shown, int total);

  /// No description provided for @analysisDataTab.
  ///
  /// In en, this message translates to:
  /// **'Raw Data'**
  String get analysisDataTab;

  /// No description provided for @advancedGraphAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Graph Analysis'**
  String get advancedGraphAnalysis;

  /// No description provided for @analysisDataSeriesCount.
  ///
  /// In en, this message translates to:
  /// **'Series: {count}'**
  String analysisDataSeriesCount(int count);

  /// No description provided for @analysisDataPointsCount.
  ///
  /// In en, this message translates to:
  /// **'Points: {count}'**
  String analysisDataPointsCount(int count);

  /// No description provided for @statsAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsAnalysis;

  /// No description provided for @statsAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Provides basic statistics such as mean, standard deviation, max/min values.'**
  String get statsAnalysisDesc;

  /// No description provided for @correlationAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Correlation'**
  String get correlationAnalysis;

  /// No description provided for @correlationAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Analyzes and visualizes correlations between multiple data.'**
  String get correlationAnalysisDesc;

  /// No description provided for @fftAnalysis.
  ///
  /// In en, this message translates to:
  /// **'FFT Analysis'**
  String get fftAnalysis;

  /// No description provided for @fftAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Checks frequency components of signals through frequency domain analysis.'**
  String get fftAnalysisDesc;

  /// No description provided for @fftEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data. Start receiving numeric JSON first.'**
  String get fftEmpty;

  /// No description provided for @fftNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Not enough samples for FFT.'**
  String get fftNotEnough;

  /// No description provided for @fftSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get fftSeries;

  /// No description provided for @fftWindowSize.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get fftWindowSize;

  /// No description provided for @fftWindowFunction.
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get fftWindowFunction;

  /// No description provided for @fftWindowRectangular.
  ///
  /// In en, this message translates to:
  /// **'Rectangular'**
  String get fftWindowRectangular;

  /// No description provided for @fftWindowHann.
  ///
  /// In en, this message translates to:
  /// **'Hann'**
  String get fftWindowHann;

  /// No description provided for @fftSampleCount.
  ///
  /// In en, this message translates to:
  /// **'Samples: {count}'**
  String fftSampleCount(int count);

  /// No description provided for @fftSampleRate.
  ///
  /// In en, this message translates to:
  /// **'Sample rate: {rate} Hz'**
  String fftSampleRate(String rate);

  /// No description provided for @fftNyquist.
  ///
  /// In en, this message translates to:
  /// **'Max detectable: {hz} Hz (Nyquist)'**
  String fftNyquist(String hz);

  /// No description provided for @fftJitterWarning.
  ///
  /// In en, this message translates to:
  /// **'Sample interval is unstable (±{percent}%). Frequency results may be inaccurate.'**
  String fftJitterWarning(String percent);

  /// No description provided for @fftPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak: {freq} Hz ({mag})'**
  String fftPeak(String freq, String mag);

  /// No description provided for @fftAxisFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency (Hz)'**
  String get fftAxisFrequency;

  /// No description provided for @fftAxisMagnitude.
  ///
  /// In en, this message translates to:
  /// **'Magnitude'**
  String get fftAxisMagnitude;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'🚧 Coming Soon 🚧'**
  String get comingSoon;

  /// No description provided for @preparingMsg.
  ///
  /// In en, this message translates to:
  /// **'In preparation'**
  String get preparingMsg;

  /// No description provided for @newSketch.
  ///
  /// In en, this message translates to:
  /// **'New Sketch'**
  String get newSketch;

  /// No description provided for @openSketch.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSketch;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @connectDeviceFirst.
  ///
  /// In en, this message translates to:
  /// **'Please connect a device first'**
  String get connectDeviceFirst;

  /// No description provided for @aboutInfoComingSoon.
  ///
  /// In en, this message translates to:
  /// **'App info will be updated later'**
  String get aboutInfoComingSoon;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @licenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licenseTitle;

  /// No description provided for @licensePackageCountDesc.
  ///
  /// In en, this message translates to:
  /// **'This app uses {count} open source packages.\nCheck each package’s license below.'**
  String licensePackageCountDesc(int count);

  /// No description provided for @licenseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String licenseLoadError(String error);

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'No chart data available'**
  String get chartNoData;

  /// No description provided for @chartNoDataHint.
  ///
  /// In en, this message translates to:
  /// **'Send numeric JSON data or import CSV/JSON files to see charts'**
  String get chartNoDataHint;

  /// No description provided for @chartDataSeries.
  ///
  /// In en, this message translates to:
  /// **'Data Series'**
  String get chartDataSeries;

  /// No description provided for @chartClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get chartClearData;

  /// No description provided for @chartNoDataPoints.
  ///
  /// In en, this message translates to:
  /// **'No data points'**
  String get chartNoDataPoints;

  /// No description provided for @chartCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get chartCurrent;

  /// No description provided for @chartMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get chartMin;

  /// No description provided for @chartMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get chartMax;

  /// No description provided for @chartPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get chartPoints;

  /// No description provided for @chartImportData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get chartImportData;

  /// No description provided for @chartSaveData.
  ///
  /// In en, this message translates to:
  /// **'Save Data'**
  String get chartSaveData;

  /// No description provided for @chartSaveAsJson.
  ///
  /// In en, this message translates to:
  /// **'Save as JSON'**
  String get chartSaveAsJson;

  /// No description provided for @chartSaveAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Save as CSV'**
  String get chartSaveAsCsv;

  /// No description provided for @chartLoadData.
  ///
  /// In en, this message translates to:
  /// **'Load Data'**
  String get chartLoadData;

  /// No description provided for @chartSavedJson.
  ///
  /// In en, this message translates to:
  /// **'Saved JSON: {path}'**
  String chartSavedJson(String path);

  /// No description provided for @chartLoadedSeries.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} series'**
  String chartLoadedSeries(int count);

  /// No description provided for @chartExportedCsv.
  ///
  /// In en, this message translates to:
  /// **'Exported CSV: {path}'**
  String chartExportedCsv(String path);

  /// No description provided for @analysisLoadRealtime.
  ///
  /// In en, this message translates to:
  /// **'Load Realtime Data'**
  String get analysisLoadRealtime;

  /// No description provided for @analysisLoadRealtimeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Apply current live data to the analysis view'**
  String get analysisLoadRealtimeTooltip;

  /// No description provided for @analysisLoadedPoints.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} series'**
  String analysisLoadedPoints(int count);

  /// No description provided for @analysisClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get analysisClearConfirmTitle;

  /// No description provided for @analysisClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save before clearing?\nData will be permanently lost if not saved.'**
  String get analysisClearConfirmMessage;

  /// No description provided for @analysisClearSaveAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Save then Clear'**
  String get analysisClearSaveAndDelete;

  /// No description provided for @analysisClearDeleteOnly.
  ///
  /// In en, this message translates to:
  /// **'Clear without Saving'**
  String get analysisClearDeleteOnly;

  /// No description provided for @chartLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data: {error}'**
  String chartLoadFailed(String error);

  /// No description provided for @tabDirectWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get tabDirectWrite;

  /// No description provided for @tabSampleCodes.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get tabSampleCodes;

  /// No description provided for @compilingOnServer.
  ///
  /// In en, this message translates to:
  /// **'Compiling on server...'**
  String get compilingOnServer;

  /// No description provided for @compileFailed.
  ///
  /// In en, this message translates to:
  /// **'Compile failed'**
  String get compileFailed;

  /// No description provided for @uploadingToDevice.
  ///
  /// In en, this message translates to:
  /// **'Uploading to device...'**
  String get uploadingToDevice;

  /// No description provided for @androidSelectHex.
  ///
  /// In en, this message translates to:
  /// **'Select HEX file'**
  String get androidSelectHex;

  /// No description provided for @androidCloudCompileDesc.
  ///
  /// In en, this message translates to:
  /// **'On Android, sketches are compiled in the cloud and uploaded with STK500 over USB.'**
  String get androidCloudCompileDesc;

  /// No description provided for @sampleEditButton.
  ///
  /// In en, this message translates to:
  /// **'Load into editor'**
  String get sampleEditButton;

  /// No description provided for @sampleDiagCategory.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get sampleDiagCategory;

  /// No description provided for @sampleGeneralCategory.
  ///
  /// In en, this message translates to:
  /// **'Sample Code'**
  String get sampleGeneralCategory;

  /// No description provided for @sampleDiagBlink.
  ///
  /// In en, this message translates to:
  /// **'[Diag] LED Blink'**
  String get sampleDiagBlink;

  /// No description provided for @sampleDiagBlinkDesc.
  ///
  /// In en, this message translates to:
  /// **'No wiring needed. Blink the built-in LED to verify board upload.'**
  String get sampleDiagBlinkDesc;

  /// No description provided for @sampleDiagJsonRandom.
  ///
  /// In en, this message translates to:
  /// **'[Diag] Random JSON'**
  String get sampleDiagJsonRandom;

  /// No description provided for @sampleDiagJsonRandomDesc.
  ///
  /// In en, this message translates to:
  /// **'Send random a/b/c values as JSON every second. Use to verify serial receive and charts.'**
  String get sampleDiagJsonRandomDesc;

  /// No description provided for @sampleBlink.
  ///
  /// In en, this message translates to:
  /// **'Blink LED'**
  String get sampleBlink;

  /// No description provided for @sampleBlinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Blink the built-in LED every second.'**
  String get sampleBlinkDesc;

  /// No description provided for @sampleBlinkMillis.
  ///
  /// In en, this message translates to:
  /// **'Non-blocking Blink (millis)'**
  String get sampleBlinkMillis;

  /// No description provided for @sampleBlinkMillisDesc.
  ///
  /// In en, this message translates to:
  /// **'Blink the built-in LED without delay() to keep loop responsive.'**
  String get sampleBlinkMillisDesc;

  /// No description provided for @sampleSerialHello.
  ///
  /// In en, this message translates to:
  /// **'Serial Hello'**
  String get sampleSerialHello;

  /// No description provided for @sampleSerialHelloDesc.
  ///
  /// In en, this message translates to:
  /// **'Send greeting text periodically over serial.'**
  String get sampleSerialHelloDesc;

  /// No description provided for @sampleAnalogRead.
  ///
  /// In en, this message translates to:
  /// **'Analog Read'**
  String get sampleAnalogRead;

  /// No description provided for @sampleAnalogReadDesc.
  ///
  /// In en, this message translates to:
  /// **'Read analog input and print the value.'**
  String get sampleAnalogReadDesc;

  /// No description provided for @samplePwmFade.
  ///
  /// In en, this message translates to:
  /// **'PWM LED Fade'**
  String get samplePwmFade;

  /// No description provided for @samplePwmFadeDesc.
  ///
  /// In en, this message translates to:
  /// **'Fade an LED on PWM pin 9 from dark to bright and back.'**
  String get samplePwmFadeDesc;

  /// No description provided for @sampleServoSweep.
  ///
  /// In en, this message translates to:
  /// **'Servo Sweep'**
  String get sampleServoSweep;

  /// No description provided for @sampleServoSweepDesc.
  ///
  /// In en, this message translates to:
  /// **'Move a servo back and forth smoothly.'**
  String get sampleServoSweepDesc;

  /// No description provided for @sampleTempDht.
  ///
  /// In en, this message translates to:
  /// **'DHT Temperature'**
  String get sampleTempDht;

  /// No description provided for @sampleTempDhtDesc.
  ///
  /// In en, this message translates to:
  /// **'Read DHT sensor values and print them.'**
  String get sampleTempDhtDesc;

  /// No description provided for @sampleLedControl.
  ///
  /// In en, this message translates to:
  /// **'LED Control'**
  String get sampleLedControl;

  /// No description provided for @sampleLedControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn LED on/off by serial command.'**
  String get sampleLedControlDesc;

  /// No description provided for @sampleButtonDebounce.
  ///
  /// In en, this message translates to:
  /// **'Button Debounce Toggle'**
  String get sampleButtonDebounce;

  /// No description provided for @sampleButtonDebounceDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle built-in LED with a debounced INPUT_PULLUP button.'**
  String get sampleButtonDebounceDesc;

  /// No description provided for @sampleUltrasonic.
  ///
  /// In en, this message translates to:
  /// **'Ultrasonic Distance'**
  String get sampleUltrasonic;

  /// No description provided for @sampleUltrasonicDesc.
  ///
  /// In en, this message translates to:
  /// **'Measure distance with an HC-SR04 sensor.'**
  String get sampleUltrasonicDesc;

  /// No description provided for @realtimeReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get realtimeReceiving;

  /// No description provided for @realtimePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get realtimePaused;

  /// No description provided for @realtimeSaveData.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get realtimeSaveData;

  /// No description provided for @realtimeClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get realtimeClearData;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @tooltipDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get tooltipDisconnect;

  /// No description provided for @tooltipClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tooltipClear;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @confirmDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect device?'**
  String get confirmDisconnectTitle;

  /// No description provided for @confirmDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Data is currently being received.\nDisconnect anyway?'**
  String get confirmDisconnectMessage;

  /// No description provided for @confirmClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear data?'**
  String get confirmClearTitle;

  /// No description provided for @confirmClearMessage.
  ///
  /// In en, this message translates to:
  /// **'All received and chart data will be removed. This cannot be undone.'**
  String get confirmClearMessage;

  /// No description provided for @terminalNoData.
  ///
  /// In en, this message translates to:
  /// **'No data received yet'**
  String get terminalNoData;

  /// No description provided for @terminalAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get terminalAutoScroll;

  /// No description provided for @terminalSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get terminalSend;

  /// No description provided for @terminalSendHint.
  ///
  /// In en, this message translates to:
  /// **'Enter data to send...'**
  String get terminalSendHint;

  /// No description provided for @terminalReceivedCount.
  ///
  /// In en, this message translates to:
  /// **'Received: {count} messages'**
  String terminalReceivedCount(int count);

  /// No description provided for @deviceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices found.\nTap \"Scan Devices\" to search.'**
  String get deviceListEmpty;

  /// No description provided for @connectionConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connectionConnecting;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get connectionFailed;

  /// No description provided for @wifiDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add WiFi Device'**
  String get wifiDialogTitle;

  /// No description provided for @wifiDialogNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get wifiDialogNameLabel;

  /// No description provided for @wifiDialogAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'WebSocket Address'**
  String get wifiDialogAddressLabel;

  /// No description provided for @wifiDialogAddressHint.
  ///
  /// In en, this message translates to:
  /// **'ws://192.168.0.10:81'**
  String get wifiDialogAddressHint;

  /// No description provided for @wifiDialogNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a device name'**
  String get wifiDialogNameEmpty;

  /// No description provided for @wifiDialogAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must start with ws:// or wss://'**
  String get wifiDialogAddressInvalid;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @baudrateChanging.
  ///
  /// In en, this message translates to:
  /// **'Changing baud rate... ({rate} bps)'**
  String baudrateChanging(int rate);

  /// No description provided for @baudrateChanged.
  ///
  /// In en, this message translates to:
  /// **'Baud rate changed ({rate} bps)'**
  String baudrateChanged(int rate);

  /// No description provided for @reconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Reconnection failed'**
  String get reconnectFailed;

  /// No description provided for @codeSenderTitle.
  ///
  /// In en, this message translates to:
  /// **'Code Sender'**
  String get codeSenderTitle;

  /// No description provided for @codeSenderTagline.
  ///
  /// In en, this message translates to:
  /// **'Write, verify, and upload code — all in one place!'**
  String get codeSenderTagline;

  /// No description provided for @codeSenderTabGuide.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get codeSenderTabGuide;

  /// No description provided for @codeSenderTabWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get codeSenderTabWrite;

  /// No description provided for @codeSenderTabSamples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get codeSenderTabSamples;

  /// No description provided for @codeSenderStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Procedure'**
  String get codeSenderStepsTitle;

  /// No description provided for @codeSenderStepsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1) Pick a sample or write code\n2) Verify to compile\n3) Make sure the device is connected\n4) Upload to send'**
  String get codeSenderStepsSubtitle;

  /// No description provided for @codeSenderRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get codeSenderRequirementsTitle;

  /// No description provided for @codeSenderRequirementBoard.
  ///
  /// In en, this message translates to:
  /// **'• Board connected: The target board/port must be connected before upload.'**
  String get codeSenderRequirementBoard;

  /// No description provided for @codeSenderRequirementOnline.
  ///
  /// In en, this message translates to:
  /// **'• Online: Android cloud compile needs an internet connection.'**
  String get codeSenderRequirementOnline;

  /// No description provided for @codeSenderRequirementOs.
  ///
  /// In en, this message translates to:
  /// **'• Supported OS: Write/Verify/Upload works on Android/Windows. HEX upload is Android-only advanced.'**
  String get codeSenderRequirementOs;

  /// No description provided for @codeSenderAndroidModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Android behavior'**
  String get codeSenderAndroidModeTitle;

  /// No description provided for @codeSenderAndroidModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Code is compiled on the server and uploaded over USB (STK500).'**
  String get codeSenderAndroidModeSubtitle;

  /// No description provided for @codeSenderCautionTitle.
  ///
  /// In en, this message translates to:
  /// **'Caveats'**
  String get codeSenderCautionTitle;

  /// No description provided for @codeSenderCautionLibs.
  ///
  /// In en, this message translates to:
  /// **'• Libraries not bundled with samples cannot be auto-installed yet.'**
  String get codeSenderCautionLibs;

  /// No description provided for @codeSenderCautionPort.
  ///
  /// In en, this message translates to:
  /// **'• On upload failure, release the port (Serial Monitor etc.) and retry.'**
  String get codeSenderCautionPort;

  /// No description provided for @codeSenderOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite editor?'**
  String get codeSenderOverwriteTitle;

  /// No description provided for @codeSenderOverwriteMessage.
  ///
  /// In en, this message translates to:
  /// **'You have code in the editor.\nLoading a sample will discard it.'**
  String get codeSenderOverwriteMessage;

  /// No description provided for @codeSenderOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get codeSenderOverwrite;

  /// No description provided for @codeSenderIosUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Code upload is not supported on iOS.\nPlease upload from PC or Android.'**
  String get codeSenderIosUnsupported;

  /// No description provided for @codeSenderBoardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The {board} board does not support Android USB upload.\nPlease upload from PC.'**
  String codeSenderBoardUnsupported(String board);

  /// No description provided for @codeSenderPortNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Port information is not available'**
  String get codeSenderPortNotAvailable;

  /// No description provided for @codeSenderSaveComplete.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String codeSenderSaveComplete(String path);

  /// No description provided for @codeSenderSaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save sketch'**
  String get codeSenderSaveDialogTitle;

  /// No description provided for @codeSenderNewSketchTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new sketch'**
  String get codeSenderNewSketchTitle;

  /// No description provided for @codeSenderNewSketchMessage.
  ///
  /// In en, this message translates to:
  /// **'Existing code in the editor will be discarded. Continue?'**
  String get codeSenderNewSketchMessage;

  /// No description provided for @codeSenderNewSketchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get codeSenderNewSketchConfirm;

  /// No description provided for @codeSenderHexHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'What is a HEX file?'**
  String get codeSenderHexHelpTitle;

  /// No description provided for @codeSenderHexHelpContent.
  ///
  /// In en, this message translates to:
  /// **'A HEX file is pre-compiled firmware.\n\nThis is an Android-only advanced option for uploading an existing .hex directly, without source compilation.'**
  String get codeSenderHexHelpContent;

  /// No description provided for @codeSenderTooltipSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get codeSenderTooltipSave;

  /// No description provided for @codeSenderTooltipSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get codeSenderTooltipSaveAs;

  /// No description provided for @codeSenderTooltipCopyOutput.
  ///
  /// In en, this message translates to:
  /// **'Copy output'**
  String get codeSenderTooltipCopyOutput;

  /// No description provided for @codeSenderTooltipClearOutput.
  ///
  /// In en, this message translates to:
  /// **'Clear output'**
  String get codeSenderTooltipClearOutput;

  /// No description provided for @codeSenderTooltipHexHelp.
  ///
  /// In en, this message translates to:
  /// **'About HEX files'**
  String get codeSenderTooltipHexHelp;

  /// No description provided for @codeSenderAdvancedShow.
  ///
  /// In en, this message translates to:
  /// **'Show advanced'**
  String get codeSenderAdvancedShow;

  /// No description provided for @codeSenderAdvancedHide.
  ///
  /// In en, this message translates to:
  /// **'Hide advanced'**
  String get codeSenderAdvancedHide;

  /// No description provided for @codeSenderHexUpload.
  ///
  /// In en, this message translates to:
  /// **'HEX upload'**
  String get codeSenderHexUpload;

  /// No description provided for @codeSenderConsoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get codeSenderConsoleLabel;

  /// No description provided for @codeSenderConsolePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Compile / upload output will appear here.'**
  String get codeSenderConsolePlaceholder;

  /// No description provided for @codeSenderCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get codeSenderCopied;

  /// No description provided for @codeSenderReconnectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reconnection... (2.5s)'**
  String get codeSenderReconnectWaiting;

  /// No description provided for @codeSenderReconnectAttempting.
  ///
  /// In en, this message translates to:
  /// **'Attempting reconnection...'**
  String get codeSenderReconnectAttempting;

  /// No description provided for @codeSenderReconnectSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Reconnected'**
  String get codeSenderReconnectSuccess;

  /// No description provided for @codeSenderReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Reconnect failed — connect manually from the Device tab'**
  String get codeSenderReconnectFailed;

  /// No description provided for @codeSenderReconnectComplete.
  ///
  /// In en, this message translates to:
  /// **'✅ Reconnect complete'**
  String get codeSenderReconnectComplete;

  /// No description provided for @connectionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection Type'**
  String get connectionTypeLabel;

  /// No description provided for @connectionScan.
  ///
  /// In en, this message translates to:
  /// **'Scan Devices'**
  String get connectionScan;

  /// No description provided for @connectionScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get connectionScanning;

  /// No description provided for @connectionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectionConnect;

  /// No description provided for @connectionDeviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Arduino WiFi'**
  String get connectionDeviceNameHint;

  /// No description provided for @connectionConnectedChip.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionConnectedChip;

  /// No description provided for @connectionConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String connectionConnectedTo(String device);

  /// No description provided for @connectionNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get connectionNoDevices;

  /// No description provided for @connectionNoDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Click \"Scan Devices\" to search'**
  String get connectionNoDevicesHint;

  /// No description provided for @connectionWarnUsbTitle.
  ///
  /// In en, this message translates to:
  /// **'USB Connection'**
  String get connectionWarnUsbTitle;

  /// No description provided for @connectionWarnUsbBody.
  ///
  /// In en, this message translates to:
  /// **'• Supported on Android only\n• Match the baud rate to your Arduino sketch.'**
  String get connectionWarnUsbBody;

  /// No description provided for @connectionWarnBluetoothTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Connection'**
  String get connectionWarnBluetoothTitle;

  /// No description provided for @connectionWarnBluetoothBody.
  ///
  /// In en, this message translates to:
  /// **'• Pair the device in system settings first\n• Match the baud rate to your Arduino sketch.'**
  String get connectionWarnBluetoothBody;

  /// No description provided for @connectionWarnWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'WiFi Connection'**
  String get connectionWarnWifiTitle;

  /// No description provided for @connectionWarnWifiBody.
  ///
  /// In en, this message translates to:
  /// **'• WebSocket address format: ws://IP:PORT\n• The Arduino must run a WebSocket server.'**
  String get connectionWarnWifiBody;

  /// No description provided for @btProtocolTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Bluetooth Protocol'**
  String get btProtocolTitle;

  /// No description provided for @btProtocolChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose the protocol for {device}:'**
  String btProtocolChoose(String device);

  /// No description provided for @btProtocolClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic Bluetooth'**
  String get btProtocolClassic;

  /// No description provided for @btProtocolClassicDesc.
  ///
  /// In en, this message translates to:
  /// **'For HC-05, HC-06, etc.'**
  String get btProtocolClassicDesc;

  /// No description provided for @btProtocolBle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Low Energy (BLE)'**
  String get btProtocolBle;

  /// No description provided for @btProtocolBleDesc.
  ///
  /// In en, this message translates to:
  /// **'For modern BLE modules'**
  String get btProtocolBleDesc;

  /// No description provided for @deviceInfoDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceInfoDeviceName;

  /// No description provided for @deviceInfoAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get deviceInfoAddress;

  /// No description provided for @deviceInfoConnType.
  ///
  /// In en, this message translates to:
  /// **'Connection Type'**
  String get deviceInfoConnType;

  /// No description provided for @deviceInfoBaudRate.
  ///
  /// In en, this message translates to:
  /// **'Baud Rate'**
  String get deviceInfoBaudRate;

  /// No description provided for @deviceInfoSelectedBoard.
  ///
  /// In en, this message translates to:
  /// **'Selected Board'**
  String get deviceInfoSelectedBoard;

  /// No description provided for @deviceInfoProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get deviceInfoProtocol;

  /// No description provided for @deviceInfoBuffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering'**
  String get deviceInfoBuffering;

  /// No description provided for @deviceInfoBufferingValue.
  ///
  /// In en, this message translates to:
  /// **'50ms timeout (Arduino compatible)'**
  String get deviceInfoBufferingValue;

  /// No description provided for @deviceInfoDataFormat.
  ///
  /// In en, this message translates to:
  /// **'Data Format'**
  String get deviceInfoDataFormat;

  /// No description provided for @deviceInfoDataFormatValue.
  ///
  /// In en, this message translates to:
  /// **'Arduino BTSerial text'**
  String get deviceInfoDataFormatValue;

  /// No description provided for @deviceInfoJsonData.
  ///
  /// In en, this message translates to:
  /// **'JSON Data'**
  String get deviceInfoJsonData;

  /// No description provided for @deviceInfoJsonSub.
  ///
  /// In en, this message translates to:
  /// **'Structured data'**
  String get deviceInfoJsonSub;

  /// No description provided for @deviceInfoTextData.
  ///
  /// In en, this message translates to:
  /// **'Text Data'**
  String get deviceInfoTextData;

  /// No description provided for @deviceInfoTextSub.
  ///
  /// In en, this message translates to:
  /// **'Raw data'**
  String get deviceInfoTextSub;

  /// No description provided for @deviceInfoConnectFromTab.
  ///
  /// In en, this message translates to:
  /// **'Please connect a device from the Device Connection tab.'**
  String get deviceInfoConnectFromTab;

  /// No description provided for @deviceInfoDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get deviceInfoDeviceSettings;

  /// No description provided for @deviceInfoArduinoBoard.
  ///
  /// In en, this message translates to:
  /// **'Arduino Board'**
  String get deviceInfoArduinoBoard;

  /// No description provided for @deviceInfoAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect'**
  String get deviceInfoAutoDetect;

  /// No description provided for @deviceInfoDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected board: {board}'**
  String deviceInfoDetected(String board);

  /// No description provided for @deviceInfoRecentUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get deviceInfoRecentUsed;

  /// No description provided for @deviceInfoBaudRateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change it in the Device Connection tab'**
  String get deviceInfoBaudRateTooltip;

  /// No description provided for @dashboardSupported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get dashboardSupported;

  /// No description provided for @dashboardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get dashboardUnsupported;

  /// No description provided for @advGraphSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get advGraphSeries;

  /// No description provided for @advGraphGraph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get advGraphGraph;

  /// No description provided for @advGraphBins.
  ///
  /// In en, this message translates to:
  /// **'Bins'**
  String get advGraphBins;

  /// No description provided for @advGraphSmoothing.
  ///
  /// In en, this message translates to:
  /// **'Smoothing'**
  String get advGraphSmoothing;

  /// No description provided for @advGraphWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get advGraphWindow;

  /// No description provided for @advGraphFitLine.
  ///
  /// In en, this message translates to:
  /// **'Fit line'**
  String get advGraphFitLine;

  /// No description provided for @advGraphType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get advGraphType;

  /// No description provided for @advGraphPeakValley.
  ///
  /// In en, this message translates to:
  /// **'Peak/Valley'**
  String get advGraphPeakValley;

  /// No description provided for @advGraphProminence.
  ///
  /// In en, this message translates to:
  /// **'Prominence'**
  String get advGraphProminence;

  /// No description provided for @advGraphDerivedSeries.
  ///
  /// In en, this message translates to:
  /// **'Derived'**
  String get advGraphDerivedSeries;

  /// No description provided for @advGraphDerivedRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get advGraphDerivedRaw;

  /// No description provided for @advGraphDerivedDerivative.
  ///
  /// In en, this message translates to:
  /// **'Derivative (d/dt)'**
  String get advGraphDerivedDerivative;

  /// No description provided for @advGraphDerivedIntegral.
  ///
  /// In en, this message translates to:
  /// **'Integral (∫dt)'**
  String get advGraphDerivedIntegral;

  /// No description provided for @advGraphSeriesOperation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get advGraphSeriesOperation;

  /// No description provided for @advGraphSecondarySeries.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get advGraphSecondarySeries;

  /// No description provided for @advGraphSeriesOperationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get advGraphSeriesOperationNone;

  /// No description provided for @advGraphSeriesOperationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add (+)'**
  String get advGraphSeriesOperationAdd;

  /// No description provided for @advGraphSeriesOperationSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract (-)'**
  String get advGraphSeriesOperationSubtract;

  /// No description provided for @advGraphSeriesOperationMultiply.
  ///
  /// In en, this message translates to:
  /// **'Multiply (×)'**
  String get advGraphSeriesOperationMultiply;

  /// No description provided for @advGraphSeriesOperationDivide.
  ///
  /// In en, this message translates to:
  /// **'Divide (÷)'**
  String get advGraphSeriesOperationDivide;

  /// No description provided for @advGraphFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get advGraphFormula;

  /// No description provided for @advGraphFormulaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. x*2+1, sin(x), x+y, x+t'**
  String get advGraphFormulaHint;

  /// No description provided for @advGraphFormulaApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get advGraphFormulaApply;

  /// No description provided for @advGraphFormulaVariables.
  ///
  /// In en, this message translates to:
  /// **'Variables: x=primary, y=secondary, t=seconds from start'**
  String get advGraphFormulaVariables;

  /// No description provided for @advGraphFormulaPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets:'**
  String get advGraphFormulaPresets;

  /// No description provided for @advGraphFormulaSecondaryAlignment.
  ///
  /// In en, this message translates to:
  /// **'Y match'**
  String get advGraphFormulaSecondaryAlignment;

  /// No description provided for @advGraphFormulaAlignIndex.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get advGraphFormulaAlignIndex;

  /// No description provided for @advGraphFormulaAlignNearestTime.
  ///
  /// In en, this message translates to:
  /// **'Nearest time'**
  String get advGraphFormulaAlignNearestTime;

  /// No description provided for @advGraphFormulaNearestTolerance.
  ///
  /// In en, this message translates to:
  /// **'Tolerance'**
  String get advGraphFormulaNearestTolerance;

  /// No description provided for @advGraphFormulaOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'If no match'**
  String get advGraphFormulaOutOfRange;

  /// No description provided for @advGraphFormulaOutOfRangeZero.
  ///
  /// In en, this message translates to:
  /// **'Use 0'**
  String get advGraphFormulaOutOfRangeZero;

  /// No description provided for @advGraphFormulaOutOfRangeHoldLast.
  ///
  /// In en, this message translates to:
  /// **'Hold previous'**
  String get advGraphFormulaOutOfRangeHoldLast;

  /// No description provided for @advGraphFormulaOutOfRangeInterpolate.
  ///
  /// In en, this message translates to:
  /// **'Interpolate'**
  String get advGraphFormulaOutOfRangeInterpolate;

  /// No description provided for @advGraphFormulaInterpolationMode.
  ///
  /// In en, this message translates to:
  /// **'Interpolation'**
  String get advGraphFormulaInterpolationMode;

  /// No description provided for @advGraphFormulaInterpolationLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get advGraphFormulaInterpolationLinear;

  /// No description provided for @advGraphFormulaInterpolationStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get advGraphFormulaInterpolationStep;

  /// No description provided for @advGraphFormulaOverlayCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare overlay'**
  String get advGraphFormulaOverlayCompare;

  /// No description provided for @advGraphFormulaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Formula error: {error}'**
  String advGraphFormulaInvalid(String error);

  /// No description provided for @advGraphErrorBars.
  ///
  /// In en, this message translates to:
  /// **'Error bars'**
  String get advGraphErrorBars;

  /// No description provided for @advGraphErrorMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get advGraphErrorMode;

  /// No description provided for @advGraphErrorModeNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get advGraphErrorModeNone;

  /// No description provided for @advGraphErrorModeAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Absolute'**
  String get advGraphErrorModeAbsolute;

  /// No description provided for @advGraphErrorModePercentage.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get advGraphErrorModePercentage;

  /// No description provided for @advGraphErrorValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get advGraphErrorValue;

  /// No description provided for @advGraphErrorPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get advGraphErrorPercent;

  /// No description provided for @advGraphMeasurementTools.
  ///
  /// In en, this message translates to:
  /// **'Measurement tools'**
  String get advGraphMeasurementTools;

  /// No description provided for @advGraphCursorA.
  ///
  /// In en, this message translates to:
  /// **'Cursor A'**
  String get advGraphCursorA;

  /// No description provided for @advGraphCursorB.
  ///
  /// In en, this message translates to:
  /// **'Cursor B'**
  String get advGraphCursorB;

  /// No description provided for @advGraphClearCursors.
  ///
  /// In en, this message translates to:
  /// **'Clear cursors'**
  String get advGraphClearCursors;

  /// No description provided for @advGraphDeltaX.
  ///
  /// In en, this message translates to:
  /// **'Δx'**
  String get advGraphDeltaX;

  /// No description provided for @advGraphDeltaY.
  ///
  /// In en, this message translates to:
  /// **'Δy'**
  String get advGraphDeltaY;

  /// No description provided for @advGraphSlope.
  ///
  /// In en, this message translates to:
  /// **'Slope'**
  String get advGraphSlope;

  /// No description provided for @advGraphMeasurementHintTitle.
  ///
  /// In en, this message translates to:
  /// **'How to measure'**
  String get advGraphMeasurementHintTitle;

  /// No description provided for @advGraphMeasurementHint.
  ///
  /// In en, this message translates to:
  /// **'Enable tools and tap chart points to set Cursor A and B.'**
  String get advGraphMeasurementHint;

  /// No description provided for @advGraphNoPoints.
  ///
  /// In en, this message translates to:
  /// **'No points'**
  String get advGraphNoPoints;

  /// No description provided for @advGraphNoData.
  ///
  /// In en, this message translates to:
  /// **'No data. Load data or start receiving numeric JSON first.'**
  String get advGraphNoData;

  /// No description provided for @advGraphHistogramNeedPoints.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 points for histogram.'**
  String get advGraphHistogramNeedPoints;

  /// No description provided for @advGraphHistogramConstantValues.
  ///
  /// In en, this message translates to:
  /// **'Values are constant. Histogram is not meaningful.'**
  String get advGraphHistogramConstantValues;

  /// No description provided for @advGraphFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get advGraphFit;

  /// No description provided for @advGraphEquation.
  ///
  /// In en, this message translates to:
  /// **'Equation'**
  String get advGraphEquation;

  /// No description provided for @advGraphRSquared.
  ///
  /// In en, this message translates to:
  /// **'R^2'**
  String get advGraphRSquared;

  /// No description provided for @advGraphCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get advGraphCount;

  /// No description provided for @advGraphFitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fit unavailable for current data.'**
  String get advGraphFitUnavailable;

  /// No description provided for @advGraphFitQuadraticNeedPoints.
  ///
  /// In en, this message translates to:
  /// **'Quadratic fit needs at least 3 valid points.'**
  String get advGraphFitQuadraticNeedPoints;

  /// No description provided for @advGraphFitExponentialNeedPoints.
  ///
  /// In en, this message translates to:
  /// **'Exponential fit needs at least 2 positive points.'**
  String get advGraphFitExponentialNeedPoints;

  /// No description provided for @advGraphFitPowerNeedPoints.
  ///
  /// In en, this message translates to:
  /// **'Power fit needs at least 2 positive points.'**
  String get advGraphFitPowerNeedPoints;

  /// No description provided for @advGraphFitLogarithmicNeedPoints.
  ///
  /// In en, this message translates to:
  /// **'Logarithmic fit needs at least 2 valid points.'**
  String get advGraphFitLogarithmicNeedPoints;

  /// No description provided for @advGraphModeLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get advGraphModeLine;

  /// No description provided for @advGraphModeScatter.
  ///
  /// In en, this message translates to:
  /// **'Scatter'**
  String get advGraphModeScatter;

  /// No description provided for @advGraphModeBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get advGraphModeBar;

  /// No description provided for @advGraphModeArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get advGraphModeArea;

  /// No description provided for @advGraphModeHistogram.
  ///
  /// In en, this message translates to:
  /// **'Histogram'**
  String get advGraphModeHistogram;

  /// No description provided for @advGraphRegressionLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get advGraphRegressionLinear;

  /// No description provided for @advGraphRegressionQuadratic.
  ///
  /// In en, this message translates to:
  /// **'Quadratic'**
  String get advGraphRegressionQuadratic;

  /// No description provided for @advGraphRegressionExponential.
  ///
  /// In en, this message translates to:
  /// **'Exponential'**
  String get advGraphRegressionExponential;

  /// No description provided for @advGraphRegressionPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get advGraphRegressionPower;

  /// No description provided for @advGraphRegressionLogarithmic.
  ///
  /// In en, this message translates to:
  /// **'Logarithmic'**
  String get advGraphRegressionLogarithmic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
