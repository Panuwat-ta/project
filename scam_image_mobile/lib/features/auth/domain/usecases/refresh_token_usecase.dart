import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

/// Attempts to refresh the access token using the stored refresh token.
///
/// Returns a new [AuthToken] on success, or `null` if no refresh token exists.
/// Propagates [AuthException] if the refresh token is expired or invalid.
class RefreshTokenUseCase {
  final AuthRepository repository;

  const RefreshTokenUseCase(this.repository);

  Future<AuthToken?> call() {
    return repository.refreshToken();
  }
}
