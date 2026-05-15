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
  String get dashboardSpecComparisonTitle => '🧭 기기 사양 점검';

  @override
  String get dashboardSpecComparisonSubtitle => '권장 사양과 현재 기기 사양을 비교합니다';

  @override
  String get dashboardSpecLoading => '현재 기기 사양을 읽는 중...';

  @override
  String get dashboardSpecFailed => '기기 사양을 불러오지 못했습니다. 권한 또는 플랫폼 지원을 확인해주세요.';

  @override
  String get dashboardSpecCurrentDevice => '현재 기기';

  @override
  String get dashboardSpecRecommended => '권장 기준';

  @override
  String get dashboardSpecItemOs => '운영체제';

  @override
  String get dashboardSpecItemCpu => 'CPU 코어';

  @override
  String get dashboardSpecItemMemory => '메모리';

  @override
  String get dashboardSpecReasonOs =>
      '최신 OS일수록 Bluetooth/USB 권한 처리와 연결 안정성이 더 좋습니다.';

  @override
  String get dashboardSpecReasonCpu => '코어 수가 많으면 실시간 파싱·차트·모니터링에서 끊김이 줄어듭니다.';

  @override
  String get dashboardSpecReasonMemory =>
      '메모리가 충분하면 차트/로그를 동시에 띄워도 프레임 드랍이 줄어듭니다.';

  @override
  String get dashboardSpecReasonConnection => '기기 사양만큼 연결 품질도 중요합니다.';

  @override
  String get dashboardSpecConnectionTip =>
      '안정적인 USB 케이블/OTG 어댑터와 신뢰할 수 있는 블루투스 페어링을 권장합니다.';

  @override
  String get dashboardSpecStatusGood => '양호';

  @override
  String get dashboardSpecStatusNeedAttention => '확인 필요';

  @override
  String get dashboardSpecStatusUnknown => '확인 불가';

  @override
  String get dashboardSpecUnknownValue => '정보 없음';

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
  String get fftEmpty => '데이터가 없습니다. 먼저 숫자 JSON 을 수신하세요.';

  @override
  String get fftNotEnough => 'FFT 를 수행할 샘플이 부족합니다.';

  @override
  String get fftSeries => '시리즈';

  @override
  String get fftWindowSize => '윈도우';

  @override
  String get fftWindowFunction => '함수';

  @override
  String get fftWindowRectangular => '사각';

  @override
  String get fftWindowHann => 'Hann';

  @override
  String fftSampleCount(int count) {
    return '샘플 수: $count';
  }

  @override
  String fftSampleRate(String rate) {
    return '샘플링률: $rate Hz';
  }

  @override
  String fftNyquist(String hz) {
    return '검출 가능 상한: $hz Hz (Nyquist)';
  }

  @override
  String fftJitterWarning(String percent) {
    return '샘플 간격이 불안정합니다 (±$percent%). 주파수 결과가 부정확할 수 있습니다.';
  }

  @override
  String fftPeak(String freq, String mag) {
    return '피크: $freq Hz ($mag)';
  }

  @override
  String get fftAxisFrequency => '주파수 (Hz)';

  @override
  String get fftAxisMagnitude => '크기';

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
  String get sampleDiagCategory => '점검용';

  @override
  String get sampleGeneralCategory => '샘플 코드';

  @override
  String get sampleDiagBlink => '[점검용] LED Blink';

  @override
  String get sampleDiagBlinkDesc =>
      '배선 없이 보드 업로드 & 동작 확인. 내장 LED를 1초 간격으로 점멸합니다.';

  @override
  String get sampleDiagJsonRandom => '[점검용] 랜덤 JSON 전송';

  @override
  String get sampleDiagJsonRandomDesc =>
      '1초마다 a / b / c 랜덤값을 JSON으로 전송. 시리얼 수신·그래프 확인용.';

  @override
  String get sampleBlink => 'LED 깜빡이기';

  @override
  String get sampleBlinkDesc => '내장 LED를 1초 간격으로 깜빡입니다.';

  @override
  String get sampleBlinkMillis => 'millis() 깜빡이기';

  @override
  String get sampleBlinkMillisDesc =>
      'delay() 없이 millis()로 LED를 깜빡여 루프가 멈추지 않게 합니다.';

  @override
  String get sampleSerialHello => '시리얼 Hello';

  @override
  String get sampleSerialHelloDesc => '시리얼로 인사 문자열을 주기적으로 전송합니다.';

  @override
  String get sampleAnalogRead => '아날로그 읽기';

  @override
  String get sampleAnalogReadDesc => '아날로그 입력 값을 읽어 출력합니다.';

  @override
  String get samplePwmFade => 'PWM LED 페이드';

  @override
  String get samplePwmFadeDesc => 'PWM 9번 핀 LED를 어둡게→밝게→어둡게 반복합니다.';

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
  String get sampleButtonDebounce => '버튼 디바운스 토글';

  @override
  String get sampleButtonDebounceDesc =>
      'INPUT_PULLUP 방식의 디바운싱 버튼으로 내장 LED를 토글합니다.';

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

  @override
  String get statusConnected => '연결됨';

  @override
  String get statusDisconnected => '연결 해제됨';

  @override
  String get tooltipDisconnect => '연결 해제';

  @override
  String get tooltipClear => '지우기';

  @override
  String get actionUndo => '실행 취소';

  @override
  String get confirmDisconnectTitle => '장치 연결을 해제할까요?';

  @override
  String get confirmDisconnectMessage => '현재 데이터를 수신 중입니다.\n그래도 연결을 해제하시겠습니까?';

  @override
  String get confirmClearTitle => '데이터를 지울까요?';

  @override
  String get confirmClearMessage => '수신된 데이터와 차트가 모두 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String get terminalNoData => '수신된 데이터가 없습니다';

  @override
  String get terminalAutoScroll => '자동 스크롤';

  @override
  String get terminalSend => '전송';

  @override
  String get terminalSendHint => '전송할 데이터를 입력하세요...';

  @override
  String terminalReceivedCount(int count) {
    return '수신: $count건';
  }

  @override
  String get deviceListEmpty => '장치를 찾지 못했습니다.\n\"장치 검색\"을 눌러 검색하세요.';

  @override
  String get connectionConnecting => '연결 중...';

  @override
  String get connectionFailed => '연결에 실패했습니다';

  @override
  String get wifiDialogTitle => 'WiFi 장치 추가';

  @override
  String get wifiDialogNameLabel => '장치 이름';

  @override
  String get wifiDialogAddressLabel => 'WebSocket 주소';

  @override
  String get wifiDialogAddressHint => 'ws://192.168.0.10:81';

  @override
  String get wifiDialogNameEmpty => '장치 이름을 입력하세요';

  @override
  String get wifiDialogAddressInvalid => 'ws:// 또는 wss:// 로 시작해야 합니다';

  @override
  String get commonAdd => '추가';

  @override
  String get commonOk => '확인';

  @override
  String baudrateChanging(int rate) {
    return '보드레이트 변경 중... ($rate bps)';
  }

  @override
  String baudrateChanged(int rate) {
    return '보드레이트 변경 완료 ($rate bps)';
  }

  @override
  String get reconnectFailed => '재연결 실패';

  @override
  String get codeSenderTitle => 'Code Sender';

  @override
  String get codeSenderTagline => '코드 작성, 검증, 업로드까지!';

  @override
  String get codeSenderTabGuide => '홈';

  @override
  String get codeSenderTabWrite => '작성';

  @override
  String get codeSenderTabSamples => '샘플';

  @override
  String get codeSenderStepsTitle => '절차';

  @override
  String get codeSenderStepsSubtitle =>
      '1) 샘플 선택 또는 코드 작성\n2) Verify로 컴파일 확인\n3) 장치 연결 확인\n4) Upload로 전송';

  @override
  String get codeSenderRequirementsTitle => '필요 조건';

  @override
  String get codeSenderRequirementBoard =>
      '• 보드 연결: 업로드 전 대상 보드/포트가 연결되어 있어야 합니다.';

  @override
  String get codeSenderRequirementOnline =>
      '• 기기 온라인 상태: Android에서 서버 컴파일을 사용할 때는 인터넷 연결이 필요합니다.';

  @override
  String get codeSenderRequirementOs =>
      '• 가용 OS: Write/Verify/Upload는 Android/Windows에서 사용 가능하며, HEX 업로드는 Android 전용 고급 기능입니다.';

  @override
  String get codeSenderAndroidModeTitle => 'Android 동작 방식';

  @override
  String get codeSenderAndroidModeSubtitle =>
      '코드는 서버에서 컴파일되고, USB(STK500)로 업로드됩니다.';

  @override
  String get codeSenderCautionTitle => '유의사항';

  @override
  String get codeSenderCautionLibs =>
      '• 샘플에 없는 라이브러리는 현재 앱에서 자동 설치되지 않아, 사용할 수 없습니다.';

  @override
  String get codeSenderCautionPort =>
      '• 업로드 실패 시 보드 포트 점유(Serial Monitor 등)를 해제하고 다시 시도하세요.';

  @override
  String get codeSenderOverwriteTitle => '에디터 내용 덮어쓰기';

  @override
  String get codeSenderOverwriteMessage =>
      '에디터에 작성한 코드가 있습니다.\n샘플 코드를 불러오면 기존 내용이 사라집니다.';

  @override
  String get codeSenderOverwrite => '덮어쓰기';

  @override
  String get codeSenderIosUnsupported =>
      'iOS에서는 코드 업로드를 지원하지 않습니다.\nPC 또는 Android에서 업로드해 주세요.';

  @override
  String codeSenderBoardUnsupported(String board) {
    return '$board 보드는 Android USB 업로드를 지원하지 않습니다.\nPC에서 업로드해 주세요.';
  }

  @override
  String get codeSenderPortNotAvailable => '포트 정보를 확인할 수 없습니다';

  @override
  String codeSenderSaveComplete(String path) {
    return '저장 완료: $path';
  }

  @override
  String get codeSenderSaveDialogTitle => '스케치 저장';

  @override
  String get codeSenderNewSketchTitle => '새 스케치 만들기';

  @override
  String get codeSenderNewSketchMessage => '기존 작업 내용이 지워집니다. 계속할까요?';

  @override
  String get codeSenderNewSketchConfirm => '새로 만들기';

  @override
  String get codeSenderHexHelpTitle => 'HEX 파일이란?';

  @override
  String get codeSenderHexHelpContent =>
      'HEX 파일은 이미 컴파일된 펌웨어 파일입니다.\n\n이 기능은 Android 전용 고급 옵션입니다. 소스코드 컴파일 없이, 기존 .hex를 장치에 바로 업로드할 때 사용합니다.';

  @override
  String get codeSenderTooltipSave => '저장';

  @override
  String get codeSenderTooltipSaveAs => '다른 이름으로 저장';

  @override
  String get codeSenderTooltipCopyOutput => '출력 복사';

  @override
  String get codeSenderTooltipClearOutput => '출력 지우기';

  @override
  String get codeSenderTooltipHexHelp => 'HEX 파일 안내';

  @override
  String get codeSenderAdvancedShow => '고급 보기';

  @override
  String get codeSenderAdvancedHide => '고급 숨기기';

  @override
  String get codeSenderHexUpload => 'HEX 업로드';

  @override
  String get codeSenderConsoleLabel => '출력';

  @override
  String get codeSenderConsolePlaceholder => '여기에 컴파일/업로드 결과가 표시됩니다.';

  @override
  String get codeSenderCopied => '복사되었습니다';

  @override
  String get codeSenderReconnectWaiting => '재연결 대기 중... (2.5s)';

  @override
  String get codeSenderReconnectAttempting => '재연결 시도 중...';

  @override
  String get codeSenderReconnectSuccess => '✅ 재연결 성공';

  @override
  String get codeSenderReconnectFailed => '⚠️ 재연결 실패 — 장치 탭에서 수동으로 연결해 주세요';

  @override
  String get codeSenderReconnectComplete => '✅ 재연결 완료';

  @override
  String get connectionTypeLabel => '연결 방식';

  @override
  String get connectionScan => '장치 검색';

  @override
  String get connectionScanning => '검색 중...';

  @override
  String get connectionConnect => '연결';

  @override
  String get connectionDeviceNameHint => 'Arduino WiFi';

  @override
  String get connectionConnectedChip => '연결됨';

  @override
  String connectionConnectedTo(String device) {
    return '$device에 연결됨';
  }

  @override
  String get connectionNoDevices => '검색된 장치가 없습니다';

  @override
  String get connectionNoDevicesHint => '\"장치 검색\"을 눌러 검색하세요';

  @override
  String get connectionWarnUsbTitle => 'USB 연결';

  @override
  String get connectionWarnUsbBody =>
      '• Android에서만 지원됩니다\n• 보드레이트를 아두이노 코드와 동일하게 설정하세요.';

  @override
  String get connectionWarnBluetoothTitle => '블루투스 연결';

  @override
  String get connectionWarnBluetoothBody =>
      '• 먼저 시스템 설정에서 페어링을 완료하세요\n• 보드레이트를 아두이노 코드와 동일하게 설정하세요.';

  @override
  String get connectionWarnWifiTitle => 'WiFi 연결';

  @override
  String get connectionWarnWifiBody =>
      '• WebSocket 주소 형식: ws://IP:PORT\n• 아두이노에서 WebSocket 서버를 실행해야 합니다';

  @override
  String get btProtocolTitle => '블루투스 프로토콜 선택';

  @override
  String btProtocolChoose(String device) {
    return '$device의 프로토콜을 선택하세요:';
  }

  @override
  String get btProtocolClassic => '클래식 블루투스';

  @override
  String get btProtocolClassicDesc => 'HC-05, HC-06 등';

  @override
  String get btProtocolBle => 'Bluetooth Low Energy (BLE)';

  @override
  String get btProtocolBleDesc => '최신 BLE 모듈용';

  @override
  String get deviceInfoDeviceName => '기기 이름';

  @override
  String get deviceInfoAddress => '주소';

  @override
  String get deviceInfoConnType => '연결 타입';

  @override
  String get deviceInfoBaudRate => '보드레이트';

  @override
  String get deviceInfoSelectedBoard => '선택된 보드';

  @override
  String get deviceInfoProtocol => '프로토콜';

  @override
  String get deviceInfoBuffering => '버퍼링';

  @override
  String get deviceInfoBufferingValue => '50ms timeout (Arduino 호환)';

  @override
  String get deviceInfoDataFormat => '데이터 형식';

  @override
  String get deviceInfoDataFormatValue => 'Arduino BTSerial 텍스트';

  @override
  String get deviceInfoJsonData => 'JSON 데이터';

  @override
  String get deviceInfoJsonSub => '구조화된 데이터';

  @override
  String get deviceInfoTextData => '텍스트 데이터';

  @override
  String get deviceInfoTextSub => '원본 데이터';

  @override
  String get deviceInfoConnectFromTab => '기기 연결 탭에서 기기를 연결해주세요.';

  @override
  String get deviceInfoDeviceSettings => '장치 설정';

  @override
  String get deviceInfoArduinoBoard => 'Arduino 보드';

  @override
  String get deviceInfoAutoDetect => '자동 감지';

  @override
  String deviceInfoDetected(String board) {
    return '감지된 보드: $board';
  }

  @override
  String get deviceInfoRecentUsed => '최근 사용';

  @override
  String get deviceInfoBaudRateTooltip => '기기 연결 탭에서 변경 가능';

  @override
  String get dashboardSupported => '지원';

  @override
  String get dashboardUnsupported => '미지원';

  @override
  String get advGraphSeries => '시리즈';

  @override
  String get advGraphGraph => '그래프';

  @override
  String get advGraphBins => '구간 수';

  @override
  String get advGraphSmoothing => '평활화';

  @override
  String get advGraphWindow => '윈도우';

  @override
  String get advGraphFitLine => '곡선 피팅';

  @override
  String get advGraphType => '유형';

  @override
  String get advGraphPeakValley => '최고점/최저점';

  @override
  String get advGraphProminence => '높이';

  @override
  String get advGraphNoPoints => '포인트 없음';

  @override
  String get advGraphNoData => '데이터가 없습니다. 데이터를 불러오거나 숫자 JSON 수신을 시작하세요.';

  @override
  String get advGraphHistogramNeedPoints => '히스토그램에는 최소 2개의 포인트가 필요합니다.';

  @override
  String get advGraphHistogramConstantValues => '값이 모두 같아 히스토그램을 만들 수 없습니다.';

  @override
  String get advGraphFit => '피팅';

  @override
  String get advGraphEquation => '방정식';

  @override
  String get advGraphRSquared => 'R^2';

  @override
  String get advGraphCount => '개수';

  @override
  String get advGraphFitUnavailable => '현재 데이터로는 피팅할 수 없습니다.';

  @override
  String get advGraphFitQuadraticNeedPoints => '이차 피팅에는 최소 3개의 유효한 포인트가 필요합니다.';

  @override
  String get advGraphFitExponentialNeedPoints =>
      '지수 피팅에는 최소 2개의 양수 포인트가 필요합니다.';

  @override
  String get advGraphFitPowerNeedPoints => '거듭제곱 피팅에는 최소 2개의 양수 포인트가 필요합니다.';

  @override
  String get advGraphFitLogarithmicNeedPoints =>
      '로그 피팅에는 최소 2개의 유효한 포인트가 필요합니다.';

  @override
  String get advGraphModeLine => '선';

  @override
  String get advGraphModeScatter => '산점도';

  @override
  String get advGraphModeBar => '막대';

  @override
  String get advGraphModeArea => '영역';

  @override
  String get advGraphModeHistogram => '히스토그램';

  @override
  String get advGraphRegressionLinear => '선형';

  @override
  String get advGraphRegressionQuadratic => '이차';

  @override
  String get advGraphRegressionExponential => '지수';

  @override
  String get advGraphRegressionPower => '거듭제곱';

  @override
  String get advGraphRegressionLogarithmic => '로그';
}
