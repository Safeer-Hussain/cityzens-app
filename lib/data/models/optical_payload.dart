class OpticalPayload {
  final String type; // 'attendance_qr', 'library_isbn', 'student_id'
  final String? code;
  final String? courseCode;
  final String? courseTitle;
  final String? room;
  final String? isbn;
  final String? title;
  final String? author;
  final String? studentId;
  final String? name;
  final String? department;
  final String? role;
  final String? clearance;
  final String checksum;
  final int timestamp;

  const OpticalPayload({
    required this.type,
    this.code,
    this.courseCode,
    this.courseTitle,
    this.room,
    this.isbn,
    this.title,
    this.author,
    this.studentId,
    this.name,
    this.department,
    this.role,
    this.clearance,
    required this.checksum,
    required this.timestamp,
  });

  factory OpticalPayload.fromMap(Map<String, dynamic> map) {
    return OpticalPayload(
      type: map['type'] as String? ?? 'unknown',
      code: map['code'] as String?,
      courseCode: map['courseCode'] as String?,
      courseTitle: map['courseTitle'] as String?,
      room: map['room'] as String?,
      isbn: map['isbn'] as String?,
      title: map['title'] as String?,
      author: map['author'] as String?,
      studentId: map['studentId'] as String?,
      name: map['name'] as String?,
      department: map['department'] as String?,
      role: map['role'] as String?,
      clearance: map['clearance'] as String?,
      checksum: map['checksum'] as String? ?? 'VERIFIED_CRC',
      timestamp:
          (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
