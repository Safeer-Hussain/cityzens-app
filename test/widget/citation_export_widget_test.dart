import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/models/book.dart';
import 'package:cityzens_app/data/repositories/library_repository.dart';
import 'package:cityzens_app/presentation/library/library_provider.dart';
import 'package:cityzens_app/presentation/library/widgets/citation_export_modal.dart';

import '../helpers/test_database.dart';

void main() {
  group('CitationExportModal Widget & Viewport Safety Tests', () {
    late LibraryRepository repository;
    late LibraryProvider provider;
    late ThemeProvider themeProvider;

    const testBook = BookModel(
      id: 'book_01',
      isbn: '978-0134494166',
      title: "Clean Architecture: A Craftsman's Guide",
      author: 'Robert C. Martin',
      category: 'Software Engineering',
      shelfLocation: 'FLOOR-2 / AISLE-A',
      totalCopies: 5,
      availableCopies: 3,
      isReserved: false,
      abstractText: 'Universal rules of software architecture.',
      tableOfContents: ['Chapter 1', 'Chapter 2'],
      coverAsset: 'assets/images/book_clean_architecture.png',
    );

    setUp(() async {
      final db = await createTestDatabase();
      repository = LibraryRepository(database: db);
      provider = LibraryProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadLibraryData();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<LibraryProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets(
      'Renders CitationExportModal with title, author, and style chips',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(
            child: CitationExportModal(book: testBook, provider: provider),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Academic Citation Exporter'), findsOneWidget);
        expect(
          find.text("Clean Architecture: A Craftsman's Guide"),
          findsOneWidget,
        );
        expect(find.text('BibTeX'), findsOneWidget);
        expect(find.text('APA 7th'), findsOneWidget);
        expect(find.text('IEEE'), findsOneWidget);
        expect(find.text('Chicago 17th'), findsOneWidget);
        expect(find.text('Copy Citation'), findsOneWidget);
      },
    );

    testWidgets('Switching style chip updates displayed reference text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          child: CitationExportModal(book: testBook, provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap APA 7th chip
      final apaChip = find.widgetWithText(ChoiceChip, 'APA 7th');
      expect(apaChip, findsOneWidget);

      await tester.tap(apaChip);
      await tester.pumpAndSettle();

      expect(find.text('APA 7TH REFERENCE'), findsOneWidget);
      expect(find.textContaining('Martin, R. C.'), findsOneWidget);
    });

    testWidgets(
      'Tapping Copy Markdown executes clipboard workflow without error',
      (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              return null;
            }
            return null;
          },
        );
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await tester.pumpWidget(
          buildTestApp(
            child: CitationExportModal(book: testBook, provider: provider),
          ),
        );
        await tester.pumpAndSettle();

        final mdButton = find.widgetWithText(
          OutlinedButton,
          'Copy Markdown (.md)',
        );
        expect(mdButton, findsOneWidget);

        await tester.tap(mdButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders 800x360 landscape viewport with ZERO RenderFlex overflows',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(
            child: CitationExportModal(book: testBook, provider: provider),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CitationExportModal), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
