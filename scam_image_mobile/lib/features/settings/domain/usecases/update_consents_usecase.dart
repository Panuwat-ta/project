import '../entities/consent_setting.dart';
import '../repositories/settings_repository.dart';

/// Persists updated consent preferences via the repository.
class UpdateConsentsUseCase {
  const UpdateConsentsUseCase(this.repository);

  final SettingsRepository repository;

  Future<void> call(ConsentSetting setting) =>
      repository.updateConsents(setting);
}
