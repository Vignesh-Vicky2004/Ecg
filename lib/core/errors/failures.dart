import 'package:equatable/equatable.dart';

/// Base failure class for all errors in the application
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Database/Firestore failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// ECG device and data failures
class ECGFailure extends Failure {
  const ECGFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// File and storage failures
class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Configuration and environment failures
class ConfigFailure extends Failure {
  const ConfigFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Medical data specific failures (HIPAA compliance)
class MedicalDataFailure extends Failure {
  const MedicalDataFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}