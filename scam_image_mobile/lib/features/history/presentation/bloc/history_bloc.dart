import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/history_repository.dart';


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
      // Client-side fallback filtering: server may ignore keyword, so filter locally too
      List<ScanHistoryItem> filtered = items;
      if (keyword != null && keyword.trim().isNotEmpty) {
        final kw = keyword.trim().toLowerCase();
        filtered = items.where((it) {
          return (it.title?.toLowerCase().contains(kw) ?? false) ||
              it.scanId.toLowerCase().contains(kw) ||
              it.status.toLowerCase().contains(kw) ||
              it.riskLevel.name.toLowerCase().contains(kw) ||
              it.riskScore.toString().contains(kw);
        }).toList();
      }
      if (filtered.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryDataLoaded(filtered));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}


