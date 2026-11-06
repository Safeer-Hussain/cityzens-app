import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/telemetry_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/library_repository.dart';
import 'data/repositories/campus_feed_repository.dart';
import 'data/repositories/scanner_repository.dart';
import 'presentation/attendance/attendance_provider.dart';
import 'presentation/library/library_provider.dart';
import 'presentation/scanner/scanner_provider.dart';
import 'presentation/ai_tutor/ai_tutor_provider.dart';
import 'presentation/campus/campus_feed_provider.dart';
import 'presentation/splash/splash_view.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      await setupServiceLocator(testPrefs: prefs);
    } catch (_) {
      // Graceful local initialization fallback
    }

    runApp(CityzensApp(sharedPreferences: prefs));
  }, (error, stack) {
    // Top-level unhandled exception guard
  });
}

class CityzensApp extends StatelessWidget {
  final SharedPreferences? sharedPreferences;

  const CityzensApp({super.key, this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(sharedPreferences),
        ),
        ChangeNotifierProvider<ConnectivityService>.value(
          value: sl<ConnectivityService>(),
        ),
        ChangeNotifierProvider<TelemetryService>.value(
          value: sl<TelemetryService>(),
        ),
        ChangeNotifierProvider<AttendanceProvider>(
          create: (_) => AttendanceProvider(repository: sl<AttendanceRepository>()),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(repository: sl<LibraryRepository>()),
        ),
        ChangeNotifierProvider<ScannerProvider>(
          create: (_) => ScannerProvider(repository: sl<ScannerRepository>()),
        ),
        ChangeNotifierProvider<AiTutorProvider>(
          create: (_) => AiTutorProvider(
            attendanceRepository: sl<AttendanceRepository>(),
            libraryRepository: sl<LibraryRepository>(),
          ),
        ),
        ChangeNotifierProvider<CampusFeedProvider>(
          create: (_) => CampusFeedProvider(repository: sl<CampusFeedRepository>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Cityzens',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: const SplashView(),
          );
        },
      ),
    );
  }
}
