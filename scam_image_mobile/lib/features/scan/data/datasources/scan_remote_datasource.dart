import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/analysis_task_model.dart';

/// Contract for the remote scan data source.
abstract class ScanRemoteDataSource {
  /// Submits an image for analysis and returns the [taskId] string.
  ///
  /// Throws [ServerException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity / timeout errors.
  Future<String> submitScan({required String filePath, String? scanName});

  /// Polls the current status of a scan task.
  ///
  /// Throws [ServerException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity / timeout errors.
  Future<AnalysisTaskModel> getScanStatus(String taskId);
}

/// Concrete implementation of [ScanRemoteDataSource] backed by [Dio].
class ScanRemoteDataSourceImpl implements ScanRemoteDataSource {
  ScanRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<String> submitScan({
    required String filePath,
    String? scanName,
  }) async {
    try {
      // Build multipart form data.
      // Compression for files > 10 MB is handled by the repository / calling
      // code before reaching this method, so we upload as-is here.
      final fileName = filePath.split(RegExp(r'[\\/]')).last;

      final Map<String, dynamic> formMap = {
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      };

      if (scanName != null && scanName.trim().isNotEmpty) {
        formMap['title'] = scanName.trim();
      }

      final formData = FormData.fromMap(formMap);

      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.scans,
        data: formData,
      );

      final body = _requireBody(response);
      // Backend returns the full ScanResponse immediately. We just need its ID.
      final taskId = body['id'];
      if (taskId is! String || taskId.trim().isEmpty) {
        throw const ServerException('Scan response missing id');
      }
      return taskId;
    } on DioException catch (e) {
      throw mapDioException(e);
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
      throw mapDioException(e);
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
}
