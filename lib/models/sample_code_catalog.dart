import 'package:serial_lab/models/sample_code.dart';

/// 아두이노 샘플 코드 전체 카탈로그 (13개)
const List<SampleCode> sampleCodes = [
  // ── 점검용 ─────────────────────────────────────────────────
  SampleCode(
    id: 'diag_blink',
    titleKey: 'sampleDiagBlink',
    descKey: 'sampleDiagBlinkDesc',
    icon: '💡',
    category: '점검용',
    code: '''// [점검용] LED Blink - 보드 정상 작동 확인
void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_BUILTIN, HIGH);
  delay(1000);
  digitalWrite(LED_BUILTIN, LOW);
  delay(1000);
}''',
  ),
  SampleCode(
    id: 'diag_json_random',
    titleKey: 'sampleDiagJsonRandom',
    descKey: 'sampleDiagJsonRandomDesc',
    icon: '📡',
    category: '점검용',
    code: r'''// [점검용] 랜덤 JSON 전송 - 시리얼 수신 & 그래프 확인용
// 1초마다 a / b / c 랜덤값(0~100)을 JSON으로 전송합니다.

unsigned long lastSendMs = 0;
const unsigned long sendIntervalMs = 1000;

void setup() {
  Serial.begin(115200);
  randomSeed(analogRead(A0)); // 노이즈로 시드 초기화
}

void loop() {
  unsigned long now = millis();
  if (now - lastSendMs >= sendIntervalMs) {
    lastSendMs = now;

    float a = random(0, 10001) / 100.0; // 0.00 ~ 100.00
    float b = random(0, 10001) / 100.0;
    float c = random(0, 10001) / 100.0;

    Serial.print("{");
    Serial.print("\"a\":");
    Serial.print(a, 2);
    Serial.print(",\"b\":");
    Serial.print(b, 2);
    Serial.print(",\"c\":");
    Serial.print(c, 2);
    Serial.println("}");
  }
}''',
  ),
  // ── 샘플 코드 ───────────────────────────────────────────────
  SampleCode(
    id: 'blink',
    titleKey: 'sampleBlink',
    descKey: 'sampleBlinkDesc',
    icon: '💡',
    code: '''const int statusLedPin = LED_BUILTIN;

void setup() {
  pinMode(statusLedPin, OUTPUT);
}

void loop() {
  digitalWrite(statusLedPin, HIGH);
  delay(1000);
  digitalWrite(statusLedPin, LOW);
  delay(1000);
}''',
  ),
  SampleCode(
    id: 'blink_millis',
    titleKey: 'sampleBlinkMillis',
    descKey: 'sampleBlinkMillisDesc',
    icon: '⏱️',
    code: '''const int statusLedPin = LED_BUILTIN;
const unsigned long blinkIntervalMs = 500;

unsigned long previousMs = 0;
bool ledOn = false;

void setup() {
  pinMode(statusLedPin, OUTPUT);
}

void loop() {
  final unsigned long currentMs = millis();
  if (currentMs - previousMs >= blinkIntervalMs) {
    previousMs = currentMs;
    ledOn = !ledOn;
    digitalWrite(statusLedPin, ledOn ? HIGH : LOW);
  }
}''',
  ),
  SampleCode(
    id: 'serial_hello',
    titleKey: 'sampleSerialHello',
    descKey: 'sampleSerialHelloDesc',
    icon: '👋',
    code: '''void setup() {
  Serial.begin(115200);
}

void loop() {
  Serial.println("Hello from Arduino!");
  delay(1000);
}''',
  ),
  SampleCode(
    id: 'serial_json',
    titleKey: 'sampleSerialJson',
    descKey: 'sampleSerialJsonDesc',
    icon: '📊',
    code: r'''const int sensorPin = A0;

void setup() {
  Serial.begin(115200);
}

void loop() {
  int sensorValue = analogRead(sensorPin);
  float voltage = sensorValue * (5.0 / 1023.0);

  Serial.print("{\"sensor\":");
  Serial.print(sensorValue);
  Serial.print(",\"voltage\":");
  Serial.print(voltage, 2);
  Serial.println("}");

  delay(100);
}''',
  ),
  SampleCode(
    id: 'analog_read',
    titleKey: 'sampleAnalogRead',
    descKey: 'sampleAnalogReadDesc',
    icon: '🔌',
    code: '''const int analogInPin = A0;

void setup() {
  Serial.begin(115200);
}

void loop() {
  int value = analogRead(analogInPin);
  Serial.println(value);
  delay(100);
}''',
  ),
  SampleCode(
    id: 'pwm_fade',
    titleKey: 'samplePwmFade',
    descKey: 'samplePwmFadeDesc',
    icon: '🌗',
    code: '''const int pwmLedPin = 9;

void setup() {
  pinMode(pwmLedPin, OUTPUT);
}

void loop() {
  for (int value = 0; value <= 255; value++) {
    analogWrite(pwmLedPin, value);
    delay(8);
  }

  for (int value = 255; value >= 0; value--) {
    analogWrite(pwmLedPin, value);
    delay(8);
  }
}''',
  ),
  SampleCode(
    id: 'servo_sweep',
    titleKey: 'sampleServoSweep',
    descKey: 'sampleServoSweepDesc',
    icon: '🔄',
    code: '''#include <Servo.h>

const int servoPin = 9;

Servo myServo;

void setup() {
  myServo.attach(servoPin);
  Serial.begin(115200);
}

void loop() {
  for (int pos = 0; pos <= 180; pos++) {
    myServo.write(pos);
    Serial.println(pos);
    delay(15);
  }
  for (int pos = 180; pos >= 0; pos--) {
    myServo.write(pos);
    Serial.println(pos);
    delay(15);
  }
}''',
  ),
  SampleCode(
    id: 'temp_dht',
    titleKey: 'sampleTempDht',
    descKey: 'sampleTempDhtDesc',
    icon: '🌡️',
    code: r'''#include <DHT.h>

const int dhtPin = 2;
const int dhtType = DHT11;

DHT dht(dhtPin, dhtType);

void setup() {
  Serial.begin(115200);
  dht.begin();
}

void loop() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    Serial.println("DHT read error");
    delay(2000);
    return;
  }

  Serial.print("{\"temp\":");
  Serial.print(t, 1);
  Serial.print(",\"humidity\":");
  Serial.print(h, 1);
  Serial.println("}");

  delay(2000);
}''',
  ),
  SampleCode(
    id: 'button_debounce',
    titleKey: 'sampleButtonDebounce',
    descKey: 'sampleButtonDebounceDesc',
    icon: '🖲️',
    code: '''const int buttonPin = 2;
const int ledPin = LED_BUILTIN;
const unsigned long debounceMs = 40;

int buttonState = HIGH;
int lastReading = HIGH;
unsigned long lastChangeMs = 0;

void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);
  Serial.begin(115200);
}

void loop() {
  final int reading = digitalRead(buttonPin);

  if (reading != lastReading) {
    lastChangeMs = millis();
  }

  if (millis() - lastChangeMs > debounceMs) {
    if (reading != buttonState) {
      buttonState = reading;
      if (buttonState == LOW) {
        digitalWrite(ledPin, !digitalRead(ledPin));
        Serial.println("Button pressed");
      }
    }
  }

  lastReading = reading;
}''',
  ),
  SampleCode(
    id: 'led_serial_ctrl',
    titleKey: 'sampleLedControl',
    descKey: 'sampleLedControlDesc',
    icon: '🎮',
    code: '''const int ledPin = 13;

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  Serial.println("Send '1' to ON, '0' to OFF");
}

void loop() {
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '1') {
      digitalWrite(ledPin, HIGH);
      Serial.println("LED ON");
    } else if (c == '0') {
      digitalWrite(ledPin, LOW);
      Serial.println("LED OFF");
    }
  }
}''',
  ),
  SampleCode(
    id: 'ultrasonic',
    titleKey: 'sampleUltrasonic',
    descKey: 'sampleUltrasonicDesc',
    icon: '📏',
    code: r'''const int trigPin = 9;
const int echoPin = 10;

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
}

void loop() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  float distance = duration * 0.034 / 2;

  Serial.print("{\"distance_cm\":");
  Serial.print(distance, 1);
  Serial.println("}");

  delay(200);
}''',
  ),
];
