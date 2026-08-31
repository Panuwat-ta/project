import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scam_image_mobile/features/result/data/models/analysis_result_model.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

void main() {
  setUpAll(() {
    // Initialize dotenv with test values so parseUrl works
    dotenv.loadFromString(envString: 'API_BASE_URL=http://10.0.0.1:8000/api/v1');
  });

  group('AnalysisResultModel.fromJson — server flat format', () {
    test('maps flat scores into RiskFactor list', () {
      final json = {
        'id': 'scan-abc',
        'status': 'completed',
        'total_risk_score': 75,
        'risk_grade': 'high',
        'text_score': 30,
        'visual_score': 25,
        'source_score': 20,
        'scam_keywords_found': ['transfer', 'urgent'],
        'ai_gen_probability': 0.85,
        'raw_image_url': 'uploads/image.jpg',
        'heatmap_image_url': 'uploads/heatmap.jpg',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);

      expect(model.scanId, 'scan-abc');
      expect(model.riskScore, 75);
      expect(model.riskLevel, RiskLevel.high);
      expect(model.factors.length, 3);

      final textFactor = model.factors.firstWhere((f) => f.type == 'textual');
      expect(textFactor.score, 30);
      expect(textFactor.details, contains('transfer'));

      final visualFactor = model.factors.firstWhere((f) => f.type == 'visual');
      expect(visualFactor.score, 25);
      expect(visualFactor.details.first, contains('0.85'));

      final sourceFactor = model.factors.firstWhere((f) => f.type == 'source');
      expect(sourceFactor.score, 20);
    });

    test('parses risk_grade medium correctly', () {
      final json = {
        'id': 'scan-1',
        'total_risk_score': 50,
        'risk_grade': 'medium',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.medium);
    });

    test('parses risk_grade low correctly', () {
      final json = {
        'id': 'scan-1',
        'total_risk_score': 10,
        'risk_grade': 'low',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.low);
    });

    test('falls back to RiskLevelHelper when no risk_grade', () {
      final json = {
        'id': 'scan-1',
        'total_risk_score': 80,
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.high);
    });

    test('falls back to RiskLevelHelper for medium range', () {
      final json = {
        'id': 'scan-1',
        'total_risk_score': 50,
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.medium);
    });

    test('falls back to RiskLevelHelper for low range', () {
      final json = {
        'id': 'scan-1',
        'total_risk_score': 10,
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.low);
    });
  });

  group('AnalysisResultModel.fromJson — client format with factors', () {
    test('parses factors array directly', () {
      final json = {
        'scanId': 'scan-1',
        'taskId': 'task-1',
        'status': 'completed',
        'riskScore': 60,
        'riskLevel': 'medium',
        'summary': 'Analysis complete',
        'createdAt': '2026-06-01T12:00:00',
        'factors': [
          {'type': 'textual', 'score': 30, 'title': 'Text', 'details': ['keyword1']},
          {'type': 'visual', 'score': 30, 'title': 'Visual', 'details': []},
        ],
      };

      final model = AnalysisResultModel.fromJson(json);

      expect(model.scanId, 'scan-1');
      expect(model.taskId, 'task-1');
      expect(model.riskScore, 60);
      expect(model.factors.length, 2);
    });
  });

  group('AnalysisResultModel URL parsing', () {
    test('absolute URLs are preserved', () {
      final json = {
        'id': 'scan-1',
        'imageUrl': 'http://cdn.example.com/image.jpg',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.imageUrl, 'http://cdn.example.com/image.jpg');
    });

    test('relative paths are resolved against API_BASE_URL', () {
      final json = {
        'id': 'scan-1',
        'raw_image_url': 'uploads/image.jpg',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.imageUrl, contains('http://10.0.0.1:8000'));
      expect(model.imageUrl, contains('/uploads/'));
    });

    test('null URLs remain null', () {
      final json = {
        'id': 'scan-1',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.imageUrl, isNull);
      expect(model.heatmapUrl, isNull);
    });

    test('backslashes in paths are normalized', () {
      final json = {
        'id': 'scan-1',
        'raw_image_url': r'uploads\subfolder\image.jpg',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.imageUrl, isNot(contains(r'\')));
      expect(model.imageUrl, contains('/uploads/'));
    });
  });

  group('AnalysisResultModel defaults', () {
    test('defaults riskScore to 0 when missing', () {
      final json = {
        'id': 'scan-1',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.riskScore, 0);
    });

    test('defaults status to completed when missing', () {
      final json = {
        'id': 'scan-1',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.status, 'completed');
    });

    test('defaults createdAt to now when missing', () {
      final json = {'id': 'scan-1'};

      final model = AnalysisResultModel.fromJson(json);
      expect(model.createdAt, isNotNull);
      // Should be approximately now
      expect(
        model.createdAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('generates summary when missing', () {
      final json = {
        'id': 'scan-1',
        'risk_grade': 'high',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.summary, contains('high'));
    });

    test('empty factors when no score fields', () {
      final json = {
        'id': 'scan-1',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = AnalysisResultModel.fromJson(json);
      expect(model.factors, isEmpty);
    });
  });
}
