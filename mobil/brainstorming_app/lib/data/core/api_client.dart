import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart'; // baseUrl buradan geliyor

class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient(AppConfig config)
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          } else {
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;

    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(
      path.startsWith('/') ? path : '/$path',
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(
      path.startsWith('/') ? path : '/$path',
      data: data,
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(
      path.startsWith('/') ? path : '/$path',
      data: data,
    );
  }

  /// PATCH desteği (topics için lazım)
  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(
      path.startsWith('/') ? path : '/$path',
      data: data,
    );
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(
      path.startsWith('/') ? path : '/$path',
      data: data,
    );
  }
}

/// global provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(config);
});
