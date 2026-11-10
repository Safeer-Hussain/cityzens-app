import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/book.dart';
import '../models/book_loan.dart';

class LibraryLoanItem {
  final BookLoanModel loan;
  final BookModel book;

  const LibraryLoanItem({required this.loan, required this.book});
}

class LibraryRepository {
  final AppDatabase database;

  LibraryRepository({required this.database});

  Database get _db => database.db;

  Future<List<BookModel>> getBooks({String? query, String? category}) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (category != null &&
        category.isNotEmpty &&
        category != 'All' &&
        category != 'Available Now' &&
        category != 'Reserved') {
      whereClause = 'category = ?';
      whereArgs.add(category);
    } else if (category == 'Available Now') {
      whereClause = 'available_copies > 0';
    } else if (category == 'Reserved') {
      whereClause = 'is_reserved = 1';
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitizedQuery = '%${query.trim()}%';
      if (whereClause.isNotEmpty) {
        whereClause += ' AND (title LIKE ? OR author LIKE ? OR isbn LIKE ?)';
      } else {
        whereClause = '(title LIKE ? OR author LIKE ? OR isbn LIKE ?)';
      }
      whereArgs.addAll([sanitizedQuery, sanitizedQuery, sanitizedQuery]);
    }

    final results = await _db.query(
      'library_books',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'title ASC',
    );

    return results.map((m) => BookModel.fromMap(m)).toList();
  }

  Future<BookModel?> getBookById(String id) async {
    final results = await _db.query(
      'library_books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return BookModel.fromMap(results.first);
  }

  Future<BookModel?> getBookByIsbn(String isbn) async {
    final results = await _db.query(
      'library_books',
      where: 'isbn = ?',
      whereArgs: [isbn],
    );
    if (results.isEmpty) return null;
    return BookModel.fromMap(results.first);
  }

  Future<List<LibraryLoanItem>> getActiveLoans() async {
    final loansRaw = await _db.query(
      'library_loans',
      where: 'is_returned = 0',
      orderBy: 'due_date ASC',
    );

    final List<LibraryLoanItem> items = [];
    for (final map in loansRaw) {
      final loan = BookLoanModel.fromMap(map);
      final book = await getBookById(loan.bookId);
      if (book != null) {
        items.add(LibraryLoanItem(loan: loan, book: book));
      }
    }
    return items;
  }

  Future<BookLoanModel> renewLoan(String loanId) async {
    final results = await _db.query(
      'library_loans',
      where: 'id = ?',
      whereArgs: [loanId],
    );

    if (results.isEmpty) {
      throw Exception('Loan record not found for id: $loanId');
    }

    final current = BookLoanModel.fromMap(results.first);
    final extendedDueDate = DateTime.fromMillisecondsSinceEpoch(current.dueDate)
        .add(const Duration(days: 14))
        .millisecondsSinceEpoch;

    final updated = current.copyWith(
      dueDate: extendedDueDate,
      renewalCount: current.renewalCount + 1,
      overdueFine: 0.0,
    );

    await _db.update(
      'library_loans',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [loanId],
    );

    return updated;
  }

  Future<void> returnBook(String loanId, String bookId) async {
    await _db.transaction((txn) async {
      await txn.update(
        'library_loans',
        {'is_returned': 1},
        where: 'id = ?',
        whereArgs: [loanId],
      );

      final bookRaw = await txn.query(
        'library_books',
        where: 'id = ?',
        whereArgs: [bookId],
      );

      if (bookRaw.isNotEmpty) {
        final currentAvail = (bookRaw.first['available_copies'] as num).toInt();
        await txn.update(
          'library_books',
          {'available_copies': currentAvail + 1},
          where: 'id = ?',
          whereArgs: [bookId],
        );
      }
    });
  }

  Future<BookModel> toggleReserveBook(String bookId) async {
    final book = await getBookById(bookId);
    if (book == null) throw Exception('Book not found: $bookId');

    final updated = book.copyWith(isReserved: !book.isReserved);
    await _db.update(
      'library_books',
      {'is_reserved': updated.isReserved ? 1 : 0},
      where: 'id = ?',
      whereArgs: [bookId],
    );

    return updated;
  }

  Future<void> checkoutBook({
    required String bookId,
    required String borrowerId,
  }) async {
    final book = await getBookById(bookId);
    if (book == null || book.availableCopies <= 0) {
      throw Exception('Book is currently unavailable for checkout.');
    }

    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 14)).millisecondsSinceEpoch;
    final loanId = 'loan_${now.microsecondsSinceEpoch}';

    await _db.transaction((txn) async {
      await txn.insert('library_loans', {
        'id': loanId,
        'book_id': bookId,
        'borrower_id': borrowerId,
        'borrow_date': now.millisecondsSinceEpoch,
        'due_date': dueDate,
        'is_returned': 0,
        'renewal_count': 0,
        'overdue_fine': 0.0,
      });

      await txn.update(
        'library_books',
        {'available_copies': book.availableCopies - 1},
        where: 'id = ?',
        whereArgs: [bookId],
      );
    });
  }
}
