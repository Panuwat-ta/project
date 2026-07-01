import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/scam_report_model.dart';

abstract class ReportRemoteDataSource {
  /// POST /reports — submits the scam report.
  Future<void> submitReport(ScamReportModel report);

  /// GET /reports/categories — returns available category labels.
  Future<List<String>> getCategories();
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  ReportRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<void> submitReport(ScamReportModel report) async {
    try {
      await dio.post<void>(
        ApiEndpoints.reports,
        data: report.toJson(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response =
          await dio.get<dynamic>(ApiEndpoints.reportCategories);
      final body = response.data;
      if (body is List) {
        return body.map((e) => e.toString()).toList();
      }
      if (body is Map<String, dynamic>) {
        final items = body['data'] as List<dynamic>? ?? [];
        return items.map((e) => e.toString()).toList();
      }
      return [];
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
