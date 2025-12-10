/*
 * 블루투스 시리얼 예제 코드 (HC-05/HC-06 모듈)
 * Serial Lab 앱과 블루투스로 데이터를 주고받습니다.
 */

#include <SoftwareSerial.h>

// 블루투스 모듈 핀 설정 (RX, TX)
SoftwareSerial bluetooth(10, 11);  // RX=10, TX=11

float temperature = 25.0;
float humidity = 50.0;
int counter = 0;

void setup() {
  // 디버깅용 하드웨어 시리얼
  Serial.begin(9600);
  
  // 블루투스 시리얼 (HC-05는 보통 9600 또는 38400)
  bluetooth.begin(9600);
  
  Serial.println("Bluetooth Serial Ready");
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // 가상 센서 값 생성
  temperature = 20.0 + random(0, 100) / 10.0;
  humidity = 40.0 + random(0, 200) / 10.0;
  counter++;
  
  // JSON 데이터 전송
  sendJsonData();
  
  // 블루투스로 데이터 수신
  if (bluetooth.available()) {
    String received = bluetooth.readStringUntil('\n');
    handleReceivedData(received);
  }
  
  // 하드웨어 시리얼로 명령 입력 (테스트용)
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    bluetooth.println(cmd);
  }
  
  delay(1000);
}

void sendJsonData() {
  String json = "{";
  json += "\"temperature\":" + String(temperature, 2);
  json += ",\"humidity\":" + String(humidity, 2);
  json += ",\"counter\":" + String(counter);
  json += "}";
  
  bluetooth.println(json);
  Serial.println("Sent: " + json);
}

void handleReceivedData(String data) {
  Serial.println("Received: " + data);
  
  // LED 제어
  if (data.indexOf("led_on") >= 0) {
    digitalWrite(LED_BUILTIN, HIGH);
    bluetooth.println("{\"led\":\"on\"}");
  } else if (data.indexOf("led_off") >= 0) {
    digitalWrite(LED_BUILTIN, LOW);
    bluetooth.println("{\"led\":\"off\"}");
  }
}
