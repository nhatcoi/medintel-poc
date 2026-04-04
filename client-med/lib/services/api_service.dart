import 'package:dio/dio.dart';
import 'package:med_intel_client/core/constants/app_constants.dart';

/// HTTP client dùng chung; gắn JWT qua interceptor sau khi có auth.
final class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: AppConstants.apiTimeout,
                receiveTimeout: AppConstants.apiTimeout,
                headers: {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  Dio get client => _dio;

  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
