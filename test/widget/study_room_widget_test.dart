import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cityzens_app/core/theme/app_theme.dart';
import 'package:cityzens_app/core/theme/theme_provider.dart';
import 'package:cityzens_app/data/repositories/study_room_repository.dart';
import 'package:cityzens_app/presentation/study_room/study_room_provider.dart';
import 'package:cityzens_app/presentation/study_room/study_room_booking_view.dart';

import '../helpers/test_database.dart';

void main() {
  group('StudyRoomBookingView Widget & Viewport Safety Tests', () {
    late StudyRoomRepository repository;
    late StudyRoomProvider provider;
    late ThemeProvider themeProvider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = StudyRoomRepository(database: db);
      provider = StudyRoomProvider(repository: repository);
      themeProvider = ThemeProvider(null);
      await provider.loadData();
    });

    Widget buildTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<StudyRoomProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(theme: AppTheme.darkTheme(), home: child),
      );
    }

    testWidgets(
      'Renders StudyRoomBookingView with unique FAB heroTag fab_study_room_booking',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const StudyRoomBookingView()),
        );
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        final fab = tester.widget<FloatingActionButton>(fabFinder);
        expect(fab.heroTag, equals('fab_study_room_booking'));
        expect(find.text('Peer Study Room Booking Engine'), findsOneWidget);
        expect(find.text('Available Pods'), findsOneWidget);
      },
    );

    testWidgets('Segmented floor chips filter room cards dynamically', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(child: const StudyRoomBookingView()),
      );
      await tester.pumpAndSettle();

      // Tap Floor 1 chip
      final floor1Chip = find.widgetWithText(
        ChoiceChip,
        'Floor 1 (Innovation)',
      );
      expect(floor1Chip, findsOneWidget);

      await tester.tap(floor1Chip);
      await tester.pumpAndSettle();

      expect(find.text('Turing Innovation Pod 101'), findsOneWidget);
      expect(find.text('Lovelace Brainstorm Suite 102'), findsOneWidget);
      // Floor 2 room should NOT be in Floor 1
      expect(find.text('Dijkstra Algorithm Pod 201'), findsNothing);
    });

    testWidgets(
      'Tab switching between Available Pods and My Reservations displays confirmed session',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const StudyRoomBookingView()),
        );
        await tester.pumpAndSettle();

        // Find tab with My Reservations
        final reservationsTab = find.textContaining('My Reservations');
        expect(reservationsTab, findsOneWidget);

        await tester.tap(reservationsTab);
        await tester.pumpAndSettle();

        expect(find.textContaining('CONFIRMED SESSIONS'), findsOneWidget);
        expect(find.text('Dijkstra Algorithm Pod 201'), findsOneWidget);
        expect(
          find.text('Distributed Systems & Raft Consensus Study'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders 800x360 landscape viewport with ZERO RenderFlex overflows',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestApp(child: const StudyRoomBookingView()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StudyRoomBookingView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
