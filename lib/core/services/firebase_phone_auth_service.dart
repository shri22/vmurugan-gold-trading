import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

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
      print('🔥 Firebase Phone Auth: Starting OTP send process');
      print('📱 Input phone number: $phoneNumber');

      // Check Firebase initialization first
      try {
        final app = _auth.app;
        print('🔥 Firebase App Name: ${app.name}');
        print('🔥 Firebase Project ID: ${app.options.projectId}');
        print('🔥 Firebase API Key: ${app.options.apiKey.substring(0, 10)}...');
      } catch (e) {
        print('❌ Firebase not properly initialized: $e');
        return {
          'success': false,
          'message': 'Firebase not initialized. Please restart the app.',
          'provider': 'firebase',
        };
      }

      // Clean and format phone number for Firebase (must include country code)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''); // Remove all non-digit characters except +
      print('📱 Cleaned phone: $cleanPhone');

      String formattedPhone = cleanPhone;
      if (!cleanPhone.startsWith('+91')) {
        // Remove any existing country code and add +91
        if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
          formattedPhone = '+$cleanPhone';
        } else if (cleanPhone.startsWith('+')) {
          formattedPhone = cleanPhone; // Already has country code
        } else {
          // Assume India (+91) if no country code provided
          formattedPhone = '+91$cleanPhone';
        }
      }

      print('📱 Final formatted phone: $formattedPhone');
      print('📱 Phone length: ${formattedPhone.length}');

      // Enhanced validation for Indian mobile numbers
      // Indian mobile numbers: +91 followed by 10 digits starting with 6,7,8,9
      final phoneRegex = RegExp(r'^\+91[6-9]\d{9}$');
      if (!phoneRegex.hasMatch(formattedPhone)) {
        print('❌ Invalid phone number format: $formattedPhone');
        print('❌ Expected format: +91XXXXXXXXXX (where X is 10 digits starting with 6,7,8,9)');
        print('❌ Regex test result: ${phoneRegex.hasMatch(formattedPhone)}');

        // Provide specific error message based on the issue
        String errorMessage;
        if (formattedPhone.length != 13) {
          errorMessage = 'Phone number must be 10 digits long.';
        } else if (!formattedPhone.startsWith('+91')) {
          errorMessage = 'Please enter an Indian mobile number.';
        } else {
          String firstDigit = formattedPhone.substring(3, 4);
          if (!['6', '7', '8', '9'].contains(firstDigit)) {
            errorMessage = 'Indian mobile numbers must start with 6, 7, 8, or 9.';
          } else {
            errorMessage = 'Invalid phone number format. Please enter a valid Indian mobile number.';
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'provider': 'firebase',
        };
      }

      // Clear previous verification data
      clearVerificationData();

      // Use Completer to handle async Firebase callbacks properly
      final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();

      print('🔥 Firebase: Calling verifyPhoneNumber...');

      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            print('✅ Firebase: Auto-verification completed');
            _credential = credential;
            if (!completer.isCompleted) {
              completer.complete({
                'success': true,
                'message': 'Auto-verification completed',
                'provider': 'firebase',
                'autoVerified': true,
              });
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            print('❌ Firebase: Verification failed');
            print('❌ Error code: ${e.code}');
            print('❌ Error message: ${e.message}');
            print('❌ Error details: ${e.toString()}');
            print('❌ Phone number that failed: $formattedPhone');

            // Log additional Firebase error details
            print('🔍 Firebase Error Analysis:');
            print('   - Code: ${e.code}');
            print('   - Message: ${e.message}');
            print('   - Plugin: ${e.plugin}');
            print('   - Stack trace: ${e.stackTrace}');

            if (!completer.isCompleted) {
              String userFriendlyMessage = _getUserFriendlyErrorMessage(e.code, e.message ?? 'Verification failed');

              // Add the actual Firebase error code to the user message for debugging
              String debugMessage = '$userFriendlyMessage\n\nDebug Info: Firebase Error Code: ${e.code}';

              completer.complete({
                'success': false,
                'message': debugMessage,
                'provider': 'firebase',
                'errorCode': e.code,
                'errorDetails': e.toString(),
                'phoneNumber': formattedPhone,
              });
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            print('📤 Firebase: OTP sent successfully');
            print('🔑 Verification ID: ${verificationId.substring(0, 10)}...');
            _verificationId = verificationId;
            _resendToken = resendToken;

            if (!completer.isCompleted) {
              completer.complete({
                'success': true,
                'message': 'OTP sent successfully via Firebase',
                'provider': 'firebase',
                'verificationId': _verificationId,
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('⏰ Firebase: Auto-retrieval timeout');
            _verificationId = verificationId;
            // Don't complete here, wait for codeSent or verificationFailed
          },
          timeout: const Duration(seconds: 60),
        );
      } catch (firebaseError) {
        print('❌ Firebase verifyPhoneNumber error: $firebaseError');
        if (!completer.isCompleted) {
          completer.complete({
            'success': false,
            'message': 'Firebase service error. Please try again.',
            'provider': 'firebase',
            'error': firebaseError.toString(),
          });
        }
      }

      // Wait for the Firebase callback to complete
      print('⏳ Waiting for Firebase callback...');
      return await completer.future.timeout(
        const Duration(seconds: 65), // Slightly longer than Firebase timeout
        onTimeout: () {
          print('❌ Firebase: Timeout waiting for callback');
          return {
            'success': false,
            'message': 'Request timeout. Please check your internet connection and try again.',
            'provider': 'firebase',
          };
        },
      );

    } catch (e) {
      print('❌ Firebase Phone Auth Exception: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection.',
        'provider': 'firebase',
      };
    }
  }

  /// Get user-friendly error message based on Firebase error code
  static String _getUserFriendlyErrorMessage(String? errorCode, String originalMessage) {
    print('🔍 Firebase Error Code: $errorCode');
    print('🔍 Original Message: $originalMessage');

    switch (errorCode) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please enter a valid mobile number.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again after some time.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again tomorrow.';
      case 'app-not-authorized':
        return 'Phone authentication not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'web-context-cancelled':
        return 'Verification cancelled. Please try again.';
      case 'missing-phone-number':
        return 'Phone number is required.';
      case 'captcha-check-failed':
        return 'Security check failed. Please try again.';
      case 'session-expired':
        return 'Session expired. Please restart the process.';
      case 'credential-already-in-use':
        return 'This phone number is already registered.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled for this app. Check Firebase Console.';
      case 'requires-recent-login':
        return 'Please restart the app and try again.';
      case 'firebase-auth-domain-config-required':
        return 'Firebase Auth domain configuration missing. Check Firebase Console.';
      case 'unauthorized-domain':
        return 'Domain not authorized in Firebase Console. Add your domain to authorized domains.';
      case 'project-not-found':
        return 'Firebase project not found. Check your Firebase configuration.';
      case 'api-key-not-valid':
        return 'Invalid Firebase API key. Check your Firebase configuration.';
      case 'auth/configuration-not-found':
        return 'Firebase configuration missing. Check your setup.';
      case 'auth/project-not-found':
        return 'Firebase project not found. Verify your project ID.';
      default:
        // For unknown errors, provide a generic but helpful message
        if (originalMessage.toLowerCase().contains('network')) {
          return 'Network error. Please check your internet connection.';
        } else if (originalMessage.toLowerCase().contains('quota') || originalMessage.toLowerCase().contains('limit')) {
          return 'Service temporarily unavailable. Please try again later.';
        } else if (originalMessage.toLowerCase().contains('auth') || originalMessage.toLowerCase().contains('permission')) {
          return 'Authentication service error. Please contact support.';
        } else {
          return 'Unable to send OTP. Please check your phone number and try again.';
        }
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

      // Use Completer for proper async handling
      final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Firebase: Auto-verification completed on resend');
          _credential = credential;
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'Auto-verification completed',
              'provider': 'firebase',
              'autoVerified': true,
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Firebase: Resend verification failed - ${e.message}');
          if (!completer.isCompleted) {
            String userFriendlyMessage = _getUserFriendlyErrorMessage(e.code, e.message ?? 'Resend failed');
            completer.complete({
              'success': false,
              'message': userFriendlyMessage,
              'provider': 'firebase',
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 Firebase: OTP resent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP resent successfully',
              'provider': 'firebase',
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Firebase: Resend auto-retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken, // Use the resend token
      );

      // Wait for the Firebase callback to complete
      return await completer.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () {
          print('❌ Firebase: Resend timeout');
          return {
            'success': false,
            'message': 'Request timeout. Please try again.',
            'provider': 'firebase',
          };
        },
      );

    } catch (e) {
      print('❌ Firebase: Resend error - $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
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

  /// Test phone number formatting (for debugging)
  static Map<String, dynamic> testPhoneFormatting(String phoneNumber) {
    try {
      // Clean and format phone number
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      print('🧪 Test - Cleaned phone: $cleanPhone');

      String formattedPhone = cleanPhone;
      if (!cleanPhone.startsWith('+91')) {
        if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
          formattedPhone = '+$cleanPhone';
        } else if (cleanPhone.startsWith('+')) {
          formattedPhone = cleanPhone;
        } else {
          formattedPhone = '+91$cleanPhone';
        }
      }

      print('🧪 Test - Final formatted phone: $formattedPhone');

      final phoneRegex = RegExp(r'^\+91[6-9]\d{9}$');
      bool isValid = phoneRegex.hasMatch(formattedPhone);

      return {
        'original': phoneNumber,
        'cleaned': cleanPhone,
        'formatted': formattedPhone,
        'isValid': isValid,
        'length': formattedPhone.length,
        'expectedLength': 13,
        'startsWithCountryCode': formattedPhone.startsWith('+91'),
        'firstDigitAfterCountryCode': formattedPhone.length >= 4 ? formattedPhone.substring(3, 4) : 'N/A',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'original': phoneNumber,
      };
    }
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
