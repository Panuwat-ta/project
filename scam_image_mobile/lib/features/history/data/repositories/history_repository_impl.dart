import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required this.remoteDataSource});
  final HistoryRemoteDataSource remoteDataSource;

  @override
  Future<List<ScanHistoryItem>> getScanHistory({
    int page = 1,
    int limit = 20,
    String? riskLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String? keyword,
  }) =>
      remoteDataSource.getScanHistory(
        page: page,
        limit: limit,
        riskLevel: riskLevel,
        fromDate: fromDate,
        toDate: toDate,
        keyword: keyword,
      );

  @override
  Future<void> deleteScanHistoryItem(String scanId) =>
      remoteDataSource.deleteScanHistoryItem(scanId);

  @override
  Future<void> clearAllHistory() => remoteDataSource.clearAllHistory();
}
