/// 업로드 프로토콜 종류
enum UploadProtocol {
  stk500,       // Arduino AVR (Uno, Nano, Mega)
  avr109,       // Arduino AVR Caterina (Leonardo, Micro)
  esptool,      // ESP32, ESP8266
  stm32,        // STM32 UART bootloader
  bossa,        // SAMD (SAM-BA)
  unsupported,  // RP2040 등
}

/// 보드별 업로드 설정
class BoardUploadConfig {
  final int pageSize;
  final int baudRate;

  const BoardUploadConfig({required this.pageSize, required this.baudRate});
}
