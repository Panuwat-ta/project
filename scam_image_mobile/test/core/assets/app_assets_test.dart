import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'runtime assets include social SVGs without duplicating launcher source',
    () async {
      final assets = (await AssetManifest.loadFromAssetBundle(
        rootBundle,
      )).listAssets();
      expect(
        assets,
        containsAll([
          'assets/icons/google.svg',
          'assets/icons/github.svg',
          'assets/icons/facebook.svg',
          'assets/images/onboarding_hero.png',
        ]),
      );
      expect(assets, isNot(contains('assets/icons/scamguard_app_icon.png')));
      for (final name in ['google', 'github', 'facebook']) {
        expect(
          await rootBundle.loadString('assets/icons/$name.svg'),
          contains('<svg'),
        );
      }
    },
  );
}
