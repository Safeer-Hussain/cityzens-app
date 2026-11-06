import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/library_repository.dart';

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final int timestamp;
  final bool isStreaming;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  AiChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    int? timestamp,
    bool? isStreaming,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class AiTutorProvider extends ChangeNotifier {
  final AttendanceRepository attendanceRepository;
  final LibraryRepository libraryRepository;

  final List<AiChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _transientStatus;

  AiTutorProvider({
    required this.attendanceRepository,
    required this.libraryRepository,
  }) {
    _initWelcomeMessage();
  }

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  String? get transientStatus => _transientStatus;

  void _initWelcomeMessage() {
    _messages.add(
      AiChatMessage(
        id: 'msg_welcome',
        text: 'Greetings Safeer. I am your Cityzens AI Academic Companion. I have real-time optical synchronization with your SQLite attendance records, active library loans, and course schedules. Select an academic action below or ask any research inquiry.',
        isUser: false,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }

  Future<void> sendPrompt(String userText) async {
    if (userText.trim().isEmpty || _isStreaming) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _messages.add(
      AiChatMessage(
        id: 'user_$now',
        text: userText.trim(),
        isUser: true,
        timestamp: now,
      ),
    );
    notifyListeners();

    _isStreaming = true;
    _transientStatus = 'Analyzing library records & course attendance...';
    notifyListeners();

    try {
      // 1. Fetch live contextual state from SQLite
      final courses = await attendanceRepository.getCourses();
      final loans = await libraryRepository.getActiveLoans();

      await Future.delayed(const Duration(milliseconds: 500));
      _transientStatus = null;

      // 2. Synthesize contextual response based on prompt
      final responseText = _generateAcademicResponse(
        prompt: userText.trim(),
        courses: courses,
        loans: loans,
      );

      // 3. Stream token by token
      final botMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
      _messages.add(
        AiChatMessage(
          id: botMsgId,
          text: '',
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isStreaming: true,
        ),
      );
      notifyListeners();

      final words = responseText.split(' ');
      String accumulated = '';

      for (int i = 0; i < words.length; i++) {
        accumulated += (i == 0 ? '' : ' ') + words[i];
        final msgIndex = _messages.indexWhere((m) => m.id == botMsgId);
        if (msgIndex != -1) {
          _messages[msgIndex] = _messages[msgIndex].copyWith(
            text: accumulated,
            isStreaming: i < words.length - 1,
          );
          notifyListeners();
        }
        await Future.delayed(const Duration(milliseconds: 28));
      }
    } finally {
      // Strict rule: ALWAYS ensure isStreaming is reset to false
      _isStreaming = false;
      _transientStatus = null;
      notifyListeners();
    }
  }

  String _generateAcademicResponse({
    required String prompt,
    required List<dynamic> courses,
    required List<dynamic> loans,
  }) {
    final lower = prompt.toLowerCase();

    if (lower.contains('attendance') || lower.contains('risk') || lower.contains('classes')) {
      final buffer = StringBuffer();
      buffer.writeln('Academic Attendance Audit (Synced with SQLite Ledger):');
      buffer.writeln('');
      for (final c in courses) {
        final percent = c.attendancePercentage;
        final isRisk = c.isAtRisk;
        final needed = c.calculateClassesNeeded(75.0);
        buffer.writeln(
          '* ${c.code} (${c.title}): $percent% (${c.presentCount}P / ${c.absentCount}A / ${c.excusedCount}E)${isRisk ? " [AT RISK - Needs $needed consecutive classes]" : " [Good Standing]"}',
        );
      }
      buffer.writeln('');
      buffer.writeln('Strategic Recommendation: Maintain attendance in AI-410 to comfortably surpass the 75.0% university accreditation threshold before end-semester exam registration.');
      return buffer.toString();
    }

    if (lower.contains('summarize') || lower.contains('borrowed') || lower.contains('library') || lower.contains('book')) {
      final buffer = StringBuffer();
      buffer.writeln('Active Digital Library Loans & Due Date Audit:');
      buffer.writeln('');
      if (loans.isEmpty) {
        buffer.writeln('You currently have zero active book loans in the university ledger.');
      } else {
        for (final item in loans) {
          final days = item.loan.daysRemaining;
          final isOver = item.loan.isOverdue;
          final fine = item.loan.calculatedFine;
          buffer.writeln(
            '* "${item.book.title}" by ${item.book.author}\n  Shelf: ${item.book.shelfLocation}\n  Status: ${isOver ? "OVERDUE by ${days.abs()} days (Fine: \$${fine.toStringAsFixed(2)})" : "Active ($days days remaining until return)"}',
          );
        }
      }
      buffer.writeln('');
      buffer.writeln('1-Tap Renewal Notice: You can renew active loans for an additional 14 days directly from the Library Records tab with zero penalty.');
      return buffer.toString();
    }

    if (lower.contains('revision') || lower.contains('schedule') || lower.contains('exam')) {
      return '''Recommended 7-Day High-Throughput Exam Revision Plan:

Day 1-2 (Distributed Systems & Cloud Computing):
* Deep dive into Raft consensus quorum calculation, leader election state machines, and log replication.
* Practical exercises: Partition fault simulation and vector clock causality.

Day 3-4 (Advanced Mobile Architecture):
* Internal mechanics of Flutter Impeller rendering pipelines and frame scheduler.
* MethodChannel memory serialization and native JNI optical sensor bridges.

Day 5 (Applied AI & Neural Heuristics):
* Backpropagation derivations, Adam optimizer momentum decay, and attention matrix operations.

Day 6 (Domain-Driven Software Engineering):
* Hexagonal Architecture, CQRS event sourcing, and SOLID clean boundary encapsulation.

Day 7 (Mock Assessment & Rest):
* 3-hour timed practice paper on Distributed Databases followed by cognitive recharge.''';
    }

    if (lower.contains('proposal') || lower.contains('faculty') || lower.contains('project')) {
      return '''Faculty Research Project Proposal Draft:

Title: Zero-Latency Edge Telemetry & Offline-First Biomolecular Verification in Campus Mobile Systems

Principal Investigator: Safeer Hussain (Senior Mobile Architect / CS Honours)
Advising Faculty: Dr. Aris Thorne & Prof. Evelyn Vance

1. Abstract:
Modern smart campus architectures struggle under intermittent Wi-Fi connectivity and high-latency cloud roundtrips during peak lecture transitions. We propose a resilient offline-first paradigm utilizing native C++/Kotlin optical sensor channels and embedded SQLite caching that guarantees sub-5ms query verification and zero UI frame drops.

2. Deliverables:
* Optical QR/Barcode scanning bridge with hardware checksum verification.
* Automated attendance ledger with Bayesian absence projection.
* Local vector-indexed library catalog with zero-cost offline availability.

Submitted for Dean Review & Laboratory Allocation.''';
    }

    return 'I have analyzed your query "$prompt" against your academic profile. Your course standings are healthy across 4 out of 5 subjects, and you have active library loans in Distributed Systems. Let me know if you would like me to draft notes, evaluate attendance risk formulas, or structure a revision schedule.';
  }
}
