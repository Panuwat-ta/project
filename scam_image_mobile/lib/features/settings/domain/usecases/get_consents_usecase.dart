import '../entities/consent_setting.dart';
import '../repositories/settings_repository.dart';

/// Retrieves the current [ConsentSetting] from the repository.
class GetConsentsUseCase {
  const GetConsentsUseCase(this.repository);

  final SettingsRepository repository;

  Future<ConsentSetting> call() => repository.getConsents();
}
