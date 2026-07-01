import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';
import 'package:scam_image_mobile/features/scan/domain/repositories/scan_repository.dart';
import 'package:uuid/uuid.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ScanEvent extends Equatable {}

class CropConfirmed extends ScanEvent {
  final String filePath;
  CropConfirmed(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class AnalysisPollTick extends ScanEvent {
  final String taskId;
  AnalysisPollTick(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class AnalysisCancelled extends ScanEvent {
  @override
  List<Object?> get props => [];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ScanState extends Equatable {}

class ScanInitial extends ScanState {
  @override
  List<Object?> get props => [];
}

class ScanUploading extends ScanState {
  @override
  List<Object?> get props => [];
}

class ScanPolling extends ScanState {
  final String taskId;
  final int progress;
  final AnalysisTaskStatus step;

  ScanPolling({
    required this.taskId,
    this.progress = 0,
    this.step = AnalysisTaskStatus.queued,
  });

  @override
  List<Object?> get props => [taskId, progress, step];
}

class ScanCompleted extends ScanState {
  final String taskId;
  ScanCompleted(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ScanError extends ScanState {
  final String message;
  ScanError(this.message);
  @override
  List<Object?> get props => [message];
}

class ScanTimeout extends ScanState {
  @override
  List<Object?> get props => [];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc({required this.repository, this.consentForResearch = false})
      : super(ScanInitial()) {
    on<CropConfirmed>(_onCropConfirmed);
    on<AnalysisPollTick>(_onPollTick);
    on<AnalysisCancelled>(_onCancelled);
  }

  final ScanRepository repository;
  final bool consentForResearch;

  Timer? _pollingTimer;
  int _elapsedSeconds = 0;
  String? _currentTaskId;

  static const int _timeoutSeconds = 3600;
  static const int _pollIntervalSeconds = 3;

  Future<void> _onCropConfirmed(
      CropConfirmed event, Emitter<ScanState> emit) async {
    emit(ScanUploading());
    try {
      final clientRequestId = const Uuid().v4();
      final taskId = await repository.submitImage(
        filePath: event.filePath,
        consentForResearch: consentForResearch,
        clientRequestId: clientRequestId,
      );
      _currentTaskId = taskId;
      _elapsedSeconds = 0;
      emit(ScanPolling(
          taskId: taskId,
          progress: 5,
          step: AnalysisTaskStatus.queued));
      _startPolling(taskId);
    } catch (e) {
      emit(ScanError(_friendlyError(e)));
    }
  }

  void _startPolling(String taskId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _pollIntervalSeconds),
      (_) => add(AnalysisPollTick(taskId)),
    );
  }

  Future<void> _onPollTick(
      AnalysisPollTick event, Emitter<ScanState> emit) async {
    _elapsedSeconds += _pollIntervalSeconds;
    if (_elapsedSeconds >= _timeoutSeconds) {
      _pollingTimer?.cancel();
      emit(ScanTimeout());
      return;
    }
    try {
      final task = await repository.getAnalysisStatus(event.taskId);
      if (task.isCompleted) {
        _pollingTimer?.cancel();
        emit(ScanCompleted(event.taskId));
      } else if (task.isFailed) {
        _pollingTimer?.cancel();
        emit(ScanError(task.errorMessage ?? 'การวิเคราะห์ล้มเหลว'));
      } else {
        emit(ScanPolling(
            taskId: event.taskId,
            progress: task.progress,
            step: task.status));
      }
    } catch (_) {
      // transient network errors: keep polling
    }
  }

  Future<void> _onCancelled(
      AnalysisCancelled event, Emitter<ScanState> emit) async {
    _pollingTimer?.cancel();
    if (_currentTaskId != null) {
      try {
        await repository.cancelScan(_currentTaskId!);
      } catch (_) {}
    }
    emit(ScanInitial());
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('socket')) {
      return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
    }
    return 'เกิดข้อผิดพลาดในการอัปโหลด กรุณาลองใหม่';
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}

// ── Mock repository stub (replaced by real DI in Task 23) ────────────────────

class MockScanRepository implements ScanRepository {
  final Map<String, DateTime> _startTimes = {};

  @override
  Future<String> submitImage({
    required String filePath,
    required bool consentForResearch,
    required String clientRequestId,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final taskId = 'mock_task_${DateTime.now().millisecondsSinceEpoch}';
    _startTimes[taskId] = DateTime.now();
    return taskId;
  }

  @override
  Future<AnalysisTask> getAnalysisStatus(String taskId) async {
    await Future.delayed(const Duration(seconds: 1));
    final startTime = _startTimes[taskId] ?? DateTime.now();
    final elapsed = DateTime.now().difference(startTime);

    if (elapsed.inMinutes >= 5) {
      return AnalysisTask(
        taskId: taskId,
        status: AnalysisTaskStatus.completed,
        progress: 100,
      );
    } else {
      final progress = (elapsed.inSeconds / 300 * 100).toInt();
      return AnalysisTask(
        taskId: taskId,
        status: AnalysisTaskStatus.processingText,
        progress: progress.clamp(0, 99),
      );
    }
  }

  @override
  Future<void> cancelScan(String taskId) async {}
}
