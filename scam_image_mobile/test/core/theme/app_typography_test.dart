import 'package:flutter_test/flutter_test.dart';

import 'package:scam_image_mobile/core/theme/app_typography.dart';

void main() {
  test('Thai UI typography contract keeps readable sizes and line heights', () {
    expect(AppTypography.headlineSize, 24);
    expect(AppTypography.titleSize, 20);
    expect(AppTypography.sectionSize, 18);
    expect(AppTypography.bodySize, 16);
    expect(AppTypography.buttonSize, 16);
    expect(AppTypography.captionSize, 13);
    expect(AppTypography.codeSize, 14);
    expect(AppTypography.bodyHeight, greaterThanOrEqualTo(1.4));
    expect(AppTypography.captionHeight, greaterThanOrEqualTo(1.35));
  });
}
