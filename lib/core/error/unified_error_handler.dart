import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../errors/failures.dart';
import '../errors/exceptions.dart';

enum ErrorSeverity {
  warning,
  error,
  critical,
}

class AppError {
  final String message;
  final String? userMessage;
  final ErrorSeverity severity;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String? context;

  AppError({
    required this.message,
    this.userMessage,
    required this.severity,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'AppError(message: $message, severity: $severity, timestamp: $timestamp)';
  }
}

/// Unified error handler for both exception conversion and UI error handling
class ErrorHandler {
  static final List<AppError> _errorLog = [];
  static const int maxLogEntries = 100;
  static final List<Function(AppError)> _listeners = [];

  /// Convert exceptions to failures (for BLoC pattern)
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

  /// Handle general app errors (for UI error handling)
  static void handleError(
    dynamic error, {
    String? userMessage,
    ErrorSeverity severity = ErrorSeverity.error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final appError = AppError(
      message: error.toString(),
      userMessage: userMessage,
      severity: severity,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
    );

    _logError(appError);
    _notifyListeners(appError);

    if (kDebugMode) {
      debugPrint('🚨 Error [${severity.name}]: ${appError.message}');
      if (context != null) {
        debugPrint('📍 Context: $context');
      }
    }
  }

  static void _logError(AppError error) {
    _errorLog.add(error);
    
    if (_errorLog.length > maxLogEntries) {
      _errorLog.removeAt(0);
    }
  }

  static void _notifyListeners(AppError error) {
    for (final listener in _listeners) {
      try {
        listener(error);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in error listener: $e');
        }
      }
    }
  }

  static void addListener(Function(AppError) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(AppError) listener) {
    _listeners.remove(listener);
  }

  static List<AppError> getRecentErrors({int? limit}) {
    final recentErrors = List<AppError>.from(_errorLog.reversed);
    if (limit != null && recentErrors.length > limit) {
      return recentErrors.take(limit).toList();
    }
    return recentErrors;
  }

  static void showErrorSnackBar(BuildContext context, AppError error) {
    if (!context.mounted) return;

    final userMessage = error.userMessage ?? _getDefaultUserMessage(error.severity);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.severity),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.severity),
        duration: Duration(
          seconds: error.severity == ErrorSeverity.critical ? 6 : 4,
        ),
        action: error.severity == ErrorSeverity.critical
            ? SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () => _showErrorDialog(context, error),
              )
            : null,
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getErrorIcon(error.severity)),
            const SizedBox(width: 8),
            Text(_getSeverityDisplayName(error.severity)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage ?? error.message),
            if (error.context != null) ...[
              const SizedBox(height: 8),
              Text('Context: ${error.context}', style: const TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Text('Time: ${error.timestamp.toString().substring(0, 19)}', 
                 style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        return 'ECG device not found. Please ensure it is powered on and nearby.';
      case 'connection-failed':
        return 'Failed to connect to ECG device. Please try again.';
      case 'data-invalid':
        return 'Invalid ECG data received. Please check device connection.';
      case 'permission-denied':
        return 'Bluetooth permission required to connect to ECG device.';
      default:
        return 'ECG device error. Please try again.';
    }
  }

  /// Convert network errors to user-friendly messages
  static String getNetworkErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'timeout':
        return 'Request timed out. Please check your connection and try again.';
      case 'no-internet':
        return 'No internet connection. Please check your network settings.';
      case 'server-error':
        return 'Server error. Please try again later.';
      case 'connection-failed':
        return 'Failed to connect to server. Please try again.';
      default:
        return 'Network error. Please check your connection and try again.';
    }
  }

  static String _getDefaultUserMessage(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return 'Something needs attention, but you can continue.';
      case ErrorSeverity.error:
        return 'An error occurred. Please try again.';
      case ErrorSeverity.critical:
        return 'A critical error occurred. Please restart the app.';
    }
  }

  static IconData _getErrorIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return Icons.warning;
      case ErrorSeverity.error:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.error_outline;
    }
  }

  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  static String _getSeverityDisplayName(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  static void clearErrorLog() {
    _errorLog.clear();
  }
}