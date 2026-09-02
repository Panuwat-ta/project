import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "scamguard.db";
  static const _databaseVersion = 4;
  static const tableHistory = 'scan_history';
  static const tableDetails = 'scan_details';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableHistory (
        scanId TEXT PRIMARY KEY,
        thumbnailUrl TEXT,
        riskScore INTEGER NOT NULL,
        riskLevel TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        title TEXT
      )
      ''');
    await _createDetailsTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDetailsTable(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tableDetails ADD COLUMN xaiExplanation TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE $tableDetails ADD COLUMN aiGenProbability REAL');
        await db.execute('ALTER TABLE $tableDetails ADD COLUMN ocrText TEXT');
        await db.execute('ALTER TABLE $tableDetails ADD COLUMN scamKeywordsJson TEXT');
      } catch (_) {}
    }
  }

  Future _createDetailsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableDetails (
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
        ocrText TEXT,
        scamKeywordsJson TEXT
      )
      ''');
  }
}
