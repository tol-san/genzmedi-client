import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Sealed hierarchy of global authentication states.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state while reading secure storage on app launch.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// User is unauthenticated (guest or logged out).
class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// Authentication is valid but the user has not completed interest onboarding.
class AuthNeedsOnboarding extends AuthState {
  final UserModel user;
  const AuthNeedsOnboarding(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is authenticated and active.
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// An authentication operation is in-progress (logging in / registering).
class AuthLoading extends AuthState {
  const AuthLoading();
}
