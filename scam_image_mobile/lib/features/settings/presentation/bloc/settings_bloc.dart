import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/consent_setting.dart';
import '../../domain/repositories/settings_repository.dart';

// ── Settings Cubit State ──────────────────────────────────────────────────────

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.language = 'th',
    this.consent = const ConsentSetting(),
    this.isLoading = false,
    this.error,
  });

  final ThemeMode themeMode;
  final String language;
  final ConsentSetting consent;
  final bool isLoading;
  final String? error;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    ConsentSetting? consent,
    bool? isLoading,
    String? error,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        consent: consent ?? this.consent,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [themeMode, language, consent, isLoading, error];
}

// ── Settings Cubit ────────────────────────────────────────────────────────────

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.repository}) : super(const SettingsState());

  final SettingsRepository repository;

<<<<<<< HEAD
  /// Loads the theme and language settings on app startup.
  Future<void> loadSettings() async {
    final mode = await repository.getThemeMode();
    final lang = await repository.getLanguage();
    emit(state.copyWith(themeMode: mode, language: lang));
=======
  /// Loads the initial settings from the repository.
  Future<void> loadSettings() async {
    final themeModeStr = await repository.getThemeMode();
    final language = await repository.getLanguage() ?? 'th';

    ThemeMode themeMode = ThemeMode.light;
    if (themeModeStr == 'ThemeMode.dark') {
      themeMode = ThemeMode.dark;
    } else if (themeModeStr == 'ThemeMode.system') {
      themeMode = ThemeMode.system;
    }

    emit(state.copyWith(themeMode: themeMode, language: language));
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099
  }

  /// Sets the application theme mode.
  Future<void> setTheme(ThemeMode mode) async {
<<<<<<< HEAD
    await repository.saveThemeMode(mode);
=======
    await repository.setThemeMode(mode.toString());
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099
    emit(state.copyWith(themeMode: mode));
  }

  /// Sets the application language.
  Future<void> setLanguage(String lang) async {
<<<<<<< HEAD
    await repository.saveLanguage(lang);
=======
    await repository.setLanguage(lang);
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099
    emit(state.copyWith(language: lang));
  }

  /// Loads current consent settings from the repository.
  Future<void> loadConsents() async {
    emit(state.copyWith(isLoading: true));
    try {
      final consent = await repository.getConsents();
      emit(state.copyWith(consent: consent, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Persists [updated] consent settings.
  Future<void> updateConsents(ConsentSetting updated) async {
    try {
      await repository.updateConsents(updated);
      emit(state.copyWith(consent: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Requests a data export for the authenticated user.
  Future<void> exportData() async {
    try {
      await repository.exportPrivacyData();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Permanently deletes the authenticated user's account.
  Future<void> deleteAccount() async {
    try {
      await repository.deleteAccount();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

// ── Mock repository stub (for local UI development) ──────────────────────────

class MockSettingsRepository implements SettingsRepository {
<<<<<<< HEAD
  ConsentSetting _consent = const ConsentSetting(
    processingConsent: true,
    historyConsent: true,
    researchConsent: false,
  );
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'th';
=======
  String? _themeMode;
  String? _language;
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099

  @override
  Future<ConsentSetting> getConsents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _consent;
  }

  @override
  Future<void> updateConsents(ConsentSetting setting) async {
    _consent = setting;
  }

  @override
  Future<void> exportPrivacyData() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
<<<<<<< HEAD
  Future<ThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  Future<String> getLanguage() async => _language;

  @override
  Future<void> saveLanguage(String language) async => _language = language;
=======
  Future<String?> getThemeMode() async => _themeMode;

  @override
  Future<void> setThemeMode(String mode) async => _themeMode = mode;

  @override
  Future<String?> getLanguage() async => _language;

  @override
  Future<void> setLanguage(String lang) async => _language = lang;
>>>>>>> 821656eeb2a76b54dc7b21b232bc919fe6f9e099
}
