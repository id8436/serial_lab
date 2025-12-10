# Serial Lab - 사용 가이드

## 빠른 시작

### 1. 프로젝트 설정

```bash
# 의존성 설치
flutter pub get

# JSON 직렬화 코드 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run
```

### 2. 아두이노 준비

`examples` 폴더에서 사용하려는 통신 방식에 맞는 예제 코드를 선택하세요:

- **arduino_serial_example.ino** - USB 시리얼 통신
- **bluetooth_serial_example.ino** - 블루투스 통신 (HC-05/HC-06)
- **esp_wifi_example.ino** - WiFi 통신 (ESP8266/ESP32)

### 3. 앱 사용법

#### USB 연결
1. 아두이노를 USB로 연결
2. 앱에서 "USB" 탭 선택
3. "Scan Devices" 클릭
4. 목록에서 아두이노 선택 후 "Connect"

#### 블루투스 연결
1. HC-05/06 모듈을 먼저 스마트폰 설정에서 페어링
2. 앱에서 "Bluetooth" 탭 선택
3. "Scan Devices" 클릭
4. 페어링된 기기 선택 후 "Connect"

#### WiFi 연결
1. ESP8266/32 코드에서 WiFi SSID와 비밀번호 설정
2. 업로드 후 시리얼 모니터에서 IP 주소 확인
3. 앱에서 "WiFi" 탭 선택
4. "Add" 버튼 클릭
5. WebSocket 주소 입력 (예: `ws://192.168.1.100:8080`)

## 데이터 형식

### 아두이노 → 앱 (JSON 형식)

```json
{
  "temperature": 25.5,
  "humidity": 60.2,
  "counter": 123
}
```

모든 숫자 값은 자동으로 차트로 표시됩니다.

### 앱 → 아두이노 (문자열)

Terminal 화면에서 명령어를 보낼 수 있습니다:
- `led_on` - LED 켜기
- `led_off` - LED 끄기
- 또는 JSON 형식의 데이터

## 화면 설명

### 1. Devices (기기 관리)
- USB/Bluetooth/WiFi 기기 스캔 및 연결
- 연결 상태 표시
- WiFi 기기 수동 추가

### 2. Terminal (터미널)
- 실시간 데이터 수신 내역 표시
- 데이터 전송
- 자동 스크롤 옵션
- 데이터 클리어

### 3. Charts (실시간 차트)
- 수신한 숫자 데이터를 실시간 그래프로 표시
- 여러 데이터 시리즈 선택 가능
- 최소/최대/현재값 통계
- 최대 100개 데이터 포인트 표시

## 주의사항

### 보드레이트
- USB 시리얼: 115200 (코드에서 변경 가능)
- 블루투스: 9600 (HC-05/06 기본값)
- WiFi: N/A

### 권한
- Android: 블루투스 및 위치 권한 필요
- iOS: 블루투스 권한 필요
- 앱 실행 시 자동으로 요청됨

### 플랫폼 지원
- USB 시리얼: Android만 지원
- 블루투스: Android, iOS
- WiFi: 모든 플랫폼

## 문제 해결

### "No devices found"
- USB: 케이블 연결 확인, OTG 지원 확인
- 블루투스: 시스템 설정에서 페어링 확인
- WiFi: 같은 네트워크에 있는지 확인

### 연결 실패
- 다른 앱이 포트를 사용 중인지 확인
- 아두이노 재부팅 시도
- 앱 재시작

### 데이터 수신 안됨
- 아두이노 코드가 올바른 JSON 형식으로 전송하는지 확인
- 보드레이트 일치 확인 (USB/블루투스)
- 시리얼 모니터로 데이터 전송 확인

## 커스터마이징

### 차트 데이터 포인트 수 변경
`lib/providers/serial_provider.dart`에서:
```dart
maxDataPoints: 100,  // 원하는 값으로 변경
```

### 보드레이트 변경
`lib/services/usb_serial_service.dart`에서:
```dart
await _port!.setPortParameters(
  115200,  // 원하는 보드레이트로 변경
  ...
);
```

### 테마 변경
`lib/main.dart`에서 `ColorScheme.fromSeed` 색상 변경

## 추가 기능 아이디어

- 데이터 로깅 (파일 저장)
- CSV 내보내기
- 차트 확대/축소
- 다중 기기 동시 연결
- 커스텀 명령어 프리셋
- 데이터 필터링
