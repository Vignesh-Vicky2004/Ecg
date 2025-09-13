import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Secure storage interface for sensitive data
abstract class SecureStorage {
  Future<void> store(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Local storage interface for non-sensitive data
abstract class LocalStorage {
  Future<void> setBool(String key, bool value);
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setStringList(String key, List<String> value);
  
  Future<bool?> getBool(String key);
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<List<String>?> getStringList(String key);
  
  Future<void> remove(String key);
  Future<void> clear();
}

/// Implementation of local storage using SharedPreferences
class SharedPreferencesStorage implements LocalStorage {
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await _preferences;
    await prefs.setInt(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final prefs = await _preferences;
    await prefs.setDouble(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _preferences;
    await prefs.setStringList(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  @override
  Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }

  @override
  Future<double?> getDouble(String key) async {
    final prefs = await _preferences;
    return prefs.getDouble(key);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final prefs = await _preferences;
    return prefs.getStringList(key);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}

/// Hive-based local database for complex data
class HiveLocalDatabase {
  static const String _userBox = 'user_box';
  static const String _ecgBox = 'ecg_box';
  static const String _settingsBox = 'settings_box';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters here if needed
    // Hive.registerAdapter(YourModelAdapter());
    
    await Future.wait([
      Hive.openBox(_userBox),
      Hive.openBox(_ecgBox),
      Hive.openBox(_settingsBox),
    ]);
  }
  
  static Box get userBox => Hive.box(_userBox);
  static Box get ecgBox => Hive.box(_ecgBox);
  static Box get settingsBox => Hive.box(_settingsBox);
  
  static Future<void> clearAll() async {
    await Future.wait([
      userBox.clear(),
      ecgBox.clear(),
      settingsBox.clear(),
    ]);
  }
  
  static Future<void> close() async {
    await Hive.close();
  }
}