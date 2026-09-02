import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/result/data/models/risk_factor_model.dart';

void main() {
  group('RiskFactorModel.fromJson', () {
    test('parses all fields', () {
      final json = {
        'type': 'textual',
        'score': 45,
        'title': 'Suspicious Text',
        'details': ['keyword1', 'keyword2'],
      };

      final model = RiskFactorModel.fromJson(json);

      expect(model.type, 'textual');
      expect(model.score, 45);
      expect(model.title, 'Suspicious Text');
      expect(model.details, ['keyword1', 'keyword2']);
    });

    test('defaults missing fields', () {
      final model = RiskFactorModel.fromJson(<String, dynamic>{});

      expect(model.type, '');
      expect(model.score, 0);
      expect(model.title, '');
      expect(model.details, isEmpty);
    });

    test('handles null details', () {
      final json = {
        'type': 'visual',
        'score': 50,
        'title': 'Visual anomaly',
        'details': null,
      };

      final model = RiskFactorModel.fromJson(json);
      expect(model.details, isEmpty);
    });

    test('converts non-string details to strings', () {
      final json = {
        'type': 'source',
        'score': 10,
        'title': 'Source check',
        'details': [42, true, 'text'],
      };

      final model = RiskFactorModel.fromJson(json);
      expect(model.details, ['42', 'true', 'text']);
    });
  });

  group('RiskFactorModel.toJson', () {
    test('round-trips correctly', () {
      const model = RiskFactorModel(
        type: 'textual',
        score: 30,
        title: 'Text Analysis',
        details: ['found', 'patterns'],
      );

      final json = model.toJson();

      expect(json['type'], 'textual');
      expect(json['score'], 30);
      expect(json['title'], 'Text Analysis');
      expect(json['details'], ['found', 'patterns']);

      // Verify round-trip
      final reconstructed = RiskFactorModel.fromJson(json);
      expect(reconstructed, equals(model));
    });
  });

  group('RiskFactorModel equality', () {
    test('equal models have same props', () {
      const a = RiskFactorModel(
        type: 'a',
        score: 10,
        title: 't',
        details: ['d'],
      );
      const b = RiskFactorModel(
        type: 'a',
        score: 10,
        title: 't',
        details: ['d'],
      );
      expect(a, equals(b));
    });

    test('different models are not equal', () {
      const a = RiskFactorModel(
        type: 'a',
        score: 10,
        title: 't',
        details: [],
      );
      const b = RiskFactorModel(
        type: 'b',
        score: 20,
        title: 'u',
        details: [],
      );
      expect(a, isNot(equals(b)));
    });
  });
}
