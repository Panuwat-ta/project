import '../repositories/settings_repository.dart';

/// Permanently deletes the authenticated user's account.
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this.repository);

  final SettingsRepository repository;

  Future<void> call() => repository.deleteAccount();
}
