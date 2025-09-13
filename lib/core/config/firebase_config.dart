import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';

/// Firebase configuration management
class FirebaseConfig {
  /// Gets Firebase options based on environment
  static FirebaseOptions getOptions() {
    // Use environment-specific configuration
    if (AppConfig.isProduction) {
      return _getProductionOptions();
    } else if (AppConfig.isStaging) {
      return _getStagingOptions();
    } else {
      return _getDevelopmentOptions();
    }
  }
  
  /// Production Firebase configuration
  static FirebaseOptions _getProductionOptions() {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
      storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
    );
  }
  
  /// Staging Firebase configuration
  static FirebaseOptions _getStagingOptions() {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey,
      appId: AppConfig.firebaseAppId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: AppConfig.firebaseProjectId,
      authDomain: '${AppConfig.firebaseProjectId}.firebaseapp.com',
      storageBucket: '${AppConfig.firebaseProjectId}.appspot.com',
    );
  }
  
  /// Development Firebase configuration with fallback
  static FirebaseOptions _getDevelopmentOptions() {
    return FirebaseOptions(
      apiKey: AppConfig.firebaseApiKey.isNotEmpty 
          ? AppConfig.firebaseApiKey 
          : 'AIzaSyDemoApiKeyForDevelopment',
      appId: AppConfig.firebaseAppId.isNotEmpty 
          ? AppConfig.firebaseAppId 
          : '1:122063994231:android:9f8f8ac299cc0e302ff572',
      messagingSenderId: AppConfig.firebaseMessagingSenderId.isNotEmpty 
          ? AppConfig.firebaseMessagingSenderId 
          : '122063994231',
      projectId: AppConfig.firebaseProjectId.isNotEmpty 
          ? AppConfig.firebaseProjectId 
          : 'ecgapp-86a0a',
      authDomain: AppConfig.firebaseProjectId.isNotEmpty 
          ? '${AppConfig.firebaseProjectId}.firebaseapp.com'
          : 'ecgapp-86a0a.firebaseapp.com',
      storageBucket: AppConfig.firebaseProjectId.isNotEmpty 
          ? '${AppConfig.firebaseProjectId}.appspot.com'
          : 'ecgapp-86a0a.appspot.com',
    );
  }
  
  /// Validates Firebase configuration
  static bool validateConfiguration() {
    final options = getOptions();
    return options.apiKey.isNotEmpty && 
           options.projectId.isNotEmpty && 
           options.appId.isNotEmpty;
  }
}
