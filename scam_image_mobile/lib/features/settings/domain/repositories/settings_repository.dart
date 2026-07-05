import 'package:flutter/material.dart';
import '../entities/consent_setting.dart';

/// Abstract contract for the settings feature data layer.
abstract class SettingsRepository {
  /// Fetches the current consent settings for the authenticated user.
  Future<ConsentSetting> getConsents();

  /// Persists updated [setting] to the remote backend.
  Future<void> updateConsents(ConsentSetting setting);

  /// Requests a privacy data export for the authenticated user.
  Future<void> exportPrivacyData();

  /// Permanently deletes the authenticated user's account.
  Future<void> deleteAccount();

  /// Gets the saved theme mode.
  Future<ThemeMode> getThemeMode();

  /// Saves the theme mode.
  Future<void> saveThemeMode(ThemeMode mode);

  /// Gets the saved language.
  Future<String> getLanguage();

  /// Saves the language.
  Future<void> saveLanguage(String language);
}
