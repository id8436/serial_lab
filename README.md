# Serial Lab

Arduino 등 마이크로컨트롤러와 시리얼 통신하기 위한 Flutter 데스크톱/모바일 앱.
실시간 데이터 시각화, 차트 분석, 그리고 보드로 직접 코드를 컴파일·업로드하는 Code Sender 까지 한 화면에서 처리한다.

> **AI / 신규 기여자에게**: 코드를 수정하기 전에 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) 를 먼저 읽을 것. 이 README 는 사용/실행 가이드, ARCHITECTURE 는 코드 구조와 규칙이다.

---

## 주요 기능

- **다중 통신 방식** — USB Serial, Bluetooth (Classic SPP / BLE), WiFi (WebSocket)
- **실시간 모니터링** — 터미널 뷰, JSON 자동 파싱, 자동 스크롤, 송수신 카운트
- **실시간 차트** — `fl_chart` 기반 라이브 그래프, 시리즈별 min/max/현재값 통계
- **데이터 분석** — Hive 자동 저장, 세션 임포트/익스포트, 통계/상관관계/FFT
- **Code Sender** — 보드 자동 감지(Arduino CLI / USB descriptor), 컴파일, USB(STK500) / HEX 업로드
- **다국어 지원** — 한국어 / English / 日本語 (gen-l10n + ARB)
- **다크 모드** — 모든 화면이 `colorScheme` 토큰 기반, 시스템/수동 전환

---

## 실행 방법

### 1. 의존성 설치

```bash
flutter pub get
```

### 2. 코드 생성 (json_serializable, hive)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. l10n 생성 (ARB → Dart)

`l10n.yaml` 가 있으므로 옵션 인자 없이 실행한다.

```bash
flutter gen-l10n
```

### 4. 실행

```bash
flutter run
```

VS Code 에서는 `Ctrl+Shift+P` → `Tasks: Run Task` → `analyze` 로 정적 분석을 돌릴 수 있다.

---

## 프로젝트 구조 (요약)

상세는 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

```
lib/
├── main.dart                # 엔트리, MultiProvider + MaterialApp
├── l10n/                    # ARB + 자동 생성된 AppLocalizations
├── models/                  # 순수 데이터 모델 (chart_data, serial_data, …)
├── providers/               # ChangeNotifier 상태 허브 (serial_provider 핵심)
├── services/                # 통신/저장/분석 부수효과
├── widgets/                 # 재사용 위젯 (page_visibility, confirm_dialog, …)
├── utils/                   # 소형 헬퍼 (logger, json_helper, permission_helper)
└── screens/
    ├── home_screen.dart        # Drawer 루트
    ├── dashboard_screen.dart   # 첫 화면 (소개/가이드)
    ├── connection/             # 기기 스캔/연결, 보드 정보
    ├── serial_monitor/         # 터미널 (시리얼 / 블루투스)
    ├── realtime_data/          # 실시간 테이블 + 그래프
    ├── data_analysis/          # 분석 페이지 (스냅샷/통계/세션 I/O)
    ├── code_sender/            # 코드 작성·컴파일·업로드
    └── settings/               # 설정/언어/테마/라이선스
```

---

## 데이터 형식

JSON 한 줄 = 한 샘플. 키는 임의로 정의 가능, 값이 `num` 인 키만 차트 시리즈가 된다.

```json
{"temperature": 25.5, "humidity": 60.2, "pressure": 1013.25}
```

### Arduino 예제

```cpp
void loop() {
  float temp = readTemperature();
  float humidity = readHumidity();

  Serial.print("{\"temperature\":");
  Serial.print(temp);
  Serial.print(",\"humidity\":");
  Serial.print(humidity);
  Serial.println("}");

  delay(1000);
}
```

`Code Sender` 탭의 샘플 코드에서 더 다양한 예제를 바로 에디터로 불러올 수 있다.

---

## WiFi (WebSocket)

ESP8266 / ESP32 측에서 WebSocket 서버를 띄운다.

```cpp
#include <WebSocketsServer.h>

WebSocketsServer webSocket = WebSocketsServer(8080);

void setup() {
  WiFi.begin("SSID", "PASSWORD");
  webSocket.begin();
}

void loop() {
  webSocket.loop();
  String json = "{\"value\":" + String(analogRead(A0)) + "}";
  webSocket.broadcastTXT(json);
  delay(100);
}
```

앱에서 `Device Connection` 탭 → `WiFi` 선택 → `Add` 로 추가:

- Device Name: `Arduino WiFi`
- WebSocket Address: `ws://192.168.1.100:8080`

---

## 권한

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

