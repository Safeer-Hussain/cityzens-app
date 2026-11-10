import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/course_attendance.dart';
import '../models/attendance_record.dart';

class AttendanceRepository {
  final AppDatabase database;

  AttendanceRepository({required this.database});

  Database get _db => database.db;

  Future<List<CourseModel>> getCourses() async {
    final results = await _db.query('courses', orderBy: 'code ASC');
    return results.map((m) => CourseModel.fromMap(m)).toList();
  }

  Future<List<AttendanceRecord>> getLedger() async {
    final results = await _db.query(
      'attendance_ledger',
      orderBy: 'timestamp DESC',
    );
    return results.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<CourseModel?> getCourseByCode(String code) async {
    final results = await _db.query(
      'courses',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (results.isEmpty) return null;
    return CourseModel.fromMap(results.first);
  }

  Future<bool> recordCheckIn({
    required String courseCode,
    required String method, // 'native_qr', 'manual_pin'
    required String verificationPayload,
  }) async {
    final course = await getCourseByCode(courseCode);
    if (course == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final recordId = 'att_${DateTime.now().microsecondsSinceEpoch}';

    await _db.transaction((txn) async {
      // 1. Insert attendance record
      await txn.insert('attendance_ledger', {
        'id': recordId,
        'course_id': course.id,
        'course_code': course.code,
        'timestamp': now,
        'status': 'present',
        'verification_method': method,
        'notes': 'Verified check-in via $method: $verificationPayload',
      });

      // 2. Increment present count and total count in course
      await txn.update(
        'courses',
        {
          'present_count': course.presentCount + 1,
          'total_classes': course.totalClasses + 1,
        },
        where: 'id = ?',
        whereArgs: [course.id],
      );
    });

    return true;
  }

  Future<bool> submitLeaveRequest({
    required String courseCode,
    required String reason,
    required DateTime date,
  }) async {
    final course = await getCourseByCode(courseCode);
    if (course == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final leaveId = 'lr_${DateTime.now().microsecondsSinceEpoch}';
    final recordId = 'att_${DateTime.now().microsecondsSinceEpoch}';

    await _db.transaction((txn) async {
      await txn.insert('leave_requests', {
        'id': leaveId,
        'course_code': courseCode,
        'reason': reason,
        'date': date.millisecondsSinceEpoch,
        'status': 'Approved',
      });

      await txn.insert('attendance_ledger', {
        'id': recordId,
        'course_id': course.id,
        'course_code': course.code,
        'timestamp': now,
        'status': 'excused',
        'verification_method': 'leave_request',
        'notes': 'Sanctioned leave request: $reason',
      });

      await txn.update(
        'courses',
        {
          'excused_count': course.excusedCount + 1,
          'total_classes': course.totalClasses + 1,
        },
        where: 'id = ?',
        whereArgs: [course.id],
      );
    });

    return true;
  }
}
