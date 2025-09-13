// Temporary bridge to maintain compatibility while transitioning to BLoC
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';

class LocalizationService {
  // Placeholder method - should only be used as last resort
  static String getString(String key) {
    // This is a fallback that returns the key itself if no context is available
    return key;
  }
  
  // Placeholder for current language
  static String get currentLanguage => 'en';
  
  // Placeholder for supported languages
  static Map<String, String> get supportedLanguages => {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
  };
  
  // Method to get string with context (preferred approach)
  static String getStringWithContext(BuildContext context, String key) {
    try {
      final localizationBloc = context.read<LocalizationBloc>();
      return localizationBloc.getString(key);
    } catch (e) {
      // Fallback to key if BLoC is not available
      return key;
    }
  }
}