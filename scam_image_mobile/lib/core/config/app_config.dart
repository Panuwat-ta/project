import 'package:flutter/foundation.dart';

/// Public build configuration only. Credentials belong in secure storage.
class AppConfig {
  AppConfig({
    required String apiBaseUrl,
    required this.environment,
    bool releaseMode = kReleaseMode,
  }) : apiBaseUrl = apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '') {
    if (!const {'development', 'staging', 'production'}.contains(environment)) {
      throw StateError('APP_ENV must be development, staging or production');
    }
    final uri = Uri.tryParse(this.apiBaseUrl);
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError(
        'API_BASE_URL must be an HTTP(S) URL without credentials, query or fragment',
      );
    }
    if (releaseMode && environment == 'development') {
      throw StateError('Release builds require staging or production APP_ENV');
    }
    if ((releaseMode || environment != 'development') &&
        uri.scheme != 'https') {
      throw StateError('Staging and production require HTTPS');
    }
  }

  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    environment: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    ),
  );

  final String apiBaseUrl;
  final String environment;
}
