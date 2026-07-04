import '../../../../core/storage/secure_storage.dart';

abstract class SettingsLocalDataSource {
  Future<String?> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<String?> getLanguage();
  Future<void> setLanguage(String lang);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl({required this.secureStorage});

  final SecureStorage secureStorage;

  @override
  Future<String?> getThemeMode() => secureStorage.getToken('theme_mode');

  @override
  Future<void> setThemeMode(String mode) =>
      secureStorage.saveToken('theme_mode', mode);

  @override
  Future<String?> getLanguage() => secureStorage.getToken('language');

  @override
  Future<void> setLanguage(String lang) =>
      secureStorage.saveToken('language', lang);
}
