import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/report/data/models/scam_report_model.dart';
import 'package:scam_image_mobile/features/report/domain/entities/scam_report.dart';

void main() {
  group('ScamReportModel.toJson', () {
    test('emits snake_case keys matching server schema', () {
      const model = ScamReportModel(
        scanId: 'scan-abc',
        category: 'fake_slip',
        description: 'This is a test report description',
        platform: 'Facebook',
        referenceUrl: 'http://example.com/suspect',
        allowResearchUse: true,
      );

      final json = model.toJson();

      expect(json['scan_id'], 'scan-abc');
      expect(json['category'], 'fake_slip');
      expect(json['description'], 'This is a test report description');
      expect(json['platform'], 'Facebook');
      expect(json['reference_url'], 'http://example.com/suspect');
      expect(json['allow_research_use'], true);

      // Verify camelCase keys are NOT present
      expect(json.containsKey('scanId'), false);
      expect(json.containsKey('referenceUrl'), false);
      expect(json.containsKey('allowResearchUse'), false);
    });

    test('omits null scanId', () {
      const model = ScamReportModel(
        category: 'other',
        description: 'General report without scan',
      );

      final json = model.toJson();

      expect(json.containsKey('scan_id'), false);
    });

    test('omits null platform', () {
      const model = ScamReportModel(
        scanId: 'scan-1',
        category: 'romance_scam',
        description: 'Report without platform',
      );

      final json = model.toJson();

      expect(json.containsKey('platform'), false);
    });

    test('omits null referenceUrl', () {
      const model = ScamReportModel(
        scanId: 'scan-1',
        category: 'online_shopping',
        description: 'Report without reference URL',
      );

      final json = model.toJson();

      expect(json.containsKey('reference_url'), false);
    });

    test('defaults allowResearchUse to false', () {
      const model = ScamReportModel(
        category: 'investment',
        description: 'Investment scam report',
      );

      final json = model.toJson();

      expect(json['allow_research_use'], false);
    });
  });

  group('ScamReportModel.fromDomain', () {
    test('copies all fields from domain entity', () {
      const report = ScamReport(
        scanId: 'scan-xyz',
        category: 'ai_deepfake',
        description: 'AI generated deepfake image',
        platform: 'Line',
        referenceUrl: 'http://line.me/suspect',
        allowResearchUse: true,
      );

      final model = ScamReportModel.fromDomain(report);

      expect(model.scanId, report.scanId);
      expect(model.category, report.category);
      expect(model.description, report.description);
      expect(model.platform, report.platform);
      expect(model.referenceUrl, report.referenceUrl);
      expect(model.allowResearchUse, report.allowResearchUse);
    });

    test('preserves null optional fields', () {
      const report = ScamReport(
        category: 'other',
        description: 'Minimal report',
      );

      final model = ScamReportModel.fromDomain(report);

      expect(model.scanId, isNull);
      expect(model.platform, isNull);
      expect(model.referenceUrl, isNull);
      expect(model.allowResearchUse, false);
    });
  });

  group('ScamReportModel equality', () {
    test('equal models have same props', () {
      const a = ScamReportModel(
        scanId: 'a',
        category: 'cat',
        description: 'desc',
      );
      const b = ScamReportModel(
        scanId: 'a',
        category: 'cat',
        description: 'desc',
      );
      expect(a, equals(b));
    });

    test('different models are not equal', () {
      const a = ScamReportModel(
        category: 'cat1',
        description: 'desc1',
      );
      const b = ScamReportModel(
        category: 'cat2',
        description: 'desc2',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
