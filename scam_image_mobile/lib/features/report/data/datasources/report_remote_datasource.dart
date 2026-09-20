import 'package:dio/dio.dart';
import '../../../../core/network/dio_error_mapper.dart';
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
      throw mapDioException(e);
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response =
          await dio.get<dynamic>(ApiEndpoints.reportCategories);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final categories = body['categories'] as List<dynamic>? ??
            body['data'] as List<dynamic>? ??
            [];
        return categories.map((e) {
          if (e is Map<String, dynamic>) {
            return e['label_th'] as String? ?? e['key'] as String? ?? e.toString();
          }
          return e.toString();
        }).toList();
      }
      if (body is List) {
        return body.map((e) {
          if (e is Map<String, dynamic>) {
            return e['label_th'] as String? ?? e['key'] as String? ?? e.toString();
          }
          return e.toString();
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

}
