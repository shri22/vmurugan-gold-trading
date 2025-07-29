import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Initialization Configuration
/// This handles Firebase setup for the VMUrugan Gold Trading app
class FirebaseInit {
  static bool _initialized = false;

  /// Initialize Firebase for the application
  static Future<void> initialize() async {
    if (_initialized) {
      print('🔥 Firebase: Already initialized');
      return;
    }

    try {
      print('🔥 Firebase: Initializing...');
      
      // Initialize Firebase with platform-specific options
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      _initialized = true;
      print('✅ Firebase: Initialized successfully');
      
      // Enable debug logging in debug mode
      if (kDebugMode) {
        print('🔥 Firebase: Debug mode enabled');
      }
      
    } catch (e) {
      print('❌ Firebase: Initialization failed - $e');
      print('💡 Firebase: App will work in demo mode without real SMS');
      // Don't throw error - app should work without Firebase
    }
  }

  /// Get Firebase options based on platform
  static FirebaseOptions? _getFirebaseOptions() {
    // Return null to use default configuration from google-services.json (Android)
    // or GoogleService-Info.plist (iOS) or firebase-config.js (Web)
    return null;
    
    // If you need custom configuration, uncomment and configure below:
    /*
    if (kIsWeb) {
      // Web configuration
      return const FirebaseOptions(
        apiKey: "your-web-api-key",
        authDomain: "your-project.firebaseapp.com",
        projectId: "your-project-id",
        storageBucket: "your-project.appspot.com",
        messagingSenderId: "123456789",
        appId: "1:123456789:web:abcdef123456",
      );
    } else if (Platform.isAndroid) {
      // Android configuration
      return const FirebaseOptions(
        apiKey: "your-android-api-key",
        appId: "1:123456789:android:abcdef123456",
        messagingSenderId: "123456789",
        projectId: "your-project-id",
        storageBucket: "your-project.appspot.com",
      );
    } else if (Platform.isIOS) {
      // iOS configuration
      return const FirebaseOptions(
        apiKey: "your-ios-api-key",
        appId: "1:123456789:ios:abcdef123456",
        messagingSenderId: "123456789",
        projectId: "your-project-id",
        storageBucket: "your-project.appspot.com",
        iosClientId: "123456789-abcdef.apps.googleusercontent.com",
        iosBundleId: "com.example.yourapp",
      );
    }
    return null;
    */
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  /// Get Firebase initialization status
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'platform': _getPlatformName(),
      'debug_mode': kDebugMode,
    };
  }

  /// Get current platform name
  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    // Note: Platform.isAndroid/isIOS would require dart:io import
    // For now, return 'Mobile' as a generic term
    return 'Mobile';
  }
}

/// Firebase Setup Instructions
/// 
/// QUICK SETUP (Recommended):
/// 1. Go to https://console.firebase.google.com/
/// 2. Create a new project: "vmurugan-gold-trading"
/// 3. Enable Authentication → Sign-in method → Phone
/// 4. Add your app:
///    - Android: com.vmurugan.digi_gold
///    - iOS: com.vmurugan.digiGold
///    - Web: vmurugan-gold-trading.web.app
/// 
/// ANDROID SETUP:
/// 1. Download google-services.json from Firebase Console
/// 2. Place it in: android/app/google-services.json
/// 3. Add to android/app/build.gradle:
///    ```
///    apply plugin: 'com.google.gms.google-services'
///    ```
/// 4. Add to android/build.gradle:
///    ```
///    classpath 'com.google.gms:google-services:4.3.15'
///    ```
/// 
/// iOS SETUP:
/// 1. Download GoogleService-Info.plist from Firebase Console
/// 2. Add to ios/Runner/ in Xcode
/// 3. Set iOS bundle ID in Xcode to match Firebase
/// 
/// WEB SETUP:
/// 1. Add Firebase SDK to web/index.html:
///    ```html
///    <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
///    <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
///    <script>
///      var firebaseConfig = {
///        // Your config from Firebase Console
///      };
///      firebase.initializeApp(firebaseConfig);
///    </script>
///    ```
/// 
/// TESTING:
/// 1. Run the app
/// 2. Go to Debug → SMS Config
/// 3. Test Firebase Phone Auth
/// 4. Check Firebase Console → Authentication → Users
/// 
/// BENEFITS:
/// ✅ FREE for up to 10,000 phone verifications/month
/// ✅ Reliable SMS delivery worldwide
/// ✅ No need to manage SMS providers
/// ✅ Built-in spam protection
/// ✅ Automatic rate limiting
/// ✅ Supports 200+ countries
/// ✅ Auto-verification on Android
/// ✅ Web support with reCAPTCHA
/// 
/// COSTS (after free tier):
/// - Phone Auth: $0.006 per verification
/// - Much cheaper than most SMS providers
/// - No monthly fees, pay per use only
