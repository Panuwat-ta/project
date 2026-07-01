/// Exception thrown when the server returns an error response (non-2xx).
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Exception thrown when there is no network connectivity or a timeout occurs.
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network error']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when an authentication or authorisation error occurs.
class AuthException implements Exception {
  final String message;

  const AuthException([this.message = 'Authentication failed']);

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when reading from or writing to local cache fails.
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when user input or request data fails validation.
class ValidationException implements Exception {
  final String message;

  const ValidationException([this.message = 'Validation error']);

  @override
  String toString() => 'ValidationException: $message';
}
