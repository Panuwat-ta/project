import 'package:scam_image_mobile/core/config/app_config.dart';

/// Test-only fixture configuration. Never print it or distribute the test APK.
class StagingTestConfig {
  StagingTestConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.email,
    required this.password,
    this.acceptTerms = false,
  }) {
    if (environment != 'staging') {
      throw StateError('E2E requires confirmed staging APP_ENV');
    }
    AppConfig(apiBaseUrl: apiBaseUrl, environment: environment);
    final host = Uri.parse(apiBaseUrl.trim()).host.toLowerCase();
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.startsWith('127.') ||
        host == '::1' ||
        host == '[::1]' ||
        host.endsWith('.invalid')) {
      throw StateError('E2E requires a confirmed staging endpoint');
    }
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw StateError('E2E requires fixture email and password');
    }
  }

  factory StagingTestConfig.fromEnvironment() => StagingTestConfig(
    environment: const String.fromEnvironment('APP_ENV'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    email: const String.fromEnvironment('E2E_EMAIL'),
    password: const String.fromEnvironment('E2E_PASSWORD'),
    acceptTerms: const bool.fromEnvironment('E2E_ACCEPT_TERMS'),
  );

  final String environment;
  final String apiBaseUrl;
  final String email;
  final String password;
  final bool acceptTerms;
}
