import 'package:equatable/equatable.dart';

/// Base event class for all BLoC events
abstract class AppEvent extends Equatable {
  const AppEvent();
  
  @override
  List<Object?> get props => [];
}

/// Base state class for all BLoC states
abstract class AppState extends Equatable {
  const AppState();
  
  @override
  List<Object?> get props => [];
}

/// Common loading state mixin
mixin LoadingState {
  bool get isLoading;
}

/// Common error state mixin
mixin ErrorState {
  String? get errorMessage;
  bool get hasError => errorMessage != null;
}

/// Base state with common patterns
abstract class BaseState extends AppState with LoadingState, ErrorState {
  @override
  final bool isLoading;
  
  @override
  final String? errorMessage;

  const BaseState({
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [isLoading, errorMessage];
}

/// Initial state for BLoCs
class InitialState extends BaseState {
  const InitialState() : super();
}

/// Loading state for BLoCs
class LoadingAppState extends BaseState {
  const LoadingAppState() : super(isLoading: true);
}

/// Error state for BLoCs
class ErrorAppState extends BaseState {
  const ErrorAppState(String errorMessage) : super(errorMessage: errorMessage);
}

/// Success state for BLoCs
class SuccessState extends BaseState {
  final dynamic data;
  
  const SuccessState({this.data}) : super();
  
  @override
  List<Object?> get props => [data, ...super.props];
}