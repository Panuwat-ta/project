import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_error_mapper.dart';
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
      throw mapDioException(e);
    }
  }

}
