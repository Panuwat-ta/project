import '../../../../core/storage/secure_storage.dart';
import '../models/auth_token_model.dart';

/// Handles local persistence of auth tokens via [SecureStorage].
class AuthLocalDataSource {
  AuthLocalDataSource({required this.secureStorage});

  final SecureStorage secureStorage;

  /// Persists both access and refresh tokens (and optional expiry) to secure
  /// storage.
  Future<void> saveTokens(AuthTokenModel token) async {
    await secureStorage.saveToken(kAccessToken, token.accessToken);
    await secureStorage.saveToken(kRefreshToken, token.refreshToken);
    if (token.expiresAt != null) {
      await secureStorage.saveToken(
        _kExpiresAt,
        token.expiresAt!.toIso8601String(),
      );
    }
  }

  /// Returns the stored access token, or `null` if not present.
  Future<String?> getAccessToken() => secureStorage.getToken(kAccessToken);

  /// Returns the stored refresh token, or `null` if not present.
  Future<String?> getRefreshToken() => secureStorage.getToken(kRefreshToken);

  /// Removes all stored tokens from secure storage.
  Future<void> clearTokens() => secureStorage.deleteAll();

  /// Returns `true` if an access token is present in storage.
  ///
  /// This is a lightweight check (existence only).  Callers that need
  /// cryptographic validity should use the refresh flow.
  Future<bool> hasValidToken() async {
    final token = await secureStorage.getToken(kAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<bool> hasSeenOnboarding() async {
    final seen = await secureStorage.getToken(kHasSeenOnboarding);
    return seen == 'true';
  }

  Future<void> markOnboardingSeen() async {
    await secureStorage.saveToken(kHasSeenOnboarding, 'true');
  }
}

/// Key used to store the token expiry timestamp.
const String _kExpiresAt = 'expires_at';
