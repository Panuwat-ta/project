import '../repositories/history_repository.dart';

class DeleteScanHistoryItemUseCase {
  final HistoryRepository repository;

  const DeleteScanHistoryItemUseCase(this.repository);

  Future<void> call(String scanId) => repository.deleteScanHistoryItem(scanId);
}
