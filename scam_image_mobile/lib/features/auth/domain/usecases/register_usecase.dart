import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String displayName;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

/// Creates a new user account and returns the authenticated [User].
///
/// Propagates [ServerException] if the email is already registered,
/// or [NetworkException] on connectivity issues.
class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<User> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}
