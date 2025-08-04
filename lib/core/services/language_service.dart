import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app language preferences
class LanguageService {
  static const String _languageKey = 'app_language';
  
  /// Available languages
  static const Map<String, String> availableLanguages = {
    'en': 'English',
    'ta': 'தமிழ்', // Tamil
  };
  
  /// Get current language code (default: 'en')
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }
  
  /// Set language preference
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    print('✅ Language set to: ${availableLanguages[languageCode]}');
  }
  
  /// Get language display name
  static Future<String> getCurrentLanguageDisplay() async {
    final currentLang = await getCurrentLanguage();
    return availableLanguages[currentLang] ?? 'English';
  }
  
  /// Check if current language is Tamil
  static Future<bool> isTamil() async {
    final currentLang = await getCurrentLanguage();
    return currentLang == 'ta';
  }
  
  /// Check if current language is English
  static Future<bool> isEnglish() async {
    final currentLang = await getCurrentLanguage();
    return currentLang == 'en';
  }
}
