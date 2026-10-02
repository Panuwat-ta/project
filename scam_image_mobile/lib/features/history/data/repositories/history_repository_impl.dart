import '../../../../core/storage/secure_storage.dart';
import '../../../../core/errors/exceptions.dart';

import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';
import '../datasources/history_local_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.sessionStorage,
  });

  final HistoryRemoteDataSource remoteDataSource;
  final HistoryLocalDataSource localDataSource;
  final SecureStorage? sessionStorage;

  @override
  Future<List<ScanHistoryItem>> getScanHistory({
    int page = 1,
    int limit = 20,
    String? riskLevel,
    DateTime? fromDate,
    DateTime? toDate,
    String? keyword,
  }) async {
    final revision = sessionStorage?.authRevision;
    final hasFilters =
        riskLevel != null ||
        fromDate != null ||
        toDate != null ||
        (keyword != null && keyword.isNotEmpty) ||
        page > 1;

    try {
      final remoteData = await remoteDataSource.getScanHistory(
        page: page,
        limit: limit,
        riskLevel: riskLevel,
        fromDate: fromDate,
        toDate: toDate,
        keyword: keyword,
      );
      if (revision != sessionStorage?.authRevision) {
        throw const AuthException('Session ended');
      }
      if (!hasFilters) {
        try {
          if (sessionStorage == null) {
            await localDataSource.cacheHistory(remoteData);
          } else {
            await localDataSource.cacheHistory(
              remoteData,
              isCurrentSession: () => revision == sessionStorage!.authRevision,
            );
          }
        } catch (_) {
          // Cache failure must not discard a successful authoritative response.
        }
      }
      if (revision != sessionStorage?.authRevision) {
        throw const AuthException('Session ended');
      }
      return remoteData;
    } on NetworkException {
      if (revision != sessionStorage?.authRevision) {
        throw const AuthException('Session ended');
      }
      if (!hasFilters) {
        final localData = await localDataSource.getHistory();
        if (revision != sessionStorage?.authRevision) {
          throw const AuthException('Session ended');
        }
        if (localData.isNotEmpty) return localData;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteScanHistoryItem(String scanId) async {
    final revision = sessionStorage?.authRevision;
    await remoteDataSource.deleteScanHistoryItem(scanId);
    if (revision != sessionStorage?.authRevision) {
      throw const AuthException('Session ended');
    }
    if (sessionStorage == null) {
      await localDataSource.deleteHistoryItem(scanId);
    } else {
      await localDataSource.deleteHistoryItem(
        scanId,
        isCurrentSession: () => revision == sessionStorage!.authRevision,
      );
    }
  }

  @override
  Future<void> clearAllHistory() async {
    final revision = sessionStorage?.authRevision;
    await remoteDataSource.clearAllHistory();
    if (revision != sessionStorage?.authRevision) {
      throw const AuthException('Session ended');
    }
    if (sessionStorage == null) {
      await localDataSource.clearHistory();
    } else {
      await localDataSource.clearHistory(
        isCurrentSession: () => revision == sessionStorage!.authRevision,
      );
    }
  }
}
