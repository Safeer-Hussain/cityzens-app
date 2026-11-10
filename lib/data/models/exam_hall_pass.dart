import 'dart:convert';
import '../../core/utils/exam_cryptography.dart';

enum SeatStatus {
  assignedToUser,
  occupied,
  available,
  accessible,
}

class ExamSeat {
  final String row;
  final int number;
  final String hallName;
  final SeatStatus status;
  final String? assignedCandidateMasked;

  const ExamSeat({
    required this.row,
    required this.number,
    required this.hallName,
    required this.status,
    this.assignedCandidateMasked,
  });

  String get deskCode => '$row$number';
  bool get isUserSeat => status == SeatStatus.assignedToUser;
  bool get isAvailable => status == SeatStatus.available;
  bool get isOccupied => status == SeatStatus.occupied;
  bool get isAccessible => status == SeatStatus.accessible;
}

class ExamHall {
  final String name;
  final String building;
  final String floor;
  final List<String> rows;
  final int seatsPerRow;
  final int totalCapacity;
  final int accessibleSeatsCount;

  const ExamHall({
    required this.name,
    required this.building,
    required this.floor,
    required this.rows,
    required this.seatsPerRow,
    required this.totalCapacity,
    required this.accessibleSeatsCount,
  });

  static const ExamHall turingHall = ExamHall(
    name: 'Turing Hall',
    building: 'Alan Turing Computing Complex',
    floor: 'Floor 2, North Wing',
    rows: ['A', 'B', 'C', 'D', 'E', 'F'],
    seatsPerRow: 16,
    totalCapacity: 96,
    accessibleSeatsCount: 4,
  );

  static const ExamHall hopperAuditorium = ExamHall(
    name: 'Hopper Auditorium',
    building: 'Grace Hopper Science & Engineering Center',
    floor: 'Ground Floor, Central Wing',
    rows: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
    seatsPerRow: 15,
    totalCapacity: 120,
    accessibleSeatsCount: 6,
  );

  static const List<ExamHall> defaultHalls = [turingHall, hopperAuditorium];
}

class ExamHallPassModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseCode;
  final String courseTitle;
  final String examType;
  final DateTime examDate;
  final int durationMinutes;
  final String hallName;
  final String seatRow;
  final int seatNumber;
  final String deskNumber;
  final String opticalToken;
  final String cryptographicChecksum;
  final bool isVerified;
  final bool isReminderSet;
  final int reminderLeadMinutes;
  final String invigilatorName;
  final List<String> instructions;

  const ExamHallPassModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseCode,
    required this.courseTitle,
    required this.examType,
    required this.examDate,
    required this.durationMinutes,
    required this.hallName,
    required this.seatRow,
    required this.seatNumber,
    required this.deskNumber,
    required this.opticalToken,
    required this.cryptographicChecksum,
    this.isVerified = false,
    this.isReminderSet = false,
    this.reminderLeadMinutes = 60,
    required this.invigilatorName,
    required this.instructions,
  });

  String get seatDesignation => 'Row $seatRow, Seat $seatNumber';

  bool get isUpcoming => examDate.isAfter(DateTime.now());

  Duration get timeUntilExam => examDate.difference(DateTime.now());

  String get countdownFormatted {
    final diff = timeUntilExam;
    if (diff.isNegative) {
      return 'Completed';
    }
    if (diff.inDays > 0) {
      return 'In ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'In ${diff.inMinutes} mins';
  }

  bool verifyIntegrity() {
    return ExamCryptography.verifyChecksum(
      passId: id,
      studentId: studentId,
      courseCode: courseCode,
      hallName: hallName,
      deskNumber: deskNumber,
      examTimestamp: examDate.millisecondsSinceEpoch,
      expectedChecksum: cryptographicChecksum,
    );
  }

  ExamHallPassModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseCode,
    String? courseTitle,
    String? examType,
    DateTime? examDate,
    int? durationMinutes,
    String? hallName,
    String? seatRow,
    int? seatNumber,
    String? deskNumber,
    String? opticalToken,
    String? cryptographicChecksum,
    bool? isVerified,
    bool? isReminderSet,
    int? reminderLeadMinutes,
    String? invigilatorName,
    List<String>? instructions,
  }) {
    return ExamHallPassModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      examType: examType ?? this.examType,
      examDate: examDate ?? this.examDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      hallName: hallName ?? this.hallName,
      seatRow: seatRow ?? this.seatRow,
      seatNumber: seatNumber ?? this.seatNumber,
      deskNumber: deskNumber ?? this.deskNumber,
      opticalToken: opticalToken ?? this.opticalToken,
      cryptographicChecksum: cryptographicChecksum ?? this.cryptographicChecksum,
      isVerified: isVerified ?? this.isVerified,
      isReminderSet: isReminderSet ?? this.isReminderSet,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      invigilatorName: invigilatorName ?? this.invigilatorName,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'course_code': courseCode,
      'course_title': courseTitle,
      'exam_type': examType,
      'exam_date': examDate.millisecondsSinceEpoch,
      'duration_minutes': durationMinutes,
      'hall_name': hallName,
      'seat_row': seatRow,
      'seat_number': seatNumber,
      'desk_number': deskNumber,
      'optical_token': opticalToken,
      'cryptographic_checksum': cryptographicChecksum,
      'is_verified': isVerified ? 1 : 0,
      'is_reminder_set': isReminderSet ? 1 : 0,
      'reminder_lead_minutes': reminderLeadMinutes,
      'invigilator_name': invigilatorName,
      'instructions': jsonEncode(instructions),
    };
  }

  factory ExamHallPassModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedInstructions = [];
    if (map['instructions'] != null) {
      try {
        final decoded = jsonDecode(map['instructions'] as String);
        if (decoded is List) {
          parsedInstructions = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedInstructions = [
          'Bring physical Student ID card and printed or optical admission slip.',
          'No unauthorized electronic devices or smartwatches inside examination hall.',
          'Doors close 10 minutes prior to official examination start time.',
        ];
      }
    }

    return ExamHallPassModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      courseCode: map['course_code'] as String,
      courseTitle: map['course_title'] as String,
      examType: map['exam_type'] as String,
      examDate: DateTime.fromMillisecondsSinceEpoch(map['exam_date'] as int),
      durationMinutes: map['duration_minutes'] as int,
      hallName: map['hall_name'] as String,
      seatRow: map['seat_row'] as String,
      seatNumber: map['seat_number'] as int,
      deskNumber: map['desk_number'] as String,
      opticalToken: map['optical_token'] as String,
      cryptographicChecksum: map['cryptographic_checksum'] as String,
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
      isReminderSet: (map['is_reminder_set'] as int? ?? 0) == 1,
      reminderLeadMinutes: map['reminder_lead_minutes'] as int? ?? 60,
      invigilatorName: map['invigilator_name'] as String,
      instructions: parsedInstructions,
    );
  }
}
