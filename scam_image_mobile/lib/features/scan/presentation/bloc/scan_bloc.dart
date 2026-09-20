import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';
import 'package:scam_image_mobile/features/scan/domain/repositories/scan_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ScanEvent extends Equatable {}

class CropConfirmed extends ScanEvent {
  final String filePath;
  final String? scanName;
  CropConfirmed(this.filePath, {this.scanName});
  @override
  List<Object?> get props => [filePath, scanName];
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
  ScanBloc({
    required this.repository,
    this.timeoutSeconds = 3600,
    this.pollInterval = const Duration(seconds: 3),
  }) : super(ScanInitial()) {
    on<CropConfirmed>(_onCropConfirmed);
    on<AnalysisPollTick>(_onPollTick);
    on<AnalysisCancelled>(_onCancelled);
  }

  final ScanRepository repository;
  final int timeoutSeconds;
  final Duration pollInterval;

  Timer? _pollingTimer;
  String? _activeTaskId;
  final Set<String> _pollsInFlight = <String>{};
  int _scanGeneration = 0;
  int _elapsedSeconds = 0;

  Future<void> _onCropConfirmed(
    CropConfirmed event,
    Emitter<ScanState> emit,
  ) async {
    final generation = ++_scanGeneration;
    _pollingTimer?.cancel();
    _activeTaskId = null;
    _elapsedSeconds = 0;
    emit(ScanUploading());

    try {
      final String taskId = await repository.submitImage(
        filePath: event.filePath,
        scanName: event.scanName,
      );

      // A newer scan/cancel may have happened while the upload was awaiting.
      if (generation != _scanGeneration || isClosed) return;

      _activeTaskId = taskId;
      _pollingTimer = Timer.periodic(pollInterval, (_) {
        if (!isClosed && _activeTaskId == taskId) {
          add(AnalysisPollTick(taskId));
        }
      });

      emit(
        ScanPolling(
          taskId: taskId,
          progress: 0,
          step: AnalysisTaskStatus.queued,
        ),
      );
    } catch (e) {
      if (generation == _scanGeneration && !isClosed) {
        emit(ScanError(_friendlyError(e)));
      }
    }
  }

  Future<void> _onPollTick(
    AnalysisPollTick event,
    Emitter<ScanState> emit,
  ) async {
    if (_activeTaskId != event.taskId || !_pollsInFlight.add(event.taskId)) {
      return;
    }

    try {
      _elapsedSeconds += pollInterval.inSeconds;
      if (_elapsedSeconds >= timeoutSeconds) {
        _pollingTimer?.cancel();
        _activeTaskId = null;
        emit(ScanTimeout());
        return;
      }

      final task = await repository.getAnalysisStatus(event.taskId);
      // Ignore a response that belongs to a task which is no longer active.
      if (_activeTaskId != event.taskId || isClosed) return;

      if (task.isCompleted) {
        _pollingTimer?.cancel();
        _activeTaskId = null;
        emit(ScanCompleted(event.taskId));
      } else if (task.isFailed) {
        _pollingTimer?.cancel();
        _activeTaskId = null;
        emit(ScanError(task.errorMessage ?? 'การวิเคราะห์ล้มเหลว'));
      } else {
        emit(
          ScanPolling(
            taskId: event.taskId,
            progress: task.progress.clamp(0, 100),
            step: task.status,
          ),
        );
      }
    } catch (_) {
      // Transient network errors keep the active polling loop alive.
    } finally {
      _pollsInFlight.remove(event.taskId);
    }
  }

  Future<void> _onCancelled(
    AnalysisCancelled event,
    Emitter<ScanState> emit,
  ) async {
    _scanGeneration += 1;
    _pollingTimer?.cancel();
    _activeTaskId = null;
    _elapsedSeconds = 0;
    emit(ScanInitial());
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
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
