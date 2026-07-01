import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Contract for the remote authentication data source.
abstract class AuthRemoteDataSource {
  /// Authenticates the user and returns the authenticated [UserModel].
  ///
  /// Throws [AuthException] on invalid credentials (401/403).
  /// Throws [ServerException] on other non-2xx responses.
  /// Throws [NetworkException] on connectivity errors.
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Registers a new account and returns the authenticated [UserModel].
  ///
  /// Throws [ServerException] if the email is already taken (409/422).
  /// Throws [NetworkException] on connectivity errors.
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Invalidates the current session server-side.
  ///
  /// Throws [NetworkException] on connectivity errors.
  Future<void> logout();

  /// Exchanges a refresh token for a new [AuthTokenModel].
  ///
  /// Returns `null` if no refresh token is provided.
  /// Throws [AuthException] if the refresh token is expired or invalid.
  Future<AuthTokenModel?> refreshToken(String refreshToken);

  /// Returns the currently authenticated user from `GET /auth/me`.
  ///
  /// Throws [AuthException] on 401.
  /// Throws [NetworkException] on connectivity errors.
  Future<UserModel> getMe();
}

/// Concrete implementation of [AuthRemoteDataSource] backed by [Dio].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final body = _requireBody(response);
      // The server may wrap the user in a 'user' key alongside tokens.
      final userJson = body['user'] as Map<String, dynamic>? ?? body;
      _saveTokensFromBody(body);
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      final body = _requireBody(response);
      final userJson = body['user'] as Map<String, dynamic>? ?? body;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post<void>(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<AuthTokenModel?> refreshToken(String refreshToken) async {
    if (refreshToken.isEmpty) return null;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );
      final body = _requireBody(response);
      return AuthTokenModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response =
          await dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      final body = _requireBody(response);
      return UserModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const ServerException('Empty response body');
    }
    return body;
  }

  /// If the login/register response already contains token fields, save them
  /// directly here so the interceptor has them for subsequent requests.
  void _saveTokensFromBody(Map<String, dynamic> body) {
    // Intentionally left empty — token persistence is handled by
    // [AuthRepositoryImpl] after this method returns, keeping concerns
    // separated.  The stub is here so the flow is self-documenting.
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(e.message ?? 'Connection error');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            e.response?.data?['message'] as String? ?? 'Unauthorised',
          );
        }
        return ServerException(
          e.response?.data?['message'] as String? ?? 'Server error',
          statusCode: statusCode,
        );
      default:
        return NetworkException(e.message ?? 'Network error');
    }
  }
}
