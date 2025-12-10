/*
 * 아두이노 시리얼 통신 예제 코드
 * Serial Lab 앱과 JSON 형식으로 데이터를 주고받습니다.
 */

// 가상 센서 값을 위한 변수
float temperature = 25.0;
float humidity = 50.0;
int counter = 0;

void setup() {
  // 시리얼 통신 시작 (115200 보드레이트)
  Serial.begin(115200);
  
  // 랜덤 시드 초기화
  randomSeed(analogRead(0));
}

void loop() {
  // 가상 센서 값 생성 (실제로는 센서에서 읽어옴)
  temperature = 20.0 + random(0, 100) / 10.0;  // 20~30도
  humidity = 40.0 + random(0, 200) / 10.0;     // 40~60%
  counter++;
  
  // JSON 형식으로 데이터 전송
  sendJsonData();
  
  // 수신 데이터 확인
  if (Serial.available() > 0) {
    String received = Serial.readStringUntil('\n');
    handleReceivedData(received);
  }
  
  // 1초 대기
  delay(1000);
}

void sendJsonData() {
  // JSON 문자열 생성 및 전송
  Serial.print("{");
  Serial.print("\"temperature\":");
  Serial.print(temperature, 2);
  Serial.print(",\"humidity\":");
  Serial.print(humidity, 2);
  Serial.print(",\"counter\":");
  Serial.print(counter);
  Serial.print(",\"analog\":");
  Serial.print(analogRead(A0));
  Serial.println("}");
}

void handleReceivedData(String data) {
  // 수신한 데이터 처리
  Serial.print("Received: ");
  Serial.println(data);
  
  // LED 제어 예제
  if (data.indexOf("led_on") >= 0) {
    digitalWrite(LED_BUILTIN, HIGH);
  } else if (data.indexOf("led_off") >= 0) {
    digitalWrite(LED_BUILTIN, LOW);
  }
}
