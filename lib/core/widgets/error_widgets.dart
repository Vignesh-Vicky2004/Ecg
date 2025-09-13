import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../errors/failures.dart';
import '../error/unified_error_handler.dart';
import '../../features/localization/presentation/bloc/localization_bloc.dart';

/// Widget to display error messages in a user-friendly way
class ErrorDisplayWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final Widget? customAction;

  const ErrorDisplayWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.showRetryButton = true,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(),
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _getErrorTitle(context.read<LocalizationBloc>()),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getUserFriendlyMessage(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (customAction != null)
            customAction!
          else if (showRetryButton && onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.read<LocalizationBloc>().getString('retry')),
            ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    if (failure is NetworkFailure) {
      return Icons.wifi_off;
    } else if (failure is AuthFailure) {
      return Icons.lock_outline;
    } else if (failure is ECGFailure) {
      return Icons.bluetooth_disabled;
    } else if (failure is StorageFailure) {
      return Icons.storage;
    } else if (failure is PermissionFailure) {
      return Icons.security;
    } else if (failure is ValidationFailure) {
      return Icons.error_outline;
    } else if (failure is MedicalDataFailure) {
      return Icons.local_hospital;
    } else {
      return Icons.error_outline;
    }
  }

  String _getErrorTitle(LocalizationBloc localizationBloc) {
    if (failure is NetworkFailure) {
      return localizationBloc.getString('network_error');
    } else if (failure is AuthFailure) {
      return localizationBloc.getString('auth_error');
    } else if (failure is ECGFailure) {
      return localizationBloc.getString('device_error');
    } else if (failure is StorageFailure) {
      return localizationBloc.getString('storage_error');
    } else if (failure is PermissionFailure) {
      return localizationBloc.getString('permission_error');
    } else if (failure is ValidationFailure) {
      return localizationBloc.getString('validation_error');
    } else if (failure is MedicalDataFailure) {
      return localizationBloc.getString('medical_data_error');
    } else {
      return localizationBloc.getString('error');
    }
  }

  String _getUserFriendlyMessage() {
    if (failure is AuthFailure && failure.code != null) {
      return ErrorHandler.getAuthErrorMessage(failure.code!);
    } else if (failure is ECGFailure && failure.code != null) {
      return ErrorHandler.getECGErrorMessage(failure.code!);
    } else if (failure is NetworkFailure) {
      return ErrorHandler.getNetworkErrorMessage(failure.code);
    } else {
      return failure.message;
    }
  }
}

/// Snackbar helper for showing error messages
class ErrorSnackBar {
  static void show(BuildContext context, Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                failure.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.read<LocalizationBloc>().getString('ok'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Error dialog helper
class ErrorDialog {
  static Future<void> show(BuildContext context, Failure failure) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(context.read<LocalizationBloc>().getString('error')),
          ],
        ),
        content: Text(failure.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.read<LocalizationBloc>().getString('ok')),
          ),
        ],
      ),
    );
  }
}