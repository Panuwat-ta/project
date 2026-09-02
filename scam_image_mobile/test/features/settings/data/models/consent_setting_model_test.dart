import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/settings/data/models/consent_setting_model.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';

void main() {
  group('ConsentSettingModel.fromJson', () {
    test('parses camelCase keys', () {
      final json = {
        'processingConsent': true,
        'historyConsent': false,
        'researchConsent': true,
      };

      final model = ConsentSettingModel.fromJson(json);

      expect(model.processingConsent, true);
      expect(model.historyConsent, false);
      expect(model.researchConsent, true);
    });

    test('parses snake_case keys', () {
      final json = {
        'processing_consent': false,
        'history_consent': true,
        'research_consent': true,
      };

      final model = ConsentSettingModel.fromJson(json);

      expect(model.processingConsent, false);
      expect(model.historyConsent, true);
      expect(model.researchConsent, true);
    });

    test('prefers camelCase over snake_case', () {
      final json = {
        'processingConsent': true,
        'processing_consent': false,
        'historyConsent': true,
        'history_consent': false,
        'researchConsent': true,
        'research_consent': false,
      };

      final model = ConsentSettingModel.fromJson(json);

      expect(model.processingConsent, true);
      expect(model.historyConsent, true);
      expect(model.researchConsent, true);
    });

    test('defaults when fields are missing', () {
      final model = ConsentSettingModel.fromJson(<String, dynamic>{});

      expect(model.processingConsent, true);
      expect(model.historyConsent, true);
      expect(model.researchConsent, false);
    });
  });

  group('ConsentSettingModel.toJson', () {
    test('round-trips correctly', () {
      const model = ConsentSettingModel(
        processingConsent: true,
        historyConsent: false,
        researchConsent: true,
      );

      final json = model.toJson();

      expect(json['processingConsent'], true);
      expect(json['historyConsent'], false);
      expect(json['researchConsent'], true);
    });
  });

  group('ConsentSettingModel.fromDomain', () {
    test('copies all fields from domain entity', () {
      const setting = ConsentSetting(
        processingConsent: false,
        historyConsent: true,
        researchConsent: true,
      );

      final model = ConsentSettingModel.fromDomain(setting);

      expect(model.processingConsent, false);
      expect(model.historyConsent, true);
      expect(model.researchConsent, true);
    });

    test('copies default domain entity', () {
      const setting = ConsentSetting();
      final model = ConsentSettingModel.fromDomain(setting);

      expect(model.processingConsent, true);
      expect(model.historyConsent, true);
      expect(model.researchConsent, false);
    });
  });

  group('ConsentSetting entity', () {
    test('default values', () {
      const setting = ConsentSetting();
      expect(setting.processingConsent, true);
      expect(setting.historyConsent, true);
      expect(setting.researchConsent, false);
    });

    test('copyWith overrides specified fields', () {
      const setting = ConsentSetting();
      final updated = setting.copyWith(researchConsent: true);

      expect(updated.processingConsent, true);
      expect(updated.historyConsent, true);
      expect(updated.researchConsent, true);
    });

    test('copyWith preserves unspecified fields', () {
      const setting = ConsentSetting(
        processingConsent: false,
        historyConsent: false,
        researchConsent: true,
      );
      final updated = setting.copyWith(processingConsent: true);

      expect(updated.processingConsent, true);
      expect(updated.historyConsent, false);
      expect(updated.researchConsent, true);
    });

    test('equality works', () {
      const a = ConsentSetting();
      const b = ConsentSetting();
      expect(a, equals(b));
    });

    test('inequality works', () {
      const a = ConsentSetting();
      const b = ConsentSetting(researchConsent: true);
      expect(a, isNot(equals(b)));
    });
  });
}
