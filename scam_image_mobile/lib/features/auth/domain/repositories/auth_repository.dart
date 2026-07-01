import '../entities/auth_token.dart';
import '../entities/user.dart';

/// Abstract interface for the authentication repository.
///
/// Implementations throw typed [Exception]s from `core/errors/exceptions.dart`
/// (e.g., [AuthException], [NetworkException], [ServerException]) on failure.
abstract class AuthRepository {
  /// Authenticates a user with email and password.
  /// Throws [AuthException] on invalid credentials, [NetworkException] on connectivity issues.
  Future<User> login({required String email, required String password});

  /// Creates a new account and returns the newly authenticated user.
  /// Throws [ServerException] if the email is already in use.
  Future<User> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Invalidates the current session on the server and clears local tokens.
  Future<void> logout();

  /// Attempts to obtain a new [AuthToken] using the stored refresh token.
  /// Returns `null` if no refresh token is available.
  /// Throws [AuthException] if the refresh token is expired or invalid.
  Future<AuthToken?> refreshToken();

  /// Returns the currently authenticated [User], or `null` if not signed in.
  Future<User?> getCurrentUser();

  /// Persists [token] to secure storage.
  Future<void> saveTokens(AuthToken token);

  /// Removes all stored tokens from secure storage.
  Future<void> clearTokens();

  /// Returns `true` if a non-expired access token is present in storage.
  Future<bool> hasValidToken();
}
