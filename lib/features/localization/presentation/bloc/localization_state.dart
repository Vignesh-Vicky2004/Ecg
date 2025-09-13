import '../../../../core/bloc/base_bloc.dart';

/// Localization states
abstract class LocalizationState extends AppState {
  const LocalizationState();
}

class LocalizationInitial extends LocalizationState {
  const LocalizationInitial();
}

class LocalizationLoaded extends LocalizationState {
  final String currentLanguage;
  final Map<String, String> supportedLanguages;
  final Map<String, String> translations;

  const LocalizationLoaded({
    required this.currentLanguage,
    required this.supportedLanguages,
    required this.translations,
  });

  @override
  List<Object?> get props => [currentLanguage, supportedLanguages, translations];

  LocalizationLoaded copyWith({
    String? currentLanguage,
    Map<String, String>? supportedLanguages,
    Map<String, String>? translations,
  }) {
    return LocalizationLoaded(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      translations: translations ?? this.translations,
    );
  }

  /// Get the native name of current language
  String get currentLanguageName => supportedLanguages[currentLanguage] ?? 'English';

  /// Check if a language is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  /// Get localized string by key
  String getString(String key) {
    return translations[key] ?? key;
  }
}