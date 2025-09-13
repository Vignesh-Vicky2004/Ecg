import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../firebase_options.dart';
import '../storage/storage_service.dart';
import '../utils/utils.dart';
import '../errors/exceptions.dart';

/// Application initialization service
/// Handles all app startup logic in a clean, testable way
class AppInitializer {
  static bool _isInitialized = false;

  /// Initialize the application
  static Future<void> initialize() async {
    if (_isInitialized) {
      LoggerService.warning('App already initialized, skipping...');
      return;
    }

    try {
      LoggerService.info('🚀 Starting app initialization...');

      // Step 1: Initialize environment variables
      await _initializeEnvironment();

      // Step 2: Initialize Firebase
      await _initializeFirebase();

      // Step 3: Initialize local storage
      await _initializeStorage();

      // Step 4: Initialize localization
      await _initializeLocalization();

      _isInitialized = true;
      LoggerService.info('✅ App initialization completed successfully');

    } catch (error, stackTrace) {
      LoggerService.critical('❌ App initialization failed', error, stackTrace);
      throw ConfigException(
        message: 'Application initialization failed: $error',
        code: 'init-failed',
        details: error,
      );
    }
  }

  /// Initialize environment variables with error handling
  static Future<void> _initializeEnvironment() async {
    try {
      LoggerService.debug('🔄 Loading environment variables...');
      
      await dotenv.load(fileName: ".env");
      
      LoggerService.info('✅ Environment variables loaded: ${dotenv.env.length} variables');
    } catch (error) {
      LoggerService.warning('⚠️ Could not load .env file, using fallback configuration');
      
      // Initialize dotenv with empty map to prevent further errors
      dotenv.env.clear();
      dotenv.env.addAll(<String, String>{});
      
      LoggerService.info('✅ Dotenv initialized with fallback configuration');
    }
  }

  /// Initialize Firebase with proper error handling
  static Future<void> _initializeFirebase() async {
    try {
      LoggerService.debug('🔥 Initializing Firebase...');
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      LoggerService.info('✅ Firebase initialized successfully');
    } catch (error, stackTrace) {
      LoggerService.error('❌ Firebase initialization failed', error, stackTrace);
      
      // Firebase failure is critical for most app functionality
      throw ConfigException(
        message: 'Firebase initialization failed: $error',
        code: 'firebase-init-failed',
        details: error,
      );
    }
  }

  /// Initialize local storage systems
  static Future<void> _initializeStorage() async {
    try {
      LoggerService.debug('💾 Initializing storage systems...');
      
      // Initialize Hive for complex data storage
      await HiveLocalDatabase.init();
      
      LoggerService.info('✅ Storage systems initialized successfully');
    } catch (error, stackTrace) {
      LoggerService.error('❌ Storage initialization failed', error, stackTrace);
      
      throw CacheException(
        message: 'Storage initialization failed: $error',
        code: 'storage-init-failed',
        details: error,
      );
    }
  }

  /// Initialize localization service
  static Future<void> _initializeLocalization() async {
    try {
      LoggerService.debug('🌐 Initializing localization...');
      
      // Localization is now handled by the LocalizationBloc
      // This method is kept for consistency but doesn't do anything
      
      LoggerService.info('✅ Localization setup ready');
    } catch (error) {
      LoggerService.warning('⚠️ Localization initialization warning', error);
      
      // Localization failure is not critical
    }
  }

  /// Check if the app is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
  }

  /// Cleanup resources on app termination
  static Future<void> cleanup() async {
    try {
      LoggerService.info('🧹 Cleaning up app resources...');
      
      await HiveLocalDatabase.close();
      
      LoggerService.info('✅ App cleanup completed');
    } catch (error) {
      LoggerService.error('❌ App cleanup failed', error);
    }
  }
}