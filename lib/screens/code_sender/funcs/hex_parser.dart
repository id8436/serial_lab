import 'dart:typed_data';

/// Intel HEX 포맷 파서
class IntelHexParser {
  /// Intel HEX 파일 내용을 파싱해 플랫(flat) 바이너리로 반환.
  /// 빈 바이트는 0xFF로 채움.
  static Uint8List parse(String hexContent) {
    int extendedAddress = 0;
    final Map<int, int> flashMap = {};

    for (final rawLine in hexContent.split('\n')) {
      final line = rawLine.trim();
      if (!line.startsWith(':') || line.length < 11) continue;

      // 각 바이트 파싱
      final bytes = <int>[];
      for (int i = 1; i < line.length - 1; i += 2) {
        bytes.add(int.parse(line.substring(i, i + 2), radix: 16));
      }

      final byteCount = bytes[0];
      final address = (bytes[1] << 8) | bytes[2];
      final recordType = bytes[3];

      switch (recordType) {
        case 0x00: // Data
          final fullAddr = extendedAddress + address;
          for (int i = 0; i < byteCount; i++) {
            flashMap[fullAddr + i] = bytes[4 + i];
          }
          break;
        case 0x01: // EOF
          break;
        case 0x02: // Extended Segment Address
          extendedAddress = ((bytes[4] << 8) | bytes[5]) << 4;
          break;
        case 0x04: // Extended Linear Address
          extendedAddress = ((bytes[4] << 8) | bytes[5]) << 16;
          break;
        default:
          break;
      }
    }

    if (flashMap.isEmpty) return Uint8List(0);

    final maxAddr = flashMap.keys.reduce((a, b) => a > b ? a : b);
    final size = maxAddr + 1;

    final flat = Uint8List(size)..fillRange(0, size, 0xFF);
    for (final entry in flashMap.entries) {
      flat[entry.key] = entry.value;
    }

    return flat;
  }

  /// 파일 크기를 pageSize의 배수로 패딩 (0xFF)
  static Uint8List padToPageSize(Uint8List data, int pageSize) {
    if (data.length % pageSize == 0) return data;
    final paddedSize = ((data.length + pageSize - 1) ~/ pageSize) * pageSize;
    final padded = Uint8List(paddedSize)..fillRange(0, paddedSize, 0xFF);
    padded.setRange(0, data.length, data);
    return padded;
  }
}
