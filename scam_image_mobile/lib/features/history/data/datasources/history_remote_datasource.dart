import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/scan_history_item_model.dart';

abstract class HistoryRemoteDataSource {
  Future<List<ScanHistoryItemModel>> getScanHistory({
    int page = 1,
    int limit = 20,
    String? riskLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String? keyword,
  });

  Future<void> deleteScanHistoryItem(String scanId);
  Future<void> clearAllHistory();
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  HistoryRemoteDataSourceImpl({required this.dio});
  final Dio dio;

  @override
  Future<List<ScanHistoryItemModel>> getScanHistory({
    int page = 1,
    int limit = 20,
    String? riskLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String? keyword,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'riskLevel': ?riskLevel,
        'fromDate': ?fromDate?.toIso8601String(),
        'toDate': ?toDate?.toIso8601String(),
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      };

      final response = await dio.get<dynamic>(
        ApiEndpoints.history,
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body == null) return [];

      // Support both array response and paginated object { data: [...] }
      final List<dynamic> items;
      if (body is List) {
        items = body;
      } else if (body is Map<String, dynamic>) {
        items = body['data'] as List<dynamic>? ??
            body['items'] as List<dynamic>? ??
            [];
      } else {
        return [];
      }

      return items
          .map((e) =>
              ScanHistoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deleteScanHistoryItem(String scanId) async {
    try {
      await dio.delete<void>(ApiEndpoints.historyById(scanId));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      await dio.delete<void>(ApiEndpoints.history);
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
