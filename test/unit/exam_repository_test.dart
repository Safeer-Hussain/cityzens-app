import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/core/utils/exam_cryptography.dart';
import 'package:cityzens_app/data/models/exam_hall_pass.dart';
import 'package:cityzens_app/data/repositories/exam_repository.dart';
import 'package:cityzens_app/presentation/exam/exam_provider.dart';
import '../helpers/test_database.dart';

void main() {
  group('ExamCryptography & SHA-256 Tests', () {
    test('generateChecksum produces deterministic 64-character SHA-256 hex digest', () {
      final checksum1 = ExamCryptography.generateChecksum(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        hallName: 'Turing Hall',
        deskNumber: 'TH-C14',
        examTimestamp: 1795000000,
      );

      final checksum2 = ExamCryptography.generateChecksum(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        hallName: 'Turing Hall',
        deskNumber: 'TH-C14',
        examTimestamp: 1795000000,
      );

      expect(checksum1.length, equals(64));
      expect(checksum1, equals(checksum2));
    });

    test('verifyChecksum correctly validates authentic payload', () {
      final checksum = ExamCryptography.generateChecksum(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        hallName: 'Turing Hall',
        deskNumber: 'TH-C14',
        examTimestamp: 1795000000,
      );

      final isValid = ExamCryptography.verifyChecksum(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        hallName: 'Turing Hall',
        deskNumber: 'TH-C14',
        examTimestamp: 1795000000,
        expectedChecksum: checksum,
      );

      expect(isValid, isTrue);
    });

    test('verifyChecksum rejects tampered desk number or timestamp', () {
      final authenticChecksum = ExamCryptography.generateChecksum(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        hallName: 'Turing Hall',
        deskNumber: 'TH-C14',
        examTimestamp: 1795000000,
      );

      final isTampered = ExamCryptography.verifyChecksum(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        hallName: 'Turing Hall',
        deskNumber: 'TH-C99', // Tampered desk!
        examTimestamp: 1795000000,
        expectedChecksum: authenticChecksum,
      );

      expect(isTampered, isFalse);
    });

    test('generateOpticalPayload creates standard Cityzens token format', () {
      final token = ExamCryptography.generateOpticalPayload(
        passId: 'exam_pass_001',
        studentId: 'CTZ-2024-8842',
        courseCode: 'CS-401',
        deskNumber: 'TH-C14',
        checksum: '7f8a9b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a',
      );

      expect(token.startsWith('CITYZENS:EXAM:'), isTrue);
      expect(token.contains('CS-401'), isTrue);
      expect(token.contains('TH-C14'), isTrue);
    });

    test('formatChecksumBlocks formats into 4-character spaced blocks', () {
      const hash = '7f8a9b2c';
      final formatted = ExamCryptography.formatChecksumBlocks(hash);
      expect(formatted, equals('7F8A 9B2C'));
    });
  });

  group('ExamRepository & SQLite Persistence Tests', () {
    late ExamRepository repository;

    setUp(() async {
      final db = await createTestDatabase();
      repository = ExamRepository(database: db);
    });

    test('getAllPasses loads 4 seeded passes sorted chronologically', () async {
      final passes = await repository.getAllPasses();
      expect(passes.length, equals(4));
      expect(passes[0].courseCode, equals('CS-401'));
      expect(passes[1].courseCode, equals('CS-420'));
      expect(passes[2].courseCode, equals('SE-450'));
      expect(passes[3].courseCode, equals('CS-490'));
    });

    test('toggleReminder updates SQLite is_reminder_set field', () async {
      final passes = await repository.getAllPasses();
      final initialArmed = passes.first.isReminderSet;

      final success = await repository.toggleReminder(passes.first.id, !initialArmed);
      expect(success, isTrue);

      final updated = await repository.getPassById(passes.first.id);
      expect(updated?.isReminderSet, equals(!initialArmed));
    });

    test('setPassVerified updates verification status in database', () async {
      const passId = 'exam_pass_002';
      final before = await repository.getPassById(passId);
      expect(before?.isVerified, isFalse);

      final success = await repository.setPassVerified(passId, true);
      expect(success, isTrue);

      final after = await repository.getPassById(passId);
      expect(after?.isVerified, isTrue);
    });

    test('verifyPassTampering confirms integrity of seeded pass record', () async {
      const passId = 'exam_pass_001';
      final isValid = await repository.verifyPassTampering(passId);
      expect(isValid, isTrue);
    });

    test('generateHallMatrix accurately identifies user assigned desk', () {
      final pass = ExamHallPassModel(
        id: 'test_pass',
        studentId: 'CTZ-2024-8842',
        studentName: 'Safeer Hussain',
        courseCode: 'CS-401',
        courseTitle: 'Advanced Distributed Systems',
        examType: 'Final',
        examDate: DateTime(2026, 11, 18),
        durationMinutes: 180,
        hallName: 'Turing Hall',
        seatRow: 'C',
        seatNumber: 14,
        deskNumber: 'TH-C14',
        opticalToken: 'token',
        cryptographicChecksum: 'checksum',
        invigilatorName: 'Dr. Vance',
        instructions: const [],
      );

      final matrix = repository.generateHallMatrix(ExamHall.turingHall, pass);
      expect(matrix.length, equals(ExamHall.turingHall.totalCapacity));

      final userSeat = matrix.firstWhere((s) => s.isUserSeat);
      expect(userSeat.row, equals('C'));
      expect(userSeat.number, equals(14));
      expect(userSeat.status, equals(SeatStatus.assignedToUser));
      expect(userSeat.assignedCandidateMasked, contains('YOU'));
    });
  });

  group('ExamProvider State Management Tests', () {
    late ExamRepository repository;
    late ExamProvider provider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = ExamRepository(database: db);
      provider = ExamProvider(repository: repository);
      await provider.loadPasses();
    });

    test('Initial state loads all passes and sets default selected pass', () {
      expect(provider.totalPasses, equals(4));
      expect(provider.selectedPass?.courseCode, equals('CS-401'));
      expect(provider.selectedHall.name, equals('Turing Hall'));
      expect(provider.userAssignedSeat?.deskCode, equals('C14'));
    });

    test('selectPass switches selected pass and synchronizes hall', () {
      final hopperPass = provider.passes.firstWhere((p) => p.hallName.contains('Hopper'));
      provider.selectPass(hopperPass);

      expect(provider.selectedPass?.id, equals(hopperPass.id));
      expect(provider.selectedHall.name, equals('Hopper Auditorium'));
    });

    test('togglePassReminder optimistically updates state and persists', () async {
      final initialArmed = provider.passes.first.isReminderSet;
      final ok = await provider.togglePassReminder(provider.passes.first.id);

      expect(ok, isTrue);
      expect(provider.passes.first.isReminderSet, equals(!initialArmed));
      expect(provider.selectedPass?.isReminderSet, equals(!initialArmed));
    });

    test('verifyCurrentPass performs SHA-256 verification and marks verified', () async {
      final passToVerify = provider.passes.firstWhere((p) => !p.isVerified);
      provider.selectPass(passToVerify);

      final ok = await provider.verifyCurrentPass();
      expect(ok, isTrue);
      expect(provider.selectedPass?.isVerified, isTrue);
      expect(provider.lastVerificationSuccess, isTrue);
      expect(provider.lastVerificationMessage, contains('authenticated'));
    });
  });
}
