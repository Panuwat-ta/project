import '../../domain/entities/consent_setting.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/consent_setting_model.dart';

/// Concrete implementation of [SettingsRepository].
///
/// Delegates all remote calls to [SettingsRemoteDataSource] and handles
/// model ↔ entity conversion.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required this.remoteDataSource});

  final SettingsRemoteDataSource remoteDataSource;

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
}
