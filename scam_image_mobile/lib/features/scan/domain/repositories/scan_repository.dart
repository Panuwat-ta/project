import '../entities/analysis_task.dart';

abstract class ScanRepository {
  /// Submits an image for analysis and returns the taskId.
  Future<String> submitImage({required String filePath, String? scanName});

  /// Polls the current status of an analysis task.
  Future<AnalysisTask> getAnalysisStatus(String taskId);
}
