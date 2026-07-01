import 'package:equatable/equatable.dart';

enum AnalysisTaskStatus {
  uploading,
  queued,
  processingText,
  processingSource,
  processingVisual,
  completed,
  failed,
  timeout,
}

class AnalysisTask extends Equatable {
  final String taskId;
  final AnalysisTaskStatus status;
  final int progress; // 0-100
  final String? errorMessage;

  const AnalysisTask({
    required this.taskId,
    required this.status,
    this.progress = 0,
    this.errorMessage,
  });

  bool get isCompleted => status == AnalysisTaskStatus.completed;

  bool get isFailed =>
      status == AnalysisTaskStatus.failed ||
      status == AnalysisTaskStatus.timeout;

  bool get isProcessing => !isCompleted && !isFailed;

  @override
  List<Object?> get props => [taskId, status, progress, errorMessage];
}
