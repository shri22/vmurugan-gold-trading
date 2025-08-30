import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static String _currentLanguage = 'en';

  static String get currentLanguage => _currentLanguage;

  static Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    } catch (e) {
      print('Error loading language: $e');
      _currentLanguage = 'en';
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _currentLanguage = languageCode;
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  static String translate(String key, {String? fallback}) {
    // Simple translation - in production this would use proper translation files
    final translations = {
      'en': {
        'logout': 'Logout',
        'cancel': 'Cancel',
        'confirm_logout': 'Are you sure you want to logout?',
      },
      'ta': {
        'logout': 'வெளியேறு',
        'cancel': 'ரத்து செய்',
        'confirm_logout': 'நீங்கள் நிச்சயமாக வெளியேற விரும்புகிறீர்களா?',
      },
    };

    return translations[_currentLanguage]?[key] ?? fallback ?? key;
  }
}
