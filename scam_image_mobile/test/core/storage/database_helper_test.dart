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
      expect(await helper.database, same(db));
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
          'manipulationConfidence',
          'ocrText',
          'scamKeywordsJson',
        ]),
      );
      await db.close();
    },
  );

  test(
    'v3 to v5 migration adds remaining columns and renames confidence',
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
      await helper.upgradeSchemaForTesting(db, 4, 5);

      final names = await columns(db, DatabaseHelper.tableDetails);
      expect(names, contains('manipulationConfidence'));
      expect(names, isNot(contains('aiGenProbability')));
      expect(names, contains('ocrText'));
      expect(names, contains('scamKeywordsJson'));
      await db.close();
    },
  );

  test(
    'v2 to v5 migration adds xai and renames the confidence column',
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
        factorsJson TEXT
      )
    ''');
      final helper = DatabaseHelper.forTesting(db);

      await helper.upgradeSchemaForTesting(db, 2, 4);
      await helper.upgradeSchemaForTesting(db, 4, 5);

      expect(
        await columns(db, DatabaseHelper.tableDetails),
        containsAll([
          'xaiExplanation',
          'manipulationConfidence',
          'ocrText',
          'scamKeywordsJson',
        ]),
      );
      expect(
        await columns(db, DatabaseHelper.tableDetails),
        isNot(contains('aiGenProbability')),
      );
      await db.close();
    },
  );

  test(
    'v1 to v5 migration tolerates columns from a partial earlier upgrade',
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
        aiGenProbability REAL,
        ocrText TEXT
      )
    ''');
      await db.insert(DatabaseHelper.tableDetails, {
        'scanId': 'scan-1',
        'taskId': 'task-1',
        'status': 'completed',
        'riskScore': 50,
        'riskLevel': 'medium',
        'createdAt': '2026-10-02T00:00:00Z',
        'aiGenProbability': 0.93,
        'ocrText': 'already migrated',
      });

      final helper = DatabaseHelper.forTesting(db);
      await helper.upgradeSchemaForTesting(db, 1, 5);

      final names = await columns(db, DatabaseHelper.tableDetails);
      expect(
        names,
        containsAll([
          'xaiExplanation',
          'manipulationConfidence',
          'ocrText',
          'scamKeywordsJson',
        ]),
      );
      final row = (await db.query(DatabaseHelper.tableDetails)).single;
      expect(row['manipulationConfidence'], isNull);
      expect(row['ocrText'], 'already migrated');
      await db.close();
    },
  );

  test('v5 migration tolerates an already-renamed confidence column', () async {
    final db = await openMemoryDb();
    await db.execute('''
      CREATE TABLE ${DatabaseHelper.tableDetails} (
        scanId TEXT PRIMARY KEY,
        manipulationConfidence REAL
      )
    ''');
    await db.insert(DatabaseHelper.tableDetails, {
      'scanId': 'scan-1',
      'manipulationConfidence': 0.75,
    });

    final helper = DatabaseHelper.forTesting(db);
    await helper.upgradeSchemaForTesting(db, 4, 5);

    final row = (await db.query(DatabaseHelper.tableDetails)).single;
    expect(row['manipulationConfidence'], isNull);
    await db.close();
  });
}
