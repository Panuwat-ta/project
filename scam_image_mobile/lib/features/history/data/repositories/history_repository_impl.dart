import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';
import '../datasources/history_local_datasource.dart';
import '../models/scan_history_item_model.dart';
import '../../../../core/errors/exceptions.dart';

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
    // Note: Local database is used primarily for the initial offline-first load.
    // If there are filters applied (e.g. search, riskLevel), we rely on remote.
    final hasFilters = riskLevel != null || fromDate != null || toDate != null || (keyword != null && keyword.isNotEmpty) || page > 1;

    if (!hasFilters) {
      try {
        // Fetch from local first to show something immediately
        final localData = await localDataSource.getHistory();
        
        // Then try to fetch from remote to sync
        _fetchAndCacheRemote(page, limit).ignore();
        
        if (localData.isNotEmpty) {
          return localData;
        }
      } catch (e) {
        // ignore local db error and fallback to remote
      }
    }

    // Normal remote fetch
    final remoteData = await remoteDataSource.getScanHistory(
      page: page,
      limit: limit,
      riskLevel: riskLevel,
      fromDate: fromDate,
      toDate: toDate,
      keyword: keyword,
    );

    // Cache first page without filters
    if (!hasFilters) {
      await localDataSource.cacheHistory(remoteData as List<ScanHistoryItemModel>);
    }

    return remoteData;
  }
  
  Future<void> _fetchAndCacheRemote(int page, int limit) async {
    try {
      final remoteData = await remoteDataSource.getScanHistory(
        page: page,
        limit: limit,
      );
      await localDataSource.cacheHistory(remoteData as List<ScanHistoryItemModel>);
    } catch (_) {
      // Background sync fail is fine
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
