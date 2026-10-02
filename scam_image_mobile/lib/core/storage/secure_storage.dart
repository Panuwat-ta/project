import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Token key constants used across the app.
const String kAccessToken = 'access_token';
const String kRefreshToken = 'refresh_token';
const String kTokenExpiresAt = 'expires_at';
const String kHasSeenOnboarding = 'has_seen_onboarding';

/// [SecureStorage] is a thin wrapper around [FlutterSecureStorage] that
/// provides typed, async helpers for token management.
class SecureStorage extends ChangeNotifier {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  int _authRevision = 0;
  bool _authSessionActive = true;
  Future<void> _authMutations = Future<void>.value();

  int get authRevision => _authRevision;
  bool get authSessionActive => _authSessionActive;

  void invalidateAuthSession() {
    _authRevision++;
    _authSessionActive = false;
    notifyListeners();
  }

  Future<T> _mutateAuth<T>(Future<T> Function() action) {
    final result = _authMutations.then((_) => action());
    _authMutations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  /// Serializes credential replacement with logout. A refresh begun in an
  /// older session cannot restore credentials after that session was cleared.
  Future<bool> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required int expectedRevision,
    String? expiresAt,
  }) => _mutateAuth(() async {
    if (expectedRevision != _authRevision) return false;
    await saveToken(kAccessToken, accessToken);
    await saveToken(kRefreshToken, refreshToken);
    if (expiresAt == null) {
      await deleteToken(kTokenExpiresAt);
    } else {
      await saveToken(kTokenExpiresAt, expiresAt);
    }
    final saved = expectedRevision == _authRevision;
    if (saved) {
      _authSessionActive = true;
      notifyListeners();
    }
    return saved;
  });

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

  /// Removes only authentication credentials, preserving onboarding and
  /// user preferences that share the same secure-storage backend.
  Future<void> clearAuthTokens() {
    invalidateAuthSession();
    return _mutateAuth(() async {
      await deleteToken(kAccessToken);
      await deleteToken(kRefreshToken);
      await deleteToken(kTokenExpiresAt);
    });
  }

  /// Deletes **all** entries managed by this storage instance.
  Future<void> deleteAll() {
    invalidateAuthSession();
    return _mutateAuth(() => _storage.deleteAll());
  }
}
