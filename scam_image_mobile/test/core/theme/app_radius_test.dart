import 'package:flutter_test/flutter_test.dart';
import 'package:scam_image_mobile/core/theme/app_radius.dart';

void main() {
  test('shape tokens follow the redesign radius scale', () {
    expect(AppRadius.xs, 4);
    expect(AppRadius.sm, 8);
    expect(AppRadius.md, 12);
    expect(AppRadius.lg, 16);
    expect(AppRadius.pill, 999);
  });
}
