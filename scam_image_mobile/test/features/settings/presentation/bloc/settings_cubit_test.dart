import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/settings/domain/entities/consent_setting.dart';
import 'package:scam_image_mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:scam_image_mobile/features/settings/presentation/bloc/settings_bloc.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  setUpAll(() {
    registerFallbackValue(ThemeMode.light);
    registerFallbackValue(const ConsentSetting());
  });

  group('loadSettings', () {
    blocTest<SettingsCubit, SettingsState>(
      'emits state with loaded themeMode and language',
      build: () {
        when(() => mockRepo.getThemeMode())
            .thenAnswer((_) async => ThemeMode.dark);
        when(() => mockRepo.getLanguage())
            .thenAnswer((_) async => 'en');
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.themeMode, 'themeMode', ThemeMode.dark)
            .having((s) => s.language, 'language', 'en'),
      ],
    );
  });

  group('setTheme', () {
    blocTest<SettingsCubit, SettingsState>(
      'saves theme mode and emits updated state',
      build: () {
        when(() => mockRepo.saveThemeMode(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.setTheme(ThemeMode.dark),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.themeMode, 'themeMode', ThemeMode.dark),
      ],
      verify: (_) {
        verify(() => mockRepo.saveThemeMode(ThemeMode.dark)).called(1);
      },
    );
  });

  group('setLanguage', () {
    blocTest<SettingsCubit, SettingsState>(
      'saves language and emits updated state',
      build: () {
        when(() => mockRepo.saveLanguage(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.setLanguage('en'),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.language, 'language', 'en'),
      ],
      verify: (_) {
        verify(() => mockRepo.saveLanguage('en')).called(1);
      },
    );
  });

  group('loadConsents', () {
    const tConsent = ConsentSetting(
      processingConsent: true,
      historyConsent: false,
      researchConsent: true,
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [loading, loaded] on success',
      build: () {
        when(() => mockRepo.getConsents())
            .thenAnswer((_) async => tConsent);
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadConsents(),
      expect: () => [
        isA<SettingsState>().having((s) => s.isLoading, 'isLoading', true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.consent, 'consent', tConsent),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => mockRepo.getConsents())
            .thenThrow(Exception('Failed to load'));
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadConsents(),
      expect: () => [
        isA<SettingsState>().having((s) => s.isLoading, 'isLoading', true),
        isA<SettingsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('updateConsents', () {
    const tConsent = ConsentSetting(
      processingConsent: true,
      historyConsent: true,
      researchConsent: true,
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits updated consent on success',
      build: () {
        when(() => mockRepo.updateConsents(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.updateConsents(tConsent),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.consent, 'consent', tConsent),
      ],
      verify: (_) {
        verify(() => mockRepo.updateConsents(tConsent)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error on failure',
      build: () {
        when(() => mockRepo.updateConsents(any()))
            .thenThrow(Exception('Update failed'));
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.updateConsents(tConsent),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('exportData', () {
    blocTest<SettingsCubit, SettingsState>(
      'calls exportPrivacyData without emitting on success',
      build: () {
        when(() => mockRepo.exportPrivacyData())
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.exportData(),
      expect: () => <SettingsState>[],
      verify: (_) {
        verify(() => mockRepo.exportPrivacyData()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error on failure',
      build: () {
        when(() => mockRepo.exportPrivacyData())
            .thenThrow(Exception('Export failed'));
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.exportData(),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('deleteAccount', () {
    blocTest<SettingsCubit, SettingsState>(
      'calls deleteAccount without emitting on success',
      build: () {
        when(() => mockRepo.deleteAccount())
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.deleteAccount(),
      expect: () => <SettingsState>[],
      verify: (_) {
        verify(() => mockRepo.deleteAccount()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error on failure',
      build: () {
        when(() => mockRepo.deleteAccount())
            .thenThrow(Exception('Delete failed'));
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('loadCacheSize', () {
    blocTest<SettingsCubit, SettingsState>(
      'emits state with real cache size on success',
      build: () {
        when(() => mockRepo.getCacheSizeBytes())
            .thenAnswer((_) async => 13002341);
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadCacheSize(),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.cacheSizeBytes, 'cacheSizeBytes', 13002341),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'keeps previous size and emits nothing on failure',
      build: () {
        when(() => mockRepo.getCacheSizeBytes())
            .thenThrow(Exception('Failed'));
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.loadCacheSize(),
      expect: () => <SettingsState>[],
    );
  });

  group('clearCache', () {
    blocTest<SettingsCubit, SettingsState>(
      'emits [clearing, cleared with refreshed size] on success',
      build: () {
        when(() => mockRepo.clearCache()).thenAnswer((_) async {});
        when(() => mockRepo.getCacheSizeBytes()).thenAnswer((_) async => 0);
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.clearCache(),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.isClearingCache, 'isClearingCache', true),
        isA<SettingsState>()
            .having((s) => s.isClearingCache, 'isClearingCache', false)
            .having((s) => s.cacheSizeBytes, 'cacheSizeBytes', 0),
      ],
      verify: (_) {
        verify(() => mockRepo.clearCache()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error on failure',
      build: () {
        when(() => mockRepo.clearCache())
            .thenThrow(Exception('Clear failed'));
        return SettingsCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.clearCache(),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.isClearingCache, 'isClearingCache', true),
        isA<SettingsState>()
            .having((s) => s.isClearingCache, 'isClearingCache', false)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('SettingsState', () {
    test('default values are correct', () {
      const state = SettingsState();
      expect(state.themeMode, ThemeMode.light);
      expect(state.language, 'th');
      expect(state.consent, const ConsentSetting());
      expect(state.isLoading, false);
      expect(state.cacheSizeBytes, 0);
      expect(state.isClearingCache, false);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged values', () {
      const state = SettingsState(language: 'en');
      final copied = state.copyWith(themeMode: ThemeMode.dark);
      expect(copied.language, 'en');
      expect(copied.themeMode, ThemeMode.dark);
    });
  });
}
