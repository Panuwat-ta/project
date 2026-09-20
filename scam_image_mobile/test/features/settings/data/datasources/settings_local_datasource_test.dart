import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_local_datasource.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage storage;
  late SettingsLocalDataSourceImpl dataSource;

  setUp(() {
    storage = MockSecureStorage();
    dataSource = SettingsLocalDataSourceImpl(secureStorage: storage);
  });

  test('theme system survives persistence round-trip', () async {
    when(
      () => storage.getToken(kThemeMode),
    ).thenAnswer((_) async => 'ThemeMode.system');
    expect(await dataSource.getThemeMode(), ThemeMode.system);
  });

  test('theme light/dark values are restored exactly', () async {
    when(
      () => storage.getToken(kThemeMode),
    ).thenAnswer((_) async => 'ThemeMode.dark');
    expect(await dataSource.getThemeMode(), ThemeMode.dark);

    when(
      () => storage.getToken(kThemeMode),
    ).thenAnswer((_) async => 'ThemeMode.light');
    expect(await dataSource.getThemeMode(), ThemeMode.light);
  });

  test('missing or unknown persisted theme safely defaults to light', () async {
    when(() => storage.getToken(kThemeMode)).thenAnswer((_) async => null);
    expect(await dataSource.getThemeMode(), ThemeMode.light);

    when(
      () => storage.getToken(kThemeMode),
    ).thenAnswer((_) async => 'corrupt-value');
    expect(await dataSource.getThemeMode(), ThemeMode.light);
  });

  test('saveThemeMode persists ThemeMode.system verbatim', () async {
    when(() => storage.saveToken(any(), any())).thenAnswer((_) async {});
    await dataSource.saveThemeMode(ThemeMode.system);
    verify(() => storage.saveToken(kThemeMode, 'ThemeMode.system')).called(1);
  });
}
