import '../../domain/entities/analysis_result.dart';
import '../../domain/repositories/result_repository.dart';
import '../datasources/result_remote_datasource.dart';

class ResultRepositoryImpl implements ResultRepository {
  ResultRepositoryImpl({required this.remoteDataSource});
  final ResultRemoteDataSource remoteDataSource;

  @override
  Future<AnalysisResult> getAnalysisResult(String taskId) =>
      remoteDataSource.getAnalysisResult(taskId);
}
