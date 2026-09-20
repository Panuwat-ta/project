import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:scam_image_mobile/core/storage/database_helper.dart';

Future<Database> openMemoryDb() =>
    databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

Future<Set<String>> columns(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name'] as String).toSet();
}

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'latest create schema contains history and every detail column',
    () async {
      final db = await openMemoryDb();
      final helper = DatabaseHelper.forTesting(db);
      await helper.createSchemaForTesting(db, 4);

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      )).map((r) => r['name']).toSet();
      expect(
        tables,
        containsAll([DatabaseHelper.tableHistory, DatabaseHelper.tableDetails]),
      );

      expect(
        await columns(db, DatabaseHelper.tableDetails),
        containsAll([
          'scanId',
          'taskId',
          'status',
          'riskScore',
          'riskLevel',
          'summary',
          'imageUrl',
          'heatmapUrl',
          'createdAt',
          'factorsJson',
          'xaiExplanation',
          'aiGenProbability',
          'ocrText',
          'scamKeywordsJson',
        ]),
      );
      await db.close();
    },
  );

  test(
    'v3 to v4 partial migration adds remaining columns independently',
    () async {
      final db = await openMemoryDb();
      await db.execute('''
      CREATE TABLE ${DatabaseHelper.tableDetails} (
        scanId TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        status TEXT NOT NULL,
        riskScore INTEGER NOT NULL,
        riskLevel TEXT NOT NULL,
        summary TEXT,
        imageUrl TEXT,
        heatmapUrl TEXT,
        createdAt TEXT NOT NULL,
        factorsJson TEXT,
        xaiExplanation TEXT,
        aiGenProbability REAL
      )
    ''');
      final helper = DatabaseHelper.forTesting(db);

      await helper.upgradeSchemaForTesting(db, 3, 4);

      final names = await columns(db, DatabaseHelper.tableDetails);
      expect(names, contains('aiGenProbability'));
      expect(names, contains('ocrText'));
      expect(names, contains('scamKeywordsJson'));
      await db.close();
    },
  );

  test('v2 to v4 migration adds xai and all v4 analysis columns', () async {
    final db = await openMemoryDb();
    await db.execute('''
      CREATE TABLE ${DatabaseHelper.tableDetails} (
        scanId TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        status TEXT NOT NULL,
        riskScore INTEGER NOT NULL,
        riskLevel TEXT NOT NULL,
        summary TEXT,
        imageUrl TEXT,
        heatmapUrl TEXT,
        createdAt TEXT NOT NULL,
        factorsJson TEXT
      )
    ''');
    final helper = DatabaseHelper.forTesting(db);

    await helper.upgradeSchemaForTesting(db, 2, 4);

    expect(
      await columns(db, DatabaseHelper.tableDetails),
      containsAll([
        'xaiExplanation',
        'aiGenProbability',
        'ocrText',
        'scamKeywordsJson',
      ]),
    );
    await db.close();
  });
}
