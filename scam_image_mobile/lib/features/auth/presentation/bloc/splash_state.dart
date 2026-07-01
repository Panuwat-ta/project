part of 'splash_cubit.dart';

/// Base class for all splash states.
abstract class SplashState extends Equatable {
  const SplashState();
}

/// Initial state before any session check has begun.
class SplashInitial extends SplashState {
  const SplashInitial();

  @override
  List<Object?> get props => [];
}

/// Token validation / session check in progress.
class CheckingSession extends SplashState {
  const CheckingSession();

  @override
  List<Object?> get props => [];
}

/// A valid session was found and the user was retrieved successfully.
class SplashAuthenticated extends SplashState {
  const SplashAuthenticated({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

/// No valid session exists — user must log in.
class SplashUnauthenticated extends SplashState {
  const SplashUnauthenticated();

  @override
  List<Object?> get props => [];
}

/// User is authenticated but has not yet accepted consent — redirect to onboarding.
class SplashConsentRequired extends SplashState {
  const SplashConsentRequired();

  @override
  List<Object?> get props => [];
}

/// An unexpected error occurred during the session check.
class SplashFailure extends SplashState {
  const SplashFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
