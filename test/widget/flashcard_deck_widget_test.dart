import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/flashcard_repository.dart';
import 'package:cityzens_app/presentation/flashcards/flashcard_provider.dart';
import 'package:cityzens_app/presentation/flashcards/flashcard_deck_builder_view.dart';

import '../helpers/test_database.dart';

void main() {
  group('FlashcardDeckBuilderView Widget & Viewport Safety Tests', () {
    late FlashcardRepository repository;
    late FlashcardProvider provider;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = FlashcardRepository(database: db);
      provider = FlashcardProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadData();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<FlashcardProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(theme: AppTheme.darkTheme(), home: child),
      );
    }

    testWidgets(
      'Renders FlashcardDeckBuilderView with unique FAB heroTag fab_flashcard_deck_builder',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const FlashcardDeckBuilderView()),
        );
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.heroTag, equals('fab_flashcard_deck_builder'));
        expect(find.text('SM-2 Flashcard Deck Builder'), findsOneWidget);
        expect(find.text('SM-2 Retention Telemetry'), findsOneWidget);
      },
    );

    testWidgets('Switching active category deck updates view', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const FlashcardDeckBuilderView()),
      );
      await tester.pumpAndSettle();

      provider.selectDeck('deck_dist');
      await tester.pumpAndSettle();

      expect(provider.selectedDeckId, 'deck_dist');
      expect(find.text('Distributed Systems & Consensus'), findsWidgets);
    });

    testWidgets(
      'Renders 800x360 landscape viewport with ZERO RenderFlex overflows',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const FlashcardDeckBuilderView()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('DECKS & CATEGORIES'), findsOneWidget);
        expect(find.text('SM-2 Retention Telemetry'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Add Card FAB opens card creation dialog with validation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const FlashcardDeckBuilderView()),
        );
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        expect(find.text('Add Flashcard'), findsOneWidget);
        expect(find.text('Question Prompt (Front)'), findsOneWidget);

        // Tap submit with empty fields
        final submitButton = find.widgetWithText(FilledButton, 'Add Card');
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Question is required'), findsOneWidget);
      },
    );
  });
}
