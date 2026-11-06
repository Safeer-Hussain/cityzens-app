import 'package:flutter/foundation.dart';
import '../../data/models/course_attendance.dart';
import '../../data/models/attendance_record.dart';
import '../../data/repositories/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository repository;

  bool _isLoading = false;
  bool _isStudentMode = true; // Toggle between Student Mode and Faculty Mode
  List<CourseModel> _courses = [];
  List<AttendanceRecord> _ledger = [];
  String? _errorMessage;

  AttendanceProvider({required this.repository});

  bool get isLoading => _isLoading;
  bool get isStudentMode => _isStudentMode;
  List<CourseModel> get courses => _courses;
  List<AttendanceRecord> get ledger => _ledger;
  String? get errorMessage => _errorMessage;

  double get overallAttendancePercentage {
    if (_courses.isEmpty) return 100.0;
    double totalP = 0;
    double totalC = 0;
    for (final c in _courses) {
      totalP += c.presentCount + (c.excusedCount * 0.5);
      totalC += c.totalClasses;
    }
    if (totalC == 0) return 100.0;
    return double.parse(((totalP / totalC) * 100).toStringAsFixed(1));
  }

  int get totalClassesCount => _courses.fold(0, (acc, c) => acc + c.totalClasses);
  int get totalPresentCount => _courses.fold(0, (acc, c) => acc + c.presentCount);
  int get totalAbsentCount => _courses.fold(0, (acc, c) => acc + c.absentCount);
  int get totalExcusedCount => _courses.fold(0, (acc, c) => acc + c.excusedCount);

  void toggleRoleMode() {
    _isStudentMode = !_isStudentMode;
    notifyListeners();
  }

  Future<void> loadAttendanceData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await repository.getCourses();
      _ledger = await repository.getLedger();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkInWithQr({
    required String courseCode,
    required String qrPayload,
  }) async {
    try {
      final success = await repository.recordCheckIn(
        courseCode: courseCode,
        method: 'native_qr',
        verificationPayload: qrPayload,
      );
      if (success) {
        await loadAttendanceData();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> checkInWithPin({
    required String courseCode,
    required String pin,
  }) async {
    try {
      final success = await repository.recordCheckIn(
        courseCode: courseCode,
        method: 'manual_pin',
        verificationPayload: 'Pin: $pin',
      );
      if (success) {
        await loadAttendanceData();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> submitLeaveRequest({
    required String courseCode,
    required String reason,
    required DateTime date,
  }) async {
    try {
      final success = await repository.submitLeaveRequest(
        courseCode: courseCode,
        reason: reason,
        date: date,
      );
      if (success) {
        await loadAttendanceData();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }
}
