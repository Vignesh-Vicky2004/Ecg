import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for monitoring app performance and setState calls
class PerformanceMonitor {
  static const int _maxDebugMessages = 100;
  static final List<String> _debugMessages = [];
  static int _setStateCallCount = 0;
  static DateTime? _lastSetStateCall;
  
  /// Track setState calls to identify performance issues
  static void trackSetState(String widgetName, [String? reason]) {
    if (!kDebugMode) return;
    
    _setStateCallCount++;
    final now = DateTime.now();
    final timeSinceLastCall = _lastSetStateCall != null 
        ? now.difference(_lastSetStateCall!).inMilliseconds 
        : 0;
    
    final message = 'setState #$_setStateCallCount in $widgetName'
        '${reason != null ? ' ($reason)' : ''}'
        '${timeSinceLastCall < 100 ? ' [RAPID: ${timeSinceLastCall}ms]' : ''}';
    
    _addDebugMessage(message);
    _lastSetStateCall = now;
    
    // Warn about rapid setState calls
    if (timeSinceLastCall < 50 && timeSinceLastCall > 0) {
      debugPrint('⚠️ PERFORMANCE WARNING: Rapid setState calls detected in $widgetName');
    }
  }
  
  /// Track widget rebuilds
  static void trackRebuild(String widgetName, [String? reason]) {
    if (!kDebugMode) return;
    
    final message = 'Rebuild: $widgetName'
        '${reason != null ? ' ($reason)' : ''}';
    
    _addDebugMessage(message);
  }
  
  /// Track async operations
  static void trackAsyncOperation(String operation, Duration duration) {
    if (!kDebugMode) return;
    
    final message = 'Async: $operation took ${duration.inMilliseconds}ms';
    _addDebugMessage(message);
    
    // Warn about slow operations
    if (duration.inMilliseconds > 100) {
      debugPrint('⚠️ PERFORMANCE WARNING: Slow async operation: $operation (${duration.inMilliseconds}ms)');
    }
  }
  
  /// Get performance statistics
  static Map<String, dynamic> getStats() {
    if (!kDebugMode) return {};
    
    return {
      'setStateCallCount': _setStateCallCount,
      'lastSetStateCall': _lastSetStateCall?.toIso8601String(),
      'recentMessages': _debugMessages.take(10).toList(),
    };
  }
  
  /// Clear all tracked data
  static void reset() {
    if (!kDebugMode) return;
    
    _setStateCallCount = 0;
    _lastSetStateCall = null;
    _debugMessages.clear();
  }
  
  static void _addDebugMessage(String message) {
    if (_debugMessages.length >= _maxDebugMessages) {
      _debugMessages.removeAt(0);
    }
    _debugMessages.add('${DateTime.now().millisecondsSinceEpoch}: $message');
  }
  
  /// Print performance summary
  static void printSummary() {
    if (!kDebugMode) return;
    
    debugPrint('=== PERFORMANCE SUMMARY ===');
    debugPrint('Total setState calls: $_setStateCallCount');
    debugPrint('Recent activity:');
    for (final message in _debugMessages.take(5)) {
      debugPrint('  $message');
    }
    debugPrint('========================');
  }
}

/// Mixin for widgets to easily track performance
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  String get widgetName => widget.runtimeType.toString();
  
  @override
  void setState(VoidCallback fn) {
    PerformanceMonitor.trackSetState(widgetName);
    super.setState(fn);
  }
  
  @override
  void didUpdateWidget(covariant T oldWidget) {
    PerformanceMonitor.trackRebuild(widgetName, 'didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }
  
  /// Safely call setState with performance tracking
  void setStateSafe(VoidCallback fn, [String? reason]) {
    if (!mounted) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted setState on unmounted widget: $widgetName');
      }
      return;
    }
    
    PerformanceMonitor.trackSetState(widgetName, reason);
    setState(fn);
  }
  
  /// Debounced setState to prevent rapid calls
  void setStateDebounced(VoidCallback fn, [Duration delay = const Duration(milliseconds: 50)]) {
    Future.delayed(delay, () {
      if (mounted) {
        setStateSafe(fn, 'debounced');
      }
    });
  }
}
