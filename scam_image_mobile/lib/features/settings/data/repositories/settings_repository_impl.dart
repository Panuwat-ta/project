import 'package:flutter/material.dart';
import '../../domain/entities/consent_setting.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';

/// Concrete implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final SettingsRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource localDataSource;

  @override
  Future<ConsentSetting> getConsents() async {
    // Return from local storage since backend is mocked/unavailable
    return localDataSource.getConsents();
  }

  @override
  Future<void> updateConsents(ConsentSetting setting) async {
    // Save locally
    await localDataSource.saveConsents(setting);
    // Optionally fire and forget remote
    try {
      await remoteDataSource.updateConsents({'dummy': 'data'});
    } catch (_) {}
  }

  @override
  Future<void> exportPrivacyData() => remoteDataSource.exportPrivacyData();

  @override
  Future<void> deleteAccount() => remoteDataSource.deleteAccount();

  @override
  Future<ThemeMode> getThemeMode() => localDataSource.getThemeMode();

  @override
  Future<void> saveThemeMode(ThemeMode mode) => localDataSource.saveThemeMode(mode);

  @override
  Future<String> getLanguage() => localDataSource.getLanguage();

  @override
  Future<void> saveLanguage(String language) => localDataSource.saveLanguage(language);
}
