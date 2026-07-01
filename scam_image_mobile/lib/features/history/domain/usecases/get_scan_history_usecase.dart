import '../entities/scan_history_item.dart';
import '../repositories/history_repository.dart';

class GetScanHistoryParams {
  final int page;
  final int limit;
  final String? riskLevel;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? keyword;

  const GetScanHistoryParams({
    this.page = 1,
    this.limit = 20,
    this.riskLevel,
    this.fromDate,
    this.toDate,
    this.keyword,
  });
}

class GetScanHistoryUseCase {
  final HistoryRepository repository;

  const GetScanHistoryUseCase(this.repository);

  Future<List<ScanHistoryItem>> call(GetScanHistoryParams params) =>
      repository.getScanHistory(
        page: params.page,
        limit: params.limit,
        riskLevel: params.riskLevel,
        fromDate: params.fromDate,
        toDate: params.toDate,
        keyword: params.keyword,
      );
}
