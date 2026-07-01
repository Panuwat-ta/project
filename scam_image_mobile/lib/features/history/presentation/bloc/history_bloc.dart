import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../../../../features/result/domain/entities/analysis_result.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
}

class HistoryLoaded extends HistoryEvent {
  const HistoryLoaded();
  @override
  List<Object?> get props => [];
}

class HistoryRefreshed extends HistoryEvent {
  const HistoryRefreshed();
  @override
  List<Object?> get props => [];
}

class HistorySearched extends HistoryEvent {
  final String keyword;
  const HistorySearched(this.keyword);
  @override
  List<Object?> get props => [keyword];
}

class HistoryItemDeleted extends HistoryEvent {
  final String scanId;
  const HistoryItemDeleted(this.scanId);
  @override
  List<Object?> get props => [scanId];
}

// ── States ──────────────────────────────────────────────────────────────────

abstract class HistoryState extends Equatable {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
  @override
  List<Object?> get props => [];
}

class HistoryDataLoaded extends HistoryState {
  final List<ScanHistoryItem> items;
  const HistoryDataLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
  @override
  List<Object?> get props => [];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required this.repository}) : super(const HistoryInitial()) {
    on<HistoryLoaded>(_onLoaded);
    on<HistoryRefreshed>(_onRefreshed);
    on<HistorySearched>(_onSearched);
    on<HistoryItemDeleted>(_onDeleted);
  }

  final HistoryRepository repository;
  String _currentKeyword = '';

  Future<void> _onLoaded(
    HistoryLoaded event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    await _fetchItems(emit, keyword: _currentKeyword);
  }

  Future<void> _onRefreshed(
    HistoryRefreshed event,
    Emitter<HistoryState> emit,
  ) async {
    await _fetchItems(emit, keyword: _currentKeyword);
  }

  Future<void> _onSearched(
    HistorySearched event,
    Emitter<HistoryState> emit,
  ) async {
    _currentKeyword = event.keyword;
    await _fetchItems(emit, keyword: event.keyword);
  }

  Future<void> _onDeleted(
    HistoryItemDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await repository.deleteScanHistoryItem(event.scanId);
      // Remove from current list without full reload
      if (state is HistoryDataLoaded) {
        final current = (state as HistoryDataLoaded).items;
        final updated =
            current.where((i) => i.scanId != event.scanId).toList();
        if (updated.isEmpty) {
          emit(const HistoryEmpty());
        } else {
          emit(HistoryDataLoaded(updated));
        }
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _fetchItems(
    Emitter<HistoryState> emit, {
    String? keyword,
  }) async {
    try {
      final items = await repository.getScanHistory(keyword: keyword);
      if (items.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryDataLoaded(items));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}

// ── Mock Repository stub (dev / demo) ────────────────────────────────────────

/// Stub that returns fake [ScanHistoryItem] entries after a short delay.
/// Used by [HistoryScreen] during development until a real backend is wired up.
class MockHistoryRepository implements HistoryRepository {
  @override
  Future<List<ScanHistoryItem>> getScanHistory({
    int page = 1,
    int limit = 20,
    String? riskLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String? keyword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final items = [
      ScanHistoryItem(
        scanId: 'scan_001',
        riskScore: 92,
        riskLevel: RiskLevel.high,
        status: 'completed',
        createdAt: DateTime(2023, 10, 24, 14, 20),
        title: 'สลิปโอนเงินธนาคาร',
        thumbnailUrl: 'https://picsum.photos/seed/slip/200', // Mock image
      ),
      ScanHistoryItem(
        scanId: 'scan_002',
        riskScore: 45,
        riskLevel: RiskLevel.medium,
        status: 'completed',
        createdAt: DateTime(2023, 10, 23, 10, 45),
        title: 'คิวอาร์โค้ดชำระเงิน',
        thumbnailUrl: 'https://picsum.photos/seed/qr/200',
      ),
      ScanHistoryItem(
        scanId: 'scan_003',
        riskScore: 12,
        riskLevel: RiskLevel.low,
        status: 'completed',
        createdAt: DateTime(2023, 10, 22, 9, 12),
        title: 'เอกสารยืนยันตัวตน',
        thumbnailUrl: 'https://picsum.photos/seed/doc/200',
      ),
      ScanHistoryItem(
        scanId: 'scan_004',
        riskScore: 88,
        riskLevel: RiskLevel.high,
        status: 'completed',
        createdAt: DateTime(2023, 10, 21, 18, 30),
        title: 'ลิงก์ข้อความ SMS',
        thumbnailUrl: 'https://picsum.photos/seed/sms/200',
      ),
    ];
    if (keyword != null && keyword.isNotEmpty) {
      return items
          .where((i) =>
              (i.title ?? '').toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    return items;
  }

  @override
  Future<void> deleteScanHistoryItem(String scanId) async {}

  @override
  Future<void> clearAllHistory() async {}
}
