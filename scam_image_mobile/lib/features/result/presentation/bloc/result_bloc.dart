import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/analysis_result.dart';

import '../../domain/repositories/result_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class ResultEvent extends Equatable {
  const ResultEvent();
}

class ResultSessionCleared extends ResultEvent {
  const ResultSessionCleared();
  @override
  List<Object?> get props => [];
}

class ResultLoadRequested extends ResultEvent {
  const ResultLoadRequested(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// โพลซ้ำเพื่อรอ XAI (ไม่แสดง loading ใหม่ เพื่อไม่ให้จอกระพริบ)
class ResultPollRequested extends ResultEvent {
  const ResultPollRequested(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class ResultPollingStopped extends ResultEvent {
  const ResultPollingStopped(this.taskId);
  final String taskId;
  @override
  List<Object?> get props => [taskId];
}

// ── States ─────────────────────────────────────────────────────────────────

abstract class ResultState extends Equatable {
  const ResultState();
}

class ResultInitial extends ResultState {
  const ResultInitial();

  @override
  List<Object?> get props => [];
}

class ResultLoading extends ResultState {
  const ResultLoading();

  @override
  List<Object?> get props => [];
}

class ResultLoaded extends ResultState {
  const ResultLoaded(this.result);

  final AnalysisResult result;

  @override
  List<Object?> get props => [result];
}

class ResultError extends ResultState {
  const ResultError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────────

class ResultBloc extends Bloc<ResultEvent, ResultState> {
  ResultBloc({required this.repository}) : super(const ResultInitial()) {
    on<ResultSessionCleared>((event, emit) {
      _generation++;
      _activeTaskId = null;
      _stopped = true;
      _pollTimer?.cancel();
      emit(const ResultInitial());
    });
    on<ResultLoadRequested>(_onLoadRequested);
    on<ResultPollRequested>(_onPollRequested);
    on<ResultPollingStopped>((event, emit) {
      if (_activeTaskId == event.taskId) {
        _generation++;
        _activeTaskId = null;
        _stopped = true;
        _pollTimer?.cancel();
      }
    });
  }

  final ResultRepository repository;
  Timer? _pollTimer;
  int _pollCount = 0;
  int _generation = 0;
  String? _activeTaskId;
  final Set<int> _pollsInFlight = {};
  bool _stopped = false;

  /// โพลสูงสุด ~5 นาที (60 ครั้ง × 5 วินาที) ตรงกับ XAI_TIMEOUT 300s ของ server
  static const int maxPolls = 60;
  static const Duration pollInterval = Duration(seconds: 5);

  /// สแกนยังไม่เสร็จ (status เป็น processing_*) และยังไม่มีคำอธิบาย = XAI กำลังสร้าง
  static bool isXaiPending(AnalysisResult result) =>
      result.summary.isEmpty &&
      result.status != 'completed' &&
      result.status != 'failed';

  Future<void> _onLoadRequested(
    ResultLoadRequested event,
    Emitter<ResultState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollCount = 0;
    final generation = ++_generation;
    _activeTaskId = event.taskId;
    _stopped = false;
    emit(const ResultLoading());
    try {
      final result = await repository.getAnalysisResult(event.taskId);
      if (generation != _generation || isClosed) return;
      emit(ResultLoaded(result));
      _schedulePollIfNeeded(event.taskId, result);
    } catch (e) {
      if (generation != _generation || isClosed) return;
      emit(ResultError(e.toString()));
    }
  }

  Future<void> _onPollRequested(
    ResultPollRequested event,
    Emitter<ResultState> emit,
  ) async {
    if (_stopped) return;
    _activeTaskId ??= event.taskId;
    if (_activeTaskId != event.taskId) return;
    final generation = _generation;
    if (!_pollsInFlight.add(generation)) return;
    try {
      final result = await repository.getAnalysisResult(event.taskId);
      if (generation != _generation || isClosed) return;
      emit(ResultLoaded(result));
      _schedulePollIfNeeded(event.taskId, result);
    } catch (_) {
      // โพลล้มเหลวครั้งเดียวไม่ควรทิ้งผลเดิมที่แสดงอยู่ ให้หยุดโพลเงียบๆ
      if (generation == _generation) _pollTimer?.cancel();
    } finally {
      _pollsInFlight.remove(generation);
    }
  }

  void _schedulePollIfNeeded(String taskId, AnalysisResult result) {
    if (!isXaiPending(result) || _pollCount >= maxPolls) return;
    _pollCount++;
    _pollTimer?.cancel();
    _pollTimer = Timer(pollInterval, () {
      if (!isClosed && _activeTaskId == taskId) {
        add(ResultPollRequested(taskId));
      }
    });
  }

  @override
  Future<void> close() {
    _generation++;
    _pollTimer?.cancel();
    return super.close();
  }
}
