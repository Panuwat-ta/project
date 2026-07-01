import '../entities/scan_history_item.dart';
import '../repositories/history_repository.dart';

/// Thin wrapper around [HistoryRepository.getScanHistory] that filters by keyword.
class SearchHistoryUseCase {
  final HistoryRepository repository;

  const SearchHistoryUseCase(this.repository);

  Future<List<ScanHistoryItem>> call(String keyword) =>
      repository.getScanHistory(keyword: keyword);
}
