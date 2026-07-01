import 'package:dio/dio.dart';

import '../../core/storage/secure_storage.dart';
import '../network/api_endpoints.dart';

/// Factory that creates a configured [Dio] instance with all interceptors.
class DioClient {
  DioClient._();

  static Dio createDio({
    required SecureStorage secureStorage,
    String baseUrl = 'http://localhost:8000',
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(secureStorage: secureStorage, dio: dio),
      LogInterceptor(request: false, responseBody: false),
    ]);

    return dio;
  }
}

/// Attaches the Bearer access token from [SecureStorage] to every outgoing
/// request. On a 401 response it attempts a token refresh; if the refresh
/// also fails it clears all stored tokens so the app can redirect to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.dio,
  });

  final SecureStorage secureStorage;

  /// The same [Dio] instance so we can retry with it after a token refresh.
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await secureStorage.getToken(kAccessToken);
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh for 401 Unauthorized errors.
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Prevent refresh-endpoint itself from looping.
    if (err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      await secureStorage.deleteAll();
      handler.next(err);
      return;
    }

    try {
      final refreshToken = await secureStorage.getToken(kRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        await secureStorage.deleteAll();
        handler.next(err);
        return;
      }

      // Attempt token refresh using a fresh Dio (avoids interceptor loop).
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data == null) {
        await secureStorage.deleteAll();
        handler.next(err);
        return;
      }

      final newAccessToken =
          data['accessToken'] as String? ?? data['access_token'] as String?;
      final newRefreshToken =
          data['refreshToken'] as String? ?? data['refresh_token'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        await secureStorage.deleteAll();
        handler.next(err);
        return;
      }

      await secureStorage.saveToken(kAccessToken, newAccessToken);
      await secureStorage.saveToken(kRefreshToken, newRefreshToken);

      // Retry the original request with the new token.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      await secureStorage.deleteAll();
      handler.next(err);
    }
  }
}
