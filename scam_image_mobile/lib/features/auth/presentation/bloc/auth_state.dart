part of 'auth_bloc.dart';

/// Base class for all auth states.
abstract class AuthState extends Equatable {
  const AuthState();
}

/// Initial state before any auth action has been taken.
class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

/// Emitted while an auth operation (login / register / logout) is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

/// Emitted when the user is successfully authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Emitted when the user is logged out or no session exists.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();

  @override
  List<Object?> get props => [];
}

/// Emitted when an auth operation fails.
class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
