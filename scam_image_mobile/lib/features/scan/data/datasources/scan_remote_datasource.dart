import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/analysis_task_model.dart';

/// Contract for the remote scan data source.
abstract class ScanRemoteDataSource {
  /// Submits an image for analysis and returns the [taskId] string.
  ///
  /// Throws [ServerException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity / timeout errors.
  Future<String> submitScan({
    required String filePath,
    required bool consentForResearch,
    required String clientRequestId,
  });

  /// Polls the current status of a scan task.
  ///
  /// Throws [ServerException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity / timeout errors.
  Future<AnalysisTaskModel> getScanStatus(String taskId);

  /// Cancels an in-progress scan task.
  ///
  /// Throws [ServerException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity / timeout errors.
  Future<void> cancelScan(String taskId);
}

/// Concrete implementation of [ScanRemoteDataSource] backed by [Dio].
class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  ScanRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<String> submitScan({
    required String filePath,
    required bool consentForResearch,
    required String clientRequestId,
  }) async {
    try {
      // Build multipart form data.
      // Compression for files > 10 MB is handled by the repository / calling
      // code before reaching this method, so we upload as-is here.
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: fileName),
        'source': 'upload',
        'consentForResearch': consentForResearch.toString(),
        'clientRequestId': clientRequestId,
      });

      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: formData,
      );

      final body = _requireBody(response);
      // Accept both camelCase and snake_case keys from the server.
      final taskId =
          body['taskId'] as String? ?? body['task_id'] as String? ?? '';
      return taskId;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<AnalysisTaskModel> getScanStatus(String taskId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.scanById(taskId),
      );
      final body = _requireBody(response);
      return AnalysisTaskModel.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> cancelScan(String taskId) async {
    try {
      await dio.delete<void>(ApiEndpoints.scanById(taskId));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const ServerException('Empty response body');
    }
    return body;
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
