import 'dart:async';
import 'package:dio/dio.dart';
import '../services/telemetry_service.dart';

class MockNetworkInterceptor extends Interceptor {
  final TelemetryService telemetryService;

  MockNetworkInterceptor({required this.telemetryService});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final latency = telemetryService.simulatedLatencyMs;
    await Future.delayed(Duration(milliseconds: latency));

    if (telemetryService.consume503Trigger()) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            statusMessage: 'Simulated 503 Service Unavailable (Testing Resilience)',
            data: {'error': 'Temporary campus gateway failure - retrying with exponential backoff'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    }

    return handler.next(options);
  }
}
