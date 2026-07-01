import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token key constants used across the app.
const String kAccessToken = 'access_token';
const String kRefreshToken = 'refresh_token';
const String kHasSeenOnboarding = 'has_seen_onboarding';

/// [SecureStorage] is a thin wrapper around [FlutterSecureStorage] that
/// provides typed, async helpers for token management.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  /// Saves [value] under [key] in the secure keychain/keystore.
  Future<void> saveToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Returns the value stored under [key], or `null` if not found.
  Future<String?> getToken(String key) async {
    return _storage.read(key: key);
  }

  /// Deletes the entry for [key].
  Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }

  /// Deletes **all** entries managed by this storage instance.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
