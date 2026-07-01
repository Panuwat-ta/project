import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_token_model.dart';

/// Concrete implementation of [AuthRepository].
///
/// Orchestrates between [AuthRemoteDataSource] and [AuthLocalDataSource],
/// mapping raw exceptions into the typed exceptions defined in
/// `core/errors/exceptions.dart`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );
      return user;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    // Typed exceptions from the data source propagate as-is.
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await remoteDataSource.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      return user;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } finally {
      // Always clear local tokens regardless of server response.
      await localDataSource.clearTokens();
    }
  }

  @override
  Future<AuthToken?> refreshToken() async {
    final storedRefreshToken = await localDataSource.getRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) return null;

    try {
      final token =
          await remoteDataSource.refreshToken(storedRefreshToken);
      if (token != null) {
        await localDataSource.saveTokens(token);
      }
      return token;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return await remoteDataSource.getMe();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> saveTokens(AuthToken token) async {
    final model = token is AuthTokenModel
        ? token
        : AuthTokenModel(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: token.expiresAt,
          );
    await localDataSource.saveTokens(model);
  }

  @override
  Future<void> clearTokens() => localDataSource.clearTokens();

  @override
  Future<bool> hasValidToken() => localDataSource.hasValidToken();

  // ── Helper ─────────────────────────────────────────────────────────────────

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
