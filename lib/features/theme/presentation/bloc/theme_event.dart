import 'package:flutter/material.dart';
import '../../../../core/bloc/base_bloc.dart';

/// Theme events
abstract class ThemeEvent extends AppEvent {
  const ThemeEvent();
}

class ThemeInitialized extends ThemeEvent {
  const ThemeInitialized();
}

class ThemeToggled extends ThemeEvent {
  const ThemeToggled();
}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  const ThemeChanged({required this.themeMode});

  @override
  List<Object?> get props => [themeMode];
}

class SystemThemeChanged extends ThemeEvent {
  final Brightness systemBrightness;

  const SystemThemeChanged({required this.systemBrightness});

  @override
  List<Object?> get props => [systemBrightness];
}