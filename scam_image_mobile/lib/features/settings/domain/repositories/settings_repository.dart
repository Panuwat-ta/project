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

  /// Retrieves the saved theme mode.
  Future<String?> getThemeMode();

  /// Saves the theme mode.
  Future<void> setThemeMode(String mode);

  /// Retrieves the saved language.
  Future<String?> getLanguage();

  /// Saves the language.
  Future<void> setLanguage(String lang);
}
