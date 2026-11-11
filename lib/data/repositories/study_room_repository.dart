import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/study_room.dart';
import '../models/study_room_booking.dart';

class StudyRoomRepository {
  final AppDatabase database;

  StudyRoomRepository({required this.database});

  Database get _db => database.db;

  Future<List<StudyRoomModel>> getRooms({
    int? floor,
    int? minCapacity,
    String? query,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (floor != null) {
      whereClauses.add('floor = ?');
      whereArgs.add(floor);
    }

    if (minCapacity != null && minCapacity > 0) {
      whereClauses.add('capacity >= ?');
      whereArgs.add(minCapacity);
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = '%${query.trim()}%';
      whereClauses.add('(name LIKE ? OR amenities LIKE ?)');
      whereArgs.addAll([sanitized, sanitized]);
    }

    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final results = await _db.query(
      'study_rooms',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'floor ASC, capacity ASC',
    );

    return results.map((m) => StudyRoomModel.fromMap(m)).toList();
  }

  Future<StudyRoomModel?> getRoomById(String id) async {
    final results = await _db.query(
      'study_rooms',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return StudyRoomModel.fromMap(results.first);
  }

  Future<List<StudyRoomBookingModel>> getBookings({
    String? roomId,
    int? floor,
    String? status,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (roomId != null) {
      whereClauses.add('room_id = ?');
      whereArgs.add(roomId);
    }

    if (floor != null) {
      whereClauses.add('floor = ?');
      whereArgs.add(floor);
    }

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }

    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final results = await _db.query(
      'study_room_bookings',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_time ASC',
    );

    return results.map((m) => StudyRoomBookingModel.fromMap(m)).toList();
  }

  Future<List<StudyRoomBookingModel>> getUserBookings(String studentId) async {
    final results = await _db.query(
      'study_room_bookings',
      where: 'booked_by_id = ? AND status != ?',
      whereArgs: [studentId, 'cancelled'],
      orderBy: 'start_time ASC',
    );
    return results.map((m) => StudyRoomBookingModel.fromMap(m)).toList();
  }

  /// Checks if any existing confirmed booking collides with the requested [startTime] and [endTime].
  /// Collision occurs if requested start is before existing end AND requested end is after existing start.
  Future<bool> checkTimeSlotCollision({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    final requestedStart = startTime.millisecondsSinceEpoch;
    final requestedEnd = endTime.millisecondsSinceEpoch;

    final whereClauses = [
      'room_id = ?',
      'status = ?',
      'start_time < ?',
      'end_time > ?',
    ];
    final whereArgs = <dynamic>[
      roomId,
      'confirmed',
      requestedEnd,
      requestedStart,
    ];

    if (excludeBookingId != null) {
      whereClauses.add('id != ?');
      whereArgs.add(excludeBookingId);
    }

    final results = await _db.query(
      'study_room_bookings',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  Future<StudyRoomBookingModel> createBooking({
    required String roomId,
    required String bookedById,
    required String bookedByName,
    required String purpose,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> attendees,
  }) async {
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError(
        'Booking end time must be strictly after start time.',
      );
    }

    final hasCollision = await checkTimeSlotCollision(
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
    );

    if (hasCollision) {
      throw StateError(
        'Room schedule collision: The selected time slot is already reserved.',
      );
    }

    final room = await getRoomById(roomId);
    if (room == null) {
      throw StateError('Room not found with ID: $roomId');
    }

    final bookingId = 'sr_book_${DateTime.now().microsecondsSinceEpoch}';
    final booking = StudyRoomBookingModel(
      id: bookingId,
      roomId: roomId,
      roomName: room.name,
      floor: room.floor,
      bookedById: bookedById,
      bookedByName: bookedByName,
      purpose: purpose,
      startTime: startTime,
      endTime: endTime,
      attendees: attendees,
      createdAt: DateTime.now(),
      status: 'confirmed',
    );

    await _db.insert(
      'study_room_bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return booking;
  }

  Future<bool> cancelBooking(String bookingId) async {
    final count = await _db.update(
      'study_room_bookings',
      {'status': 'cancelled'},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
    return count > 0;
  }
}
