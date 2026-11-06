import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/attendance_repository.dart';
import 'package:cityzens_app/data/repositories/library_repository.dart';
import 'package:cityzens_app/presentation/ai_tutor/ai_tutor_provider.dart';
import '../helpers/test_database.dart';

void main() {
  group('AiTutorProvider Tests', () {
    late AiTutorProvider provider;
    late AttendanceRepository attendanceRepo;
    late LibraryRepository libraryRepo;

    setUp(() async {
      final db = await createTestDatabase();
      attendanceRepo = AttendanceRepository(database: db);
      libraryRepo = LibraryRepository(database: db);
      provider = AiTutorProvider(
        attendanceRepository: attendanceRepo,
        libraryRepository: libraryRepo,
      );
    });

    test('Initializes with default academic companion welcome message', () {
      expect(provider.messages.length, equals(1));
      expect(provider.messages.first.isUser, isFalse);
      expect(provider.messages.first.text, contains('Cityzens AI Academic Companion'));
      expect(provider.isStreaming, isFalse);
    });

    test('sendPrompt strictly resets isStreaming to false on completion via finally block', () async {
      expect(provider.isStreaming, isFalse);

      final future = provider.sendPrompt('Check My Attendance Risk & Required Classes');
      // Wait for completion
      await future;

      // Crucial requirement: isStreaming must be false
      expect(provider.isStreaming, isFalse);
      expect(provider.transientStatus, isNull);
      expect(provider.messages.length, equals(3)); // welcome + user + ai response
      final aiResponse = provider.messages.last;
      expect(aiResponse.isUser, isFalse);
      expect(aiResponse.text, contains('CS-401'));
      expect(aiResponse.text, contains('Good Standing'));
    });

    test('Synthesizes borrowed library books contextually', () async {
      await provider.sendPrompt('Summarize My Borrowed Library Books');
      expect(provider.isStreaming, isFalse);
      final aiResponse = provider.messages.last;
      expect(aiResponse.text, contains('Clean Architecture'));
    });

    test('clearChat resets conversation to initial state', () async {
      await provider.sendPrompt('Draft Faculty Project Proposal');
      expect(provider.messages.length, equals(3));

      provider.clearChat();
      expect(provider.messages.length, equals(1));
      expect(provider.messages.first.id, equals('msg_welcome'));
    });
  });
}
