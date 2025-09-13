import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // Secure API configuration
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty && !kDebugMode) {
      throw Exception('GEMINI_API_KEY not configured');
    }
    return key;
  }

  static String get geminiApiUrl => dotenv.env['GEMINI_API_URL'] ?? 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static bool validateConfig() {
    if (kDebugMode) {
      debugPrint('🔍 Validating app configuration...');
      debugPrint('Environment: $environment');
      debugPrint('Firebase Project: ${firebaseProjectId.isEmpty ? "Not set" : "Set"}');
      debugPrint('Gemini API: ${geminiApiKey.isEmpty ? "Not set" : "Set"}');
    }

    if (isProduction) {
      return firebaseProjectId.isNotEmpty && 
             firebaseApiKey.isNotEmpty && 
             geminiApiKey.isNotEmpty;
    }

    return true; // Allow development mode without all keys
  }
}
