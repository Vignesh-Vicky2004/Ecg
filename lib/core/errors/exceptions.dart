/// Custom exceptions for the ECG application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server/API related exceptions
class ServerException extends AppException {
  const ServerException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Network connectivity exceptions
class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Cache/Local storage exceptions
class CacheException extends AppException {
  const CacheException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// ECG device and Bluetooth exceptions
class ECGDeviceException extends AppException {
  const ECGDeviceException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// File and media exceptions
class FileException extends AppException {
  const FileException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Medical data specific exceptions (for HIPAA compliance)
class MedicalDataException extends AppException {
  const MedicalDataException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Configuration exceptions
class ConfigException extends AppException {
  const ConfigException({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}