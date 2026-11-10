import 'package:flutter/foundation.dart';
import '../../data/models/exam_hall_pass.dart';
import '../../data/repositories/exam_repository.dart';

class ExamProvider extends ChangeNotifier {
  final ExamRepository repository;

  ExamProvider({required this.repository});

  List<ExamHallPassModel> _passes = [];
  ExamHallPassModel? _selectedPass;
  ExamHall _selectedHall = ExamHall.turingHall;
  ExamSeat? _selectedSeat;
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _lastVerificationMessage;
  bool? _lastVerificationSuccess;

  List<ExamHallPassModel> get passes => List.unmodifiable(_passes);
  ExamHallPassModel? get selectedPass => _selectedPass;
  ExamHall get selectedHall => _selectedHall;
  ExamSeat? get selectedSeat => _selectedSeat;
  bool get isLoading => _isLoading;
  bool get isVerifying => _isVerifying;
  String? get lastVerificationMessage => _lastVerificationMessage;
  bool? get lastVerificationSuccess => _lastVerificationSuccess;

  int get totalPasses => _passes.length;

  int get armedRemindersCount => _passes.where((p) => p.isReminderSet).length;

  ExamHallPassModel? get nextUpcomingExam {
    if (_passes.isEmpty) return null;
    final upcoming = _passes.where((p) => p.isUpcoming).toList();
    if (upcoming.isEmpty) return _passes.first;
    return upcoming.first;
  }

  List<ExamSeat> get currentHallMatrix {
    return repository.generateHallMatrix(_selectedHall, _selectedPass);
  }

  ExamSeat? get userAssignedSeat {
    try {
      return currentHallMatrix.firstWhere((s) => s.isUserSeat);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadPasses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _passes = await repository.getAllPasses();
      if (_passes.isNotEmpty) {
        _selectedPass ??= _passes.first;
        _syncHallWithPass(_selectedPass!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPass(ExamHallPassModel pass) {
    _selectedPass = pass;
    _syncHallWithPass(pass);
    _selectedSeat = null;
    _lastVerificationMessage = null;
    _lastVerificationSuccess = null;
    notifyListeners();
  }

  void selectHall(ExamHall hall) {
    _selectedHall = hall;
    _selectedSeat = null;
    notifyListeners();
  }

  void selectSeat(ExamSeat seat) {
    _selectedSeat = seat;
    notifyListeners();
  }

  void _syncHallWithPass(ExamHallPassModel pass) {
    if (pass.hallName.toLowerCase().contains('hopper')) {
      _selectedHall = ExamHall.hopperAuditorium;
    } else {
      _selectedHall = ExamHall.turingHall;
    }
  }

  /// Toggles the offline timetable reminder alarm state for an examination.
  Future<bool> togglePassReminder(String passId) async {
    final index = _passes.indexWhere((p) => p.id == passId);
    if (index == -1) return false;

    final targetPass = _passes[index];
    final updatedArmed = !targetPass.isReminderSet;
    final updatedPass = targetPass.copyWith(isReminderSet: updatedArmed);

    // Optimistic list update
    _passes[index] = updatedPass;
    if (_selectedPass?.id == passId) {
      _selectedPass = updatedPass;
    }
    notifyListeners();

    // Persist to SQLite
    final success = await repository.toggleReminder(passId, updatedArmed);
    if (!success) {
      // Rollback on failure
      _passes[index] = targetPass;
      if (_selectedPass?.id == passId) {
        _selectedPass = targetPass;
      }
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Cryptographically verifies the current examination pass with SHA-256 integrity check.
  Future<bool> verifyCurrentPass() async {
    if (_selectedPass == null) return false;

    _isVerifying = true;
    _lastVerificationMessage = null;
    notifyListeners();

    try {
      final isValid = await repository.verifyPassTampering(_selectedPass!.id);
      _lastVerificationSuccess = isValid;

      if (isValid) {
        _lastVerificationMessage = 'Pass cryptographically authenticated by Cityzens Academic Registry.';
        await repository.setPassVerified(_selectedPass!.id, true);

        final index = _passes.indexWhere((p) => p.id == _selectedPass!.id);
        if (index != -1) {
          final verifiedPass = _passes[index].copyWith(isVerified: true);
          _passes[index] = verifiedPass;
          _selectedPass = verifiedPass;
        }
      } else {
        _lastVerificationMessage = 'Cryptographic signature mismatch! Potential pass tampering detected.';
      }

      return isValid;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  /// Simulates candidate gate check-in at turnstile.
  Future<void> simulateGateTurnstileScan() async {
    await verifyCurrentPass();
  }
}
