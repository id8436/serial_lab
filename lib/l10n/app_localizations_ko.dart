// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Serial Lab';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get navHome => '홈';

  @override
  String get navHomeSubtitle => '앱 개요 및 빠른 실행';

  @override
  String get navDevice => '장치';

  @override
  String get navDeviceSubtitle => '기기 연결 및 설정';

  @override
  String get navSerialMonitor => '시리얼 모니터';

  @override
  String get navSerialMonitorSubtitle => '실시간 데이터 모니터링';

  @override
  String get navRealtimeData => '실시간 데이터';

  @override
  String get navRealtimeDataSubtitle => '실시간 표와 그래프 보기';

  @override
  String get navDataAnalysis => '데이터 분석';

  @override
  String get navDataAnalysisSubtitle => 'JSON 데이터 시각화';

  @override
  String get navCodeSend => '코드 전송';

  @override
  String get navCodeSendSubtitle => 'Arduino 코드 컴파일 & 업로드';

  @override
  String get navSettings => '설정';

  @override
  String get navSettingsSubtitle => '앱 환경 설정';

  @override
  String drawerConnectedTo(String device) {
    return 'Connected to $device';
  }

  @override
  String get drawerNoDevice => 'No device connected';

  @override
  String get drawerQuickActions => '빠른 실행';

  @override
  String get drawerClearData => '데이터 지우기';

  @override
  String get drawerDataCleared => '데이터가 삭제되었습니다';

  @override
  String get drawerDisconnect => '연결 해제';

  @override
  String get dashboardWelcome => 'Serial Lab에 오신 것을 환영합니다!';

  @override
  String get dashboardSubtitle => '아두이노와 시리얼 통신하는 데이터 분석 플랫폼';

  @override
  String get dashboardGettingStarted => '🚀 시작하기';

  @override
  String get dashboardStep1Title => '기기 연결';

  @override
  String get dashboardStep1Desc => '좌측 메뉴에서 \"기기 연결\"을 선택하세요';

  @override
  String get dashboardStep2Title => '데이터 수신';

  @override
  String get dashboardStep2Desc => 'JSON 형식으로 데이터를 전송하면 자동으로 파싱';

  @override
  String get dashboardStep3Title => '실시간 분석';

  @override
  String get dashboardStep3Desc => '그래프로 데이터를 시각화하고 분석';

  @override
  String get dashboardIntro => '📱 소개';

  @override
  String get dashboardIntroText =>
      'Serial Lab은 아두이노 및 기타 마이크로컨트롤러와 시리얼 통신을 수행하고, 실시간으로 데이터를 시각화 및 분석할 수 있는 올인원 도구입니다.\n\nUSB, Bluetooth, WiFi 등 다양한 통신 방식을 지원하며, JSON 형식의 데이터를 자동으로 파싱하여 그래프로 표시합니다.';

  @override
  String get dashboardMainFeatures => '✨ 주요 기능';

  @override
  String get dashboardUsbSerial => 'USB 시리얼 통신';

  @override
  String get dashboardBluetooth => 'Bluetooth 통신';

  @override
  String get dashboardWifi => 'WiFi (WebSocket) 통신';

  @override
  String get dashboardRealtimeViz => '실시간 데이터 시각화';

  @override
  String get dashboardSerialMonitor => '시리얼 모니터';

  @override
  String get dashboardDataAnalysis => '데이터 분석 (통계, 상관도, FFT)';

  @override
  String get dashboardCodeSnippet => '코드 스니펫 전송';

  @override
  String get dashboardIosNoticeTitle => 'iPhone / iPad 사용자 안내';

  @override
  String get dashboardIosAvailable =>
      'BLE · WiFi 시리얼 통신 ✓\n실시간 데이터 시각화 ✓\n시리얼 모니터 ✓\n데이터 분석 ✓';

  @override
  String get dashboardIosUnavailable =>
      'USB 연결 ✗\nClassic Bluetooth (HC-05/06) ✗\n코드 업로드 ✗\n(iOS 시스템 정책 제한)';

  @override
  String get settingsTabSettings => '설정';

  @override
  String get settingsTabAbout => '정보';

  @override
  String get settingsTabLicense => '라이선스';

  @override
  String get generalSettingsTitle => '일반 설정';

  @override
  String get settingsDataSection => '데이터 설정';

  @override
  String get settingsAutoSave => '자동 데이터 저장';

  @override
  String get settingsAutoSaveDesc => '수신한 데이터를 자동으로 Hive에 저장';

  @override
  String get settingsAppSection => '앱 설정';

  @override
  String get settingsDarkMode => '다크 모드';

  @override
  String get settingsDarkModeDesc => '어두운 테마 사용';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsDataMgmt => '데이터 관리';

  @override
  String get settingsSavedData => '저장된 데이터';

  @override
  String get settingsSavedDataDesc => '저장된 데이터 파일 보기 (개발 예정)';

  @override
  String get settingsDeleteAll => '모든 데이터 삭제';

  @override
  String get settingsDeleteAllDesc => '저장된 모든 데이터를 삭제합니다';

  @override
  String get dialogDeleteTitle => '데이터 삭제';

  @override
  String get dialogDeleteContent => '모든 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get snackbarDataDeleted => '모든 데이터가 삭제되었습니다';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get languageSelectTitle => '언어 선택';

  @override
  String get connectionInfoTab => '연결 정보';

  @override
  String get deviceConnectionTab => '기기 연결';

  @override
  String get serialTab => '시리얼';

  @override
  String get bluetoothSerialTab => '블루투스 시리얼';

  @override
  String get realtimeTable => '실시간 표';

  @override
  String get realtimeGraph => '실시간 그래프';

  @override
  String get analysisTableNoData => '표시할 실시간 데이터가 없습니다';

  @override
  String get analysisTableNoDataHint => 'JSON 형식 데이터가 수신되면 표에 자동으로 누적됩니다';

  @override
  String get analysisTableTime => '시간';

  @override
  String analysisTableRows(int count) {
    return '행 수: $count';
  }

  @override
  String analysisTableShowingRecent(int shown, int total) {
    return '최근 $shown / 전체 $total행 표시 중';
  }

  @override
  String get analysisDataTab => '기초데이터';

  @override
  String get advancedGraphAnalysis => '그래프 분석';

  @override
  String analysisDataSeriesCount(int count) {
    return '시리즈: $count';
  }

  @override
  String analysisDataPointsCount(int count) {
    return '포인트: $count';
  }

  @override
  String get statsAnalysis => '통계 분석';

  @override
  String get statsAnalysisDesc => '평균, 표준편차, 최대/최소값 등 기본 통계 정보를 제공합니다.';

  @override
  String get correlationAnalysis => '상관도 분석';

  @override
  String get correlationAnalysisDesc => '여러 데이터 간의 상관관계를 분석하고 시각화합니다.';

  @override
  String get fftAnalysis => 'FFT 분석';

  @override
  String get fftAnalysisDesc => '주파수 영역 분석으로 신호의 주파수 성분을 확인합니다.';

  @override
  String get comingSoon => '🚧 Coming Soon 🚧';

  @override
  String get preparingMsg => '준비 중입니다';

  @override
  String get newSketch => '새 스케치';

  @override
  String get openSketch => '열기';

  @override
  String get verify => '검증';

  @override
  String get upload => '업로드';

  @override
  String get connectDeviceFirst => '먼저 기기를 연결해주세요';

  @override
  String get aboutInfoComingSoon => '앱 정보는 추후 업데이트 예정입니다';

  @override
  String appVersion(String version) {
    return '$version 버전';
  }

  @override
  String get licenseTitle => '오픈소스 라이선스';

  @override
  String licensePackageCountDesc(int count) {
    return '이 앱은 $count개의 오픈소스 패키지를 사용합니다.\n아래에서 각 패키지의 라이선스를 확인할 수 있습니다.';
  }

  @override
  String licenseLoadError(String error) {
    return '오류: $error';
  }

  @override
  String get chartNoData => '차트 데이터가 없습니다';

  @override
  String get chartNoDataHint =>
      '숫자형 JSON 데이터를 전송하거나 CSV/JSON 파일을 불러오면 차트가 표시됩니다';

  @override
  String get chartDataSeries => '데이터 시리즈';

  @override
  String get chartClearData => '데이터 지우기';

  @override
  String get chartNoDataPoints => '데이터 포인트 없음';

  @override
  String get chartCurrent => '현재값';

  @override
  String get chartMin => '최솟값';

  @override
  String get chartMax => '최댓값';

  @override
  String get chartPoints => '포인트 수';

  @override
  String get chartImportData => '데이터 불러오기';

  @override
  String get chartSaveData => '데이터 저장';

  @override
  String get chartSaveAsJson => 'JSON으로 저장';

  @override
  String get chartSaveAsCsv => 'CSV로 저장';

  @override
  String get chartLoadData => '데이터 불러오기';

  @override
  String chartSavedJson(String path) {
    return 'JSON 저장 완료: $path';
  }

  @override
  String chartLoadedSeries(int count) {
    return '시리즈 $count개를 불러왔습니다';
  }

  @override
  String chartExportedCsv(String path) {
    return 'CSV 내보내기 완료: $path';
  }

  @override
  String get analysisLoadRealtime => '실시간 데이터 불러오기';

  @override
  String get analysisLoadRealtimeTooltip => '현재 수신된 실시간 데이터를 분석 화면에 적용합니다';

  @override
  String analysisLoadedPoints(int count) {
    return '$count개 시리즈를 불러왔습니다';
  }

  @override
  String get analysisClearConfirmTitle => '데이터 삭제';

  @override
  String get analysisClearConfirmMessage =>
      '데이터를 삭제하기 전에 저장하시겠습니까?\n저장하지 않으면 데이터가 영구적으로 사라집니다.';

  @override
  String get analysisClearSaveAndDelete => '저장 후 삭제';

  @override
  String get analysisClearDeleteOnly => '저장 없이 삭제';

  @override
  String chartLoadFailed(String error) {
    return '데이터를 불러오지 못했습니다: $error';
  }

  @override
  String get tabDirectWrite => '직접 작성';

  @override
  String get tabSampleCodes => '샘플 코드';

  @override
  String get compilingOnServer => '서버에서 컴파일 중...';

  @override
  String get compileFailed => '컴파일 실패';

  @override
  String get uploadingToDevice => '장치에 업로드 중...';

  @override
  String get androidSelectHex => 'HEX 파일 선택';

  @override
  String get androidCloudCompileDesc =>
      'Android에서는 스케치를 클라우드에서 컴파일하고 USB STK500 방식으로 업로드합니다.';

  @override
  String get sampleEditButton => '에디터에 불러오기';

  @override
  String get sampleBlink => 'LED 깜빡이기';

  @override
  String get sampleBlinkDesc => '내장 LED를 1초 간격으로 깜빡입니다.';

  @override
  String get sampleSerialHello => '시리얼 Hello';

  @override
  String get sampleSerialHelloDesc => '시리얼로 인사 문자열을 주기적으로 전송합니다.';

  @override
  String get sampleSerialJson => '시리얼 JSON';

  @override
  String get sampleSerialJsonDesc => '온도/습도 데이터를 JSON으로 전송합니다.';

  @override
  String get sampleAnalogRead => '아날로그 읽기';

  @override
  String get sampleAnalogReadDesc => '아날로그 입력 값을 읽어 출력합니다.';

  @override
  String get sampleServoSweep => '서보 스윕';

  @override
  String get sampleServoSweepDesc => '서보 모터를 좌우로 부드럽게 움직입니다.';

  @override
  String get sampleTempDht => 'DHT 온도';

  @override
  String get sampleTempDhtDesc => 'DHT 센서 값을 읽어 출력합니다.';

  @override
  String get sampleLedControl => 'LED 제어';

  @override
  String get sampleLedControlDesc => '시리얼 명령으로 LED를 켜고 끕니다.';

  @override
  String get sampleUltrasonic => '초음파 거리';

  @override
  String get sampleUltrasonicDesc => 'HC-SR04로 거리를 측정합니다.';

  @override
  String get realtimeReceiving => '수신 중';

  @override
  String get realtimePaused => '일시정지';

  @override
  String get realtimeSaveData => '저장';

  @override
  String get realtimeClearData => '지우기';
}
