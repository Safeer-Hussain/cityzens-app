import 'dart:convert';
import 'dart:math';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cityzens_app/core/database/app_database.dart';
import 'package:cityzens_app/core/utils/exam_cryptography.dart';

Future<AppDatabase> createTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbName =
      'cityzens_test_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}.db';

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

      await db.execute('''
        CREATE TABLE exam_hall_passes (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          student_name TEXT NOT NULL,
          course_code TEXT NOT NULL,
          course_title TEXT NOT NULL,
          exam_type TEXT NOT NULL,
          exam_date INTEGER NOT NULL,
          duration_minutes INTEGER NOT NULL,
          hall_name TEXT NOT NULL,
          seat_row TEXT NOT NULL,
          seat_number INTEGER NOT NULL,
          desk_number TEXT NOT NULL,
          optical_token TEXT NOT NULL,
          cryptographic_checksum TEXT NOT NULL,
          is_verified INTEGER NOT NULL DEFAULT 0,
          is_reminder_set INTEGER NOT NULL DEFAULT 0,
          reminder_lead_minutes INTEGER NOT NULL DEFAULT 60,
          invigilator_name TEXT NOT NULL,
          instructions TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE study_rooms (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          floor INTEGER NOT NULL,
          capacity INTEGER NOT NULL,
          amenities TEXT NOT NULL,
          is_available INTEGER NOT NULL DEFAULT 1,
          photo_asset TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE study_room_bookings (
          id TEXT PRIMARY KEY,
          room_id TEXT NOT NULL,
          room_name TEXT NOT NULL,
          floor INTEGER NOT NULL,
          booked_by_id TEXT NOT NULL,
          booked_by_name TEXT NOT NULL,
          purpose TEXT NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER NOT NULL,
          attendees TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE flashcard_decks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT NOT NULL,
          card_count INTEGER NOT NULL DEFAULT 0,
          mastery_percentage REAL NOT NULL DEFAULT 0.0,
          color_hex TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE flashcards (
          id TEXT PRIMARY KEY,
          deck_id TEXT NOT NULL,
          front TEXT NOT NULL,
          back TEXT NOT NULL,
          hint TEXT NOT NULL,
          repetitions INTEGER NOT NULL DEFAULT 0,
          interval_days INTEGER NOT NULL DEFAULT 1,
          ease_factor REAL NOT NULL DEFAULT 2.5,
          next_review_date INTEGER NOT NULL,
          last_reviewed_date INTEGER,
          mastery_level TEXT NOT NULL DEFAULT 'learning',
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE flashcard_reviews (
          id TEXT PRIMARY KEY,
          card_id TEXT NOT NULL,
          deck_id TEXT NOT NULL,
          quality INTEGER NOT NULL,
          interval_days INTEGER NOT NULL,
          ease_factor REAL NOT NULL,
          reviewed_at INTEGER NOT NULL
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
        'borrow_date': now
            .subtract(const Duration(days: 9))
            .millisecondsSinceEpoch,
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
        {
          'id': 'sem_01',
          'semester_name': 'Semester 1 (Fall 2023)',
          'credit_hours': 17,
          'gpa': 3.92,
        },
        {
          'id': 'sem_02',
          'semester_name': 'Semester 2 (Spring 2024)',
          'credit_hours': 18,
          'gpa': 3.95,
        },
        {
          'id': 'sem_03',
          'semester_name': 'Semester 3 (Fall 2024)',
          'credit_hours': 17,
          'gpa': 3.90,
        },
        {
          'id': 'sem_04',
          'semester_name': 'Semester 4 (Spring 2025)',
          'credit_hours': 18,
          'gpa': 3.96,
        },
        {
          'id': 'sem_05',
          'semester_name': 'Semester 5 (Fall 2025)',
          'credit_hours': 16,
          'gpa': 3.94,
        },
        {
          'id': 'sem_06',
          'semester_name': 'Semester 6 (Spring 2026)',
          'credit_hours': 16,
          'gpa': 3.98,
        },
        {
          'id': 'sem_07',
          'semester_name': 'Semester 7 (Fall 2026)',
          'credit_hours': 16,
          'gpa': 3.92,
        },
      ];
      for (final t in transcripts) {
        await db.insert('academic_transcripts', t);
      }

      // Seed 4 Exam Passes
      const studentId = 'CTZ-2024-8842';
      const studentName = 'Safeer Hussain';
      final passes = [
        {
          'id': 'exam_pass_001',
          'student_id': studentId,
          'student_name': studentName,
          'course_code': 'CS-401',
          'course_title': 'Advanced Distributed Systems',
          'exam_type': 'Final Comprehensive Examination',
          'exam_date': DateTime(2026, 11, 18, 9, 0).millisecondsSinceEpoch,
          'duration_minutes': 180,
          'hall_name': 'Turing Hall',
          'seat_row': 'C',
          'seat_number': 14,
          'desk_number': 'TH-C14',
          'is_verified': 1,
          'is_reminder_set': 1,
          'reminder_lead_minutes': 60,
          'invigilator_name': 'Dr. Alan Vance',
          'instructions': jsonEncode([
            'Candidate must present official physical student ID card along with optical admission pass.',
            'No programmable calculators, cellular devices, or wearable electronics allowed at candidate desk.',
            'Candidates must occupy assigned desk TH-C14 at least 15 minutes before exam commencement.',
          ]),
        },
        {
          'id': 'exam_pass_002',
          'student_id': studentId,
          'student_name': studentName,
          'course_code': 'CS-420',
          'course_title': 'Applied Machine Learning & Neural Systems',
          'exam_type': 'Midterm Laboratory Evaluation',
          'exam_date': DateTime(2026, 11, 20, 14, 0).millisecondsSinceEpoch,
          'duration_minutes': 120,
          'hall_name': 'Hopper Auditorium',
          'seat_row': 'E',
          'seat_number': 8,
          'desk_number': 'HA-E08',
          'is_verified': 0,
          'is_reminder_set': 0,
          'reminder_lead_minutes': 60,
          'invigilator_name': 'Prof. Margaret Hamilton',
          'instructions': jsonEncode([
            'Laboratory terminals are pre-configured in strict sandboxed mode with zero internet routing.',
            'All model checkpoints and code solutions must be committed to the offline university repository before time expires.',
            'Maintain complete silence and raise hand for proctor assistance.',
          ]),
        },
        {
          'id': 'exam_pass_003',
          'student_id': studentId,
          'student_name': studentName,
          'course_code': 'SE-450',
          'course_title': 'Autonomous Mobile Architectures',
          'exam_type': 'Final Theory Examination',
          'exam_date': DateTime(2026, 11, 23, 9, 0).millisecondsSinceEpoch,
          'duration_minutes': 180,
          'hall_name': 'Turing Hall',
          'seat_row': 'B',
          'seat_number': 6,
          'desk_number': 'TH-B06',
          'is_verified': 1,
          'is_reminder_set': 1,
          'reminder_lead_minutes': 120,
          'invigilator_name': 'Dr. Barbara Liskov',
          'instructions': jsonEncode([
            'Closed-book examination covering concurrency models, state isolation, and native platform channels.',
            'Clear plastic pencil cases only; unauthorized paper notes will result in immediate disqualification.',
            'Exit from examination hall permitted only after first 60 minutes of session.',
          ]),
        },
        {
          'id': 'exam_pass_004',
          'student_id': studentId,
          'student_name': studentName,
          'course_code': 'CS-490',
          'course_title': 'Senior Capstone Defense & Cloud Systems',
          'exam_type': 'Oral Defense & System Validation',
          'exam_date': DateTime(2026, 11, 26, 11, 30).millisecondsSinceEpoch,
          'duration_minutes': 90,
          'hall_name': 'Hopper Auditorium',
          'seat_row': 'A',
          'seat_number': 4,
          'desk_number': 'HA-A04',
          'is_verified': 0,
          'is_reminder_set': 0,
          'reminder_lead_minutes': 60,
          'invigilator_name': 'Prof. Donald Knuth',
          'instructions': jsonEncode([
            'Presentation slides and architectural proof-of-concept system demonstration to evaluation jury.',
            'Q&A defense session follows immediately after the 30-minute system walkthrough.',
            'Formal academic dress code required for all graduating senior candidates.',
          ]),
        },
      ];

      for (final pass in passes) {
        final checksum = ExamCryptography.generateChecksum(
          passId: pass['id'] as String,
          studentId: pass['student_id'] as String,
          courseCode: pass['course_code'] as String,
          hallName: pass['hall_name'] as String,
          deskNumber: pass['desk_number'] as String,
          examTimestamp: pass['exam_date'] as int,
        );

        final opticalToken = ExamCryptography.generateOpticalPayload(
          passId: pass['id'] as String,
          studentId: pass['student_id'] as String,
          courseCode: pass['course_code'] as String,
          deskNumber: pass['desk_number'] as String,
          checksum: checksum,
        );

        await db.insert('exam_hall_passes', {
          ...pass,
          'optical_token': opticalToken,
          'cryptographic_checksum': checksum,
        });
      }

      // Seed Study Rooms
      final rooms = [
        {
          'id': 'sr_101',
          'name': 'Turing Innovation Pod 101',
          'floor': 1,
          'capacity': 4,
          'amenities': jsonEncode([
            '4K Presentation Display',
            'Whiteboard Wall',
            'Type-C Fast Charging',
          ]),
          'is_available': 1,
          'photo_asset': 'assets/images/study_room_turing.png',
        },
        {
          'id': 'sr_102',
          'name': 'Lovelace Brainstorm Suite 102',
          'floor': 1,
          'capacity': 8,
          'amenities': jsonEncode([
            'Interactive Smartboard',
            'Video Conference Rig',
            'Acoustic Baffles',
            'Whiteboard Wall',
          ]),
          'is_available': 1,
          'photo_asset': 'assets/images/study_room_lovelace.png',
        },
        {
          'id': 'sr_201',
          'name': 'Dijkstra Algorithm Pod 201',
          'floor': 2,
          'capacity': 4,
          'amenities': jsonEncode([
            'Whiteboard Wall',
            '4K Presentation Display',
            'Ergonomic Chairs',
          ]),
          'is_available': 1,
          'photo_asset': 'assets/images/study_room_dijkstra.png',
        },
        {
          'id': 'sr_301',
          'name': 'Lamport Consensus Hub 301',
          'floor': 3,
          'capacity': 6,
          'amenities': jsonEncode([
            'Whiteboard Wall',
            'Ultra-wide Presentation Monitor',
            'Type-C Fast Charging',
          ]),
          'is_available': 1,
          'photo_asset': 'assets/images/study_room_lamport.png',
        },
        {
          'id': 'sr_401',
          'name': 'Chomsky Linguistics Alcove 401',
          'floor': 4,
          'capacity': 4,
          'amenities': jsonEncode([
            'Acoustic Quiet Pod',
            'Whiteboard Wall',
            'Ergonomic Recliners',
          ]),
          'is_available': 1,
          'photo_asset': 'assets/images/study_room_chomsky.png',
        },
      ];

      for (final r in rooms) {
        await db.insert('study_rooms', r);
      }

      // Seed Initial Booking
      await db.insert('study_room_bookings', {
        'id': 'sr_book_init_01',
        'room_id': 'sr_201',
        'room_name': 'Dijkstra Algorithm Pod 201',
        'floor': 2,
        'booked_by_id': 'CTZ-2026-8842',
        'booked_by_name': 'Safeer Hussain',
        'purpose': 'Distributed Systems & Raft Consensus Study',
        'start_time': now.add(const Duration(hours: 2)).millisecondsSinceEpoch,
        'end_time': now.add(const Duration(hours: 4)).millisecondsSinceEpoch,
        'attendees': jsonEncode([
          'safeer@cityzens.edu',
          'aris.thorne@cityzens.edu',
        ]),
        'created_at': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'status': 'confirmed',
      });

      // Seed Flashcard Decks
      final decks = [
        {
          'id': 'deck_algo',
          'title': 'Algorithms & Complexity',
          'category': 'Algorithms',
          'description': 'Asymptotic notations, graph traversals, dynamic programming, and amortized complexity.',
          'card_count': 4,
          'mastery_percentage': 75.0,
          'color_hex': '0xFF0D9488',
          'created_at': now
              .subtract(const Duration(days: 14))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'deck_dist',
          'title': 'Distributed Systems & Consensus',
          'category': 'Distributed Systems',
          'description': 'CAP theorem, Raft consensus, vector clocks, byzantine faults, and two-phase commits.',
          'card_count': 4,
          'mastery_percentage': 50.0,
          'color_hex': '0xFFD97706',
          'created_at': now
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'deck_mobile',
          'title': 'Mobile System Architecture',
          'category': 'Mobile Architecture',
          'description': 'Impeller rendering pipeline, VSync 120Hz frame scheduling, and Dart generational GC.',
          'card_count': 4,
          'mastery_percentage': 50.0,
          'color_hex': '0xFF2563EB',
          'created_at': now
              .subtract(const Duration(days: 7))
              .millisecondsSinceEpoch,
        },
      ];

      for (final d in decks) {
        await db.insert('flashcard_decks', d);
      }

      // Seed Flashcards
      final cards = [
        {
          'id': 'fc_algo_01',
          'deck_id': 'deck_algo',
          'front': 'What is the amortized time complexity of inserting into a dynamic array that doubles its capacity when full?',
          'back': 'O(1) amortized. Resizing costs O(N) but occurs only once every N insertions, so total work across N insertions is O(N).',
          'hint': 'Consider aggregate work across N append operations.',
          'repetitions': 3,
          'interval_days': 15,
          'ease_factor': 2.6,
          'next_review_date': now
              .add(const Duration(days: 8))
              .millisecondsSinceEpoch,
          'last_reviewed_date': now
              .subtract(const Duration(days: 7))
              .millisecondsSinceEpoch,
          'mastery_level': 'mastered',
          'created_at': now
              .subtract(const Duration(days: 14))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'fc_algo_02',
          'deck_id': 'deck_algo',
          'front': 'What is the time complexity difference between Dijkstra algorithm with binary heap vs Fibonacci heap?',
          'back': 'Binary heap: O((V + E) log V). Fibonacci heap: O(E + V log V), since decrease-key is reduced to O(1) amortized.',
          'hint':
              'Focus on the cost of decrease-key operations in dense graphs.',
          'repetitions': 2,
          'interval_days': 6,
          'ease_factor': 2.5,
          'next_review_date': now
              .subtract(const Duration(hours: 3))
              .millisecondsSinceEpoch,
          'last_reviewed_date': now
              .subtract(const Duration(days: 6))
              .millisecondsSinceEpoch,
          'mastery_level': 'reviewing',
          'created_at': now
              .subtract(const Duration(days: 14))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'fc_dist_01',
          'deck_id': 'deck_dist',
          'front': 'Why does the CAP theorem state that consistency and availability cannot both be guaranteed during a network partition?',
          'back': 'In a network partition, communication between node groups is severed. A node must either reject updates (sacrificing Availability) or accept updates without consensus (sacrificing Consistency).',
          'hint': 'Consider the decision a node must make when isolated from other replicas.',
          'repetitions': 3,
          'interval_days': 12,
          'ease_factor': 2.5,
          'next_review_date': now
              .add(const Duration(days: 5))
              .millisecondsSinceEpoch,
          'last_reviewed_date': now
              .subtract(const Duration(days: 7))
              .millisecondsSinceEpoch,
          'mastery_level': 'mastered',
          'created_at': now
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'fc_dist_02',
          'deck_id': 'deck_dist',
          'front': 'In the Raft consensus protocol, what is the role of terms and how are stale leaders handled?',
          'back': 'Terms act as logical clocks. Each RPC contains the sender term; if a leader or candidate receives a message with a higher term, it immediately steps down to follower.',
          'hint': 'Logical clock monotonic counters in RPC headers.',
          'repetitions': 2,
          'interval_days': 6,
          'ease_factor': 2.45,
          'next_review_date': now
              .subtract(const Duration(hours: 4))
              .millisecondsSinceEpoch,
          'last_reviewed_date': now
              .subtract(const Duration(days: 6))
              .millisecondsSinceEpoch,
          'mastery_level': 'reviewing',
          'created_at': now
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'fc_mobile_01',
          'deck_id': 'deck_mobile',
          'front': 'Why does Flutter Impeller eliminate runtime shader compilation jank on Android and iOS?',
          'back': 'Impeller pre-compiles all pipeline shaders offline at application build time into an immutable shader cache, eliminating runtime SPIR-V/GLSL compilation during first draw.',
          'hint': 'Ahead-of-Time (AOT) graphics pipeline generation.',
          'repetitions': 2,
          'interval_days': 6,
          'ease_factor': 2.5,
          'next_review_date': now
              .add(const Duration(days: 2))
              .millisecondsSinceEpoch,
          'last_reviewed_date': now
              .subtract(const Duration(days: 4))
              .millisecondsSinceEpoch,
          'mastery_level': 'reviewing',
          'created_at': now
              .subtract(const Duration(days: 7))
              .millisecondsSinceEpoch,
        },
      ];

      for (final c in cards) {
        await db.insert('flashcards', c);
      }

      // Seed Reviews
      final reviews = [
        {
          'id': 'rev_01',
          'card_id': 'fc_algo_01',
          'deck_id': 'deck_algo',
          'quality': 5,
          'interval_days': 15,
          'ease_factor': 2.6,
          'reviewed_at': now
              .subtract(const Duration(days: 6))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'rev_02',
          'card_id': 'fc_dist_01',
          'deck_id': 'deck_dist',
          'quality': 5,
          'interval_days': 12,
          'ease_factor': 2.5,
          'reviewed_at': now
              .subtract(const Duration(days: 4))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'rev_03',
          'card_id': 'fc_mobile_01',
          'deck_id': 'deck_mobile',
          'quality': 4,
          'interval_days': 6,
          'ease_factor': 2.5,
          'reviewed_at': now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
        },
      ];

      for (final r in reviews) {
        await db.insert('flashcard_reviews', r);
      }
    },
  );

  return AppDatabase(db);
}
