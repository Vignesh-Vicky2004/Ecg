import 'package:flutter/foundation.dart';

/// Optimization configuration for performance tuning
class OptimizationConfig {
  // setState debouncing
  static const Duration setStateDebounceDelay = Duration(milliseconds: 50);
  static const Duration themeChangeDebounceDelay = Duration(milliseconds: 200);
  static const Duration navigationDebounceDelay = Duration(milliseconds: 100);
  
  // Performance monitoring
  static const bool enablePerformanceMonitoring = kDebugMode;
  static const bool enableMemoryTracking = kDebugMode;
  static const bool enableRebuildTracking = kDebugMode;
  static const bool shouldMonitorPerformance = kDebugMode;
  
  // Widget optimization
  static const bool enableWidgetCaching = true;
  static const bool enableListOptimizations = true;
  static const bool enableImageCaching = true;
  
  // Animation optimization
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  
  // Memory management
  static const int maxCachedWidgets = 50;
  static const int maxCachedImages = 100;
  static const Duration cacheCleanupInterval = Duration(minutes: 5);
  
  // ECG-specific optimizations
  static const int ecgDataBufferSize = 1000;
  static const Duration ecgUpdateInterval = Duration(milliseconds: 16); // 60 FPS
  static const int maxEcgHistoryPoints = 5000;
  
  // Bluetooth optimization
  static const Duration bluetoothScanDuration = Duration(seconds: 10);
  static const Duration bluetoothConnectionTimeout = Duration(seconds: 15);
  static const int maxBluetoothRetries = 3;
  
  // Network optimization
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxNetworkRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Gets optimization settings based on device performance
  static Map<String, dynamic> getOptimizationSettings() {
    return {
      'setStateDebounceDelay': setStateDebounceDelay.inMilliseconds,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableWidgetCaching': enableWidgetCaching,
      'maxCachedWidgets': maxCachedWidgets,
      'ecgUpdateInterval': ecgUpdateInterval.inMilliseconds,
      'bluetoothScanDuration': bluetoothScanDuration.inSeconds,
      'networkTimeout': networkTimeout.inSeconds,
    };
  }
  
  /// Checks if performance optimizations should be enabled
  static bool shouldOptimizeFor(String feature) {
    switch (feature) {
      case 'animations':
        return enableWidgetCaching;
      case 'lists':
        return enableListOptimizations;
      case 'images':
        return enableImageCaching;
      case 'ecg':
        return true; // Always optimize ECG data handling
      case 'bluetooth':
        return true; // Always optimize Bluetooth operations
      default:
        return false;
    }
  }
}
