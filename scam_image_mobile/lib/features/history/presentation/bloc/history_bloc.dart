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
  final Completer<void>? completer;
  const HistoryRefreshed([this.completer]);
  @override
  List<Object?> get props => [completer];
}

class HistorySearched extends HistoryEvent {
  final String keyword;
  const HistorySearched(this.keyword);
  @override
  List<Object?> get props => [keyword];
}

class HistoryItemDeleted extends HistoryEvent {
  final String scanId;
  final Completer<bool>? completer;
  const HistoryItemDeleted(this.scanId, [this.completer]);
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
    try {
      await _fetchItems(emit, keyword: _currentKeyword);
    } finally {
      if (event.completer?.isCompleted == false) {
        event.completer?.complete();
      }
    }
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
      // Remove from current list only after the server confirms deletion.
      if (state is HistoryDataLoaded) {
        final current = (state as HistoryDataLoaded).items;
        final updated = current.where((i) => i.scanId != event.scanId).toList();
        if (updated.isEmpty) {
          emit(const HistoryEmpty());
        } else {
          emit(HistoryDataLoaded(updated));
        }
      }
      if (event.completer?.isCompleted == false) {
        event.completer?.complete(true);
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
      if (event.completer?.isCompleted == false) {
        event.completer?.complete(false);
      }
    }
  }

  Future<void> _fetchItems(
    Emitter<HistoryState> emit, {
    String? keyword,
  }) async {
    try {
      const pageSize = 100;
      final items = <ScanHistoryItem>[];
      final seenScanIds = <String>{};
      var page = 1;

      while (true) {
        final batch = await repository.getScanHistory(
          page: page,
          limit: pageSize,
          keyword: keyword,
        );
        final before = items.length;
        for (final item in batch) {
          if (seenScanIds.add(item.scanId)) items.add(item);
        }
        if (batch.length < pageSize || items.length == before) break;
        page += 1;
      }
      // Client-side fallback filtering: server may ignore keyword, so filter locally too
      List<ScanHistoryItem> filtered = items;
      if (keyword != null && keyword.trim().isNotEmpty) {
        final kw = keyword.trim().toLowerCase();
        filtered = items.where((it) {
          return it.title?.toLowerCase().contains(kw) ?? false;
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
