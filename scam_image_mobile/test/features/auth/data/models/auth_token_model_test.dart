import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/auth/data/models/auth_token_model.dart';

void main() {
  group('AuthTokenModel.fromJson', () {
    test('parses camelCase keys', () {
      final json = {
        'accessToken': 'abc123',
        'refreshToken': 'xyz789',
        'expiresAt': '2026-12-31T23:59:59.000',
      };

      final model = AuthTokenModel.fromJson(json);

      expect(model.accessToken, 'abc123');
      expect(model.refreshToken, 'xyz789');
      expect(model.expiresAt, DateTime(2026, 12, 31, 23, 59, 59));
    });

    test('parses snake_case keys', () {
      final json = {
        'access_token': 'abc123',
        'refresh_token': 'xyz789',
      };

      final model = AuthTokenModel.fromJson(json);

      expect(model.accessToken, 'abc123');
      expect(model.refreshToken, 'xyz789');
      expect(model.expiresAt, isNull);
    });

    test('prefers camelCase over snake_case when both present', () {
      final json = {
        'accessToken': 'camel',
        'access_token': 'snake',
        'refreshToken': 'camelRefresh',
        'refresh_token': 'snakeRefresh',
      };

      final model = AuthTokenModel.fromJson(json);

      expect(model.accessToken, 'camel');
      expect(model.refreshToken, 'camelRefresh');
    });

    test('handles null expiresAt', () {
      final json = {
        'access_token': 'abc',
        'refresh_token': 'xyz',
      };

      final model = AuthTokenModel.fromJson(json);

      expect(model.expiresAt, isNull);
      expect(model.isExpired, false);
    });
  });

  group('AuthTokenModel.toJson', () {
    test('round-trips correctly', () {
      const model = AuthTokenModel(
        accessToken: 'abc',
        refreshToken: 'xyz',
      );

      final json = model.toJson();

      expect(json['accessToken'], 'abc');
      expect(json['refreshToken'], 'xyz');
      expect(json['expiresAt'], isNull);
    });

    test('includes expiresAt when set', () {
      final model = AuthTokenModel(
        accessToken: 'abc',
        refreshToken: 'xyz',
        expiresAt: DateTime(2026, 6, 15),
      );

      final json = model.toJson();

      expect(json['expiresAt'], isNotNull);
      expect(json['expiresAt'], contains('2026'));
    });
  });

  group('AuthTokenModel equality', () {
    test('equal tokens have same props', () {
      const a = AuthTokenModel(accessToken: 'a', refreshToken: 'b');
      const b = AuthTokenModel(accessToken: 'a', refreshToken: 'b');
      expect(a, equals(b));
    });

    test('different tokens are not equal', () {
      const a = AuthTokenModel(accessToken: 'a', refreshToken: 'b');
      const b = AuthTokenModel(accessToken: 'x', refreshToken: 'y');
      expect(a, isNot(equals(b)));
    });
  });
}
