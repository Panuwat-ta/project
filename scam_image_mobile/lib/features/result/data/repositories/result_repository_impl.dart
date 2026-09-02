import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/repositories/result_repository.dart';
import '../datasources/result_local_datasource.dart';
import '../datasources/result_remote_datasource.dart';

class ResultRepositoryImpl implements ResultRepository {
  ResultRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  final ResultRemoteDataSource remoteDataSource;
  final ResultLocalDataSource? localDataSource;

  @override
  Future<AnalysisResult> getAnalysisResult(String taskId) async {
    try {
      final result = await remoteDataSource.getAnalysisResult(taskId);
      // Cache successful fetch for offline viewing
      if (localDataSource != null) {
        try {
          await localDataSource!.cacheResult(result);
        } catch (_) {}
      }
      return result;
    } on NetworkException {
      // Offline — try local cache
      if (localDataSource != null) {
        final cached = await localDataSource!.getResult(taskId);
        if (cached != null) return cached;
      }
      rethrow;
    } catch (e) {
      // For other errors (e.g. 404), still try cache as fallback
      if (localDataSource != null) {
        try {
          final cached = await localDataSource!.getResult(taskId);
          if (cached != null) return cached;
        } catch (_) {}
      }
      rethrow;
    }
  }
}
