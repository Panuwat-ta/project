import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scam_report.dart';
import '../../domain/repositories/report_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class ReportEvent extends Equatable {
  const ReportEvent();
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
    on<ReportSubmitted>(_onSubmitted);
  }

  final ReportRepository repository;

  Future<void> _onSubmitted(
    ReportSubmitted event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportSubmitting());
    try {
      await repository.submitReport(event.report);
      emit(const ReportSuccess());
    } catch (e) {
      emit(ReportError(_friendlyMessage(e)));
    }
  }

  String _friendlyMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('NetworkException') ||
        raw.contains('Connection error') ||
        raw.contains('SocketException')) {
      return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }
    if (raw.contains('401') || raw.contains('403') || raw.contains('AuthException')) {
      return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
    }
    return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }
}

// ── Mock Repository stub (dev / demo) ────────────────────────────────────────

/// Stub that simulates a successful submission with a short delay.
/// Used by [ReportScamScreen] during development until a real backend is wired up.
class MockReportRepository implements ReportRepository {
  @override
  Future<void> submitReport(ScamReport report) async {
    await Future.delayed(const Duration(seconds: 1));
    // No exception thrown — simulates a successful POST /reports
  }

  @override
  Future<List<String>> getCategories() async => [
        'Romance Scam',
        'ซื้อขายออนไลน์',
        'สลิปปลอม',
        'ลงทุนหรือผลตอบแทนสูง',
        'ปลอมแปลงตัวตน',
        'ภาพ AI หรือ Deepfake',
        'อื่นๆ',
      ];
}
