import 'package:equatable/equatable.dart';
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
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<AuthSessionRestored>(
      (event, emit) => emit(AuthAuthenticated(event.user)),
    );
  }

  final AuthRepository _repository;

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyMessage(e)));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        systemConsent: event.systemConsent,
        researchConsent: event.researchConsent,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyMessage(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(_friendlyMessage(e)));
    }
  }

  /// Converts raw exception messages into user-friendly Thai strings.
  String _friendlyMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('incorrect email') ||
        msg.contains('invalid') ||
        msg.contains('credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
    }
    if (msg.contains('email already') || msg.contains('already registered')) {
      return 'อีเมลนี้ถูกใช้งานแล้ว';
    }
    return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }
}
