import 'package:dio/dio.dart';

import '../../../../core/network/dio_error_mapper.dart';
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
    this.clearUserCache,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  int _sessionGeneration = 0;
  final Future<void> Function()? clearUserCache;

  void _requireCurrentSession(int generation) {
    if (generation != _sessionGeneration) {
      throw const AuthException('Session ended');
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final generation = ++_sessionGeneration;
    await localDataSource.clearTokens();
    await clearUserCache?.call();
    _requireCurrentSession(generation);
    try {
      final (user, token) = await remoteDataSource.login(
        email: email,
        password: password,
      );
      _requireCurrentSession(generation);
      await saveTokens(token);
      return user;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
    // Typed exceptions from the data source propagate as-is.
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
    required bool systemConsent,
    required bool researchConsent,
  }) async {
    final generation = ++_sessionGeneration;
    await localDataSource.clearTokens();
    await clearUserCache?.call();
    _requireCurrentSession(generation);
    try {
      final (user, token) = await remoteDataSource.register(
        email: email,
        password: password,
        displayName: displayName,
        systemConsent: systemConsent,
        researchConsent: researchConsent,
      );
      _requireCurrentSession(generation);
      await saveTokens(token);
      return user;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    _sessionGeneration++;
    await localDataSource.clearTokens();
    await clearUserCache?.call();
    try {
      // The current backend uses stateless JWT logout, so this is best-effort.
      await remoteDataSource.logout();
    } catch (_) {
      // Network/server failure must not trap the user in an authenticated UI.
    }
  }

  @override
  Future<AuthToken?> refreshToken() async {
    final generation = _sessionGeneration;
    final storedRefreshToken = await localDataSource.getRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) return null;

    try {
      final token = await remoteDataSource.refreshToken(storedRefreshToken);
      _requireCurrentSession(generation);
      if (token != null) {
        await localDataSource.saveTokens(token);
      }
      return token;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final generation = _sessionGeneration;
    try {
      final user = await remoteDataSource.getMe();
      _requireCurrentSession(generation);
      return user;
    } on DioException catch (e) {
      throw mapDioException(e);
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
  Future<void> clearTokens() {
    _sessionGeneration++;
    return localDataSource.clearTokens();
  }

  @override
  Future<bool> hasValidToken() => localDataSource.hasValidToken();

  @override
  Future<bool> hasSeenOnboarding() => localDataSource.hasSeenOnboarding();

  @override
  Future<void> markOnboardingSeen() => localDataSource.markOnboardingSeen();

  // ── Helper ─────────────────────────────────────────────────────────────────
}
