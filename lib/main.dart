import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:serial_lab/providers/serial_provider.dart';
import 'package:serial_lab/providers/settings_provider.dart';
import 'package:serial_lab/screens/home/startup_screen.dart';
import 'package:serial_lab/models/app_settings.dart';
import 'package:serial_lab/models/serial_data.dart';
import 'package:serial_lab/l10n/app_localizations.dart';
import 'package:serial_lab/utils/app_logger.dart';

Future<void> _initializeApp() async {
  // Hive 초기화
  await Hive.initFlutter();

  // TypeAdapter 등록 (hot restart에서 중복 등록 방지)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(SerialDataLogAdapter());
  }

  // Box 열기
  if (!Hive.isBoxOpen('settings')) {
    await Hive.openBox<AppSettings>('settings');
  }
  if (!Hive.isBoxOpen('editor')) {
    await Hive.openBox('editor'); // 에디터 코드 저장용 (raw box)
  }
}

Future<void> _warmUpNonCriticalBoxes() async {
  try {
    // serial_logs는 초기 부팅 필수 의존성이 아니므로 백그라운드로 연다.
    if (!Hive.isBoxOpen('serial_logs')) {
      await Hive.openBox<SerialDataLog>('serial_logs');
    }
  } catch (e, st) {
    logger.e('Non-critical box warm-up failed', error: e, stackTrace: st);
  }
}

void main() {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 예외 처리 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e('Flutter Error', error: details.exception, stackTrace: details.stack);
  };

  runApp(MainApp(initializationFuture: _initializeApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.initializationFuture});

  final Future<void> initializationFuture;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.initializationFuture.then((_) {
      unawaited(_warmUpNonCriticalBoxes());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 앱이 백그라운드로 갔다가 다시 포어그라운드로 올 때 처리
    switch (state) {
      case AppLifecycleState.paused:
        logger.d('App paused');
        break;
      case AppLifecycleState.resumed:
        logger.d('App resumed');
        break;
      case AppLifecycleState.detached:
        logger.d('App detached');
        break;
      case AppLifecycleState.inactive:
        logger.d('App inactive');
        break;
      case AppLifecycleState.hidden:
        logger.d('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: widget.initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Initializing...'),
                  ],
                ),
              ),
            ),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SerialProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
          ],
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return MaterialApp(
                title: 'Serial Lab',
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: settings.locale,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                  cardTheme: const CardThemeData(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                  cardTheme: const CardThemeData(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                home: const StartupScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }
}

