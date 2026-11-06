import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cityzens_app/core/database/app_database.dart';

Future<AppDatabase> createTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbName = 'cityzens_test_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}.db';

  final db = await openDatabase(
    dbName,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE courses (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL,
          title TEXT NOT NULL,
          instructor TEXT NOT NULL,
          room TEXT NOT NULL,
          schedule TEXT NOT NULL,
          present_count INTEGER NOT NULL DEFAULT 0,
          absent_count INTEGER NOT NULL DEFAULT 0,
          excused_count INTEGER NOT NULL DEFAULT 0,
          total_classes INTEGER NOT NULL DEFAULT 0,
          min_required_percentage REAL NOT NULL DEFAULT 75.0
        )
      ''');

      await db.execute('''
        CREATE TABLE attendance_ledger (
          id TEXT PRIMARY KEY,
          course_id TEXT NOT NULL,
          course_code TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          status TEXT NOT NULL,
          verification_method TEXT NOT NULL,
          notes TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE library_books (
          id TEXT PRIMARY KEY,
          isbn TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          category TEXT NOT NULL,
          shelf_location TEXT NOT NULL,
          total_copies INTEGER NOT NULL,
          available_copies INTEGER NOT NULL,
          is_reserved INTEGER NOT NULL DEFAULT 0,
          abstract TEXT NOT NULL,
          table_of_contents TEXT NOT NULL,
          cover_asset TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE library_loans (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          borrower_id TEXT NOT NULL,
          borrow_date INTEGER NOT NULL,
          due_date INTEGER NOT NULL,
          is_returned INTEGER NOT NULL DEFAULT 0,
          renewal_count INTEGER NOT NULL DEFAULT 0,
          overdue_fine REAL NOT NULL DEFAULT 0.0
        )
      ''');

      await db.execute('''
        CREATE TABLE campus_posts (
          id TEXT PRIMARY KEY,
          author_name TEXT NOT NULL,
          author_role TEXT NOT NULL,
          author_avatar TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          category TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          likes_count INTEGER NOT NULL DEFAULT 0,
          is_liked INTEGER NOT NULL DEFAULT 0,
          comments_count INTEGER NOT NULL DEFAULT 0,
          is_bookmarked INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE campus_comments (
          id TEXT PRIMARY KEY,
          post_id TEXT NOT NULL,
          author_name TEXT NOT NULL,
          author_role TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE leave_requests (
          id TEXT PRIMARY KEY,
          course_code TEXT NOT NULL,
          reason TEXT NOT NULL,
          date INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE academic_transcripts (
          id TEXT PRIMARY KEY,
          semester_name TEXT NOT NULL,
          credit_hours INTEGER NOT NULL,
          gpa REAL NOT NULL
        )
      ''');

      // Seed core test course
      await db.insert('courses', {
        'id': 'crs_01',
        'code': 'CS-401',
        'title': 'Distributed Systems & Cloud Computing',
        'instructor': 'Dr. Aris Thorne',
        'room': 'Alan Turing Hall 302',
        'schedule': 'Mon & Wed 09:00',
        'present_count': 20,
        'absent_count': 2,
        'excused_count': 0,
        'total_classes': 22,
        'min_required_percentage': 75.0,
      });

      // Seed test book
      await db.insert('library_books', {
        'id': 'book_01',
        'isbn': '978-0134494166',
        'title': "Clean Architecture: A Craftsman's Guide",
        'author': 'Robert C. Martin',
        'category': 'Software Engineering',
        'shelf_location': 'FLOOR-2 / AISLE-A',
        'total_copies': 5,
        'available_copies': 3,
        'is_reserved': 0,
        'abstract': 'Universal rules of software architecture.',
        'table_of_contents': '["Chapter 1", "Chapter 2"]',
        'cover_asset': 'assets/images/book_clean_architecture.png',
      });

      // Seed test loan (due in 5 days)
      final now = DateTime.now();
      await db.insert('library_loans', {
        'id': 'loan_01',
        'book_id': 'book_01',
        'borrower_id': 'CTZ-2026-8842',
        'borrow_date': now.subtract(const Duration(days: 9)).millisecondsSinceEpoch,
        'due_date': now.add(const Duration(days: 5)).millisecondsSinceEpoch,
        'is_returned': 0,
        'renewal_count': 0,
        'overdue_fine': 0.0,
      });

      // Seed test post
      await db.insert('campus_posts', {
        'id': 'post_01',
        'author_name': 'Dr. Aris Thorne',
        'author_role': 'Faculty',
        'author_avatar': 'AT',
        'title': 'Distributed Consensus Workshop',
        'content': 'Workshop on Raft consensus this Thursday.',
        'category': 'Faculty Announcement',
        'timestamp': now.millisecondsSinceEpoch,
        'likes_count': 10,
        'is_liked': 0,
        'comments_count': 0,
        'is_bookmarked': 0,
      });

      // Seed 7 Historical Semesters for Safeer Hussain (CGPA 3.94)
      final transcripts = [
        {'id': 'sem_01', 'semester_name': 'Semester 1 (Fall 2023)', 'credit_hours': 17, 'gpa': 3.92},
        {'id': 'sem_02', 'semester_name': 'Semester 2 (Spring 2024)', 'credit_hours': 18, 'gpa': 3.95},
        {'id': 'sem_03', 'semester_name': 'Semester 3 (Fall 2024)', 'credit_hours': 17, 'gpa': 3.90},
        {'id': 'sem_04', 'semester_name': 'Semester 4 (Spring 2025)', 'credit_hours': 18, 'gpa': 3.96},
        {'id': 'sem_05', 'semester_name': 'Semester 5 (Fall 2025)', 'credit_hours': 16, 'gpa': 3.94},
        {'id': 'sem_06', 'semester_name': 'Semester 6 (Spring 2026)', 'credit_hours': 16, 'gpa': 3.98},
        {'id': 'sem_07', 'semester_name': 'Semester 7 (Fall 2026)', 'credit_hours': 16, 'gpa': 3.92},
      ];
      for (final t in transcripts) {
        await db.insert('academic_transcripts', t);
      }
    },
  );

  return AppDatabase(db);
}
