import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/native_camera_bridge.dart';
import '../services/telemetry_service.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/campus_feed_repository.dart';
import '../../data/repositories/scanner_repository.dart';
import '../../data/repositories/transcript_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/study_room_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator({
  SharedPreferences? testPrefs,
  AppDatabase? testDb,
}) async {
  // 1. SharedPreferences
  final prefs = testPrefs ?? await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // 2. Core Services
  final db = testDb ?? AppDatabase();
  sl.registerSingleton<AppDatabase>(db);

  final telemetry = TelemetryService();
  sl.registerSingleton<TelemetryService>(telemetry);

  final connectivity = ConnectivityService();
  sl.registerSingleton<ConnectivityService>(connectivity);

  final cameraBridge = NativeCameraBridge();
  sl.registerSingleton<NativeCameraBridge>(cameraBridge);

  final apiClient = ApiClient(telemetryService: telemetry);
  sl.registerSingleton<ApiClient>(apiClient);

  // 3. Repositories
  sl.registerSingleton<AttendanceRepository>(
    AttendanceRepository(database: db),
  );

  sl.registerSingleton<LibraryRepository>(LibraryRepository(database: db));

  sl.registerSingleton<CampusFeedRepository>(
    CampusFeedRepository(database: db),
  );

  sl.registerSingleton<ScannerRepository>(
    ScannerRepository(bridge: cameraBridge),
  );

  sl.registerSingleton<TranscriptRepository>(
    TranscriptRepository(database: db),
  );

  sl.registerSingleton<ExamRepository>(ExamRepository(database: db));
  sl.registerSingleton<StudyRoomRepository>(StudyRoomRepository(database: db));
}
