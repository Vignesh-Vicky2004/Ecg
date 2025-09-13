import 'package:flutter/material.dart';
import '../../../../core/bloc/base_bloc.dart';

/// Theme states
abstract class ThemeState extends AppState {
  const ThemeState();
}

class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

class ThemeLoaded extends ThemeState {
  final ThemeMode themeMode;
  final bool followSystemTheme;

  const ThemeLoaded({
    required this.themeMode,
    this.followSystemTheme = false,
  });

  @override
  List<Object?> get props => [themeMode, followSystemTheme];

  ThemeLoaded copyWith({
    ThemeMode? themeMode,
    bool? followSystemTheme,
  }) {
    return ThemeLoaded(
      themeMode: themeMode ?? this.themeMode,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
    );
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;
}