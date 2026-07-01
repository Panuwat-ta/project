import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/consent_setting.dart';
import '../../domain/repositories/settings_repository.dart';

// ── Settings Cubit State ──────────────────────────────────────────────────────

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.consent = const ConsentSetting(),
    this.isLoading = false,
    this.error,
  });

  final ThemeMode themeMode;
  final ConsentSetting consent;
  final bool isLoading;
  final String? error;

  SettingsState copyWith({
    ThemeMode? themeMode,
    ConsentSetting? consent,
    bool? isLoading,
    String? error,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        consent: consent ?? this.consent,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [themeMode, consent, isLoading, error];
}

// ── Settings Cubit ────────────────────────────────────────────────────────────

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.repository}) : super(const SettingsState());

  final SettingsRepository repository;

  /// Sets the application theme mode.
  void setTheme(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
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
  @override
  Future<ConsentSetting> getConsents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ConsentSetting(
      processingConsent: true,
      historyConsent: true,
      researchConsent: false,
    );
  }

  @override
  Future<void> updateConsents(ConsentSetting setting) async {}

  @override
  Future<void> exportPrivacyData() async {}

  @override
  Future<void> deleteAccount() async {}
}
