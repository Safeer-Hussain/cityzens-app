import 'package:flutter/foundation.dart';

class TelemetryService extends ChangeNotifier {
  int _screenRebuilds = 0;
  int _lastLoadTimeMs = 142;
  final double _frameRateFps = 59.8;
  final int _sqliteQueryLatencyMs = 4;
  int _simulatedLatencyMs = 500;
  bool _simulateHttp503Once = false;

  int get screenRebuilds => _screenRebuilds;
  int get lastLoadTimeMs => _lastLoadTimeMs;
  double get frameRateFps => _frameRateFps;
  int get sqliteQueryLatencyMs => _sqliteQueryLatencyMs;
  int get simulatedLatencyMs => _simulatedLatencyMs;
  bool get simulateHttp503Once => _simulateHttp503Once;

  void recordRebuild() {
    _screenRebuilds++;
    notifyListeners();
  }

  void recordLoadTime(int ms) {
    _lastLoadTimeMs = ms;
    notifyListeners();
  }

  void setSimulatedLatency(int ms) {
    _simulatedLatencyMs = ms;
    notifyListeners();
  }

  void toggleSimulate503() {
    _simulateHttp503Once = !_simulateHttp503Once;
    notifyListeners();
  }

  bool consume503Trigger() {
    if (_simulateHttp503Once) {
      _simulateHttp503Once = false;
      notifyListeners();
      return true;
    }
    return false;
  }
}
