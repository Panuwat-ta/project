import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'splash_state.dart';

/// Checks the stored session on app launch and emits the appropriate routing state.
class SplashCubit extends Cubit<SplashState> {
  final AuthRepository _authRepository;

  SplashCubit(this._authRepository) : super(const SplashInitial());

  /// Verifies token validity and resolves the current user.
  Future<void> checkSession() async {
    emit(const CheckingSession());
    try {
      final hasToken = await _authRepository.hasValidToken();
      if (!hasToken) {
        emit(const SplashUnauthenticated());
        return;
      }
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(SplashAuthenticated(user: user));
      } else {
        emit(const SplashUnauthenticated());
      }
    } catch (e) {
      emit(SplashFailure(message: e.toString()));
    }
  }
}
