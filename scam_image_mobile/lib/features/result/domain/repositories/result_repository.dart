import '../entities/analysis_result.dart';

abstract class ResultRepository {
  Future<AnalysisResult> getAnalysisResult(String taskId);
}
