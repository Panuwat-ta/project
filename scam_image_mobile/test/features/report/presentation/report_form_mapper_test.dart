import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/features/report/presentation/report_form_mapper.dart';

void main() {
  test('standard category keeps trimmed details unchanged', () {
    expect(
      buildReportDescription(
        category: 'fake_slip',
        customCategory: 'ignored',
        details: '  รายละเอียดเหตุการณ์  ',
      ),
      'รายละเอียดเหตุการณ์',
    );
  });

  test('other category prefixes custom category exactly once', () {
    expect(
      buildReportDescription(
        category: 'other',
        customCategory: ' ประเภทเฉพาะ ',
        details: ' รายละเอียดเหตุการณ์ ',
      ),
      '[ประเภทเฉพาะ] รายละเอียดเหตุการณ์',
    );
  });

  test('standard platform returns stable stored value', () {
    expect(
      resolveReportPlatform(
        selectedPlatform: 'LINE',
        customPlatform: 'ignored',
      ),
      'LINE',
    );
  });

  test('other platform returns custom value, never translated label', () {
    expect(
      resolveReportPlatform(
        selectedPlatform: 'other',
        customPlatform: ' Discord ',
      ),
      'Discord',
    );
  });

  test('missing or blank platform maps to null', () {
    expect(
      resolveReportPlatform(selectedPlatform: null, customPlatform: ''),
      isNull,
    );
    expect(
      resolveReportPlatform(selectedPlatform: 'other', customPlatform: '  '),
      isNull,
    );
  });
}
