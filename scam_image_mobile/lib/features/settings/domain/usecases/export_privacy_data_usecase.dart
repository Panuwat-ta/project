import '../repositories/settings_repository.dart';

/// Requests a privacy data export for the authenticated user.
class ExportPrivacyDataUseCase {
  const ExportPrivacyDataUseCase(this.repository);

  final SettingsRepository repository;

  Future<void> call() => repository.exportPrivacyData();
}
