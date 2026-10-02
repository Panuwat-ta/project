import 'package:equatable/equatable.dart';
import '../../../../core/storage/secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Handles authentication operations: login, register, logout.
///
/// Constructed with the app-scoped [AuthRepository] provided by dependency
/// injection in `main.dart`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository, {this.sessionStorage})
    : super(const AuthInitial()) {
    sessionStorage?.addListener(_onSessionChanged);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<AuthSessionRestored>(
      (event, emit) => emit(AuthAuthenticated(event.user)),
    );
  }

  final AuthRepository _repository;
  int _sessionGeneration = 0;
  final SecureStorage? sessionStorage;

  void _onSessionChanged() {
    if (!isClosed &&
        sessionStorage?.authSessionActive == false &&
        state is AuthAuthenticated) {
      add(const LogoutRequested());
    }
  }

  @override
  Future<void> close() {
    sessionStorage?.removeListener(_onSessionChanged);
    _sessionGeneration++;
    return super.close();
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    if (state is AuthLoading) return;
    final generation = _sessionGeneration;
    emit(const AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      if (generation != _sessionGeneration || isClosed) return;
      emit(AuthAuthenticated(user));
    } catch (e) {
      if (generation != _sessionGeneration || isClosed) return;
      emit(AuthError(_friendlyMessage(e)));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading) return;
    final generation = _sessionGeneration;
    emit(const AuthLoading());
    try {
      final user = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        systemConsent: event.systemConsent,
        researchConsent: event.researchConsent,
      );
      if (generation != _sessionGeneration || isClosed) return;
      emit(AuthAuthenticated(user));
    } catch (e) {
      if (generation != _sessionGeneration || isClosed) return;
      emit(AuthError(_friendlyMessage(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    _sessionGeneration++;
    emit(const AuthLoading());
    try {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_friendlyMessage(e)));
    }
  }

  /// Converts raw exception messages into localization keys.
  String _friendlyMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('incorrect email') ||
        msg.contains('invalid') ||
        msg.contains('credentials')) {
      return 'auth_error_credentials';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return 'auth_error_network';
    }
    if (msg.contains('email already') || msg.contains('already registered')) {
      return 'auth_error_email_registered';
    }
    return 'auth_error_generic';
  }
}
