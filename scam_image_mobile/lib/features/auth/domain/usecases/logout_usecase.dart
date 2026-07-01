import '../repositories/auth_repository.dart';

/// Signs the current user out, invalidating the session on the server
/// and clearing all locally stored tokens.
class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}
