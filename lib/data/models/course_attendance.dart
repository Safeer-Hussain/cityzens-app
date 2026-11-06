class CourseModel {
  final String id;
  final String code;
  final String title;
  final String instructor;
  final String room;
  final String schedule;
  final int presentCount;
  final int absentCount;
  final int excusedCount;
  final int totalClasses;
  final double minRequiredPercentage;

  const CourseModel({
    required this.id,
    required this.code,
    required this.title,
    required this.instructor,
    required this.room,
    required this.schedule,
    required this.presentCount,
    required this.absentCount,
    required this.excusedCount,
    required this.totalClasses,
    this.minRequiredPercentage = 75.0,
  });

  double get attendancePercentage {
    if (totalClasses == 0) return 100.0;
    final effectivePresent = presentCount + (excusedCount * 0.5);
    return double.parse(((effectivePresent / totalClasses) * 100).toStringAsFixed(1));
  }

  bool get isAtRisk => attendancePercentage < minRequiredPercentage;

  int calculateClassesNeeded(double targetPercent) {
    if (attendancePercentage >= targetPercent) return 0;
    // target = (P + x) / (T + x) => x = (target * T - P) / (1 - target)
    final targetFraction = targetPercent / 100.0;
    if (targetFraction >= 1.0) return 999;
    final needed = ((targetFraction * totalClasses - presentCount) / (1.0 - targetFraction)).ceil();
    return needed > 0 ? needed : 0;
  }

  CourseModel copyWith({
    String? id,
    String? code,
    String? title,
    String? instructor,
    String? room,
    String? schedule,
    int? presentCount,
    int? absentCount,
    int? excusedCount,
    int? totalClasses,
    double? minRequiredPercentage,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      excusedCount: excusedCount ?? this.excusedCount,
      totalClasses: totalClasses ?? this.totalClasses,
      minRequiredPercentage: minRequiredPercentage ?? this.minRequiredPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'instructor': instructor,
      'room': room,
      'schedule': schedule,
      'present_count': presentCount,
      'absent_count': absentCount,
      'excused_count': excusedCount,
      'total_classes': totalClasses,
      'min_required_percentage': minRequiredPercentage,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as String,
      code: map['code'] as String,
      title: map['title'] as String,
      instructor: map['instructor'] as String,
      room: map['room'] as String,
      schedule: map['schedule'] as String,
      presentCount: (map['present_count'] as num).toInt(),
      absentCount: (map['absent_count'] as num).toInt(),
      excusedCount: (map['excused_count'] as num).toInt(),
      totalClasses: (map['total_classes'] as num).toInt(),
      minRequiredPercentage: (map['min_required_percentage'] as num).toDouble(),
    );
  }
}
