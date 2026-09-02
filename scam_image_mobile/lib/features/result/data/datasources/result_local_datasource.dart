import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/database_helper.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/risk_factor.dart';

abstract class ResultLocalDataSource {
  Future<void> cacheResult(AnalysisResult result);
  Future<AnalysisResult?> getResult(String scanId);
  Future<void> clearCache();
}

class ResultLocalDataSourceImpl implements ResultLocalDataSource {
  ResultLocalDataSourceImpl({required this.databaseHelper});
  final DatabaseHelper databaseHelper;

  @override
  Future<void> cacheResult(AnalysisResult result) async {
    final db = await databaseHelper.database;
    final factorsJson = jsonEncode(result.factors.map((f) => {
          'type': f.type,
          'score': f.score,
          'title': f.title,
          'details': f.details,
        }).toList());
    await db.insert(
      DatabaseHelper.tableDetails,
      {
        'scanId': result.scanId,
        'taskId': result.taskId,
        'status': result.status,
        'riskScore': result.riskScore,
        'riskLevel': result.riskLevel.name,
        'summary': result.summary,
        'imageUrl': result.imageUrl,
        'heatmapUrl': result.heatmapUrl,
        'createdAt': result.createdAt.toIso8601String(),
        'factorsJson': factorsJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<AnalysisResult?> getResult(String scanId) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableDetails,
      where: 'scanId = ?',
      whereArgs: [scanId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final m = maps.first;
      return _mapToResult(m);
    }
    // Fallback: synthesize minimal result from history list cache (offline first view)
    final histMaps = await db.query(
      DatabaseHelper.tableHistory,
      where: 'scanId = ?',
      whereArgs: [scanId],
      limit: 1,
    );
    if (histMaps.isEmpty) return null;
    final h = histMaps.first;
    final riskLevel = RiskLevel.values.firstWhere(
      (e) => e.name == h['riskLevel'] as String,
      orElse: () => RiskLevel.low,
    );
    return AnalysisResult(
      scanId: h['scanId'] as String,
      taskId: h['scanId'] as String,
      status: h['status'] as String,
      riskScore: h['riskScore'] as int,
      riskLevel: riskLevel,
      summary: h['title'] as String? ?? '',
      imageUrl: h['thumbnailUrl'] as String?,
      heatmapUrl: null,
      createdAt: DateTime.parse(h['createdAt'] as String).toLocal(),
      factors: [
        RiskFactor(type: 'visual', score: h['riskScore'] as int, title: '', details: []),
      ],
    );
  }

  AnalysisResult _mapToResult(Map<String, dynamic> m) {
    final riskLevel = RiskLevel.values.firstWhere(
      (e) => e.name == m['riskLevel'] as String,
      orElse: () => RiskLevel.low,
    );
    List<RiskFactor> factors = [];
    try {
      final raw = m['factorsJson'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        factors = decoded.map((e) {
          final jm = e as Map<String, dynamic>;
          return RiskFactor(
            type: jm['type'] as String,
            score: jm['score'] as int,
            title: jm['title'] as String,
            details: (jm['details'] as List<dynamic>).map((d) => d as String).toList(),
          );
        }).toList();
      }
    } catch (_) {}
    return AnalysisResult(
      scanId: m['scanId'] as String,
      taskId: m['taskId'] as String,
      status: m['status'] as String,
      riskScore: m['riskScore'] as int,
      riskLevel: riskLevel,
      summary: m['summary'] as String? ?? '',
      imageUrl: m['imageUrl'] as String?,
      heatmapUrl: m['heatmapUrl'] as String?,
      createdAt: DateTime.parse(m['createdAt'] as String).toLocal(),
      factors: factors,
    );
  }

  @override
  Future<void> clearCache() async {
    final db = await databaseHelper.database;
    await db.delete(DatabaseHelper.tableDetails);
  }
}
