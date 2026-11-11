import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/study_room_repository.dart';
import 'package:cityzens_app/presentation/study_room/study_room_provider.dart';

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyRoomProvider & Repository Business Logic Tests', () {
    late StudyRoomRepository repository;
    late StudyRoomProvider provider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = StudyRoomRepository(database: db);
      provider = StudyRoomProvider(repository: repository);
      await provider.loadData();
    });

    test(
      'Loads all seeded study rooms across campus floors 1 through 4',
      () async {
        expect(provider.rooms, isNotEmpty);
        expect(provider.totalRooms, greaterThanOrEqualTo(5));

        final floors = provider.rooms.map((r) => r.floor).toSet();
        expect(floors.contains(1), isTrue);
        expect(floors.contains(2), isTrue);
        expect(floors.contains(3), isTrue);
        expect(floors.contains(4), isTrue);
      },
    );

    test('Floor filter selectively filters room listings', () async {
      provider.setFloor(1);
      for (final room in provider.filteredRooms) {
        expect(room.floor, equals(1));
      }

      provider.setFloor(3);
      for (final room in provider.filteredRooms) {
        expect(room.floor, equals(3));
      }

      provider.setFloor(null);
      expect(provider.filteredRooms.length, equals(provider.totalRooms));
    });

    test(
      'Capacity filter correctly filters rooms by minimum seat threshold',
      () async {
        provider.setCapacityFilter(6);
        for (final room in provider.filteredRooms) {
          expect(room.capacity, greaterThanOrEqualTo(6));
        }

        provider.setCapacityFilter(10);
        for (final room in provider.filteredRooms) {
          expect(room.capacity, greaterThanOrEqualTo(10));
        }

        provider.setCapacityFilter(null);
        expect(provider.filteredRooms.length, equals(provider.totalRooms));
      },
    );

    test(
      'Search query matches room name and amenity keywords case-insensitively',
      () async {
        provider.setSearchQuery('Turing');
        expect(provider.filteredRooms.length, equals(1));
        expect(provider.filteredRooms.first.name, contains('Turing'));

        provider.setSearchQuery('Whiteboard');
        expect(provider.filteredRooms, isNotEmpty);
        for (final room in provider.filteredRooms) {
          final matchesName = room.name.toLowerCase().contains('whiteboard');
          final matchesAmenity = room.amenities.any(
            (a) => a.toLowerCase().contains('whiteboard'),
          );
          expect(matchesName || matchesAmenity, isTrue);
        }
      },
    );

    test(
      'Collision radar detects overlapping booking interval on the same room',
      () async {
        final existing = provider.bookings.firstWhere(
          (b) => b.roomId == 'sr_201',
        );
        final collision = await provider.checkCollision(
          roomId: 'sr_201',
          startTime: existing.startTime.add(const Duration(minutes: 30)),
          endTime: existing.endTime.subtract(const Duration(minutes: 30)),
        );
        expect(collision, isTrue);
      },
    );

    test(
      'Collision radar allows adjacent non-overlapping booking intervals',
      () async {
        final existing = provider.bookings.firstWhere(
          (b) => b.roomId == 'sr_201',
        );
        final noCollisionBefore = await provider.checkCollision(
          roomId: 'sr_201',
          startTime: existing.startTime.subtract(const Duration(hours: 1)),
          endTime: existing.startTime, // Ends exactly when existing starts
        );
        expect(noCollisionBefore, isFalse);

        final noCollisionAfter = await provider.checkCollision(
          roomId: 'sr_201',
          startTime: existing.endTime, // Starts exactly when existing ends
          endTime: existing.endTime.add(const Duration(hours: 1)),
        );
        expect(noCollisionAfter, isFalse);
      },
    );

    test(
      'bookRoom persists valid reservation and updates myReservations list',
      () async {
        final now = DateTime.now();
        final start = now.add(const Duration(days: 2, hours: 10));
        final end = start.add(const Duration(hours: 1));

        final success = await provider.bookRoom(
          roomId: 'sr_101',
          purpose: 'Architecture Capstone Brainstorm',
          startTime: start,
          endTime: end,
          attendees: ['safeer@cityzens.edu', 'aris@cityzens.edu'],
        );

        expect(success, isTrue);
        expect(provider.errorMessage, isNull);

        final matching = provider.myReservations.where(
          (b) =>
              b.roomId == 'sr_101' &&
              b.purpose == 'Architecture Capstone Brainstorm',
        );
        expect(matching.isNotEmpty, isTrue);
        expect(matching.first.floor, equals(1));
      },
    );

    test(
      'bookRoom rejects collision and returns false with error message',
      () async {
        // Try to book overlapping slot on sr_201
        final now = DateTime.now();
        final success = await provider.bookRoom(
          roomId: 'sr_201',
          purpose: 'Duplicate Overlapping Meeting',
          startTime: now.add(const Duration(hours: 2, minutes: 15)),
          endTime: now.add(const Duration(hours: 3, minutes: 45)),
          attendees: ['test@cityzens.edu'],
        );

        expect(success, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('collision'));
      },
    );

    test(
      'cancelBooking updates status to cancelled and releases room interval',
      () async {
        // Cancel the initial booking sr_book_init_01 on sr_201
        final success = await provider.cancelBooking('sr_book_init_01');
        expect(success, isTrue);

        final initialBooking = provider.bookings.firstWhere(
          (b) => b.id == 'sr_book_init_01',
        );
        expect(initialBooking.status, equals('cancelled'));

        // Now the previously occupied slot should have 0 collisions
        final now = DateTime.now();
        final collisionAfterCancel = await provider.checkCollision(
          roomId: 'sr_201',
          startTime: now.add(const Duration(hours: 2, minutes: 30)),
          endTime: now.add(const Duration(hours: 3, minutes: 30)),
        );
        expect(collisionAfterCancel, isFalse);
      },
    );
  });
}
