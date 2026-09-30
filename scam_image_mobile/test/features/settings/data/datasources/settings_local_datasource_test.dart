import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/core/storage/secure_storage.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';

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

  test('language defaults to th and restores persisted language', () async {
    when(() => storage.getToken(kLanguage)).thenAnswer((_) async => null);
    expect(await dataSource.getLanguage(), 'th');

    when(() => storage.getToken(kLanguage)).thenAnswer((_) async => 'en');
    expect(await dataSource.getLanguage(), 'en');
  });

  test('saveLanguage persists the selected language', () async {
    when(() => storage.saveToken(any(), any())).thenAnswer((_) async {});

    await dataSource.saveLanguage('en');

    verify(() => storage.saveToken(kLanguage, 'en')).called(1);
  });

  test('consents use safe defaults when nothing is persisted', () async {
    when(
      () => storage.getToken(kConsentProcessing),
    ).thenAnswer((_) async => null);
    when(() => storage.getToken(kConsentHistory)).thenAnswer((_) async => null);
    when(
      () => storage.getToken(kConsentResearch),
    ).thenAnswer((_) async => null);

    final setting = await dataSource.getConsents();

    expect(setting.processingConsent, isTrue);
    expect(setting.historyConsent, isTrue);
    expect(setting.researchConsent, isFalse);
  });

  test('consents restore persisted boolean strings exactly', () async {
    when(
      () => storage.getToken(kConsentProcessing),
    ).thenAnswer((_) async => 'false');
    when(
      () => storage.getToken(kConsentHistory),
    ).thenAnswer((_) async => 'false');
    when(
      () => storage.getToken(kConsentResearch),
    ).thenAnswer((_) async => 'true');

    final setting = await dataSource.getConsents();

    expect(setting.processingConsent, isFalse);
    expect(setting.historyConsent, isFalse);
    expect(setting.researchConsent, isTrue);
  });

  test('saveConsents persists all consent flags', () async {
    when(() => storage.saveToken(any(), any())).thenAnswer((_) async {});
    const setting = ConsentSetting(
      processingConsent: false,
      historyConsent: true,
      researchConsent: true,
    );

    await dataSource.saveConsents(setting);

    verify(() => storage.saveToken(kConsentProcessing, 'false')).called(1);
    verify(() => storage.saveToken(kConsentHistory, 'true')).called(1);
    verify(() => storage.saveToken(kConsentResearch, 'true')).called(1);
  });
  test('getCacheSizeBytes totals files recursively', () async {
    final dir = await Directory.systemTemp.createTemp('settings-cache-size-');
    addTearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });
    await File('${dir.path}/one.bin').writeAsBytes(<int>[1, 2, 3]);
    final nested = await Directory('${dir.path}/nested').create();
    await File('${nested.path}/two.bin').writeAsBytes(<int>[4, 5, 6, 7, 8]);
    dataSource = SettingsLocalDataSourceImpl(
      secureStorage: storage,
      temporaryDirectoryProvider: () async => dir,
      imageCacheClearer: () async {},
    );

    expect(await dataSource.getCacheSizeBytes(), 8);
  });

  test(
    'getCacheSizeBytes returns zero for missing directory or provider error',
    () async {
      final missing = Directory(
        '${Directory.systemTemp.path}/missing-settings-cache-${DateTime.now().microsecondsSinceEpoch}',
      );
      dataSource = SettingsLocalDataSourceImpl(
        secureStorage: storage,
        temporaryDirectoryProvider: () async => missing,
        imageCacheClearer: () async {},
      );
      expect(await dataSource.getCacheSizeBytes(), 0);

      dataSource = SettingsLocalDataSourceImpl(
        secureStorage: storage,
        temporaryDirectoryProvider: () =>
            Future<Directory>.error(StateError('temp failed')),
        imageCacheClearer: () async {},
      );
      expect(await dataSource.getCacheSizeBytes(), 0);
    },
  );

  test(
    'clearCache clears image cache and deletes temporary contents',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'settings-clear-cache-',
      );
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      await File('${dir.path}/scan.tmp').writeAsString('scan');
      await Directory('${dir.path}/nested').create();
      await File('${dir.path}/nested/image.tmp').writeAsString('image');
      var imageClearCalls = 0;
      dataSource = SettingsLocalDataSourceImpl(
        secureStorage: storage,
        temporaryDirectoryProvider: () async => dir,
        imageCacheClearer: () async => imageClearCalls += 1,
      );

      await dataSource.clearCache();

      expect(imageClearCalls, 1);
      expect(dir.listSync(), isEmpty);
    },
  );

  test(
    'clearCache tolerates cache-manager and temp-directory failures',
    () async {
      dataSource = SettingsLocalDataSourceImpl(
        secureStorage: storage,
        temporaryDirectoryProvider: () =>
            Future<Directory>.error(StateError('temp failed')),
        imageCacheClearer: () => Future<void>.error(StateError('cache failed')),
      );

      await expectLater(dataSource.clearCache(), completes);
    },
  );
}
