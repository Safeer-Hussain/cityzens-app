import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/exam_cryptography.dart';
import '../models/exam_hall_pass.dart';

class ExamRepository {
  final AppDatabase database;

  ExamRepository({required this.database});

  Database get _db => database.db;

  /// Retrieves all examination hall passes sorted chronologically.
  Future<List<ExamHallPassModel>> getAllPasses() async {
    final rows = await _db.query('exam_hall_passes', orderBy: 'exam_date ASC');
    return rows.map((r) => ExamHallPassModel.fromMap(r)).toList();
  }

  /// Retrieves a specific examination pass by its identifier.
  Future<ExamHallPassModel?> getPassById(String id) async {
    final rows = await _db.query(
      'exam_hall_passes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExamHallPassModel.fromMap(rows.first);
  }

  /// Toggles the offline timetable reminder alarm state for a pass.
  Future<bool> toggleReminder(String passId, bool isArmed) async {
    final count = await _db.update(
      'exam_hall_passes',
      {'is_reminder_set': isArmed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [passId],
    );
    return count > 0;
  }

  /// Updates verification status (e.g. at security turnstile or exam gate).
  Future<bool> setPassVerified(String passId, bool verified) async {
    final count = await _db.update(
      'exam_hall_passes',
      {'is_verified': verified ? 1 : 0},
      where: 'id = ?',
      whereArgs: [passId],
    );
    return count > 0;
  }

  /// Cryptographically verifies the admission slip token against database record.
  Future<bool> verifyPassTampering(String passId) async {
    final pass = await getPassById(passId);
    if (pass == null) return false;

    return ExamCryptography.verifyChecksum(
      passId: pass.id,
      studentId: pass.studentId,
      courseCode: pass.courseCode,
      hallName: pass.hallName,
      deskNumber: pass.deskNumber,
      examTimestamp: pass.examDate.millisecondsSinceEpoch,
      expectedChecksum: pass.cryptographicChecksum,
    );
  }

  /// Generates a realistic, deterministic seat grid matrix for a given examination hall.
  List<ExamSeat> generateHallMatrix(
    ExamHall hall,
    ExamHallPassModel? activePass,
  ) {
    final seats = <ExamSeat>[];
    final seed = hall.name.hashCode;
    final random = Random(seed);

    for (final row in hall.rows) {
      for (int num = 1; num <= hall.seatsPerRow; num++) {
        final isUserSeat =
            activePass != null &&
            activePass.hallName.toLowerCase() == hall.name.toLowerCase() &&
            activePass.seatRow.toUpperCase() == row.toUpperCase() &&
            activePass.seatNumber == num;

        if (isUserSeat) {
          seats.add(
            ExamSeat(
              row: row,
              number: num,
              hallName: hall.name,
              status: SeatStatus.assignedToUser,
              assignedCandidateMasked: 'CTZ-***-8842 (YOU)',
            ),
          );
          continue;
        }

        // Accessible seating on front row ends
        final isAccessible =
            (row == 'A' && (num <= 2 || num >= hall.seatsPerRow - 1));
        if (isAccessible) {
          final isAccOccupied = random.nextBool();
          seats.add(
            ExamSeat(
              row: row,
              number: num,
              hallName: hall.name,
              status: isAccOccupied
                  ? SeatStatus.occupied
                  : SeatStatus.accessible,
              assignedCandidateMasked: isAccOccupied
                  ? 'CTZ-***-${1000 + random.nextInt(8999)}'
                  : null,
            ),
          );
          continue;
        }

        // Realistic ~65% occupancy density
        final isOccupied = random.nextDouble() < 0.65;
        seats.add(
          ExamSeat(
            row: row,
            number: num,
            hallName: hall.name,
            status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
            assignedCandidateMasked: isOccupied
                ? 'CTZ-***-${1000 + random.nextInt(8999)}'
                : null,
          ),
        );
      }
    }

    return seats;
  }
}
