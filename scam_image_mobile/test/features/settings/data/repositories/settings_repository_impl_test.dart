import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:scam_image_mobile/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:scam_image_mobile/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';

class MockSettingsLocal extends Mock implements SettingsLocalDataSource {}

class MockSettingsRemote extends Mock implements SettingsRemoteDataSource {}

void main() {
  late MockSettingsLocal local;
  late MockSettingsRemote remote;
  late SettingsRepositoryImpl repository;

  setUp(() {
    local = MockSettingsLocal();
    remote = MockSettingsRemote();
    repository = SettingsRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  test(
    'updateConsents is local-only while backend consent route is absent',
    () async {
      const consent = ConsentSetting(
        processingConsent: true,
        historyConsent: true,
        researchConsent: false,
      );
      when(() => local.saveConsents(consent)).thenAnswer((_) async {});

      await repository.updateConsents(consent);

      verify(() => local.saveConsents(consent)).called(1);
      verifyNoMoreInteractions(remote);
    },
  );

  test(
    'exportPrivacyData fails locally instead of issuing known 404 request',
    () {
      expect(repository.exportPrivacyData, throwsA(isA<UnsupportedError>()));
      verifyNoMoreInteractions(remote);
    },
  );

  test('deleteAccount forwards password to supported backend route', () async {
    when(() => remote.deleteAccount('secret123')).thenAnswer((_) async {});

    await repository.deleteAccount('secret123');

    verify(() => remote.deleteAccount('secret123')).called(1);
  });

  test('getConsents returns local consent state', () async {
    const consent = ConsentSetting(
      processingConsent: true,
      historyConsent: false,
      researchConsent: true,
    );
    when(() => local.getConsents()).thenAnswer((_) async => consent);

    expect(await repository.getConsents(), consent);
    verify(() => local.getConsents()).called(1);
  });

  test('theme mode reads and writes through local datasource', () async {
    when(() => local.getThemeMode()).thenAnswer((_) async => ThemeMode.dark);
    when(() => local.saveThemeMode(ThemeMode.system)).thenAnswer((_) async {});

    expect(await repository.getThemeMode(), ThemeMode.dark);
    await repository.saveThemeMode(ThemeMode.system);

    verify(() => local.getThemeMode()).called(1);
    verify(() => local.saveThemeMode(ThemeMode.system)).called(1);
  });

  test('language reads and writes through local datasource', () async {
    when(() => local.getLanguage()).thenAnswer((_) async => 'en');
    when(() => local.saveLanguage('th')).thenAnswer((_) async {});

    expect(await repository.getLanguage(), 'en');
    await repository.saveLanguage('th');

    verify(() => local.getLanguage()).called(1);
    verify(() => local.saveLanguage('th')).called(1);
  });

  test(
    'cache size and clear operations delegate to local datasource',
    () async {
      when(() => local.getCacheSizeBytes()).thenAnswer((_) async => 1234);
      when(() => local.clearCache()).thenAnswer((_) async {});

      expect(await repository.getCacheSizeBytes(), 1234);
      await repository.clearCache();

      verify(() => local.getCacheSizeBytes()).called(1);
      verify(() => local.clearCache()).called(1);
    },
  );

  test('delegated local errors propagate instead of being hidden', () async {
    when(
      () => local.getLanguage(),
    ).thenAnswer((_) async => throw StateError('storage failed'));

    await expectLater(repository.getLanguage(), throwsA(isA<StateError>()));
  });
}
