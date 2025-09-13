import '../../../../core/bloc/base_bloc.dart';

/// Localization events
abstract class LocalizationEvent extends AppEvent {
  const LocalizationEvent();
}

class LocalizationInitialized extends LocalizationEvent {
  final String? savedLanguage;

  const LocalizationInitialized({this.savedLanguage});

  @override
  List<Object?> get props => [savedLanguage];
}

class LanguageChanged extends LocalizationEvent {
  final String languageCode;

  const LanguageChanged({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}