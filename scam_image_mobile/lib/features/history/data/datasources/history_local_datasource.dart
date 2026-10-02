import '../../../../core/storage/database_helper.dart';
import '../models/scan_history_item_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class HistoryLocalDataSource {
  Future<List<ScanHistoryItemModel>> getHistory();
  Future<void> cacheHistory(
    List<ScanHistoryItemModel> items, {
    bool Function()? isCurrentSession,
  });
  Future<void> clearHistory({bool Function()? isCurrentSession});
  Future<void> deleteHistoryItem(
    String scanId, {
    bool Function()? isCurrentSession,
  });
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  final DatabaseHelper databaseHelper;

  HistoryLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<ScanHistoryItemModel>> getHistory() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableHistory,
      orderBy: 'createdAt DESC',
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return ScanHistoryItemModel.fromMap(maps[i]);
    });
  }

  @override
  Future<void> cacheHistory(
    List<ScanHistoryItemModel> items, {
    bool Function()? isCurrentSession,
  }) async {
    final db = await databaseHelper.database;

    // Start a transaction to ensure all inserts succeed
    await db.transaction((txn) async {
      if (isCurrentSession != null && !isCurrentSession()) return;
      // Clear existing first for simplicity, or we can use replace.
      // Here we replace to keep the cache fresh.
      await txn.delete(DatabaseHelper.tableHistory);

      for (var item in items) {
        await txn.insert(
          DatabaseHelper.tableHistory,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> clearHistory({bool Function()? isCurrentSession}) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      if (isCurrentSession != null && !isCurrentSession()) return;
      await txn.delete(DatabaseHelper.tableHistory);
      await txn.delete(DatabaseHelper.tableDetails);
    });
  }

  @override
  Future<void> deleteHistoryItem(
    String scanId, {
    bool Function()? isCurrentSession,
  }) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      if (isCurrentSession != null && !isCurrentSession()) return;
      await txn.delete(
        DatabaseHelper.tableHistory,
        where: 'scanId = ?',
        whereArgs: [scanId],
      );
      await txn.delete(
        DatabaseHelper.tableDetails,
        where: 'scanId = ?',
        whereArgs: [scanId],
      );
    });
  }
}
