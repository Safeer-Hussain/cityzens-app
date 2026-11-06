class AttendanceRecord {
  final String id;
  final String courseId;
  final String courseCode;
  final int timestamp;
  final String status; // 'present', 'absent', 'excused'
  final String verificationMethod; // 'native_qr', 'manual_pin', 'leave_request'
  final String notes;

  const AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.timestamp,
    required this.status,
    required this.verificationMethod,
    required this.notes,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'course_code': courseCode,
      'timestamp': timestamp,
      'status': status,
      'verification_method': verificationMethod,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      courseCode: map['course_code'] as String,
      timestamp: (map['timestamp'] as num).toInt(),
      status: map['status'] as String,
      verificationMethod: map['verification_method'] as String,
      notes: map['notes'] as String,
    );
  }
}
