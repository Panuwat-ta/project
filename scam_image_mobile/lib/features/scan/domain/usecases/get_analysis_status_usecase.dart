import '../entities/analysis_task.dart';
import '../repositories/scan_repository.dart';

/// Fetches the current status of an analysis task by taskId.
class GetAnalysisStatusUseCase {
  final ScanRepository repository;

  GetAnalysisStatusUseCase(this.repository);

  Future<AnalysisTask> call(String taskId) {
    return repository.getAnalysisStatus(taskId);
  }
}
