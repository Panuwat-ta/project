import '../../domain/entities/analysis_task.dart';

/// Data-layer model that extends [AnalysisTask] with JSON deserialisation.
class AnalysisTaskModel extends AnalysisTask {
  const AnalysisTaskModel({
    required super.taskId,
    required super.status,
    super.progress,
    super.errorMessage,
  });

  factory AnalysisTaskModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'queued';
    return AnalysisTaskModel(
      taskId: json['taskId'] as String? ?? json['task_id'] as String? ?? '',
      status: _parseStatus(statusStr),
      progress: json['progress'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  static AnalysisTaskStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'uploading':
        return AnalysisTaskStatus.uploading;
      case 'queued':
        return AnalysisTaskStatus.queued;
      case 'processing_text':
      case 'processingtext':
        return AnalysisTaskStatus.processingText;
      case 'processing_source':
      case 'processingsource':
        return AnalysisTaskStatus.processingSource;
      case 'processing_visual':
      case 'processingvisual':
        return AnalysisTaskStatus.processingVisual;
      case 'completed':
        return AnalysisTaskStatus.completed;
      case 'failed':
        return AnalysisTaskStatus.failed;
      case 'timeout':
        return AnalysisTaskStatus.timeout;
      default:
        return AnalysisTaskStatus.queued;
    }
  }
}
