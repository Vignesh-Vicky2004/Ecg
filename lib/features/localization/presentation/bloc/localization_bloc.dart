import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/utils.dart';
import 'localization_event.dart';
import 'localization_state.dart';

/// Localization BLoC to manage language state and persistence
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  final LocalStorage _localStorage;
  static const String _languageKey = 'selected_language';

  // Supported languages
  static const Map<String, String> _supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
  };

  // Default translations (English)
  static const Map<String, String> _defaultTranslations = {
    'app_name': 'Cardiart',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'ok': 'OK',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'done': 'Done',
    'next': 'Next',
    'previous': 'Previous',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'sign_out': 'Sign Out',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'invalid_email': 'Please enter a valid email',
    'password_too_short': 'Password must be at least 6 characters',
    'passwords_do_not_match': 'Passwords do not match',
    'forgot_password': 'Forgot Password?',
    'create_account': 'Create Account',
    'already_have_account': 'Already have an account?',
    'no_ecg_data_message': 'No ECG data available',
    'home': 'Home',
    'record': 'Record',
    'history': 'History',
    'profile': 'Profile',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'light_theme': 'Light',
    'dark_theme': 'Dark',
    'system_theme': 'System',
  };

  LocalizationBloc({LocalStorage? localStorage})
      : _localStorage = localStorage ?? SharedPreferencesStorage(),
        super(const LocalizationInitial()) {
    on<LocalizationInitialized>(_onLocalizationInitialized);
    on<LanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onLocalizationInitialized(
    LocalizationInitialized event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      LoggerService.debug('Initializing localization...');
      
      // Get saved language or use provided one or default to English
      String currentLanguage = event.savedLanguage ?? 
                               await _localStorage.getString(_languageKey) ?? 
                               'en';
      
      // Validate that the language is supported
      if (!_supportedLanguages.containsKey(currentLanguage)) {
        LoggerService.warning('Unsupported language: $currentLanguage, falling back to English');
        currentLanguage = 'en';
      }
      
      emit(LocalizationLoaded(
        currentLanguage: currentLanguage,
        supportedLanguages: _supportedLanguages,
        translations: _defaultTranslations,
      ));
      
      LoggerService.info('Localization initialized with language: $currentLanguage');
    } catch (error) {
      LoggerService.error('Failed to initialize localization', error);
      // Emit default state on error
      emit(const LocalizationLoaded(
        currentLanguage: 'en',
        supportedLanguages: {'en': 'English'},
        translations: _defaultTranslations,
      ));
    }
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<LocalizationState> emit,
  ) async {
    final currentState = state;
    if (currentState is LocalizationLoaded) {
      try {
        // Validate the language code
        if (!currentState.isLanguageSupported(event.languageCode)) {
          LoggerService.warning('Attempted to change to unsupported language: ${event.languageCode}');
          return;
        }
        
        // Don't change if it's already the current language
        if (currentState.currentLanguage == event.languageCode) {
          LoggerService.debug('Language is already set to: ${event.languageCode}');
          return;
        }
        
        LoggerService.debug('Changing language to: ${event.languageCode}');
        
        // Save to local storage
        await _localStorage.setString(_languageKey, event.languageCode);
        
        // For now, we'll use the same translations for all languages
        // In a real app, you'd load different translation files here
        Map<String, String> translations = _defaultTranslations;
        
        // Emit new state
        emit(currentState.copyWith(
          currentLanguage: event.languageCode,
          translations: translations,
        ));
        
        LoggerService.info('Language changed to: ${event.languageCode}');
      } catch (error) {
        LoggerService.error('Failed to change language', error);
        // Don't emit error state for language changes, just log the error
      }
    }
  }

  /// Get the current language code
  String get currentLanguage {
    final currentState = state;
    if (currentState is LocalizationLoaded) {
      return currentState.currentLanguage;
    }
    return 'en'; // Default fallback
  }

  /// Get the current language name
  String get currentLanguageName {
    final currentState = state;
    if (currentState is LocalizationLoaded) {
      return currentState.currentLanguageName;
    }
    return 'English'; // Default fallback
  }

  /// Get all supported languages
  Map<String, String> get supportedLanguages {
    final currentState = state;
    if (currentState is LocalizationLoaded) {
      return currentState.supportedLanguages;
    }
    return {'en': 'English'}; // Default fallback
  }

  /// Check if a language is supported
  bool isLanguageSupported(String languageCode) {
    final currentState = state;
    if (currentState is LocalizationLoaded) {
      return currentState.isLanguageSupported(languageCode);
    }
    return languageCode == 'en'; // Default fallback
  }

  /// Get localized string by key
  String getString(String key) {
    final currentState = state;
    if (currentState is LocalizationLoaded) {
      return currentState.getString(key);
    }
    return key; // Default fallback
  }
}