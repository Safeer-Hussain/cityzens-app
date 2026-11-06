import 'package:flutter/foundation.dart';
import '../../data/models/optical_payload.dart';
import '../../data/repositories/scanner_repository.dart';

enum ScannerMode {
  attendanceQr,
  libraryIsbn,
  studentId,
}

extension ScannerModeExtension on ScannerMode {
  String get label {
    switch (this) {
      case ScannerMode.attendanceQr:
        return 'Attendance QR';
      case ScannerMode.libraryIsbn:
        return 'Book ISBN Barcode';
      case ScannerMode.studentId:
        return 'Smart Campus ID';
    }
  }

  String get apiParam {
    switch (this) {
      case ScannerMode.attendanceQr:
        return 'attendance_qr';
      case ScannerMode.libraryIsbn:
        return 'library_isbn';
      case ScannerMode.studentId:
        return 'student_id';
    }
  }
}

class ScannerProvider extends ChangeNotifier {
  final ScannerRepository repository;

  ScannerMode _selectedMode = ScannerMode.attendanceQr;
  bool _isCameraReady = false;
  bool _isScanning = false;
  bool _isTorchOn = false;
  Map<String, dynamic> _sensorInfo = {};
  OpticalPayload? _lastPayload;
  String? _errorMessage;

  ScannerProvider({required this.repository});

  ScannerMode get selectedMode => _selectedMode;
  bool get isCameraReady => _isCameraReady;
  bool get isScanning => _isScanning;
  bool get isTorchOn => _isTorchOn;
  Map<String, dynamic> get sensorInfo => _sensorInfo;
  OpticalPayload? get lastPayload => _lastPayload;
  String? get errorMessage => _errorMessage;

  void setMode(ScannerMode mode) {
    if (_selectedMode == mode) return;
    _selectedMode = mode;
    _lastPayload = null;
    notifyListeners();
  }

  Future<void> initializeCamera() async {
    try {
      _sensorInfo = await repository.initializeCamera();
      _isCameraReady = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTorch() async {
    try {
      _isTorchOn = await repository.toggleTorch();
      notifyListeners();
    } catch (e) {
      _isTorchOn = !_isTorchOn;
      notifyListeners();
    }
  }

  Future<OpticalPayload?> scanPayload() async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = await repository.scanOpticalPayload(mode: _selectedMode.apiParam);
      _lastPayload = payload;
      return payload;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  void clearLastPayload() {
    _lastPayload = null;
    notifyListeners();
  }
}
