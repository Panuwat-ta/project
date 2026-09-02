import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Total size in bytes of on-device cache files (temp + image cache).
  Future<int> getCacheSizeBytes();

  /// Deletes all on-device cache files (temp + downloaded image cache).
  Future<void> clearCache();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl({required this.secureStorage});

  final SecureStorage secureStorage;

  @override
  Future<ThemeMode> getThemeMode() async {
    final mode = await secureStorage.getToken(kThemeMode);
    if (mode == 'ThemeMode.dark') return ThemeMode.dark;
    return ThemeMode.light;
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

  @override
  Future<int> getCacheSizeBytes() async {
    try {
      final dir = await getTemporaryDirectory();
      return await _directorySize(dir);
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> clearCache() async {
    // Clear the downloaded-image cache (cached_network_image) first.
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}

    // Then remove leftover temp files (scan crops, etc.).
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        await for (final entity in dir.list(followLinks: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<int> _directorySize(Directory dir) async {
    if (!dir.existsSync()) return 0;
    int total = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }
}
