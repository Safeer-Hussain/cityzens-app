import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../models/academic_transcript.dart';

class TranscriptCalculationResult {
  final int priorCredits;
  final double priorCgpa;
  final int simulatedCredits;
  final double simulatedSemesterGpa;
  final int projectedTotalCredits;
  final double projectedCgpa;
  final String honorsClassification;

  const TranscriptCalculationResult({
    required this.priorCredits,
    required this.priorCgpa,
    required this.simulatedCredits,
    required this.simulatedSemesterGpa,
    required this.projectedTotalCredits,
    required this.projectedCgpa,
    required this.honorsClassification,
  });
}

class TranscriptRepository {
  final AppDatabase database;

  TranscriptRepository({required this.database});

  Database get _db => database.db;

  Future<List<AcademicTranscriptModel>> getTranscripts() async {
    final results = await _db.query('academic_transcripts', orderBy: 'id ASC');
    return results.map((m) => AcademicTranscriptModel.fromMap(m)).toList();
  }

  Future<void> saveTranscript(AcademicTranscriptModel transcript) async {
    await _db.insert(
      'academic_transcripts',
      transcript.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTranscript(String id) async {
    await _db.delete('academic_transcripts', where: 'id = ?', whereArgs: [id]);
  }

  TranscriptCalculationResult calculateProjection({
    required List<AcademicTranscriptModel> transcripts,
    required List<WhatIfCourseSimulation> simulations,
  }) {
    int priorCredits = 0;
    double priorPoints = 0.0;

    for (final t in transcripts) {
      priorCredits += t.creditHours;
      priorPoints += (t.creditHours * t.gpa);
    }

    final priorCgpa = priorCredits > 0
        ? double.parse((priorPoints / priorCredits).toStringAsFixed(2))
        : 0.0;

    int simCredits = 0;
    double simPoints = 0.0;

    for (final s in simulations) {
      simCredits += s.creditHours;
      simPoints += (s.creditHours * s.gradePointValue);
    }

    final simSemesterGpa = simCredits > 0
        ? double.parse((simPoints / simCredits).toStringAsFixed(2))
        : 0.0;

    final projectedTotalCredits = priorCredits + simCredits;
    final projectedCgpa = projectedTotalCredits > 0
        ? double.parse(
            ((priorPoints + simPoints) / projectedTotalCredits).toStringAsFixed(
              2,
            ),
          )
        : 0.0;

    String honors;
    if (projectedCgpa >= 3.90) {
      honors = 'Summa Cum Laude (Highest Distinction)';
    } else if (projectedCgpa >= 3.75) {
      honors = 'Magna Cum Laude (High Distinction)';
    } else if (projectedCgpa >= 3.50) {
      honors = 'Cum Laude (Distinction)';
    } else if (projectedCgpa >= 3.00) {
      honors = 'Honours Standing';
    } else {
      honors = 'Good Academic Standing';
    }

    return TranscriptCalculationResult(
      priorCredits: priorCredits,
      priorCgpa: priorCgpa,
      simulatedCredits: simCredits,
      simulatedSemesterGpa: simSemesterGpa,
      projectedTotalCredits: projectedTotalCredits,
      projectedCgpa: projectedCgpa,
      honorsClassification: honors,
    );
  }
}
