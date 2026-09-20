import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:scam_image_mobile/core/storage/database_helper.dart';
import 'package:scam_image_mobile/features/history/data/datasources/history_local_datasource.dart';
import 'package:scam_image_mobile/features/history/data/models/scan_history_item_model.dart';
import 'package:scam_image_mobile/features/result/data/datasources/result_local_datasource.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/result/domain/entities/risk_factor.dart';

void main() {
  late Database db;
  late DatabaseHelper helper;
  late HistoryLocalDataSourceImpl history;
  late ResultLocalDataSourceImpl results;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    helper = DatabaseHelper.forTesting(db);
    await helper.createSchemaForTesting(db, 4);
    history = HistoryLocalDataSourceImpl(databaseHelper: helper);
    results = ResultLocalDataSourceImpl(databaseHelper: helper);
  });

  tearDown(() async {
    await db.close();
  });

  ScanHistoryItemModel historyItem(
    String id, {
    DateTime? createdAt,
    int score = 50,
  }) => ScanHistoryItemModel(
    scanId: id,
    thumbnailUrl: '/uploads/$id.jpg',
    riskScore: score,
    riskLevel: RiskLevel.medium,
    status: 'completed',
    createdAt: createdAt ?? DateTime.utc(2026, 9, 20),
    title: 'Title $id',
  );

  AnalysisResult fullResult(String id) => AnalysisResult(
    scanId: id,
    taskId: id,
    status: 'completed',
    riskScore: 88,
    riskLevel: RiskLevel.high,
    summary: 'summary',
    imageUrl: 'http://host/image.jpg',
    heatmapUrl: 'http://host/heatmap.jpg',
    xaiExplanation: 'explanation',
    aiGenProbability: 0.72,
    ocrText: 'ข้อความ',
    scamKeywords: const ['keyword-a', 'keyword-b'],
    createdAt: DateTime.utc(2026, 9, 20, 1, 2, 3),
    factors: const [
      RiskFactor(
        type: 'visual',
        score: 88,
        title: 'Visual',
        details: ['detail'],
      ),
    ],
  );

  test('history cache round-trips and is ordered newest first', () async {
    await history.cacheHistory([
      historyItem('old', createdAt: DateTime.utc(2026, 9, 19)),
      historyItem('new', createdAt: DateTime.utc(2026, 9, 20)),
    ]);

    final items = await history.getHistory();

    expect(items.map((e) => e.scanId), ['new', 'old']);
    expect(items.first.title, 'Title new');
  });

  test(
    'cacheHistory replaces stale list instead of retaining removed rows',
    () async {
      await history.cacheHistory([historyItem('old')]);
      await history.cacheHistory([historyItem('fresh')]);

      expect((await history.getHistory()).map((e) => e.scanId), ['fresh']);
    },
  );

  test('full analysis result round-trips all extended fields', () async {
    final original = fullResult('scan-1');
    await results.cacheResult(original);

    final cached = await results.getResult('scan-1');

    expect(cached, isNotNull);
    expect(cached!.scanId, original.scanId);
    expect(cached.riskScore, 88);
    expect(cached.riskLevel, RiskLevel.high);
    expect(cached.xaiExplanation, 'explanation');
    expect(cached.aiGenProbability, 0.72);
    expect(cached.ocrText, 'ข้อความ');
    expect(cached.scamKeywords, ['keyword-a', 'keyword-b']);
    expect(cached.factors.single.details, ['detail']);
  });

  test('result cache falls back to a minimal history result offline', () async {
    await history.cacheHistory([historyItem('scan-h', score: 44)]);

    final cached = await results.getResult('scan-h');

    expect(cached, isNotNull);
    expect(cached!.taskId, 'scan-h');
    expect(cached.riskScore, 44);
    expect(cached.factors.single.type, 'visual');
  });

  test(
    'malformed optional JSON does not crash cached result decoding',
    () async {
      final r = fullResult('broken');
      await results.cacheResult(r);
      await db.update(
        DatabaseHelper.tableDetails,
        {'factorsJson': '{bad', 'scamKeywordsJson': '{bad'},
        where: 'scanId = ?',
        whereArgs: ['broken'],
      );

      final cached = await results.getResult('broken');

      expect(cached, isNotNull);
      expect(cached!.factors, isEmpty);
      expect(cached.scamKeywords, isNull);
    },
  );

  test(
    'deleteHistoryItem removes both list and matching detail cache',
    () async {
      await history.cacheHistory([
        historyItem('scan-1'),
        historyItem('scan-2'),
      ]);
      await results.cacheResult(fullResult('scan-1'));
      await results.cacheResult(fullResult('scan-2'));

      await history.deleteHistoryItem('scan-1');

      expect((await history.getHistory()).map((e) => e.scanId), ['scan-2']);
      expect(await results.getResult('scan-1'), isNull);
      expect(await results.getResult('scan-2'), isNotNull);
    },
  );

  test('clearHistory clears history and all cached details', () async {
    await history.cacheHistory([historyItem('scan-1')]);
    await results.cacheResult(fullResult('scan-1'));

    await history.clearHistory();

    expect(await history.getHistory(), isEmpty);
    expect(await results.getResult('scan-1'), isNull);
  });

  test('clearCache removes result details without deleting history', () async {
    await history.cacheHistory([historyItem('scan-1')]);
    await results.cacheResult(fullResult('scan-1'));

    await results.clearCache();

    expect(await history.getHistory(), hasLength(1));
    final fallback = await results.getResult('scan-1');
    expect(fallback, isNotNull);
    expect(fallback!.summary, 'Title scan-1');
  });
}
