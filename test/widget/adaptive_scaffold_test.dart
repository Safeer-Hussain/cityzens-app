import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/services/connectivity_service.dart';
import 'package:cityzens_app/core/services/native_camera_bridge.dart';
import 'package:cityzens_app/core/services/telemetry_service.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/attendance_repository.dart';
import 'package:cityzens_app/data/repositories/library_repository.dart';
import 'package:cityzens_app/data/repositories/campus_feed_repository.dart';
import 'package:cityzens_app/data/repositories/scanner_repository.dart';
import 'package:cityzens_app/presentation/attendance/attendance_provider.dart';
import 'package:cityzens_app/presentation/attendance/widgets/attendance_trend_chart.dart';
import 'package:cityzens_app/presentation/library/library_provider.dart';
import 'package:cityzens_app/presentation/scanner/scanner_provider.dart';
import 'package:cityzens_app/presentation/ai_tutor/ai_tutor_provider.dart';
import 'package:cityzens_app/presentation/campus/campus_feed_provider.dart';
import 'package:cityzens_app/presentation/shell/adaptive_scaffold.dart';
import '../helpers/test_database.dart';

void main() {
  Widget createTestWidget({
    required Widget child,
    required ThemeProvider themeProvider,
    required AttendanceProvider attendanceProvider,
    required LibraryProvider libraryProvider,
    required ScannerProvider scannerProvider,
    required AiTutorProvider aiTutorProvider,
    required CampusFeedProvider campusFeedProvider,
    required ConnectivityService connectivityService,
    required TelemetryService telemetryService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),
        ChangeNotifierProvider<TelemetryService>.value(value: telemetryService),
        ChangeNotifierProvider<AttendanceProvider>.value(value: attendanceProvider),
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
        ChangeNotifierProvider<ScannerProvider>.value(value: scannerProvider),
        ChangeNotifierProvider<AiTutorProvider>.value(value: aiTutorProvider),
        ChangeNotifierProvider<CampusFeedProvider>.value(value: campusFeedProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: theme.themeMode,
            home: child,
          );
        },
      ),
    );
  }

  group('AdaptiveScaffold & Widget Safety Tests', () {
    late ThemeProvider themeProvider;
    late AttendanceProvider attendanceProvider;
    late LibraryProvider libraryProvider;
    late ScannerProvider scannerProvider;
    late AiTutorProvider aiTutorProvider;
    late CampusFeedProvider campusFeedProvider;
    late ConnectivityService connectivityService;
    late TelemetryService telemetryService;

    setUp(() async {
      final db = await createTestDatabase();
      final attendanceRepo = AttendanceRepository(database: db);
      final libraryRepo = LibraryRepository(database: db);
      final campusFeedRepo = CampusFeedRepository(database: db);
      final cameraBridge = NativeCameraBridge();
      final scannerRepo = ScannerRepository(bridge: cameraBridge);

      themeProvider = ThemeProvider(null);
      attendanceProvider = AttendanceProvider(repository: attendanceRepo);
      libraryProvider = LibraryProvider(repository: libraryRepo);
      scannerProvider = ScannerProvider(repository: scannerRepo);
      aiTutorProvider = AiTutorProvider(
        attendanceRepository: attendanceRepo,
        libraryRepository: libraryRepo,
      );
      campusFeedProvider = CampusFeedProvider(repository: campusFeedRepo);
      connectivityService = ConnectivityService();
      telemetryService = TelemetryService();

      await attendanceProvider.loadAttendanceData();
      await libraryProvider.loadLibraryData();
      await campusFeedProvider.loadFeed();
    });

    testWidgets('Renders portrait shell with zero duplicate Hero tag exceptions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const AdaptiveScaffold(),
          themeProvider: themeProvider,
          attendanceProvider: attendanceProvider,
          libraryProvider: libraryProvider,
          scannerProvider: scannerProvider,
          aiTutorProvider: aiTutorProvider,
          campusFeedProvider: campusFeedProvider,
          connectivityService: connectivityService,
          telemetryService: telemetryService,
        ),
      );
      await tester.pumpAndSettle();

      // Look for FAB and verify tag is unique
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fab = tester.widget<FloatingActionButton>(fabFinder);
      expect(fab.heroTag, equals('fab_attendance_checkin'));
    });

    testWidgets('Renders 800x360 landscape viewport with NavigationRail and ZERO RenderFlex overflows', (tester) async {
      // Set to 800x360 dp landscape
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const AdaptiveScaffold(),
          themeProvider: themeProvider,
          attendanceProvider: attendanceProvider,
          libraryProvider: libraryProvider,
          scannerProvider: scannerProvider,
          aiTutorProvider: aiTutorProvider,
          campusFeedProvider: campusFeedProvider,
          connectivityService: connectivityService,
          telemetryService: telemetryService,
        ),
      );
      await tester.pumpAndSettle();

      // NavigationRail must be active instead of NavigationBar
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Verify zero Flutter errors / RenderFlex overflow stripes
      expect(tester.takeException(), isNull);
    });

    testWidgets('Instant Dark and Light theme switching updates UI dynamically', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const AdaptiveScaffold(),
          themeProvider: themeProvider,
          attendanceProvider: attendanceProvider,
          libraryProvider: libraryProvider,
          scannerProvider: scannerProvider,
          aiTutorProvider: aiTutorProvider,
          campusFeedProvider: campusFeedProvider,
          connectivityService: connectivityService,
          telemetryService: telemetryService,
        ),
      );
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, isTrue);

      // Tap theme toggle button
      final themeToggleBtn = find.byTooltip('Toggle Dark/Light Mode');
      expect(themeToggleBtn, findsOneWidget);
      await tester.tap(themeToggleBtn);
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, isFalse);
    });

    testWidgets('AttendanceTrendChart renders full-width edge-to-edge without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: AttendanceTrendChart(currentPercentage: 91.4),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceTrendChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
