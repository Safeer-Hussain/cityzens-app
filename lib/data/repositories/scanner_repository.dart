import '../../core/services/native_camera_bridge.dart';
import '../models/optical_payload.dart';

class ScannerRepository {
  final NativeCameraBridge bridge;

  ScannerRepository({required this.bridge});

  Future<Map<String, dynamic>> initializeCamera() =>
      bridge.initializeCameraSensor();

  Future<bool> toggleTorch() => bridge.toggleTorch();

  bool get isTorchOn => bridge.isTorchOn;

  Future<OpticalPayload> scanOpticalPayload({required String mode}) async {
    final raw = await bridge.scanOpticalPayload(mode: mode);
    return OpticalPayload.fromMap(raw);
  }
}
