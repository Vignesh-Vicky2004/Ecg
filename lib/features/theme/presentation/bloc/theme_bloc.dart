import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/utils.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// Theme BLoC to manage theme state and persistence
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final LocalStorage _localStorage;
  static const String _themeKey = 'theme_mode';
  static const String _followSystemKey = 'follow_system_theme';

  ThemeBloc({LocalStorage? localStorage})
      : _localStorage = localStorage ?? SharedPreferencesStorage(),
        super(const ThemeInitial()) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeToggled>(_onThemeToggled);
    on<ThemeChanged>(_onThemeChanged);
    on<SystemThemeChanged>(_onSystemThemeChanged);
  }

  Future<void> _onThemeInitialized(
    ThemeInitialized event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      LoggerService.debug('Initializing theme...');
      
      final savedThemeIndex = await _localStorage.getInt(_themeKey);
      final followSystem = await _localStorage.getBool(_followSystemKey) ?? true;
      
      ThemeMode themeMode;
      if (savedThemeIndex != null && savedThemeIndex >= 0 && savedThemeIndex < ThemeMode.values.length) {
        themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        themeMode = ThemeMode.system; // Default to system theme
      }
      
      emit(ThemeLoaded(
        themeMode: themeMode,
        followSystemTheme: followSystem,
      ));
      
      LoggerService.info('Theme initialized: $themeMode, follow system: $followSystem');
    } catch (error) {
      LoggerService.error('Failed to initialize theme', error);
      // Emit default theme on error
      emit(const ThemeLoaded(
        themeMode: ThemeMode.system,
        followSystemTheme: true,
      ));
    }
  }

  Future<void> _onThemeToggled(
    ThemeToggled event,
    Emitter<ThemeState> emit,
  ) async {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      ThemeMode newThemeMode;
      
      if (currentState.followSystemTheme) {
        // If following system, first toggle sets to light mode
        newThemeMode = ThemeMode.light;
      } else {
        // Toggle between light and dark
        switch (currentState.themeMode) {
          case ThemeMode.light:
            newThemeMode = ThemeMode.dark;
            break;
          case ThemeMode.dark:
            newThemeMode = ThemeMode.light;
            break;
          case ThemeMode.system:
            newThemeMode = ThemeMode.light;
            break;
        }
      }
      
      await _saveThemeMode(newThemeMode, followSystemTheme: false);
      
      emit(currentState.copyWith(
        themeMode: newThemeMode,
        followSystemTheme: false,
      ));
      
      LoggerService.info('Theme toggled to: $newThemeMode');
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      final followSystem = event.themeMode == ThemeMode.system;
      
      await _saveThemeMode(event.themeMode, followSystemTheme: followSystem);
      
      emit(currentState.copyWith(
        themeMode: event.themeMode,
        followSystemTheme: followSystem,
      ));
      
      LoggerService.info('Theme changed to: ${event.themeMode}');
    }
  }

  Future<void> _onSystemThemeChanged(
    SystemThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    final currentState = state;
    if (currentState is ThemeLoaded && currentState.followSystemTheme) {
      // Only respond to system theme changes if we're following the system
      LoggerService.info('System theme changed to: ${event.systemBrightness}');
      
      // The system will handle the actual theme change,
      // we just log it for debugging purposes
      // No need to emit a new state as ThemeMode.system automatically follows system brightness
    }
  }

  Future<void> _saveThemeMode(ThemeMode themeMode, {required bool followSystemTheme}) async {
    try {
      await Future.wait([
        _localStorage.setInt(_themeKey, themeMode.index),
        _localStorage.setBool(_followSystemKey, followSystemTheme),
      ]);
      LoggerService.debug('Theme preferences saved: $themeMode, follow system: $followSystemTheme');
    } catch (error) {
      LoggerService.error('Failed to save theme preferences', error);
    }
  }

  /// Get the current theme mode
  ThemeMode get currentThemeMode {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.themeMode;
    }
    return ThemeMode.system;
  }

  /// Check if currently using dark mode
  bool get isDarkMode {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.isDarkMode;
    }
    return false;
  }

  /// Check if following system theme
  bool get isFollowingSystem {
    final currentState = state;
    if (currentState is ThemeLoaded) {
      return currentState.followSystemTheme;
    }
    return true;
  }
}