import 'package:dio/dio.dart';

import 'mock_network_interceptor.dart';
import '../services/telemetry_service.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required TelemetryService telemetryService}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.campus.cityzens.internal/v1',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    _dio.interceptors.add(
      MockNetworkInterceptor(telemetryService: telemetryService),
    );
  }

  Dio get dio => _dio;
}
