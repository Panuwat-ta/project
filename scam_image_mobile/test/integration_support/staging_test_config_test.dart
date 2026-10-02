import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/staging_test_config.dart';

void main() {
  test('rejects production before starting the app', () {
    expect(
      () => StagingTestConfig(
        environment: 'production',
        apiBaseUrl: 'https://staging.example.test/api/v1',
        email: 'fixture@example.test',
        password: 'test-only-fixture',
      ),
      throwsStateError,
    );
  });
  for (final (index, url) in [
    '',
    'http://staging.example.test/api/v1',
    'https://example.invalid/api/v1',
    'https://localhost/api/v1',
    'https://127.0.0.1/api/v1',
    'https://[::1]/api/v1',
    'https://user:secret@staging.example.test/api/v1',
    'https://staging.example.test/api/v1?token=secret',
    'https://staging.example.test/api/v1#fragment',
  ].indexed) {
    test('rejects unsafe or compile-only staging URL case $index', () {
      expect(
        () => StagingTestConfig(
          environment: 'staging',
          apiBaseUrl: url,
          email: 'fixture@example.test',
          password: 'test-only-fixture',
        ),
        throwsStateError,
      );
    });
  }
  test('rejects missing credentials without exposing them', () {
    for (final credentials in [
      ('', 'private-value'),
      ('fixture@example.test', ''),
    ]) {
      try {
        StagingTestConfig(
          environment: 'staging',
          apiBaseUrl: 'https://staging.example.test/api/v1',
          email: credentials.$1,
          password: credentials.$2,
        );
        fail('Expected missing credential rejection');
      } on StateError catch (error) {
        expect(error.message, 'E2E requires fixture email and password');
      }
    }
  });
  test(
    'accepts explicit staging fixture and preserves password whitespace',
    () {
      final config = StagingTestConfig(
        environment: 'staging',
        apiBaseUrl: 'https://staging.example.test/api/v1',
        email: 'fixture@example.test',
        password: ' test-only-fixture ',
      );
      expect(config.password, ' test-only-fixture ');
      expect(config.acceptTerms, isFalse);
    },
  );
}
