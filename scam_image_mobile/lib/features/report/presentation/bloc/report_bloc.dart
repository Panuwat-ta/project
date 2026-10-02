import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scam_report.dart';
import '../../domain/repositories/report_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class ReportEvent extends Equatable {
  const ReportEvent();
}

class ReportSessionCleared extends ReportEvent {
  const ReportSessionCleared();
  @override
  List<Object?> get props => [];
}

class ReportSubmitted extends ReportEvent {
  const ReportSubmitted(this.report);

  final ScamReport report;

  @override
  List<Object?> get props => [report];
}

// ── States ──────────────────────────────────────────────────────────────────

abstract class ReportState extends Equatable {
  const ReportState();
}

class ReportInitial extends ReportState {
  const ReportInitial();
  @override
  List<Object?> get props => [];
}

class ReportSubmitting extends ReportState {
  const ReportSubmitting();
  @override
  List<Object?> get props => [];
}

class ReportSuccess extends ReportState {
  const ReportSuccess();
  @override
  List<Object?> get props => [];
}

class ReportError extends ReportState {
  const ReportError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc({required this.repository}) : super(const ReportInitial()) {
    on<ReportSessionCleared>((event, emit) {
      _sessionGeneration++;
      emit(const ReportInitial());
    });
    on<ReportSubmitted>(_onSubmitted);
  }

  final ReportRepository repository;
  int _sessionGeneration = 0;

  Future<void> _onSubmitted(
    ReportSubmitted event,
    Emitter<ReportState> emit,
  ) async {
    if (state is ReportSubmitting) return;
    final generation = _sessionGeneration;
    emit(const ReportSubmitting());
    try {
      await repository.submitReport(event.report);
      if (generation != _sessionGeneration || isClosed) return;
      emit(const ReportSuccess());
    } catch (e) {
      if (generation != _sessionGeneration || isClosed) return;
      emit(ReportError(_friendlyMessage(e)));
    }
  }

  String _friendlyMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('NetworkException') ||
        raw.contains('Connection error') ||
        raw.contains('SocketException')) {
      return 'report_error_network';
    }
    if (raw.contains('401') ||
        raw.contains('403') ||
        raw.contains('AuthException')) {
      return 'report_error_auth';
    }
    return 'report_error_generic';
  }
}
