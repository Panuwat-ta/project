import '../../../../core/storage/database_helper.dart';
import '../models/scan_history_item_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class HistoryLocalDataSource {
  Future<List<ScanHistoryItemModel>> getHistory();
  Future<void> cacheHistory(List<ScanHistoryItemModel> items);
  Future<void> clearHistory();
  Future<void> deleteHistoryItem(String scanId);
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
  Future<void> cacheHistory(List<ScanHistoryItemModel> items) async {
    final db = await databaseHelper.database;
    
    // Start a transaction to ensure all inserts succeed
    await db.transaction((txn) async {
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
  Future<void> clearHistory() async {
    final db = await databaseHelper.database;
    await db.delete(DatabaseHelper.tableHistory);
    // Also clear cached details
    try {
      await db.delete(DatabaseHelper.tableDetails);
    } catch (_) {}
  }

  @override
  Future<void> deleteHistoryItem(String scanId) async {
    final db = await databaseHelper.database;
    await db.delete(
      DatabaseHelper.tableHistory,
      where: 'scanId = ?',
      whereArgs: [scanId],
    );
    try {
      await db.delete(
        DatabaseHelper.tableDetails,
        where: 'scanId = ?',
        whereArgs: [scanId],
      );
    } catch (_) {}
  }
}
