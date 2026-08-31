import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses server response with full_name', () {
      final json = {
        'id': 42,
        'email': 'test@example.com',
        'full_name': 'Test User',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, '42');
      expect(model.email, 'test@example.com');
      expect(model.displayName, 'Test User');
      expect(model.avatarUrl, isNull);
    });

    test('parses camelCase displayName', () {
      final json = {
        'id': '1',
        'email': 'user@test.com',
        'displayName': 'Display Name',
      };

      final model = UserModel.fromJson(json);

      expect(model.displayName, 'Display Name');
    });

    test('parses display_name snake_case', () {
      final json = {
        'id': 1,
        'email': 'user@test.com',
        'display_name': 'Snake Name',
      };

      final model = UserModel.fromJson(json);

      expect(model.displayName, 'Snake Name');
    });

    test('prefers displayName over display_name over full_name', () {
      final json = {
        'id': 1,
        'email': 'user@test.com',
        'displayName': 'CamelCase',
        'display_name': 'SnakeCase',
        'full_name': 'FullName',
      };

      final model = UserModel.fromJson(json);

      expect(model.displayName, 'CamelCase');
    });

    test('defaults to empty string when no name field present', () {
      final json = {
        'id': 1,
        'email': 'user@test.com',
      };

      final model = UserModel.fromJson(json);

      expect(model.displayName, '');
    });

    test('converts int id to string', () {
      final json = {
        'id': 123,
        'email': 'user@test.com',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, '123');
    });

    test('handles string id', () {
      final json = {
        'id': 'user-abc',
        'email': 'user@test.com',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'user-abc');
    });

    test('parses avatarUrl', () {
      final json = {
        'id': 1,
        'email': 'user@test.com',
        'avatarUrl': 'http://example.com/avatar.jpg',
      };

      final model = UserModel.fromJson(json);

      expect(model.avatarUrl, 'http://example.com/avatar.jpg');
    });
  });

  group('UserModel.toJson', () {
    test('round-trips correctly', () {
      const model = UserModel(
        id: '42',
        email: 'test@example.com',
        displayName: 'Test User',
        avatarUrl: 'http://example.com/avatar.jpg',
      );

      final json = model.toJson();

      expect(json['id'], '42');
      expect(json['email'], 'test@example.com');
      expect(json['displayName'], 'Test User');
      expect(json['avatarUrl'], 'http://example.com/avatar.jpg');
    });
  });

  group('UserModel equality', () {
    test('equal models have same props', () {
      const a = UserModel(id: '1', email: 'a@b.com', displayName: 'A');
      const b = UserModel(id: '1', email: 'a@b.com', displayName: 'A');
      expect(a, equals(b));
    });

    test('different models are not equal', () {
      const a = UserModel(id: '1', email: 'a@b.com', displayName: 'A');
      const b = UserModel(id: '2', email: 'b@b.com', displayName: 'B');
      expect(a, isNot(equals(b)));
    });
  });
}
