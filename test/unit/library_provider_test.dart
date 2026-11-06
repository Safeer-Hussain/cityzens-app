import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/library_repository.dart';
import 'package:cityzens_app/presentation/library/library_provider.dart';
import '../helpers/test_database.dart';

void main() {
  group('LibraryProvider & Repository Tests', () {
    late LibraryProvider provider;
    late LibraryRepository repository;

    setUp(() async {
      final db = await createTestDatabase();
      repository = LibraryRepository(database: db);
      provider = LibraryProvider(repository: repository);
      await provider.loadLibraryData();
    });

    test('Initializes with catalog books and active loans from SQLite', () {
      expect(provider.books.isNotEmpty, isTrue);
      expect(provider.books.first.title, contains('Clean Architecture'));
      expect(provider.activeLoans.length, equals(1));
      expect(provider.borrowedCount, equals(1));
    });

    test('1-Tap renewLoan extends dueDate by 14 days and increments renewal count', () async {
      final loanId = provider.activeLoans.first.loan.id;
      final initialDueDate = provider.activeLoans.first.loan.dueDate;

      final success = await provider.renewLoan(loanId);
      expect(success, isTrue);

      final updated = provider.activeLoans.first.loan;
      expect(updated.renewalCount, equals(1));
      final expectedDate = DateTime.fromMillisecondsSinceEpoch(initialDueDate)
          .add(const Duration(days: 14))
          .millisecondsSinceEpoch;
      expect(updated.dueDate, equals(expectedDate));
    });

    test('toggleReserve immediately updates isReserved status via copyWith', () async {
      final bookId = provider.books.first.id;
      expect(provider.books.first.isReserved, isFalse);

      final success = await provider.toggleReserve(bookId);
      expect(success, isTrue);
      expect(provider.books.first.isReserved, isTrue);

      // Toggle back
      await provider.toggleReserve(bookId);
      expect(provider.books.first.isReserved, isFalse);
    });

    test('checkoutBook decreases available copies and creates active loan', () async {
      final bookId = provider.books.first.id;
      final initialAvailable = provider.books.first.availableCopies;

      final success = await provider.checkoutBook(bookId, 'CTZ-2026-8842');
      expect(success, isTrue);

      final updatedBook = provider.books.firstWhere((b) => b.id == bookId);
      expect(updatedBook.availableCopies, equals(initialAvailable - 1));
      expect(provider.activeLoans.length, equals(2));
    });

    test('returnBook marks loan as returned and restores available copy count', () async {
      final item = provider.activeLoans.first;
      final initialAvailable = provider.books.first.availableCopies;

      final success = await provider.returnBook(item.loan.id, item.book.id);
      expect(success, isTrue);
      expect(provider.activeLoans.isEmpty, isTrue);
      expect(provider.books.first.availableCopies, equals(initialAvailable + 1));
    });
  });
}
