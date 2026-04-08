import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전역 로거
/// - 릴리즈 빌드에서는 warning/error 이상만 출력
/// - 디버그 빌드에서는 모든 레벨 출력
final logger = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
