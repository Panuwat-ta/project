import 'dart:convert';

import '../../../../core/storage/secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_token_model.dart';

/// Handles local persistence of auth tokens via [SecureStorage].
class AuthLocalDataSource {
  AuthLocalDataSource({required this.secureStorage});

  final SecureStorage secureStorage;

  /// Persists both access and refresh tokens (and optional expiry) to secure
  /// storage.
  Future<void> saveTokens(AuthTokenModel token) async {
    final saved = await secureStorage.saveAuthTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresAt: token.expiresAt?.toIso8601String(),
      expectedRevision: secureStorage.authRevision,
    );
    if (!saved) {
      throw const AuthException('Session ended during credential save');
    }
  }

  /// Returns the stored access token, or `null` if not present.
  Future<String?> getAccessToken() => secureStorage.getToken(kAccessToken);

  /// Returns the stored refresh token, or `null` if not present.
  Future<String?> getRefreshToken() => secureStorage.getToken(kRefreshToken);

  /// Removes auth credentials only. Onboarding/settings must survive logout.
  Future<void> clearTokens() => secureStorage.clearAuthTokens();

  /// Returns `true` when a non-empty access token has not expired.
  ///
  /// The backend currently encodes expiry in the JWT `exp` claim rather than
  /// returning a separate expiry field, so we use a persisted expiry when one
  /// exists and otherwise read `exp` from the JWT payload. This is only a local
  /// freshness check; the server remains authoritative for token validity.
  Future<bool> hasValidToken() async {
    if (!secureStorage.authSessionActive) return false;
    final token = await secureStorage.getToken(kAccessToken);
    if (token == null || token.isEmpty) return false;

    final storedExpiry = await secureStorage.getToken(kTokenExpiresAt);
    DateTime? expiresAt;
    if (storedExpiry != null && storedExpiry.isNotEmpty) {
      expiresAt = DateTime.tryParse(storedExpiry)?.toUtc();
    }
    expiresAt ??= _jwtExpiry(token);

    if (expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc())) {
      await secureStorage.clearAuthTokens();
      return false;
    }
    return true;
  }

  DateTime? _jwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      // Opaque/non-JWT tokens are still allowed; the server will validate them.
      return null;
    }
  }

  Future<bool> hasSeenOnboarding() async {
    final seen = await secureStorage.getToken(kHasSeenOnboarding);
    return seen == 'true';
  }

  Future<void> markOnboardingSeen() async {
    await secureStorage.saveToken(kHasSeenOnboarding, 'true');
  }
}
