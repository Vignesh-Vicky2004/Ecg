import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/bloc/base_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/user_profile.dart';

/// Authentication states
abstract class AuthState extends AppState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final UserProfile? userProfile;

  const AuthAuthenticated({
    required this.user,
    this.userProfile,
  });

  @override
  List<Object?> get props => [user, userProfile];

  AuthAuthenticated copyWith({
    User? user,
    UserProfile? userProfile,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final Failure failure;

  const AuthError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}