USB Serial 은 `usb_serial` 패키지가 자동으로 인텐트 필터를 등록한다.

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>블루투스 기기와 통신하기 위해 필요합니다</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>블루투스 기기와 연결하기 위해 필요합니다</string>
```

> iOS 는 시스템 정책상 **USB Serial / Classic Bluetooth(HC-05/06) / 코드 업로드 미지원**.

---

## 플랫폼별 지원 매트릭스

| 기능 | Android | Windows | macOS / Linux | iOS |
|---|:-:|:-:|:-:|:-:|
| USB Serial | ✅ | ✅ | ✅ | ❌ |
| Classic Bluetooth (HC-05/06) | ✅ | ✅ | ⚠️ | ❌ |
| BLE | ✅ | ✅ | ✅ | ✅ |
| WiFi (WebSocket) | ✅ | ✅ | ✅ | ✅ |
| 코드 컴파일 (서버) | ✅ | — | — | ❌ |
| 코드 업로드 (STK500) | ✅ | ✅ | — | ❌ |
| HEX 업로드 | ✅ | — | — | ❌ |

---

## 주의사항

- USB Serial 은 **드라이버가 잡힌 후** 약 800ms 대기 후 연결 시도한다 (`SerialProvider._kUsbDriverInitDelay`).
- Bluetooth 는 시스템 설정에서 페어링이 선행되어야 한다.
- 보드레이트 기본값은 9600 — Arduino 스케치와 동일하게 맞출 것.
- 차트 시리즈는 시리즈당 2000 포인트, 수신 raw 텍스트는 1000 줄로 캡되어 있다 (`ARCHITECTURE.md` 4.1).

---

## 문서

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — 폴더 지도, Provider 2-rate 알림 계약, 성능 규칙, l10n / 에러 서페이싱 / 다이얼로그 / 테마 패턴, PR 체크리스트
- [`GUIDE.md`](GUIDE.md) — 사용자 관점 가이드

---

## 라이선스

MIT License
# Serial Lab

아두이노 등의 디바이스와 시리얼 통신하는 Flutter 어플리케이션

## 주요 기능

- **다중 통신 방식 지원**
  - USB 시리얼 통신
  - 블루투스 시리얼 통신
  - WiFi (WebSocket) 통신

- **실시간 데이터 모니터링**
  - JSON 형식 데이터 송수신
  - 실시간 터미널 뷰
  - 자동 스크롤 및 데이터 히스토리

- **실시간 차트**
  - 수신 데이터 실시간 그래프 표시
  - 여러 데이터 시리즈 선택 가능
  - 최소/최대/현재값 통계 표시

## 프로젝트 구조

```
lib/
├── models/              # 데이터 모델
│   ├── device_info.dart       # 기기 정보
│   ├── serial_data.dart       # 시리얼 데이터
│   └── chart_data.dart        # 차트 데이터
├── services/            # 통신 서비스
│   ├── communication_service.dart     # 통신 인터페이스
│   ├── usb_serial_service.dart        # USB 통신
│   ├── bluetooth_serial_service.dart  # 블루투스 통신
│   └── wifi_serial_service.dart       # WiFi 통신
├── providers/           # 상태 관리
│   └── serial_provider.dart   # 메인 Provider
├── screens/             # UI 화면
│   ├── home_screen.dart           # 홈 화면
│   ├── device_list_screen.dart    # 기기 목록
│   ├── terminal_screen.dart       # 터미널
│   └── chart_screen.dart          # 차트
├── widgets/             # 재사용 위젯
└── utils/               # 유틸리티
    ├── permission_helper.dart
    └── json_helper.dart
```

## 사용 방법

### 1. 패키지 설치

```bash
flutter pub get
```

### 2. JSON 직렬화 코드 생성

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 앱 실행

```bash
flutter run
```

## 데이터 형식

아두이노에서 다음과 같은 JSON 형식으로 데이터를 전송하세요:

```json
{
  "temperature": 25.5,
  "humidity": 60.2,
  "pressure": 1013.25
}
```

### 아두이노 예제 코드

```cpp
void loop() {
  // 센서 값 읽기
  float temp = readTemperature();
  float humidity = readHumidity();
  
  // JSON 형식으로 전송
  Serial.print("{\"temperature\":");
  Serial.print(temp);
  Serial.print(",\"humidity\":");
  Serial.print(humidity);
  Serial.println("}");
  
  delay(1000);
}
```

## WiFi 사용 시

ESP8266/ESP32에서 WebSocket 서버 실행:

```cpp
#include <WebSocketsServer.h>

WebSocketsServer webSocket = WebSocketsServer(8080);

void setup() {
  WiFi.begin("SSID", "PASSWORD");
  webSocket.begin();
}

void loop() {
  webSocket.loop();
  
  // JSON 데이터 전송
  String json = "{\"value\":" + String(analogRead(A0)) + "}";
  webSocket.broadcastTXT(json);
  
  delay(100);
}
```

앱에서 WiFi 기기 추가 시:
- 이름: Arduino WiFi
- 주소: `ws://192.168.1.100:8080`

## 권한 설정

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>블루투스 기기와 통신하기 위해 필요합니다</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>블루투스 기기와 연결하기 위해 필요합니다</string>
```

## 주의사항

- USB 시리얼 통신은 Android에서만 지원됩니다
- 블루투스는 먼저 시스템 설정에서 페어링이 필요합니다
- 보드레이트는 기본값 115200을 사용합니다 (코드에서 변경 가능)

## 라이선스

MIT License

