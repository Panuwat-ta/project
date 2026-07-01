import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/analysis_result_model.dart';

abstract class ResultRemoteDataSource {
  Future<AnalysisResultModel> getAnalysisResult(String taskId);
}

class ResultRemoteDataSourceImpl implements ResultRemoteDataSource {
  ResultRemoteDataSourceImpl({required this.dio});
  final Dio dio;

  @override
  Future<AnalysisResultModel> getAnalysisResult(String taskId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.scanResult(taskId),
      );
      final body = response.data;
      if (body == null) throw const ServerException('Empty response body');
      return AnalysisResultModel.fromJson(body);
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
