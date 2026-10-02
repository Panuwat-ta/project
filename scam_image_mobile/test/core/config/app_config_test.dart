import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/config/app_config.dart';

void main() {
  test(
    'development explicitly permits local HTTP and normalizes trailing slash',
    () {
      final config = AppConfig(
        apiBaseUrl: ' http://localhost:8000/api/v1/ ',
        environment: 'development',
        releaseMode: false,
      );
      expect(config.apiBaseUrl, 'http://localhost:8000/api/v1');
    },
  );
  for (final environment in ['staging', 'production']) {
    test('$environment requires HTTPS in every build mode', () {
      expect(
        () => AppConfig(
          apiBaseUrl: 'http://localhost:8000/api/v1',
          environment: environment,
          releaseMode: false,
        ),
        throwsStateError,
      );
      expect(
        AppConfig(
          apiBaseUrl: 'https://api.example.invalid/api/v1',
          environment: environment,
          releaseMode: true,
        ).environment,
        environment,
      );
    });
  }
  test('release cannot use development configuration', () {
    expect(
      () => AppConfig(
        apiBaseUrl: 'https://example.invalid/api/v1',
        environment: 'development',
        releaseMode: true,
      ),
      throwsStateError,
    );
  });
  for (final url in [
    '',
    'file:///tmp/image',
    'ftp://example.invalid',
    'https://user:secret@example.invalid',
    'https://example.invalid?token=secret',
    'https://example.invalid/#secret',
    'https:///',
  ]) {
    test('rejects missing or unsafe URL ${url.split(':').first}', () {
      expect(
        () => AppConfig(
          apiBaseUrl: url,
          environment: 'production',
          releaseMode: true,
        ),
        throwsStateError,
      );
    });
  }
  test('rejects unknown environment', () {
    expect(
      () => AppConfig(
        apiBaseUrl: 'https://example.invalid',
        environment: 'unknown',
        releaseMode: true,
      ),
      throwsStateError,
    );
  });
}
