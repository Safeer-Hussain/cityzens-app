import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.safeer.cityzens/native_camera"
  private var isTorchOn = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let controller = window?.rootViewController as? FlutterViewController
    let channel: FlutterMethodChannel
    if let controller = controller {
      channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    } else {
      channel = FlutterMethodChannel(name: channelName, binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "NativeCamera").messenger())
    }

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      switch call.method {
      case "initializeCameraSensor":
        let sensorInfo: [String: Any] = [
          "status": "initialized",
          "sensor": "Apple LiDAR & 48MP Fusion Camera",
          "focalLength": "24mm f/1.78",
          "fps": 60,
          "resolution": "1920x1080",
          "autofocus": "LiDAR-Assisted AF",
          "opticalStabilization": true
        ]
        result(sensorInfo)
      case "scanOpticalPayload":
        let args = call.arguments as? [String: Any]
        let mode = args?["mode"] as? String ?? "attendance_qr"
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let payload: [String: Any]
        if mode == "library_isbn" {
          payload = [
            "type": "library_isbn",
            "isbn": "978-0134494166",
            "title": "Clean Architecture: A Craftsman's Guide",
            "author": "Robert C. Martin",
            "checksum": "VALID_MOD10",
            "timestamp": timestamp
          ]
        } else if mode == "student_id" {
          payload = [
            "type": "student_id",
            "studentId": "CTZ-2026-8842",
            "name": "Safeer Hussain",
            "department": "Computer Science & Engineering",
            "role": "Senior Mobile Architect / Honours",
            "clearance": "TIER_1_ADVANCED_RESEARCH_ACCESS",
            "cardHash": "SHA256:7e9a03b51fa2",
            "timestamp": timestamp
          ]
        } else {
          payload = [
            "type": "attendance_qr",
            "code": "LEC-CS801-4921",
            "courseCode": "CS-401",
            "courseTitle": "Distributed Systems & Cloud Computing",
            "room": "Alan Turing Hall 302",
            "sessionToken": UUID().uuidString,
            "checksum": "VERIFIED_SHA256",
            "timestamp": timestamp
          ]
        }
        result(payload)
      case "toggleTorch":
        self.isTorchOn = !self.isTorchOn
        result(self.isTorchOn)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
