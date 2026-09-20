import 'package:flutter_test/flutter_test.dart';

import 'package:scam_image_mobile/features/scan/presentation/image_crop_navigation.dart';

void main() {
  test('blank scan name is omitted from analysis navigation payload', () {
    final extra = buildAnalysisNavigationExtra(
      filePath: '/tmp/example.jpg',
      scanName: '   ',
    );

    expect(extra, {'filePath': '/tmp/example.jpg'});
    expect(extra.containsKey('scanName'), isFalse);
  });

  test('named scan is trimmed and included in payload', () {
    final extra = buildAnalysisNavigationExtra(
      filePath: '/tmp/example.jpg',
      scanName: '  หลักฐาน  ',
    );

    expect(extra['scanName'], 'หลักฐาน');
  });
}
