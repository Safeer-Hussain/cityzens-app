package com.safeer.cityzens

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.safeer.cityzens/native_camera"
    private var isTorchOn = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeCameraSensor" -> {
                    val sensorInfo = mapOf(
                        "status" to "initialized",
                        "sensor" to "Sony IMX890 50MP (Binned 12.5MP)",
                        "focalLength" to "24mm f/1.8",
                        "fps" to 60,
                        "resolution" to "1920x1080",
                        "autofocus" to "Phase-Detection-AF",
                        "opticalStabilization" to true
                    )
                    result.success(sensorInfo)
                }
                "scanOpticalPayload" -> {
                    val mode = call.argument<String>("mode") ?: "attendance_qr"
                    val payload = when (mode) {
                        "library_isbn" -> mapOf(
                            "type" to "library_isbn",
                            "isbn" to "978-0134494166",
                            "title" to "Clean Architecture: A Craftsman's Guide",
                            "author" to "Robert C. Martin",
                            "checksum" to "VALID_MOD10",
                            "timestamp" to System.currentTimeMillis()
                        )
                        "student_id" -> mapOf(
                            "type" to "student_id",
                            "studentId" to "CTZ-2026-8842",
                            "name" to "Safeer Hussain",
                            "department" to "Computer Science & Engineering",
                            "role" to "Senior Mobile Architect / Honours",
                            "clearance" to "TIER_1_ADVANCED_RESEARCH_ACCESS",
                            "cardHash" to "SHA256:7e9a03b51fa2",
                            "timestamp" to System.currentTimeMillis()
                        )
                        else -> mapOf(
                            "type" to "attendance_qr",
                            "code" to "LEC-CS801-4921",
                            "courseCode" to "CS-401",
                            "courseTitle" to "Distributed Systems & Cloud Computing",
                            "room" to "Alan Turing Hall 302",
                            "sessionToken" to UUID.randomUUID().toString(),
                            "checksum" to "VERIFIED_SHA256",
                            "timestamp" to System.currentTimeMillis()
                        )
                    }
                    result.success(payload)
                }
                "toggleTorch" -> {
                    isTorchOn = !isTorchOn
                    result.success(isTorchOn)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
