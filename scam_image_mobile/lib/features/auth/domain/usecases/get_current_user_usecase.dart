import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Retrieves the currently authenticated user from the remote source.
///
/// Returns `null` if the user is not signed in or the session has expired.
class GetCurrentUserUseCase {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  Future<User?> call() {
    return repository.getCurrentUser();
  }
}
