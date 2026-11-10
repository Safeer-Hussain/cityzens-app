import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/exam_repository.dart';
import 'package:cityzens_app/presentation/exam/exam_provider.dart';
import 'package:cityzens_app/presentation/exam/exam_hall_pass_view.dart';
import '../helpers/test_database.dart';

void main() {
  group('ExamHallPassView Widget & Viewport Safety Tests', () {
    late ExamRepository repository;
    late ExamProvider provider;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = ExamRepository(database: db);
      provider = ExamProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadPasses();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ExamProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          home: child,
        ),
      );
    }

    testWidgets('Renders ExamHallPassView with unique FAB heroTag fab_exam_reminder_toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const ExamHallPassView()));
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fab = tester.widget<FloatingActionButton>(fabFinder);
      expect(fab.heroTag, equals('fab_exam_reminder_toggle'));
      expect(find.text('Exam Hall Seat Finder & Digital Pass'), findsOneWidget);
    });

    testWidgets('Renders 800x360 landscape viewport with ZERO RenderFlex overflows', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const ExamHallPassView()));
      await tester.pumpAndSettle();

      expect(find.byType(ExamHallPassView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Segmented tab switching between Admission Pass, Seat Finder and Timetable', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const ExamHallPassView()));
      await tester.pumpAndSettle();

      // Starts on Admission Pass
      expect(find.text('CITYZENS ADMISSION SLIP'), findsOneWidget);
      expect(find.text('SHA-256 REGISTRY CHECKSUM'), findsOneWidget);

      // Switch to Seat Finder
      await tester.tap(find.text('Seat Finder'));
      await tester.pumpAndSettle();

      expect(find.text('EXAMINATION PODIUM & PROCTOR STAGE'), findsOneWidget);
      expect(find.text('Your Seat'), findsOneWidget);

      // Switch to Timetable
      await tester.tap(find.text('Timetable'));
      await tester.pumpAndSettle();

      expect(find.text('Registered Examination Timetable'), findsOneWidget);
      expect(find.text('4 Sessions'), findsOneWidget);
    });

    testWidgets('Switching exam chip updates selected course code and desk badge', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const ExamHallPassView()));
      await tester.pumpAndSettle();

      // Find chip for CS-420
      final chipFinder = find.widgetWithText(ChoiceChip, 'CS-420 (HA-E08)');
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(provider.selectedPass?.courseCode, equals('CS-420'));
      expect(find.text('HA-E08'), findsWidgets);
    });
  });
}
