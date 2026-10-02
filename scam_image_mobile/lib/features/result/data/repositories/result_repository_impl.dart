import '../../../../core/storage/secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/repositories/result_repository.dart';
import '../datasources/result_local_datasource.dart';
import '../datasources/result_remote_datasource.dart';

class ResultRepositoryImpl implements ResultRepository {
  ResultRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    this.sessionStorage,
  });

  final ResultRemoteDataSource remoteDataSource;
  final ResultLocalDataSource? localDataSource;
  final SecureStorage? sessionStorage;

  @override
  Future<AnalysisResult> getAnalysisResult(String taskId) async {
    final revision = sessionStorage?.authRevision;
    try {
      final result = await remoteDataSource.getAnalysisResult(taskId);
      if (revision != sessionStorage?.authRevision) {
        throw const AuthException('Session ended');
      }
      // Cache successful fetch for offline viewing
      if (localDataSource != null) {
        try {
          if (sessionStorage == null) {
            await localDataSource!.cacheResult(result);
          } else {
            await localDataSource!.cacheResult(
              result,
              isCurrentSession: () => revision == sessionStorage!.authRevision,
            );
          }
        } catch (_) {}
      }
      if (revision != sessionStorage?.authRevision) {
        throw const AuthException('Session ended');
      }
      return result;
    } on NetworkException {
      if (revision != sessionStorage?.authRevision) {
        throw const AuthException('Session ended');
      }
      // Offline — try local cache
      if (localDataSource != null) {
        final cached = await localDataSource!.getResult(taskId);
        if (revision != sessionStorage?.authRevision) {
          throw const AuthException('Session ended');
        }
        if (cached != null) return cached;
      }
      rethrow;
    } catch (_) {
      // Authentication, validation and 4xx/5xx responses are authoritative.
      // Only genuine network failures are eligible for offline cache fallback.
      rethrow;
    }
  }
}
