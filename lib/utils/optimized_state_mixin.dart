import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/optimization_config.dart';

/// Optimized setState manager to prevent performance issues
mixin OptimizedStateMixin<T extends StatefulWidget> on State<T> {
  bool _isMounted = true;
  bool _isDisposed = false;
  final Map<String, Timer> _debouncers = {};
  final Map<String, dynamic> _cachedData = {};
  
  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }
  
  @override
  void dispose() {
    _isMounted = false;
    _isDisposed = true;
    
    // Cancel all active debouncers
    for (final debouncer in _debouncers.values) {
      debouncer.cancel();
    }
    _debouncers.clear();
    _cachedData.clear();
    
    super.dispose();
  }
  
  /// Safe setState that checks mounted state
  void setStateSafe(VoidCallback fn, [String? reason]) {
    if (_isDisposed || !_isMounted || !mounted) {
      if (kDebugMode && OptimizationConfig.shouldMonitorPerformance) {
        debugPrint('⚠️ Attempted setState on unmounted widget: ${widget.runtimeType}');
      }
      return;
    }
    
    if (OptimizationConfig.shouldMonitorPerformance) {
      _trackSetStateCall(reason);
    }
    
    setState(fn);
  }
  
  /// Debounced setState to prevent rapid successive calls
  void setStateDebounced(
    VoidCallback fn, {
    String? key,
    Duration? delay,
    String? reason,
  }) {
    final debouncerKey = key ?? 'default';
    delay ??= OptimizationConfig.setStateDebounceDelay;
    
    // Cancel previous debouncer with same key
    _debouncers[debouncerKey]?.cancel();
    
    _debouncers[debouncerKey] = Timer(delay, () {
      if (_isMounted && mounted && !_isDisposed) {
        setStateSafe(fn, reason ?? 'debounced:$debouncerKey');
      }
      _debouncers.remove(debouncerKey);
    });
  }
  
  /// Async setState with proper error handling
  Future<void> setStateAsync(
    Future<void> Function() asyncFn, {
    String? reason,
    VoidCallback? onError,
  }) async {
    try {
      await asyncFn();
      
      if (_isMounted && mounted && !_isDisposed) {
        // Use PostFrameCallback to ensure safe timing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMounted && mounted && !_isDisposed) {
            setStateSafe(() {}, reason ?? 'async_completion');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in async setState: $e');
      }
      onError?.call();
    }
  }
  
  /// Cache data to prevent unnecessary rebuilds
  TCached getCachedData<TCached>(String key, TCached Function() dataProvider) {
    if (!_cachedData.containsKey(key)) {
      _cachedData[key] = dataProvider();
    }
    return _cachedData[key] as TCached;
  }
  
  /// Clear cached data
  void clearCache([String? key]) {
    if (key != null) {
      _cachedData.remove(key);
    } else {
      _cachedData.clear();
    }
  }
  
  /// Update cached data and trigger rebuild if needed
  void updateCachedData<TCached>(String key, TCached newData, {bool forceRebuild = false}) {
    final oldData = _cachedData[key];
    _cachedData[key] = newData;
    
    if (forceRebuild || oldData != newData) {
      setStateSafe(() {}, 'cache_update:$key');
    }
  }
  
  /// Batch multiple state changes
  void batchSetState(List<VoidCallback> functions, [String? reason]) {
    if (_isDisposed || !_isMounted || !mounted) return;
    
    setStateSafe(() {
      for (final fn in functions) {
        fn();
      }
    }, reason ?? 'batch_update');
  }
  
  void _trackSetStateCall(String? reason) {
    if (kDebugMode && OptimizationConfig.shouldMonitorPerformance) {
      debugPrint('setState in ${widget.runtimeType}${reason != null ? ' ($reason)' : ''}');
    }
  }
}

/// Utility class for managing complex state updates
class StateUpdateManager {
  static final Map<String, Timer> _globalDebouncers = {};
  
  /// Global debounced function execution
  static void debounceGlobal(
    String key,
    VoidCallback function, {
    Duration? delay,
  }) {
    delay ??= OptimizationConfig.setStateDebounceDelay;
    
    _globalDebouncers[key]?.cancel();
    _globalDebouncers[key] = Timer(delay, () {
      function();
      _globalDebouncers.remove(key);
    });
  }
  
  /// Cancel all global debouncers
  static void cancelAllDebouncers() {
    for (final timer in _globalDebouncers.values) {
      timer.cancel();
    }
    _globalDebouncers.clear();
  }
  
  /// Check if a debouncer is active
  static bool isDebouncing(String key) {
    return _globalDebouncers.containsKey(key) && 
           _globalDebouncers[key]!.isActive;
  }
}

/// Widget that automatically optimizes rebuilds
class OptimizedConsumer<T extends ChangeNotifier> extends StatefulWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  final bool Function(T previous, T current)? shouldRebuild;
  
  const OptimizedConsumer({
    super.key,
    required this.builder,
    this.child,
    this.shouldRebuild,
  });
  
  @override
  State<OptimizedConsumer<T>> createState() => _OptimizedConsumerState<T>();
}

class _OptimizedConsumerState<T extends ChangeNotifier> 
    extends State<OptimizedConsumer<T>> with OptimizedStateMixin {
  
  T? _previousValue;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      child: widget.child,
      builder: (context, value, child) {
        // Check if rebuild is actually needed
        if (widget.shouldRebuild != null && _previousValue != null) {
          if (!widget.shouldRebuild!(_previousValue!, value)) {
            // Return cached widget if no rebuild needed
            return getCachedData('last_widget', () => widget.builder(context, value, child));
          }
        }
        
        _previousValue = value;
        final builtWidget = widget.builder(context, value, child);
        
        // Cache the built widget
        updateCachedData('last_widget', builtWidget);
        
        return builtWidget;
      },
    );
  }
}
