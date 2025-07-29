import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Phone Authentication Service for real OTP functionality
/// This service provides free, reliable SMS OTP using Firebase Authentication
class FirebasePhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? _verificationId;
  static int? _resendToken;
  static PhoneAuthCredential? _credential;

  /// Send OTP to phone number using Firebase Authentication
  /// This is completely FREE and handles SMS delivery automatically
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      print('🔥 Firebase Phone Auth: Sending OTP to $phoneNumber');
      
      // Format phone number for Firebase (must include country code)
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Assume India (+91) if no country code provided
        formattedPhone = '+91$phoneNumber';
      }
      
      print('📱 Formatted phone: $formattedPhone');
      
      // Completer to handle async callback
      bool otpSent = false;
      String? error;
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Firebase: Auto-verification completed');
          _credential = credential;
          // Auto-verification successful (happens on some Android devices)
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Firebase: Verification failed - ${e.message}');
          error = e.message ?? 'Verification failed';
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 Firebase: OTP sent successfully');
          print('🔑 Verification ID: ${verificationId.substring(0, 10)}...');
          _verificationId = verificationId;
          _resendToken = resendToken;
          otpSent = true;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Firebase: Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      
      // Wait a bit for the callback to complete
      await Future.delayed(const Duration(seconds: 2));
      
      if (error != null) {
        return {
          'success': false,
          'message': 'Failed to send OTP: $error',
          'provider': 'firebase',
        };
      }
      
      if (otpSent || _verificationId != null) {
        return {
          'success': true,
          'message': 'OTP sent successfully via Firebase',
          'provider': 'firebase',
          'verificationId': _verificationId,
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to send OTP: Unknown error',
        'provider': 'firebase',
      };
      
    } catch (e) {
      print('❌ Firebase Phone Auth Error: $e');
      return {
        'success': false,
        'message': 'Firebase error: $e',
        'provider': 'firebase',
      };
    }
  }

  /// Verify OTP entered by user
  static Future<Map<String, dynamic>> verifyOTP(String otp) async {
    try {
      print('🔥 Firebase: Verifying OTP: $otp');
      
      if (_verificationId == null) {
        return {
          'success': false,
          'message': 'No verification ID found. Please request OTP again.',
        };
      }
      
      // Create credential with verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      // Verify the credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        print('✅ Firebase: OTP verified successfully');
        print('👤 User ID: ${userCredential.user!.uid}');
        
        return {
          'success': true,
          'message': 'OTP verified successfully',
          'userId': userCredential.user!.uid,
          'phoneNumber': userCredential.user!.phoneNumber,
        };
      } else {
        return {
          'success': false,
          'message': 'Verification failed: No user returned',
        };
      }
      
    } catch (e) {
      print('❌ Firebase: OTP verification failed - $e');
      
      String errorMessage = 'Invalid OTP';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Invalid OTP. Please check and try again.';
            break;
          case 'invalid-verification-id':
            errorMessage = 'Verification session expired. Please request new OTP.';
            break;
          case 'session-expired':
            errorMessage = 'OTP expired. Please request new OTP.';
            break;
          default:
            errorMessage = e.message ?? 'Verification failed';
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Resend OTP using the resend token
  static Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    try {
      print('🔥 Firebase: Resending OTP to $phoneNumber');
      
      // Format phone number
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+91$phoneNumber';
      }
      
      bool otpSent = false;
      String? error;
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Firebase: Auto-verification completed on resend');
          _credential = credential;
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Firebase: Resend verification failed - ${e.message}');
          error = e.message ?? 'Resend failed';
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 Firebase: OTP resent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          otpSent = true;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Firebase: Resend auto-retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken, // Use the resend token
      );
      
      // Wait for callback
      await Future.delayed(const Duration(seconds: 2));
      
      if (error != null) {
        return {
          'success': false,
          'message': 'Failed to resend OTP: $error',
          'provider': 'firebase',
        };
      }
      
      if (otpSent || _verificationId != null) {
        return {
          'success': true,
          'message': 'OTP resent successfully',
          'provider': 'firebase',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to resend OTP: Unknown error',
        'provider': 'firebase',
      };
      
    } catch (e) {
      print('❌ Firebase: Resend error - $e');
      return {
        'success': false,
        'message': 'Resend failed: $e',
        'provider': 'firebase',
      };
    }
  }

  /// Sign out the current Firebase user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _verificationId = null;
      _resendToken = null;
      _credential = null;
      print('🔥 Firebase: User signed out');
    } catch (e) {
      print('❌ Firebase: Sign out error - $e');
    }
  }

  /// Get current Firebase user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in with Firebase
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get Firebase Auth instance for advanced usage
  static FirebaseAuth get instance => _auth;

  /// Clear verification data (call when starting new verification)
  static void clearVerificationData() {
    _verificationId = null;
    _resendToken = null;
    _credential = null;
    print('🔥 Firebase: Verification data cleared');
  }

  /// Get verification status
  static Map<String, dynamic> getVerificationStatus() {
    return {
      'hasVerificationId': _verificationId != null,
      'hasResendToken': _resendToken != null,
      'hasCredential': _credential != null,
      'isSignedIn': isSignedIn(),
      'currentUser': getCurrentUser()?.phoneNumber,
    };
  }
}

/// Firebase Phone Auth Configuration Instructions
/// 
/// SETUP STEPS:
/// 
/// 1. FIREBASE PROJECT SETUP:
///    - Go to https://console.firebase.google.com/
///    - Create a new project or use existing
///    - Enable Authentication → Sign-in method → Phone
/// 
/// 2. ANDROID SETUP:
///    - Download google-services.json
///    - Place in android/app/
///    - Add Firebase SDK to android/app/build.gradle
/// 
/// 3. iOS SETUP (if needed):
///    - Download GoogleService-Info.plist
///    - Add to ios/Runner/
///    - Configure iOS bundle ID
/// 
/// 4. WEB SETUP (if needed):
///    - Add Firebase config to web/index.html
///    - Enable reCAPTCHA for web
/// 
/// 5. INITIALIZE IN MAIN:
///    - Add Firebase.initializeApp() in main()
/// 
/// BENEFITS OF FIREBASE PHONE AUTH:
/// - ✅ FREE for moderate usage (10K verifications/month)
/// - ✅ Reliable SMS delivery worldwide
/// - ✅ Automatic spam protection
/// - ✅ No need to manage SMS providers
/// - ✅ Built-in rate limiting
/// - ✅ Supports 200+ countries
/// - ✅ Auto-verification on Android
/// - ✅ Web support with reCAPTCHA
