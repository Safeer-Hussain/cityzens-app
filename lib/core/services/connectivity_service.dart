import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isDeviceOnline = true;
  bool _forceOfflineDebug = false;

  ConnectivityService() {
    _init();
  }

  bool get isOnline => _isDeviceOnline && !_forceOfflineDebug;
  bool get isOffline => !isOnline;
  bool get isForceOfflineDebug => _forceOfflineDebug;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    } catch (_) {
      _isDeviceOnline = true;
      notifyListeners();
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    if (_isDeviceOnline != hasConnection) {
      _isDeviceOnline = hasConnection;
      notifyListeners();
    }
  }

  void toggleForceOfflineDebug() {
    _forceOfflineDebug = !_forceOfflineDebug;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
