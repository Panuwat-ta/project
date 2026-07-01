import '../entities/analysis_result.dart';
import '../repositories/result_repository.dart';

class GetAnalysisResultUseCase {
  final ResultRepository repository;
  const GetAnalysisResultUseCase(this.repository);
  Future<AnalysisResult> call(String taskId) => repository.getAnalysisResult(taskId);
}
