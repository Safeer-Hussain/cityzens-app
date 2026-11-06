import 'package:flutter/foundation.dart';
import '../../data/models/academic_transcript.dart';
import '../../data/repositories/transcript_repository.dart';

class GpaCalculatorProvider extends ChangeNotifier {
  final TranscriptRepository repository;

  bool _isLoading = false;
  List<AcademicTranscriptModel> _transcripts = [];
  List<WhatIfCourseSimulation> _simulatedCourses = [];
  String? _errorMessage;

  GpaCalculatorProvider({required this.repository}) {
    _initDefaultSimulationCourses();
  }

  bool get isLoading => _isLoading;
  List<AcademicTranscriptModel> get transcripts => List.unmodifiable(_transcripts);
  List<WhatIfCourseSimulation> get simulatedCourses => List.unmodifiable(_simulatedCourses);
  String? get errorMessage => _errorMessage;

  void _initDefaultSimulationCourses() {
    _simulatedCourses = [
      const WhatIfCourseSimulation(
        id: 'sim_cs401',
        courseCode: 'CS-401',
        title: 'Distributed Systems & Cloud Computing',
        creditHours: 4,
        expectedGrade: 'A',
      ),
      const WhatIfCourseSimulation(
        id: 'sim_cs405',
        courseCode: 'CS-405',
        title: 'Advanced Mobile Architecture & Kernels',
        creditHours: 4,
        expectedGrade: 'A',
      ),
      const WhatIfCourseSimulation(
        id: 'sim_ai410',
        courseCode: 'AI-410',
        title: 'Applied AI & Neural Heuristics',
        creditHours: 4,
        expectedGrade: 'A',
      ),
      const WhatIfCourseSimulation(
        id: 'sim_se420',
        courseCode: 'SE-420',
        title: 'Domain-Driven Enterprise Software',
        creditHours: 3,
        expectedGrade: 'A',
      ),
      const WhatIfCourseSimulation(
        id: 'sim_sec430',
        courseCode: 'SEC-430',
        title: 'Zero-Trust Cryptographic Infrastructure',
        creditHours: 3,
        expectedGrade: 'A',
      ),
    ];
  }

  Future<void> loadTranscripts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transcripts = await repository.getTranscripts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  TranscriptCalculationResult get projection {
    return repository.calculateProjection(
      transcripts: _transcripts,
      simulations: _simulatedCourses,
    );
  }

  int get priorCredits => projection.priorCredits;
  double get priorCgpa => projection.priorCgpa;
  int get simulatedCredits => projection.simulatedCredits;
  double get simulatedSemesterGpa => projection.simulatedSemesterGpa;
  int get projectedTotalCredits => projection.projectedTotalCredits;
  double get projectedCgpa => projection.projectedCgpa;
  String get honorsClassification => projection.honorsClassification;

  void updateCourseGrade(String courseId, String grade) {
    final index = _simulatedCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _simulatedCourses[index] = _simulatedCourses[index].copyWith(expectedGrade: grade);
      notifyListeners();
    }
  }

  void updateCourseCredits(String courseId, int credits) {
    final index = _simulatedCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _simulatedCourses[index] = _simulatedCourses[index].copyWith(creditHours: credits);
      notifyListeners();
    }
  }

  void addCustomCourse({
    required String courseCode,
    required String title,
    required int credits,
    required String grade,
  }) {
    final newId = 'sim_${DateTime.now().microsecondsSinceEpoch}';
    _simulatedCourses.add(
      WhatIfCourseSimulation(
        id: newId,
        courseCode: courseCode,
        title: title,
        creditHours: credits,
        expectedGrade: grade,
      ),
    );
    notifyListeners();
  }

  void removeCourse(String courseId) {
    _simulatedCourses.removeWhere((c) => c.id == courseId);
    notifyListeners();
  }

  void resetSimulation() {
    _initDefaultSimulationCourses();
    notifyListeners();
  }

  Future<bool> commitSemesterToTranscript({
    String semesterName = 'Semester 8 (Spring 2027 - Final)',
  }) async {
    try {
      final simGpa = simulatedSemesterGpa;
      final simCredits = simulatedCredits;
      final newId = 'sem_0${_transcripts.length + 1}';

      final record = AcademicTranscriptModel(
        id: newId,
        semesterName: semesterName,
        creditHours: simCredits,
        gpa: simGpa,
      );

      await repository.saveTranscript(record);
      await loadTranscripts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
