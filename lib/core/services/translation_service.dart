import 'language_service.dart';

/// Translation service for English and Tamil
class TranslationService {
  
  /// Profile screen translations
  static const Map<String, Map<String, String>> _translations = {
    // Profile Screen
    'profile_title': {
      'en': 'Profile',
      'ta': 'சுயவிவரம்',
    },
    'personal_information': {
      'en': 'Personal Information',
      'ta': 'தனிப்பட்ட தகவல்',
    },
    'name': {
      'en': 'Name',
      'ta': 'பெயர்',
    },
    'phone': {
      'en': 'Phone',
      'ta': 'தொலைபேசி',
    },
    'email': {
      'en': 'Email',
      'ta': 'மின்னஞ்சல்',
    },
    'customer_id': {
      'en': 'Customer ID',
      'ta': 'வாடிக்கையாளர் அடையாள எண்',
    },
    'address': {
      'en': 'Address',
      'ta': 'முகவரி',
    },
    'pan_card': {
      'en': 'PAN Card',
      'ta': 'பான் கார்டு',
    },
    'join_date': {
      'en': 'Joined',
      'ta': 'சேர்ந்த தேதி',
    },
    'kyc_status': {
      'en': 'KYC Status',
      'ta': 'கேஒய்சி நிலை',
    },
    'verified': {
      'en': 'Verified',
      'ta': 'சரிபார்க்கப்பட்டது',
    },
    'not_available': {
      'en': 'Not Available',
      'ta': 'கிடைக்கவில்லை',
    },
    
    // Settings Section
    'settings': {
      'en': 'Settings',
      'ta': 'அமைப்புகள்',
    },
    'language': {
      'en': 'Language',
      'ta': 'மொழி',
    },
    'notifications': {
      'en': 'Notifications',
      'ta': 'அறிவிப்புகள்',
    },
    'privacy_security': {
      'en': 'Privacy & Security',
      'ta': 'தனியுரிமை மற்றும் பாதுகாப்பு',
    },
    'help_support': {
      'en': 'Help & Support',
      'ta': 'உதவி மற்றும் ஆதரவு',
    },
    'about': {
      'en': 'About',
      'ta': 'பற்றி',
    },
    'logout': {
      'en': 'Logout',
      'ta': 'வெளியேறு',
    },
    
    // Language Selection
    'select_language': {
      'en': 'Select Language',
      'ta': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    },
    'english': {
      'en': 'English',
      'ta': 'ஆங்கிலம்',
    },
    'tamil': {
      'en': 'Tamil',
      'ta': 'தமிழ்',
    },
    'language_changed': {
      'en': 'Language changed successfully',
      'ta': 'மொழி வெற்றிகரமாக மாற்றப்பட்டது',
    },
    
    // Common
    'cancel': {
      'en': 'Cancel',
      'ta': 'ரத்து செய்',
    },
    'ok': {
      'en': 'OK',
      'ta': 'சரி',
    },
    'save': {
      'en': 'Save',
      'ta': 'சேமி',
    },
    'loading': {
      'en': 'Loading...',
      'ta': 'ஏற்றுகிறது...',
    },
    'error': {
      'en': 'Error',
      'ta': 'பிழை',
    },
    'success': {
      'en': 'Success',
      'ta': 'வெற்றி',
    },
    
    // Main Screen
    'home': {
      'en': 'Home',
      'ta': 'முகப்பு',
    },
    'portfolio': {
      'en': 'Portfolio',
      'ta': 'போர்ட்ஃபோலியோ',
    },
    'transactions': {
      'en': 'Transactions',
      'ta': 'பரிவர்த்தனைகள்',
    },
    'schemes': {
      'en': 'Schemes',
      'ta': 'திட்டங்கள்',
    },
    
    // Gold/Silver
    'gold': {
      'en': 'Gold',
      'ta': 'தங்கம்',
    },
    'silver': {
      'en': 'Silver',
      'ta': 'வெள்ளி',
    },
    'buy_gold': {
      'en': 'Buy Gold',
      'ta': 'தங்கம் வாங்கு',
    },
    'buy_silver': {
      'en': 'Buy Silver',
      'ta': 'வெள்ளி வாங்கு',
    },
    'join_now': {
      'en': 'Join Now',
      'ta': 'இப்போது சேரு',
    },
    'installment': {
      'en': 'Installment',
      'ta': 'தவணை',
    },
    
    // Authentication
    'login': {
      'en': 'Login',
      'ta': 'உள்நுழை',
    },
    'register': {
      'en': 'Register',
      'ta': 'பதிவு செய்',
    },
    'phone_number': {
      'en': 'Phone Number',
      'ta': 'தொலைபேசி எண்',
    },
    'enter_otp': {
      'en': 'Enter OTP',
      'ta': 'ஒடிபி உள்ளிடவும்',
    },
    'enter_mpin': {
      'en': 'Enter MPIN',
      'ta': 'எம்பின் உள்ளிடவும்',
    },
  };
  
  /// Get translated text for a key
  static Future<String> get(String key) async {
    final currentLang = await LanguageService.getCurrentLanguage();
    final translations = _translations[key];
    
    if (translations == null) {
      print('⚠️ Translation key not found: $key');
      return key; // Return key if translation not found
    }
    
    return translations[currentLang] ?? translations['en'] ?? key;
  }
  
  /// Get translated text synchronously (requires language to be passed)
  static String getSync(String key, String languageCode) {
    final translations = _translations[key];
    
    if (translations == null) {
      return key;
    }
    
    return translations[languageCode] ?? translations['en'] ?? key;
  }
  
  /// Get all available translations for a key
  static Map<String, String>? getAllTranslations(String key) {
    return _translations[key];
  }
}
