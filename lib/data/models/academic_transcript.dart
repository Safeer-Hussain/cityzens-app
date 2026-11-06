class AcademicTranscriptModel {
  final String id;
  final String semesterName;
  final int creditHours;
  final double gpa;

  const AcademicTranscriptModel({
    required this.id,
    required this.semesterName,
    required this.creditHours,
    required this.gpa,
  });

  double get qualityPoints => double.parse((creditHours * gpa).toStringAsFixed(2));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_name': semesterName,
      'credit_hours': creditHours,
      'gpa': gpa,
    };
  }

  factory AcademicTranscriptModel.fromMap(Map<String, dynamic> map) {
    return AcademicTranscriptModel(
      id: map['id'] as String,
      semesterName: map['semester_name'] as String,
      creditHours: (map['credit_hours'] as num).toInt(),
      gpa: (map['gpa'] as num).toDouble(),
    );
  }
}

class WhatIfCourseSimulation {
  final String id;
  final String courseCode;
  final String title;
  final int creditHours;
  final String expectedGrade;

  static const Map<String, double> gradeScale = {
    'A+': 4.0,
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'D': 1.0,
    'F': 0.0,
  };

  const WhatIfCourseSimulation({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.creditHours,
    required this.expectedGrade,
  });

  double get gradePointValue => gradeScale[expectedGrade] ?? 4.0;
  double get totalQualityPoints => double.parse((creditHours * gradePointValue).toStringAsFixed(2));

  WhatIfCourseSimulation copyWith({
    String? id,
    String? courseCode,
    String? title,
    int? creditHours,
    String? expectedGrade,
  }) {
    return WhatIfCourseSimulation(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      creditHours: creditHours ?? this.creditHours,
      expectedGrade: expectedGrade ?? this.expectedGrade,
    );
  }
}
