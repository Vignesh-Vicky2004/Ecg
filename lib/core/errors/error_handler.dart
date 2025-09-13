import '../errors/failures.dart';
import '../errors/exceptions.dart';

/// Error handler to convert exceptions to failures
class ErrorHandler {
  static Failure handleException(Exception exception) {
    if (exception is ServerException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is ECGDeviceException) {
      return ECGFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is FileException) {
      return StorageFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is PermissionException) {
      return PermissionFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is MedicalDataException) {
      return MedicalDataFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is ConfigException) {
      return ConfigFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else {
      return UnknownFailure(
        message: 'An unexpected error occurred: ${exception.toString()}',
        details: exception,
      );
    }
  }

  /// Convert Firebase Auth errors to user-friendly messages
  static String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Convert ECG device errors to user-friendly messages
  static String getECGErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'device-not-found':
        return 'ECG device not found. Please check if it\'s powered on and nearby.';
      case 'connection-failed':
        return 'Failed to connect to ECG device. Please try again.';
      case 'bluetooth-disabled':
        return 'Bluetooth is disabled. Please enable Bluetooth and try again.';
      case 'permission-denied':
        return 'Bluetooth permission denied. Please grant permission in settings.';
      case 'data-corrupted':
        return 'ECG data appears to be corrupted. Please record again.';
      case 'recording-failed':
        return 'Failed to record ECG data. Please ensure device is properly connected.';
      case 'low-battery':
        return 'ECG device battery is low. Please charge the device.';
      case 'signal-quality-poor':
        return 'Poor signal quality. Please check electrode contact.';
      default:
        return 'ECG device error. Please check device and try again.';
    }
  }

  /// Convert network errors to user-friendly messages
  static String getNetworkErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'no-internet':
        return 'No internet connection. Please check your network and try again.';
      case 'timeout':
        return 'Connection timeout. Please try again.';
      case 'server-error':
        return 'Server error. Please try again later.';
      case 'bad-request':
        return 'Invalid request. Please check your input.';
      case 'unauthorized':
        return 'Session expired. Please log in again.';
      case 'forbidden':
        return 'Access denied. You don\'t have permission for this action.';
      case 'not-found':
        return 'Requested resource not found.';
      default:
        return 'Network error. Please check your connection and try again.';
    }
  }
}