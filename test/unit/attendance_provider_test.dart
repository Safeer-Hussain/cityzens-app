import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/attendance_repository.dart';
import 'package:cityzens_app/presentation/attendance/attendance_provider.dart';
import '../helpers/test_database.dart';

void main() {
  group('AttendanceProvider & Repository Tests', () {
    late AttendanceProvider provider;
    late AttendanceRepository repository;

    setUp(() async {
      final db = await createTestDatabase();
      repository = AttendanceRepository(database: db);
      provider = AttendanceProvider(repository: repository);
      await provider.loadAttendanceData();
    });

    test('Loads enrolled courses and computes overall percentage', () {
      expect(provider.courses.isNotEmpty, isTrue);
      final course = provider.courses.first;
      expect(course.code, equals('CS-401'));
      expect(course.presentCount, equals(20));
      expect(course.totalClasses, equals(22));
      // 20 / 22 = 90.9%
      expect(course.attendancePercentage, equals(90.9));
      expect(provider.overallAttendancePercentage, equals(90.9));
    });

    test('checkInWithQr increments present count and updates course percentage', () async {
      final courseCode = provider.courses.first.code;
      final initialPresent = provider.courses.first.presentCount;
      final initialTotal = provider.courses.first.totalClasses;

      final success = await provider.checkInWithQr(
        courseCode: courseCode,
        qrPayload: 'LEC-CS801-4921 Turing Hall 302',
      );

      expect(success, isTrue);
      final updated = provider.courses.firstWhere((c) => c.code == courseCode);
      expect(updated.presentCount, equals(initialPresent + 1));
      expect(updated.totalClasses, equals(initialTotal + 1));
      // 21 / 23 = 91.3%
      expect(updated.attendancePercentage, equals(91.3));
    });

    test('submitLeaveRequest records sanctioned absence in SQLite ledger', () async {
      final courseCode = provider.courses.first.code;
      final initialExcused = provider.courses.first.excusedCount;

      final success = await provider.submitLeaveRequest(
        courseCode: courseCode,
        reason: 'Medical consultation at University Health Center',
        date: DateTime.now(),
      );

      expect(success, isTrue);
      final updated = provider.courses.firstWhere((c) => c.code == courseCode);
      expect(updated.excusedCount, equals(initialExcused + 1));
    });

    test('toggleRoleMode switches between Student Mode and Faculty Mode', () {
      expect(provider.isStudentMode, isTrue);
      provider.toggleRoleMode();
      expect(provider.isStudentMode, isFalse);
      provider.toggleRoleMode();
      expect(provider.isStudentMode, isTrue);
    });

    test('calculateClassesNeeded correctly projects minimum required lectures', () {
      final course = provider.courses.first;
      // Already 90.9% > 75%, so 0 needed
      expect(course.calculateClassesNeeded(75.0), equals(0));

      // With lower present count (e.g. 10 present, 20 total = 50%)
      final atRiskCourse = course.copyWith(presentCount: 10, totalClasses: 20);
      expect(atRiskCourse.isAtRisk, isTrue);
      // To reach 75%: (0.75 * 20 - 10) / (1 - 0.75) = 5 / 0.25 = 20 classes
      expect(atRiskCourse.calculateClassesNeeded(75.0), equals(20));
    });
  });
}
