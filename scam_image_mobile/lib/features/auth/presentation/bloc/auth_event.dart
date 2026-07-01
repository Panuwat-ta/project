part of 'auth_bloc.dart';

/// Base class for all auth events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

/// Triggered when the user submits login credentials.
class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Triggered when the user submits the registration form.
class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Triggered when the user requests to log out.
class LogoutRequested extends AuthEvent {
  const LogoutRequested();

  @override
  List<Object?> get props => [];
}
