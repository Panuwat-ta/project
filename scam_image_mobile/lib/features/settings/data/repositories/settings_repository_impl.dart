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
  Future<ConsentSetting> getConsents() => localDataSource.getConsents();

  @override
  Future<void> updateConsents(ConsentSetting setting) =>
      localDataSource.saveConsents(setting);

  @override
  Future<void> exportPrivacyData() {
    // The current server does not expose /privacy/export yet. Fail locally
    // instead of issuing a known-404 request and pretending export started.
    throw UnsupportedError('Privacy export is not available on this server');
  }

  @override
  Future<void> deleteAccount(String password) =>
      remoteDataSource.deleteAccount(password);

  @override
  Future<ThemeMode> getThemeMode() => localDataSource.getThemeMode();

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      localDataSource.saveThemeMode(mode);

  @override
  Future<String> getLanguage() => localDataSource.getLanguage();

  @override
  Future<void> saveLanguage(String language) =>
      localDataSource.saveLanguage(language);

  @override
  Future<int> getCacheSizeBytes() => localDataSource.getCacheSizeBytes();

  @override
  Future<void> clearCache() => localDataSource.clearCache();
}
