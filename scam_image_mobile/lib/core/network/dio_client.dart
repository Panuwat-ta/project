import 'package:dio/dio.dart';

import '../../core/storage/secure_storage.dart';
import '../network/api_endpoints.dart';

/// Factory that creates a configured [Dio] instance with all interceptors.
class DioClient {
  DioClient._();

  static Dio createDio({
    required SecureStorage secureStorage,
    required String baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // No network logger in any build: URL/query/error output can contain PII.
    dio.interceptors.add(
      AuthInterceptor(secureStorage: secureStorage, dio: dio),
    );

    return dio;
  }
}

/// Attaches the Bearer access token from [SecureStorage] to every outgoing
/// request. On a 401 response it attempts a token refresh; if the refresh
/// also fails it clears all stored tokens so the app can redirect to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.secureStorage, required this.dio});

  final SecureStorage secureStorage;

  /// The same [Dio] instance so we can retry with it after a token refresh.
  final Dio dio;

  Future<({String accessToken, String refreshToken})?>? _refreshFuture;

  int? _refreshRevision;

  bool _isPublicAuthPath(String path) {
    return path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.register) ||
        path.contains(ApiEndpoints.refresh);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['_sessionRevision'] ??= secureStorage.authRevision;
    if (!_isPublicAuthPath(options.path)) {
      if (options.extra['_sessionRevision'] != secureStorage.authRevision ||
          !secureStorage.authSessionActive) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: 'Session ended',
          ),
        );
        return;
      }
      final accessToken = await secureStorage.getToken(kAccessToken);
      if (options.extra['_sessionRevision'] != secureStorage.authRevision ||
          !secureStorage.authSessionActive) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: 'Session ended',
          ),
        );
        return;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra['_sessionRevision'] !=
        secureStorage.authRevision) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra['_authRetry'] == true) {
      await secureStorage.clearAuthTokens();
      handler.next(err);
      return;
    }

    final path = err.requestOptions.path;
    if (path.contains(ApiEndpoints.refresh)) {
      await secureStorage.clearAuthTokens();
      handler.next(err);
      return;
    }

    // Invalid login/register credentials must never trigger a refresh of a
    // previous session.
    if (path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.register)) {
      handler.next(err);
      return;
    }

    if (!secureStorage.authSessionActive) {
      handler.next(err);
      return;
    }

    final revision = secureStorage.authRevision;
    Future<({String accessToken, String refreshToken})?>? refresh;
    try {
      final refreshToken = await secureStorage.getToken(kRefreshToken);
      if (revision != secureStorage.authRevision) {
        handler.next(err);
        return;
      }
      if (refreshToken == null || refreshToken.isEmpty) {
        await secureStorage.clearAuthTokens();
        handler.next(err);
        return;
      }

      if (_refreshRevision != revision) {
        _refreshFuture = null;
        _refreshRevision = revision;
      }
      refresh = _refreshFuture ??= _performRefresh(refreshToken);
      final tokens = await refresh;
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;

      if (tokens == null) {
        if (revision == secureStorage.authRevision) {
          await secureStorage.clearAuthTokens();
        }
        handler.next(err);
        return;
      }

      final saved = await secureStorage.saveAuthTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expectedRevision: revision,
      );
      if (!saved) {
        handler.next(err);
        return;
      }

      final retryOptions = err.requestOptions;
      retryOptions.extra['_authRetry'] = true;
      retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      if (retryOptions.data is FormData) {
        retryOptions.data = (retryOptions.data as FormData).clone();
      }

      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
      if (revision == secureStorage.authRevision) {
        await secureStorage.clearAuthTokens();
      }
      handler.next(err);
    } catch (_) {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
      if (revision == secureStorage.authRevision) {
        await secureStorage.clearAuthTokens();
      }
      handler.next(err);
    }
  }

  Future<({String accessToken, String refreshToken})?> _performRefresh(
    String refreshToken,
  ) async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        sendTimeout: dio.options.sendTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data == null) return null;

      final accessToken =
          data['accessToken'] as String? ?? data['access_token'] as String?;
      final nextRefreshToken =
          data['refreshToken'] as String? ?? data['refresh_token'] as String?;
      if (accessToken == null ||
          accessToken.isEmpty ||
          nextRefreshToken == null ||
          nextRefreshToken.isEmpty) {
        return null;
      }
      return (accessToken: accessToken, refreshToken: nextRefreshToken);
    } finally {
      refreshDio.close(force: true);
    }
  }
}
