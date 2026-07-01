import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';

/// Contract for the settings remote data source.
abstract class SettingsRemoteDataSource {
  /// GET /consents/me — returns the user's current consent map.
  Future<Map<String, dynamic>> getConsents();

  /// PUT /consents/me — persists updated consent data.
  Future<void> updateConsents(Map<String, dynamic> data);

  /// POST /privacy/export — triggers a privacy data export.
  Future<void> exportPrivacyData();

  /// DELETE /privacy/account — permanently deletes the user account.
  Future<void> deleteAccount();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<Map<String, dynamic>> getConsents() async {
    try {
      final response =
          await dio.get<dynamic>(ApiEndpoints.consentsMe);
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return {};
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> updateConsents(Map<String, dynamic> data) async {
    try {
      await dio.put<void>(ApiEndpoints.consentsMe, data: data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> exportPrivacyData() async {
    try {
      await dio.post<void>(ApiEndpoints.privacyExport);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await dio.delete<void>(ApiEndpoints.privacyDeleteAccount);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(e.message ?? 'Connection error');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            e.response?.data?['message'] as String? ?? 'Unauthorised',
          );
        }
        return ServerException(
          e.response?.data?['message'] as String? ?? 'Server error',
          statusCode: statusCode,
        );
      default:
        return NetworkException(e.message ?? 'Network error');
    }
  }
}
