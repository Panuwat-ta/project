import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:scam_image_mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:scam_image_mobile/features/auth/data/models/auth_token_model.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

String _jwtWithExp(DateTime expiry) {
  String enc(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final exp = expiry.toUtc().millisecondsSinceEpoch ~/ 1000;
  return '${enc({'alg': 'HS256', 'typ': 'JWT'})}.${enc({'exp': exp})}.sig';
}

void main() {
  late MockSecureStorage storage;
  late AuthLocalDataSource dataSource;

  setUp(() {
    storage = MockSecureStorage();
    dataSource = AuthLocalDataSource(secureStorage: storage);
  });

  test(
    'clearTokens removes auth credentials without deleting all storage',
    () async {
      when(() => storage.clearAuthTokens()).thenAnswer((_) async {});

      await dataSource.clearTokens();

      verify(() => storage.clearAuthTokens()).called(1);
      verifyNever(() => storage.deleteAll());
    },
  );

  test(
    'saveTokens removes stale persisted expiry when new token has no expiry',
    () async {
      when(() => storage.saveToken(any(), any())).thenAnswer((_) async {});
      when(() => storage.deleteToken(any())).thenAnswer((_) async {});

      await dataSource.saveTokens(
        const AuthTokenModel(accessToken: 'access', refreshToken: 'refresh'),
      );

      verify(() => storage.saveToken(kAccessToken, 'access')).called(1);
      verify(() => storage.saveToken(kRefreshToken, 'refresh')).called(1);
      verify(() => storage.deleteToken(kTokenExpiresAt)).called(1);
    },
  );

  test('saveTokens persists an explicit expiry', () async {
    final expiry = DateTime.utc(2030, 1, 1);
    when(() => storage.saveToken(any(), any())).thenAnswer((_) async {});

    await dataSource.saveTokens(
      AuthTokenModel(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: expiry,
      ),
    );

    verify(
      () => storage.saveToken(kTokenExpiresAt, expiry.toIso8601String()),
    ).called(1);
    verifyNever(() => storage.deleteToken(kTokenExpiresAt));
  });

  test('hasValidToken returns false for missing access token', () async {
    when(() => storage.getToken(kAccessToken)).thenAnswer((_) async => null);

    expect(await dataSource.hasValidToken(), isFalse);
    verifyNever(() => storage.getToken(kTokenExpiresAt));
  });

  test(
    'hasValidToken rejects expired persisted expiry and clears auth tokens',
    () async {
      when(
        () => storage.getToken(kAccessToken),
      ).thenAnswer((_) async => 'opaque');
      when(() => storage.getToken(kTokenExpiresAt)).thenAnswer(
        (_) async => DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      );
      when(() => storage.clearAuthTokens()).thenAnswer((_) async {});

      expect(await dataSource.hasValidToken(), isFalse);
      verify(() => storage.clearAuthTokens()).called(1);
    },
  );

  test('hasValidToken reads JWT exp when no persisted expiry exists', () async {
    final token = _jwtWithExp(
      DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
    when(() => storage.getToken(kAccessToken)).thenAnswer((_) async => token);
    when(() => storage.getToken(kTokenExpiresAt)).thenAnswer((_) async => null);

    expect(await dataSource.hasValidToken(), isTrue);
  });

  test('expired JWT exp is rejected and clears auth tokens', () async {
    final token = _jwtWithExp(
      DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
    );
    when(() => storage.getToken(kAccessToken)).thenAnswer((_) async => token);
    when(() => storage.getToken(kTokenExpiresAt)).thenAnswer((_) async => null);
    when(() => storage.clearAuthTokens()).thenAnswer((_) async {});

    expect(await dataSource.hasValidToken(), isFalse);
    verify(() => storage.clearAuthTokens()).called(1);
  });

  test(
    'opaque non-JWT token remains eligible for server-side validation',
    () async {
      when(
        () => storage.getToken(kAccessToken),
      ).thenAnswer((_) async => 'opaque-token');
      when(
        () => storage.getToken(kTokenExpiresAt),
      ).thenAnswer((_) async => null);

      expect(await dataSource.hasValidToken(), isTrue);
    },
  );
}
