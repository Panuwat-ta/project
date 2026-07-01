import '../entities/scan_history_item.dart';

abstract class HistoryRepository {
  Future<List<ScanHistoryItem>> getScanHistory({
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
