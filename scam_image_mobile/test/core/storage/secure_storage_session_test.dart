import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';

class _MemoryStorage extends SecureStorage {
  final values = <String, String>{};
  Completer<void>? accessWrite;
  @override
  Future<void> saveToken(String key, String value) async {
    if (key == kAccessToken && accessWrite != null) {
      final pending = accessWrite!;
      accessWrite = null;
      await pending.future;
    }
    values[key] = value;
  }

  @override
  Future<void> deleteToken(String key) async => values.remove(key);
  @override
  Future<String?> getToken(String key) async => values[key];
}

void main() {
  test('old refresh cannot restore credentials after logout', () async {
    final storage = _MemoryStorage();
    final revision = storage.authRevision;
    await storage.clearAuthTokens();
    final saved = await storage.saveAuthTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      expectedRevision: revision,
    );
    expect(saved, isFalse);
    expect(storage.values, isEmpty);
  });
  test(
    'logout and new login serialize behind an in-flight credential write',
    () async {
      final storage = _MemoryStorage();
      final pending = Completer<void>();
      storage.accessWrite = pending;
      final oldSave = storage.saveAuthTokens(
        accessToken: 'old',
        refreshToken: 'old-refresh',
        expectedRevision: storage.authRevision,
      );
      await Future<void>.delayed(Duration.zero);
      final logout = storage.clearAuthTokens();
      final newSave = storage.saveAuthTokens(
        accessToken: 'new',
        refreshToken: 'new-refresh',
        expectedRevision: storage.authRevision,
      );
      pending.complete();
      expect(await oldSave, isFalse);
      await logout;
      expect(await newSave, isTrue);
      expect(storage.values[kAccessToken], 'new');
      expect(storage.values[kRefreshToken], 'new-refresh');
    },
  );
  test(
    'replacing credentials removes stale expiry and preserves onboarding',
    () async {
      final storage = _MemoryStorage()
        ..values[kTokenExpiresAt] = 'old'
        ..values[kHasSeenOnboarding] = 'true';
      await storage.saveAuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        expectedRevision: storage.authRevision,
      );
      expect(storage.values[kTokenExpiresAt], isNull);
      await storage.clearAuthTokens();
      expect(storage.values, {kHasSeenOnboarding: 'true'});
    },
  );
}
