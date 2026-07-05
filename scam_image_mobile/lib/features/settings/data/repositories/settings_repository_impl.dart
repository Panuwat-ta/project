import '../../domain/entities/consent_setting.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/consent_setting_model.dart';

/// Concrete implementation of [SettingsRepository].
///
/// Delegates all remote calls to [SettingsRemoteDataSource] and handles
/// model ↔ entity conversion.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final SettingsRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource localDataSource;

  @override
  Future<ConsentSetting> getConsents() async {
    final json = await remoteDataSource.getConsents();
    return ConsentSettingModel.fromJson(json);
  }

  @override
  Future<void> updateConsents(ConsentSetting setting) =>
      remoteDataSource.updateConsents(
        ConsentSettingModel.fromDomain(setting).toJson(),
      );

  @override
  Future<void> exportPrivacyData() => remoteDataSource.exportPrivacyData();

  @override
  Future<void> deleteAccount() => remoteDataSource.deleteAccount();

  @override
  Future<String?> getThemeMode() => localDataSource.getThemeMode();

  @override
  Future<void> setThemeMode(String mode) =>
      localDataSource.setThemeMode(mode);

  @override
  Future<String?> getLanguage() => localDataSource.getLanguage();

  @override
  Future<void> setLanguage(String lang) =>
      localDataSource.setLanguage(lang);
}
