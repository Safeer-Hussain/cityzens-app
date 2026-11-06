import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/transcript_repository.dart';
import 'package:cityzens_app/presentation/gpa_calculator/gpa_calculator_provider.dart';
import 'package:cityzens_app/presentation/gpa_calculator/gpa_calculator_view.dart';
import '../helpers/test_database.dart';

void main() {
  group('GpaCalculatorView Widget & Viewport Safety Tests', () {
    late GpaCalculatorProvider provider;
    late TranscriptRepository repository;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = TranscriptRepository(database: db);
      provider = GpaCalculatorProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadTranscripts();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<GpaCalculatorProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          home: child,
        ),
      );
    }

    testWidgets('Renders GpaCalculatorView with unique FAB heroTag fab_gpa_simulate', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const GpaCalculatorView()));
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final fab = tester.widget<FloatingActionButton>(fabFinder);
      expect(fab.heroTag, equals('fab_gpa_simulate'));
    });

    testWidgets('Renders 800x360 landscape viewport with ZERO RenderFlex overflows', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const GpaCalculatorView()));
      await tester.pumpAndSettle();

      expect(find.byType(GpaCalculatorView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping grade chip updates projected CGPA without errors', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(child: const GpaCalculatorView()));
      await tester.pumpAndSettle();

      expect(find.text('3.95'), findsOneWidget);

      // Find 'B' grade chip
      final bFinder = find.text('B').first;
      await tester.tap(bFinder);
      await tester.pumpAndSettle();

      // Should have recalculated
      expect(provider.simulatedSemesterGpa, isNot(equals(4.00)));
      expect(tester.takeException(), isNull);
    });
  });
}
