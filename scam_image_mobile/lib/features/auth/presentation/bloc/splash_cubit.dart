import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'splash_state.dart';

/// Checks the stored session on app launch and emits the appropriate routing state.
class SplashCubit extends Cubit<SplashState> {
  final AuthRepository _authRepository;
  final Duration splashDelay;

  SplashCubit(this._authRepository, {this.splashDelay = Duration.zero})
    : super(const SplashInitial());

  bool _checkingSession = false;

  /// Resolves the stored session without delaying startup for branding.
  Future<void> checkSession() async {
    if (_checkingSession || isClosed) return;
    _checkingSession = true;
    emit(const CheckingSession());
    try {
      if (splashDelay > Duration.zero) {
        await Future<void>.delayed(splashDelay);
      }
      if (isClosed) return;
      final hasSeenOnboarding = await _authRepository.hasSeenOnboarding();
      if (isClosed) return;
      if (!hasSeenOnboarding) {
        emit(const SplashConsentRequired());
        return;
      }

      final hasToken = await _authRepository.hasValidToken();
      if (isClosed) return;
      if (!hasToken) {
        emit(const SplashUnauthenticated());
        return;
      }
      final user = await _authRepository.getCurrentUser();
      if (isClosed) return;
      if (user != null) {
        emit(SplashAuthenticated(user: user));
      } else {
        emit(const SplashUnauthenticated());
      }
    } catch (e) {
      if (!isClosed) emit(SplashFailure(message: e.toString()));
    } finally {
      _checkingSession = false;
    }
  }
}
