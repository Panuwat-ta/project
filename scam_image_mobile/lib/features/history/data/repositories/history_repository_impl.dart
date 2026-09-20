import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';
import '../datasources/history_local_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final HistoryRemoteDataSource remoteDataSource;
  final HistoryLocalDataSource localDataSource;

  @override
  Future<List<ScanHistoryItem>> getScanHistory({
    int page = 1,
    int limit = 20,
    String? riskLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String? keyword,
  }) async {
    final hasFilters =
        riskLevel != null ||
        fromDate != null ||
        toDate != null ||
        (keyword != null && keyword.isNotEmpty) ||
        page > 1;

    try {
      final remoteData = await remoteDataSource.getScanHistory(
        page: page,
        limit: limit,
        riskLevel: riskLevel,
        fromDate: fromDate,
        toDate: toDate,
        keyword: keyword,
      );
      if (!hasFilters) {
        await localDataSource.cacheHistory(remoteData);
      }
      return remoteData;
    } catch (_) {
      if (!hasFilters) {
        final localData = await localDataSource.getHistory();
        if (localData.isNotEmpty) return localData;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteScanHistoryItem(String scanId) async {
    await remoteDataSource.deleteScanHistoryItem(scanId);
    await localDataSource.deleteHistoryItem(scanId);
  }

  @override
  Future<void> clearAllHistory() async {
    await remoteDataSource.clearAllHistory();
    await localDataSource.clearHistory();
  }
}
