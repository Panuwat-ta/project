<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/consent_setting.dart';

const String kThemeMode = 'settings_theme_mode';
const String kLanguage = 'settings_language';
const String kConsentProcessing = 'settings_consent_processing';
const String kConsentHistory = 'settings_consent_history';
const String kConsentResearch = 'settings_consent_research';

abstract class SettingsLocalDataSource {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
  
  Future<String> getLanguage();
  Future<void> saveLanguage(String language);
  
  Future<ConsentSetting> getConsents();
  Future<void> saveConsents(ConsentSetting setting);
=======
import '../../../../core/storage/secure_storage.dart';

abstract class SettingsLocalDataSource {
  Future<String?> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<String?> getLanguage();
  Future<void> setLanguage(String lang);
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl({required this.secureStorage});

  final SecureStorage secureStorage;

  @override
<<<<<<< HEAD
  Future<ThemeMode> getThemeMode() async {
    final mode = await secureStorage.getToken(kThemeMode);
    if (mode == 'ThemeMode.dark') return ThemeMode.dark;
    if (mode == 'ThemeMode.light') return ThemeMode.light;
    return ThemeMode.system;
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await secureStorage.saveToken(kThemeMode, mode.toString());
  }

  @override
  Future<String> getLanguage() async {
    final lang = await secureStorage.getToken(kLanguage);
    return lang ?? 'th';
  }

  @override
  Future<void> saveLanguage(String language) async {
    await secureStorage.saveToken(kLanguage, language);
  }

  @override
  Future<ConsentSetting> getConsents() async {
    final processing = await secureStorage.getToken(kConsentProcessing) ?? 'true';
    final history = await secureStorage.getToken(kConsentHistory) ?? 'true';
    final research = await secureStorage.getToken(kConsentResearch) ?? 'false';
    
    return ConsentSetting(
      processingConsent: processing == 'true',
      historyConsent: history == 'true',
      researchConsent: research == 'true',
    );
  }

  @override
  Future<void> saveConsents(ConsentSetting setting) async {
    await secureStorage.saveToken(kConsentProcessing, setting.processingConsent.toString());
    await secureStorage.saveToken(kConsentHistory, setting.historyConsent.toString());
    await secureStorage.saveToken(kConsentResearch, setting.researchConsent.toString());
  }
=======
  Future<String?> getThemeMode() => secureStorage.getToken('theme_mode');

  @override
  Future<void> setThemeMode(String mode) =>
      secureStorage.saveToken('theme_mode', mode);

  @override
  Future<String?> getLanguage() => secureStorage.getToken('language');

  @override
  Future<void> setLanguage(String lang) =>
      secureStorage.saveToken('language', lang);
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099
}
