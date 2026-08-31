import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scam_image_mobile/features/history/data/models/scan_history_item_model.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://10.0.0.1:8000/api/v1');
  });

  group('ScanHistoryItemModel.fromJson', () {
    test('parses server format with snake_case keys', () {
      final json = {
        'scan_id': 'abc-123',
        'thumbnail_url': '/uploads/thumb.jpg',
        'risk_score': 80,
        'risk_level': 'high',
        'status': 'completed',
        'created_at': '2026-01-15T10:30:00',
        'title': 'Scan Result: HIGH',
      };

      final model = ScanHistoryItemModel.fromJson(json);

      expect(model.scanId, 'abc-123');
      expect(model.riskScore, 80);
      expect(model.riskLevel, RiskLevel.high);
      expect(model.status, 'completed');
      expect(model.title, 'Scan Result: HIGH');
      expect(model.createdAt, DateTime(2026, 1, 15, 10, 30));
    });

    test('parses camelCase keys', () {
      final json = {
        'scanId': 'scan-camel',
        'thumbnailUrl': 'http://example.com/thumb.jpg',
        'riskScore': 50,
        'riskLevel': 'medium',
        'status': 'completed',
        'createdAt': '2026-06-01T12:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);

      expect(model.scanId, 'scan-camel');
      expect(model.thumbnailUrl, 'http://example.com/thumb.jpg');
      expect(model.riskScore, 50);
      expect(model.riskLevel, RiskLevel.medium);
    });

    test('parses risk_level low', () {
      final json = {
        'scan_id': 'scan-1',
        'risk_score': 10,
        'risk_level': 'low',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.low);
    });

    test('falls back to RiskLevelHelper when no risk_level', () {
      final json = {
        'scan_id': 'scan-1',
        'risk_score': 75,
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.riskLevel, RiskLevel.high);
    });

    test('defaults riskScore to 0 when missing', () {
      final json = {
        'scan_id': 'scan-1',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.riskScore, 0);
    });

    test('defaults status to completed when missing', () {
      final json = {
        'scan_id': 'scan-1',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.status, 'completed');
    });

    test('defaults scanId to empty string when missing', () {
      final json = {
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.scanId, '');
    });

    test('handles null thumbnailUrl', () {
      final json = {
        'scan_id': 'scan-1',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.thumbnailUrl, isNull);
    });

    test('handles null title', () {
      final json = {
        'scan_id': 'scan-1',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.title, isNull);
    });

    test('defaults createdAt to now when missing', () {
      final json = {'scan_id': 'scan-1'};

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.createdAt, isNotNull);
      expect(
        model.createdAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('parses relative thumbnailUrl correctly', () {
      final json = {
        'scan_id': 'scan-1',
        'thumbnail_url': r'uploads\image.jpg',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.thumbnailUrl, contains('uploads'));
    });

    test('preserves absolute thumbnailUrl', () {
      final json = {
        'scan_id': 'scan-1',
        'thumbnail_url': 'http://cdn.example.com/image.jpg',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00',
      };

      final model = ScanHistoryItemModel.fromJson(json);
      expect(model.thumbnailUrl, 'http://cdn.example.com/image.jpg');
    });
  });

  group('ScanHistoryItemModel equality', () {
    test('equal models have same props', () {
      final a = ScanHistoryItemModel(
        scanId: 'a',
        riskScore: 10,
        riskLevel: RiskLevel.low,
        status: 'completed',
        createdAt: DateTime(2026, 1, 1),
      );
      final b = ScanHistoryItemModel(
        scanId: 'a',
        riskScore: 10,
        riskLevel: RiskLevel.low,
        status: 'completed',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(a, equals(b));
    });
  });
}
