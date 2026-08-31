import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/analysis_result.dart';

import '../../domain/repositories/result_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class ResultEvent extends Equatable {
  const ResultEvent();
}

class ResultLoadRequested extends ResultEvent {
  const ResultLoadRequested(this.taskId);

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
    on<ResultLoadRequested>(_onLoadRequested);
  }

  final ResultRepository repository;

  Future<void> _onLoadRequested(
    ResultLoadRequested event,
    Emitter<ResultState> emit,
  ) async {
    emit(const ResultLoading());
    try {
      final result = await repository.getAnalysisResult(event.taskId);
      emit(ResultLoaded(result));
    } catch (e) {
      emit(ResultError(e.toString()));
    }
  }
}


