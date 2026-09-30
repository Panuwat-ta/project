import 'package:dio/dio.dart';

import '../errors/exceptions.dart';

/// Single error-mapping truth for all remote datasources.
/// (Unifies 7 verbatim copies; the fuller message/detail/String semantics wins.)
Exception mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return NetworkException(e.message ?? 'Connection error');
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Server error';

      if (data is Map<String, dynamic>) {
        final rawMessage = data['message'] ?? data['detail'];
        if (rawMessage is String) {
          message = rawMessage;
        } else if (rawMessage is List) {
          final messages = rawMessage
              .map((item) {
                if (item is Map && item['msg'] != null) {
                  return item['msg'].toString();
                }
                return item.toString();
              })
              .where((item) => item.isNotEmpty)
              .toList();
          if (messages.isNotEmpty) message = messages.join('; ');
        } else if (rawMessage != null) {
          message = rawMessage.toString();
        }
      } else if (data is String) {
        message = data;
      }

      if (statusCode == 401 || statusCode == 403) {
        return AuthException(
          message == 'Server error' ? 'Unauthorised' : message,
        );
      }
      return ServerException(message, statusCode: statusCode);
    default:
      return NetworkException(e.message ?? 'Network error');
  }
}
