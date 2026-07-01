import '../entities/analysis_task.dart';

abstract class ScanRepository {
  /// Submits an image for analysis and returns the taskId.
  Future<String> submitImage({
    required String filePath,
    required bool consentForResearch,
    required String clientRequestId,
  });

  /// Polls the current status of an analysis task.
  Future<AnalysisTask> getAnalysisStatus(String taskId);

  /// Cancels an in-progress scan.
  Future<void> cancelScan(String taskId);
}
