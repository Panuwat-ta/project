import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/localization/app_translations.dart';

void main() {
  test('Thai and English dictionaries contain the same keys', () {
    final th = AppTranslations.localizedValues['th']!;
    final en = AppTranslations.localizedValues['en']!;
    expect(en.keys.toSet(), th.keys.toSet());
  });

  test(
    'English UI copy does not contain Thai literals except language name',
    () {
      final en = AppTranslations.localizedValues['en']!;
      final thai = RegExp(r'[ก-๙]');
      final offenders = <String>[];
      for (final entry in en.entries) {
        if (entry.key == 'language_th') continue;
        if (thai.hasMatch(entry.value)) offenders.add(entry.key);
      }
      expect(offenders, isEmpty);
    },
  );

  test('critical risk and unavailable states have localized copy', () {
    final th = AppTranslations.localizedValues['th']!;
    final en = AppTranslations.localizedValues['en']!;
    for (final key in <String>[
      'risk_low',
      'risk_medium',
      'risk_high',
      'risk_unknown',
      'result_evidence_unavailable',
      'result_summary_unavailable',
    ]) {
      expect(th[key], isNotEmpty, reason: 'missing Thai $key');
      expect(en[key], isNotEmpty, reason: 'missing English $key');
    }
  });
}
