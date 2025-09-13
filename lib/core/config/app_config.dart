import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized app configuration management
class AppConfig {
  // Environment configuration
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  // API Configuration
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get geminiApiUrl => dotenv.env['GEMINI_API_URL'] ?? 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';
  
  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  
  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'CardiArt ECG';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get supportEmail => dotenv.env['SUPPORT_EMAIL'] ?? 'support@yourcompany.com';
  
  // Feature Flags
  static bool get enableAiAnalysis => dotenv.env['ENABLE_AI_ANALYSIS']?.toLowerCase() == 'true';
  static bool get enableCloudSync => dotenv.env['ENABLE_CLOUD_SYNC']?.toLowerCase() == 'true';
  static bool get enableDebugLogging => dotenv.env['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';
  
  // Medical Constants
  static const int normalHeartRateMin = 60;
  static const int normalHeartRateMax = 100;
  static const int bradycardiaThreshold = 60;
  static const int tachycardiaThreshold = 100;
  static const int criticalHeartRateMin = 40;
  static const int criticalHeartRateMax = 150;
  
  // ECG Constants
  static const int ecgSampleRate = 250; // Hz
  static const int ecgBufferSize = 1000;
  static const Duration ecgSessionTimeout = Duration(minutes: 30);
  
  // Database Configuration
  static String get databaseName => isDevelopment ? 'ecg_dev' : 'ecg_prod';
  
  /// Validates if essential configuration is available
  static bool validateConfig() {
    if (kDebugMode && enableDebugLogging) {
      debugPrint('🔍 Validating app configuration...');
      debugPrint('Environment: $environment');
      debugPrint('Firebase Project: ${firebaseProjectId.isEmpty ? "Not set" : "Set"}');
      debugPrint('Gemini API: ${geminiApiKey.isEmpty ? "Not set" : "Set"}');
    }
    
    // Check critical configuration
    if (firebaseProjectId.isEmpty || firebaseApiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Warning: Firebase configuration incomplete');
      }
      return false;
    }
    
    return true;
  }
  
  /// Validates API key format
  static bool isApiKeyValid(String apiKey) {
    if (apiKey.isEmpty) return false;
    
    // Basic validation - API keys should be at least 20 characters
    if (apiKey.length < 20) return false;
    
    // Check for placeholder values
    if (apiKey.contains('your_') || apiKey.contains('_here')) return false;
    
    return true;
  }
  
  /// Gets environment-specific settings
  static Map<String, dynamic> getEnvironmentSettings() {
    return {
      'environment': environment,
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'enableAiAnalysis': enableAiAnalysis,
      'enableCloudSync': enableCloudSync,
      'enableDebugLogging': enableDebugLogging,
      'appName': appName,
      'appVersion': appVersion,
      'databaseName': databaseName,
    };
  }
}
