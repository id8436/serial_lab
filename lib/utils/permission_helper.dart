import 'package:permission_handler/permission_handler.dart';

/// 권한 관리 유틸리티
class PermissionHelper {
  /// 블루투스 권한 요청
  static Future<bool> requestBluetoothPermissions() async {
    if (await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      return true;
    }

    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// 위치 권한 요청 (블루투스 스캔에 필요)
  static Future<bool> requestLocationPermissions() async {
    if (await Permission.location.isGranted) {
      return true;
    }

    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// USB 권한 확인 (Android에서 자동으로 처리됨)
  static Future<bool> checkUsbPermissions() async {
    // USB 권한은 사용자가 기기를 연결할 때 시스템이 자동으로 요청
    return true;
  }
}
