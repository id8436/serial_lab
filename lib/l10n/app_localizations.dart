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

  /// No description provided for @realtimeGraph.
  ///
  /// In en, this message translates to:
  /// **'Real-time Graph'**
  String get realtimeGraph;

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
  /// **'Send numeric JSON data to see charts'**
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
