import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/transcript_repository.dart';
import 'package:cityzens_app/presentation/gpa_calculator/gpa_calculator_provider.dart';

import '../helpers/test_database.dart';

void main() {
  group('GpaCalculatorProvider & TranscriptRepository Tests', () {
    late GpaCalculatorProvider provider;
    late TranscriptRepository repository;

    setUp(() async {
      final db = await createTestDatabase();
      repository = TranscriptRepository(database: db);
      provider = GpaCalculatorProvider(repository: repository);
      await provider.loadTranscripts();
    });

    test(
      'Initializes with 7 historical semesters and computes prior 3.94 CGPA',
      () {
        expect(provider.transcripts.length, equals(7));
        expect(provider.priorCredits, equals(118));
        expect(provider.priorCgpa, equals(3.94));
      },
    );

    test('All A simulation yields 4.00 semester GPA and elevates projected CGPA to 3.95', () {
      expect(provider.simulatedCourses.length, equals(5));
      expect(provider.simulatedCredits, equals(18));
      expect(provider.simulatedSemesterGpa, equals(4.00));
      expect(provider.projectedTotalCredits, equals(136));
      expect(provider.projectedCgpa, equals(3.95));
      expect(provider.honorsClassification, contains('Summa Cum Laude'));
    });

    test('Toggling expected grades reactively recalculates projected CGPA and honors', () {
      // Change CS-401 (4 cr) from A (4.0) to B (3.0)
      provider.updateCourseGrade('sim_cs401', 'B');
      expect(provider.simulatedSemesterGpa, equals(3.78));
      expect(provider.projectedCgpa, equals(3.92));

      // Change CS-405 (4 cr) to C (2.0)
      provider.updateCourseGrade('sim_cs405', 'C');
      expect(provider.simulatedSemesterGpa, equals(3.33));
      expect(provider.projectedCgpa, equals(3.86));
      expect(provider.honorsClassification, contains('Magna Cum Laude'));
    });

    test('addCustomCourse increments term credits and quality points', () {
      final initialCredits = provider.simulatedCredits;

      provider.addCustomCourse(
        courseCode: 'CS-499',
        title: 'Senior Capstone Research',
        credits: 4,
        grade: 'A',
      );

      expect(provider.simulatedCredits, equals(initialCredits + 4));
      expect(provider.simulatedCourses.length, equals(6));
    });

    test('removeCourse removes simulated course and recalculates', () {
      provider.removeCourse('sim_sec430');
      expect(provider.simulatedCourses.length, equals(4));
      expect(provider.simulatedCredits, equals(15));
    });

    test('commitSemesterToTranscript persists record in SQLite and advances semester count', () async {
      expect(provider.transcripts.length, equals(7));

      final success = await provider.commitSemesterToTranscript(
        semesterName: 'Semester 8 (Spring 2027 - Final)',
      );

      expect(success, isTrue);
      expect(provider.transcripts.length, equals(8));
      expect(provider.transcripts.last.semesterName, contains('Semester 8'));
      expect(provider.priorCredits, equals(136));
      expect(provider.priorCgpa, equals(3.95));
    });
  });
}
