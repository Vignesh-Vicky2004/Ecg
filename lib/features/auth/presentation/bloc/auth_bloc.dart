import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/error/unified_error_handler.dart';
import '../../../../core/utils/utils.dart';
import '../../../../services/firebase_service.dart';
import '../../../../models/user_profile.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Authentication BLoC to manage authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);

    // Listen to auth state changes
    _initializeAuthStateListener();
  }

  void _initializeAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription = FirebaseService.authStateChanges().listen(
      (User? user) {
        add(AuthUserUpdated(user: user));
      },
      onError: (error) {
        LoggerService.error('Auth state change error', error);
        add(AuthUserUpdated(user: null));
      },
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        await _loadUserProfile(currentUser, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (error, stackTrace) {
      LoggerService.error('Auth check failed', error, stackTrace);
      final failure = ErrorHandler.handleException(
        AuthException(message: 'Failed to check authentication status'),
      );
      emit(AuthError(failure: failure));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final userCredential = await FirebaseService.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (userCredential.user != null) {
        await _loadUserProfile(userCredential.user!, emit);
        LoggerService.info('User signed in successfully');
      } else {
        throw const AuthException(message: 'Sign in failed');
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      LoggerService.error('Firebase auth sign in error', error, stackTrace);
      final failure = AuthFailure(
        message: ErrorHandler.getAuthErrorMessage(error.code),
        code: error.code,
        details: error,
      );
      emit(AuthError(failure: failure));
    } catch (error, stackTrace) {
      LoggerService.error('Sign in error', error, stackTrace);
      final failure = ErrorHandler.handleException(
        AuthException(message: 'Sign in failed'),
      );
      emit(AuthError(failure: failure));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final userCredential = await FirebaseService.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (userCredential.user != null) {
        // Update display name if provided
        if (event.displayName != null) {
          await userCredential.user!.updateDisplayName(event.displayName);
        }
        
        // Create user profile
        final userProfile = UserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: event.displayName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
        );
        
        await FirebaseService.saveUserProfile(
          userId: userCredential.user!.uid,
          userProfile: userProfile,
        );
        
        emit(AuthAuthenticated(
          user: userCredential.user!,
          userProfile: userProfile,
        ));
        
        LoggerService.info('User signed up successfully');
      } else {
        throw const AuthException(message: 'Sign up failed');
      }
    } on FirebaseAuthException catch (error, stackTrace) {
      LoggerService.error('Firebase auth sign up error', error, stackTrace);
      final failure = AuthFailure(
        message: ErrorHandler.getAuthErrorMessage(error.code),
        code: error.code,
        details: error,
      );
      emit(AuthError(failure: failure));
    } catch (error, stackTrace) {
      LoggerService.error('Sign up error', error, stackTrace);
      final failure = ErrorHandler.handleException(
        AuthException(message: 'Sign up failed'),
      );
      emit(AuthError(failure: failure));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      await FirebaseService.signOut();
      emit(const AuthUnauthenticated());
      LoggerService.info('User signed out successfully');
    } catch (error, stackTrace) {
      LoggerService.error('Sign out error', error, stackTrace);
      final failure = ErrorHandler.handleException(
        AuthException(message: 'Sign out failed'),
      );
      emit(AuthError(failure: failure));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: event.email);
      emit(AuthPasswordResetSent(email: event.email));
      LoggerService.info('Password reset email sent');
    } on FirebaseAuthException catch (error, stackTrace) {
      LoggerService.error('Firebase auth password reset error', error, stackTrace);
      final failure = AuthFailure(
        message: ErrorHandler.getAuthErrorMessage(error.code),
        code: error.code,
        details: error,
      );
      emit(AuthError(failure: failure));
    } catch (error, stackTrace) {
      LoggerService.error('Password reset error', error, stackTrace);
      final failure = ErrorHandler.handleException(
        AuthException(message: 'Failed to send password reset email'),
      );
      emit(AuthError(failure: failure));
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      // Google Sign In requires additional setup and packages
      // For now, show a helpful message to users
      throw const AuthException(
        message: 'Google Sign In requires additional configuration. Please use email sign in.',
        code: 'google-signin-unavailable',
      );
    } catch (error, stackTrace) {
      LoggerService.error('Google sign in error', error, stackTrace);
      final failure = ErrorHandler.handleException(
        AuthException(message: 'Google sign in failed'),
      );
      emit(AuthError(failure: failure));
    }
  }

  Future<void> _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user as User?;
    
    if (user != null) {
      await _loadUserProfile(user, emit);
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _loadUserProfile(User user, Emitter<AuthState> emit) async {
    try {
      final userProfile = await FirebaseService.getUserProfileData(user.uid);
      emit(AuthAuthenticated(user: user, userProfile: userProfile));
    } catch (error) {
      LoggerService.warning('Failed to load user profile', error);
      // Still emit authenticated state even if profile loading fails
      emit(AuthAuthenticated(user: user, userProfile: null));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}