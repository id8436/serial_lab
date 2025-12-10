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

