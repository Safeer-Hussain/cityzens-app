import 'dart:convert';

class StudyRoomBookingModel {
  final String id;
  final String roomId;
  final String roomName;
  final int floor;
  final String bookedById;
  final String bookedByName;
  final String purpose;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> attendees;
  final DateTime createdAt;
  final String status; // 'confirmed', 'cancelled', 'completed'

  const StudyRoomBookingModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.floor,
    required this.bookedById,
    required this.bookedByName,
    required this.purpose,
    required this.startTime,
    required this.endTime,
    required this.attendees,
    required this.createdAt,
    this.status = 'confirmed',
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  bool get isActiveNow {
    final now = DateTime.now();
    return isConfirmed && now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return isConfirmed && startTime.isAfter(now);
  }

  String get formattedTimeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMin = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[startTime.month - 1]} ${startTime.day}, ${startTime.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'room_name': roomName,
      'floor': floor,
      'booked_by_id': bookedById,
      'booked_by_name': bookedByName,
      'purpose': purpose,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'attendees': jsonEncode(attendees),
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory StudyRoomBookingModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedAttendees = [];
    final rawAttendees = map['attendees'];
    if (rawAttendees is String) {
      try {
        parsedAttendees = List<String>.from(jsonDecode(rawAttendees) as List);
      } catch (_) {
        parsedAttendees = [];
      }
    } else if (rawAttendees is List) {
      parsedAttendees = List<String>.from(rawAttendees);
    }

    return StudyRoomBookingModel(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      roomName: map['room_name'] as String,
      floor: (map['floor'] as num).toInt(),
      bookedById: map['booked_by_id'] as String,
      bookedByName: map['booked_by_name'] as String,
      purpose: map['purpose'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map['start_time'] as num).toInt(),
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        (map['end_time'] as num).toInt(),
      ),
      attendees: parsedAttendees,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num).toInt(),
      ),
      status: (map['status'] as String?) ?? 'confirmed',
    );
  }

  StudyRoomBookingModel copyWith({
    String? id,
    String? roomId,
    String? roomName,
    int? floor,
    String? bookedById,
    String? bookedByName,
    String? purpose,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? attendees,
    DateTime? createdAt,
    String? status,
  }) {
    return StudyRoomBookingModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      floor: floor ?? this.floor,
      bookedById: bookedById ?? this.bookedById,
      bookedByName: bookedByName ?? this.bookedByName,
      purpose: purpose ?? this.purpose,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attendees: attendees ?? this.attendees,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
