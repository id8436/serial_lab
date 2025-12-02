/*
 * ESP8266/ESP32 WiFi WebSocket 예제 코드
 * Serial Lab 앱과 WiFi로 데이터를 주고받습니다.
 */

#include <ESP8266WiFi.h>          // ESP8266용 (ESP32는 <WiFi.h> 사용)
#include <WebSocketsServer.h>     // WebSocket 서버 라이브러리

// WiFi 설정
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// WebSocket 서버 (포트 8080)
WebSocketsServer webSocket = WebSocketsServer(8080);

float temperature = 25.0;
float humidity = 50.0;
unsigned long lastSendTime = 0;
const long sendInterval = 1000;  // 1초마다 전송

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  
  // WiFi 연결
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.print("Connected! IP: ");
  Serial.println(WiFi.localIP());
  
  // WebSocket 서버 시작
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  
  Serial.println("WebSocket server started on port 8080");
  Serial.print("Use: ws://");
  Serial.print(WiFi.localIP());
  Serial.println(":8080");
}

void loop() {
  webSocket.loop();
  
  // 주기적으로 데이터 전송
  unsigned long currentTime = millis();
  if (currentTime - lastSendTime >= sendInterval) {
    lastSendTime = currentTime;
    
    // 가상 센서 값 생성
    temperature = 20.0 + random(0, 100) / 10.0;
    humidity = 40.0 + random(0, 200) / 10.0;
    
    // JSON 데이터 생성 및 전송
    String json = createJsonData();
    webSocket.broadcastTXT(json);
    
    Serial.println("Sent: " + json);
  }
}

String createJsonData() {
  String json = "{";
  json += "\"temperature\":" + String(temperature, 2);
  json += ",\"humidity\":" + String(humidity, 2);
  json += ",\"rssi\":" + String(WiFi.RSSI());
  json += ",\"uptime\":" + String(millis() / 1000);
  json += "}";
  return json;
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
      
    case WStype_CONNECTED: {
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("[%u] Connected from %d.%d.%d.%d\n", 
                    num, ip[0], ip[1], ip[2], ip[3]);
      
      // 연결 확인 메시지
      webSocket.sendTXT(num, "{\"status\":\"connected\"}");
    }
      break;
      
    case WStype_TEXT:
      Serial.printf("[%u] Received: %s\n", num, payload);
      
      // 수신 데이터 처리
      String message = String((char*)payload);
      if (message.indexOf("led_on") >= 0) {
        digitalWrite(LED_BUILTIN, LOW);  // ESP8266은 반대
        webSocket.sendTXT(num, "{\"led\":\"on\"}");
      } else if (message.indexOf("led_off") >= 0) {
        digitalWrite(LED_BUILTIN, HIGH);
        webSocket.sendTXT(num, "{\"led\":\"off\"}");
      }
      break;
  }
}
