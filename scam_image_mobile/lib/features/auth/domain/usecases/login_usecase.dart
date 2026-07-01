import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

/// Authenticates a user by email and password.
///
/// On success returns the authenticated [User].
/// Propagates [AuthException] or [NetworkException] on failure.
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<User> call(LoginParams params) {
    return repository.login(
      email: params.email,
      password: params.password,
    );
  }
}
