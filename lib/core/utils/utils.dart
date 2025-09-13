import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network information service
class NetworkInfo {
  final Connectivity _connectivity;
  
  NetworkInfo(this._connectivity);
  
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi) ||
           result.contains(ConnectivityResult.ethernet);
  }
  
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.contains(ConnectivityResult.mobile) || 
             results.contains(ConnectivityResult.wifi) ||
             results.contains(ConnectivityResult.ethernet);
    });
  }
  
  Future<ConnectivityResult> get connectivityType async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else {
      return ConnectivityResult.none;
    }
  }
}

/// Logger service for debugging and error tracking
class LoggerService {
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🐛 DEBUG: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }
  
  static void warning(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
    
    // In production, you might want to send errors to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  }
  
  static void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('🚨 CRITICAL: $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    
    // Always log critical errors regardless of debug mode
    // Consider immediate notification to monitoring services
  }
}