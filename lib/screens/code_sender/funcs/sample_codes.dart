/// 아두이노 샘플 코드 모음
class SampleCode {
  final String id;
  final String titleKey; // l10n key
  final String descKey; // l10n key
  final String icon;
  final String code;

  const SampleCode({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.code,
  });
}

const List<SampleCode> sampleCodes = [
  SampleCode(
    id: 'blink',
    titleKey: 'sampleBlink',
    descKey: 'sampleBlinkDesc',
    icon: '💡',
    code: '''void setup() {
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
    code: r'''void setup() {
  Serial.begin(115200);
}

void loop() {
  int sensorValue = analogRead(A0);
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
    code: '''void setup() {
  Serial.begin(115200);
}

void loop() {
  int value = analogRead(A0);
  Serial.println(value);
  delay(100);
}''',
  ),
  SampleCode(
    id: 'servo_sweep',
    titleKey: 'sampleServoSweep',
    descKey: 'sampleServoSweepDesc',
    icon: '🔄',
    code: '''#include <Servo.h>

Servo myServo;

void setup() {
  myServo.attach(9);
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

#define DHTPIN 2
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

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
    id: 'led_serial_ctrl',
    titleKey: 'sampleLedControl',
    descKey: 'sampleLedControlDesc',
    icon: '🎮',
    code: '''int ledPin = 13;

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
    code: r'''#define TRIG_PIN 9
#define ECHO_PIN 10

void setup() {
  Serial.begin(115200);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
}

void loop() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH);
  float distance = duration * 0.034 / 2;

  Serial.print("{\"distance_cm\":");
  Serial.print(distance, 1);
  Serial.println("}");

  delay(200);
}''',
  ),
];
