import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'customer_service.dart';
import 'secure_http_client.dart';
import 'sms_service.dart';
import 'firebase_phone_auth_service.dart';
import 'encryption_service.dart';
import '../config/client_server_config.dart';
import '../config/validation_config.dart';

/// Enhanced Authentication service to handle the complete login flow
/// This works alongside existing login functionality without breaking it
class AuthService {
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _lastOtpKey = 'last_otp';
  static const String _otpTimestampKey = 'otp_timestamp';
  static const String _mpinKey = 'user_mpin';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _enhancedFlowEnabledKey = 'enhanced_flow_enabled';

  /// Enable or disable the enhanced authentication flow
  static Future<void> setEnhancedFlowEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enhancedFlowEnabledKey, enabled);
  }

  /// Check if enhanced authentication flow is enabled
  static Future<bool> isEnhancedFlowEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enhancedFlowEnabledKey) ?? false;
  }
  
  /// Check if this is the first time the app is launched
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }
  
  /// Mark that the app has been launched before
  static Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }
  
  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }
  
  /// Mark onboarding as complete
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
  }
  
  /// Check if phone number is already registered
  static Future<bool> isPhoneRegistered(String phone) async {
    try {
      print('🔍 AuthService: Checking if phone $phone is registered...');

      // Use SQL Server endpoint instead of Firebase for better performance
      final response = await SecureHttpClient.get(
        '$baseUrl/customers/$phone',
        headers: headers,
      ).timeout(const Duration(seconds: 5)); // Reduced timeout for faster response

      if (response.statusCode == 200) {
        print('✅ AuthService: Phone $phone is registered');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ AuthService: Phone $phone is not registered');
        return false;
      } else {
        print('⚠️ AuthService: Unexpected response ${response.statusCode} for phone $phone');
        return false;
      }
    } catch (e) {
      print('❌ AuthService: Error checking phone registration: $e');
      // Fallback to Firebase if server is unreachable
      try {
        print('🔄 AuthService: Falling back to Firebase check...');
        final result = await FirebaseService.getCustomerByPhone(phone);
        return result['success'] == true && result['customer'] != null;
      } catch (fallbackError) {
        print('❌ AuthService: Firebase fallback also failed: $fallbackError');
        return false;
      }
    }
  }
  
  /// Generate and send real OTP via SMS providers
  static Future<String> generateOTP(String phone) async {
    try {
      print('🔐 AuthService: Generating OTP for phone $phone');
      print('🔧 AuthService: Current validation mode: ${ValidationConfig.getModeDescription()}');

      // Check validation mode
      if (ValidationConfig.isDemoMode) {
        print('🎭 AuthService: Using demo mode...');
        return await _generateOTPFallback(phone);
      } else {
        print('🚀 AuthService: Using production mode...');
        return await _generateProductionOTP(phone);
      }

      // Commented out for demo mode - uncomment when SMS is ready
      /*
      // Try custom SMS service first (more reliable than Firebase billing issues)
      print('📱 AuthService: Trying custom SMS service...');
      final customSmsResult = await _tryCustomSmsFirst(phone);
      if (customSmsResult != null) {
        return customSmsResult;
      }

      // If custom SMS fails, try Firebase as fallback
      print('🔥 AuthService: Trying Firebase Phone Authentication as fallback...');

      try {
        // Clear any previous verification data
        FirebasePhoneAuthService.clearVerificationData();

        // OPTION 1: Use Firebase (FREE SMS)
        final firebaseResult = await FirebasePhoneAuthService.sendOTP(phone);

        if (firebaseResult['success'] == true) {
          // Firebase handles OTP generation and SMS sending automatically
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_otpTimestampKey, DateTime.now().millisecondsSinceEpoch);
          await prefs.setString('firebase_verification_id', firebaseResult['verificationId'] ?? '');

          print('✅ AuthService: Firebase OTP sent successfully');
          print('🔥 Provider: Firebase (FREE SMS)');

          // Return a placeholder since Firebase manages the actual OTP
          return 'FIREBASE_OTP';
        }

        // OPTION 2: Alternative SMS service (if Firebase fails)
        // Uncomment below to use paid SMS service instead:
        /*
        final alternativeResult = await AlternativeSmsService.sendOTP(phone);
        if (alternativeResult['success'] == true) {
          return alternativeResult['otp'];
        }
        */
      } catch (firebaseError) {
        print('⚠️ AuthService: Firebase error: $firebaseError');
      }

      // Final fallback to demo mode
      print('🎭 AuthService: Using demo mode...');
      return await _generateOTPFallback(phone);
      */
    } catch (e) {
      print('❌ AuthService: OTP generation error: $e');
      // Final fallback to demo mode
      return await _generateOTPFallback(phone);
    }
  }

  /// Try custom SMS service first (to avoid Firebase billing issues)
  static Future<String?> _tryCustomSmsFirst(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate 6-digit OTP
      final random = Random();
      final otp = (100000 + random.nextInt(900000)).toString();

      print('🔐 AuthService: Generated custom OTP $otp for phone $phone');

      // Try custom SMS service
      final smsResult = await SmsService.sendOtp(phone, otp);

      if (smsResult['success'] == true) {
        // Store OTP and timestamp only after successful SMS send
        await prefs.setString(_lastOtpKey, otp);
        await prefs.setInt(_otpTimestampKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setString('sms_message_id', smsResult['messageId'] ?? '');

        print('✅ AuthService: Custom SMS OTP sent via ${smsResult['provider']}');
        return otp;
      } else {
        print('⚠️ AuthService: Custom SMS failed: ${smsResult['message']}');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: Custom SMS error: $e');
      return null;
    }
  }

  /// Production OTP generation using SMS service
  static Future<String> _generateProductionOTP(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // PRIORITY 1: Try Firebase Phone Authentication (Verified by User)
      print('🔥 AuthService: Trying Firebase Phone Authentication...');

      try {
        // Clear any previous verification data
        FirebasePhoneAuthService.clearVerificationData();

        // Send OTP via Firebase Phone Authentication
        final firebaseResult = await FirebasePhoneAuthService.sendOTP(phone);

        if (firebaseResult['success'] == true) {
          // Firebase handles OTP generation and SMS sending automatically
          await prefs.setInt(_otpTimestampKey, DateTime.now().millisecondsSinceEpoch);
          await prefs.setString('firebase_verification_id', firebaseResult['verificationId'] ?? '');

          print('✅ AuthService: Firebase OTP sent successfully');
          print('🔥 Provider: Firebase (FREE SMS)');

          // Return a placeholder since Firebase manages the actual OTP
          return 'FIREBASE_OTP';
        } else {
           print('⚠️ AuthService: Firebase failed: ${firebaseResult['message']}');
        }
      } catch (firebaseError) {
        print('⚠️ AuthService: Firebase error: $firebaseError');
      }

      // PRIORITY 2: Try custom SMS service as fallback
      print('📱 AuthService: Falling back to custom SMS service...');
      final customSmsResult = await _tryCustomSmsFirst(phone);
      if (customSmsResult != null) {
        return customSmsResult;
      }

      throw Exception('All SMS services failed. Please check your configuration.');
    } catch (e) {
      print('❌ AuthService: Production OTP generation error: $e');
      throw e;
    }
  }

  /// Demo OTP generation using fixed OTP
  static Future<String> _generateOTPFallback(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Use configured demo OTP
      final otp = ValidationConfig.getOtp();

      print('🔐 AuthService: Using demo OTP $otp for phone $phone');

      // Store OTP and timestamp
      await prefs.setString(_lastOtpKey, otp);
      await prefs.setInt(_otpTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('🎭 AuthService: Demo mode - OTP: $otp');
      print('💡 AuthService: Switch to production mode in ValidationConfig for real SMS');

      return otp;
    } catch (e) {
      print('❌ AuthService: Demo OTP generation error: $e');
      throw Exception('Failed to generate OTP: $e');
    }
  }
  
  /// Verify OTP entered by user (Firebase or fallback)
  static Future<bool> verifyOTP(String enteredOtp) async {
    try {
      print('🔐 AuthService: Verifying OTP: $enteredOtp');

      // Check if we're using Firebase verification
      final prefs = await SharedPreferences.getInstance();
      final firebaseVerificationId = prefs.getString('firebase_verification_id');

      if (firebaseVerificationId != null && firebaseVerificationId.isNotEmpty) {
        // Use Firebase verification
        print('🔥 AuthService: Using Firebase OTP verification');
        final firebaseResult = await FirebasePhoneAuthService.verifyOTP(enteredOtp);

        if (firebaseResult['success'] == true) {
          print('✅ AuthService: Firebase OTP verified successfully');
          
          // CRITICAL: Call backend to get JWT token after Firebase verification
          final phone = firebaseResult['phoneNumber'] ?? '';
          if (phone.isNotEmpty) {
            print('🔄 AuthService: Calling backend to authenticate phone: $phone');
            final backendResult = await makeSecureRequest(
              '/auth/verify-otp',
              body: {
                'phone': phone.replaceAll('+', ''), // Send without plus sign for backend compatibility
                'otp': enteredOtp, // Send the same OTP for backend bookkeeping
              },
            );

            if (backendResult['success'] == true) {
              print('✅ AuthService: Backend authentication successful');
              await _saveBackendToken(backendResult['token']);
              
              // Save customer data if returned
              if (backendResult['customer'] != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_data', jsonEncode(backendResult['customer']));
                await prefs.setString('customer_id', backendResult['customer']['customer_id']?.toString() ?? '');
              }
            } else {
              print('⚠️ AuthService: Backend auto-authentication failed: ${backendResult['message']}');
              // We'll still return true for OTP verification since Firebase succeeded,
              // but some backend features might be limited until next login
            }
          }

          // Clear Firebase verification data
          await prefs.remove('firebase_verification_id');
          return true;
        }
 else {
          print('❌ AuthService: Firebase OTP verification failed: ${firebaseResult['message']}');
          return false;
        }
      } else {
        // Use fallback verification (custom SMS or demo)
        print('📱 AuthService: Using fallback OTP verification');
        return await _verifyOTPFallback(enteredOtp);
      }
    } catch (e) {
      print('❌ AuthService: OTP verification error: $e');
      // Try fallback verification
      return await _verifyOTPFallback(enteredOtp);
    }
  }

  /// Fallback OTP verification for custom SMS or demo mode
  static Future<bool> _verifyOTPFallback(String enteredOtp) async {
    final prefs = await SharedPreferences.getInstance();

    final storedOtp = prefs.getString(_lastOtpKey);
    final timestamp = prefs.getInt(_otpTimestampKey);

    if (storedOtp == null || timestamp == null) {
      print('❌ AuthService: No fallback OTP found');
      return false;
    }

    // Check if OTP is expired using validation config
    final now = DateTime.now().millisecondsSinceEpoch;
    final otpAge = now - timestamp;
    final expiryDuration = ValidationConfig.isDemoMode
        ? ValidationConfig.demoOtpExpiry
        : ValidationConfig.productionOtpExpiry;
    final expiryMilliseconds = expiryDuration.inMilliseconds;

    if (otpAge > expiryMilliseconds) {
      print('❌ AuthService: Fallback OTP expired (${expiryDuration.inMinutes} minutes)');
      await prefs.remove(_lastOtpKey);
      await prefs.remove(_otpTimestampKey);
      return false;
    }

    // Verify OTP using validation config
    final isValid = ValidationConfig.validateOtp(enteredOtp, storedOtp);

    if (isValid) {
      print('✅ AuthService: Fallback OTP verified successfully');
      // Clear OTP after successful verification
      await prefs.remove(_lastOtpKey);
      await prefs.remove(_otpTimestampKey);
    } else {
      print('❌ AuthService: Invalid fallback OTP');
    }

    return isValid;
  }
  
  /// Check if user has set up MPIN
  static Future<bool> hasMPIN() async {
    final prefs = await SharedPreferences.getInstance();
    final mpin = prefs.getString(_mpinKey);
    return mpin != null && mpin.isNotEmpty;
  }
  
  /// Set up MPIN
  static Future<void> setMPIN(String mpin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mpinKey, mpin);
    print('✅ AuthService: MPIN set successfully');
  }
  
  /// Verify MPIN
  static Future<bool> verifyMPIN(String enteredMpin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedMpin = prefs.getString(_mpinKey);
    
    if (storedMpin == null) {
      print('❌ AuthService: No MPIN found');
      return false;
    }
    
    if (storedMpin == enteredMpin) {
      print('✅ AuthService: MPIN verified successfully');
      return true;
    } else {
      print('❌ AuthService: Invalid MPIN');
      return false;
    }
  }
  
  /// Complete login process
  static Future<void> completeLogin(String phone, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);

    // Save phone number for future quick login
    await savePhoneNumber(phone);

    // Save user ID for server API calls
    if (userId != null) {
      await prefs.setInt('current_user_id', userId);
      print('✅ AuthService: User ID saved: $userId');
    }

    // Save login session with customer data
    await CustomerService.saveLoginSession(phone);

    print('✅ AuthService: Login completed for phone $phone');
  }
  
  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await CustomerService.clearLoginSession();
    print('✅ AuthService: User logged out');
  }
  
  /// Get the complete authentication state
  static Future<AuthState> getAuthState() async {
    final isFirstTime = await isFirstLaunch();
    final hasOnboarding = await hasCompletedOnboarding();
    final isUserLoggedIn = await isLoggedIn();
    final userHasMpin = await hasMPIN();
    final savedPhone = await getSavedPhoneNumber();

    if (isFirstTime || !hasOnboarding) {
      return AuthState.needsOnboarding;
    }

    if (isUserLoggedIn) {
      return AuthState.loggedIn;
    }

    // If user has MPIN and saved phone, go directly to MPIN login
    if (userHasMpin && savedPhone != null) {
      return AuthState.needsMpinLogin;
    }

    return AuthState.needsPhoneNumber;
  }

  /// Get saved phone number for returning users
  static Future<String?> getSavedPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_phone_number');
  }

  /// Save phone number for future logins
  static Future<void> savePhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_phone_number', phone);
  }

  // =============================================================================
  // NEW LOGIN FUNCTIONALITY WITH ENCRYPTED MPIN
  // =============================================================================

  // API base URL
  static String get baseUrl => ClientServerConfig.baseUrl;

  // Headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  /// Register new user with encrypted MPIN
  static Future<Map<String, dynamic>> registerWithEncryptedMPIN({
    required String phone,
    required String name,
    required String email,
    required String address,
    required String panCard,
    required String mpin,
    required String deviceId,
  }) async {
    try {
      print('📝 AuthService: Registering user with encrypted MPIN: $phone');

      // Encrypt MPIN
      final encryptedMpin = EncryptionService.encryptMPIN(mpin);

      // Prepare customer data
      final customerData = {
        'phone': phone,
        'name': name,
        'email': email,
        'address': address,
        'pan_card': panCard,
        'device_id': deviceId,
        'encrypted_mpin': encryptedMpin,
      };

      // Send to new server API using secure HTTP client
      final response = await SecureHttpClient.post(
        '$baseUrl/customers',
        headers: headers,
        body: jsonEncode(customerData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Save login state with user ID
          final userData = data['user'];
          await _saveUserLoginState(phone, userData);

          // Save numeric user ID for server API calls (Safe parse for int/string)
          final prefs = await SharedPreferences.getInstance();
          final rawId = userData['id'];
          int numericId = 0;
          if (rawId is int) {
            numericId = rawId;
          } else if (rawId != null) {
            numericId = int.tryParse(rawId.toString()) ?? 0;
          }
          await prefs.setInt('current_user_id', numericId);

          // SECURITY FIX: Save only non-sensitive customer data locally
          await prefs.setString('customer_phone', phone);
          await prefs.setString('customer_name', name);
          // Store the merchant customer_id string (e.g. VM1, VM2)
          await prefs.setString('customer_id', userData['customer_id']?.toString() ?? userData['id']?.toString() ?? '');
          await prefs.setBool('customer_registered', true);
          // SECURITY: PAN card, email, address NOT stored locally - fetch from server when needed

          print('✅ AuthService: Registration successful for: $phone');
          print('✅ AuthService: Customer data saved to SharedPreferences');
          return {
            'success': true,
            'message': 'Registration successful',
            'user': userData,
            'customer': {
              'phone': phone,
              'name': name,
              'email': email,
              'address': address,
              'pan_card': panCard,
              'customer_id': userData['customer_id']?.toString() ?? userData['id']?.toString() ?? '',
            },
          };
        } else {
          return data;
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ AuthService: Registration error: $e');
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  /// Login user with phone and MPIN
  static Future<Map<String, dynamic>> loginWithMPIN({
    required String phone,
    required String mpin,
  }) async {
    try {
      print('🔐 AuthService: Attempting login for: $phone');

      // Encrypt MPIN for verification
      final encryptedMpin = EncryptionService.encryptMPIN(mpin);

      // Prepare login data
      final loginData = {
        'phone': phone,
        'encrypted_mpin': encryptedMpin,
      };

      // Send to new server API using secure HTTP client
      final response = await SecureHttpClient.post(
        '$baseUrl/login',
        headers: headers,
        body: jsonEncode(loginData),
      ).timeout(const Duration(seconds: 15)); // Reduced timeout for faster response

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Save token if present
          if (data['token'] != null) {
            await _saveBackendToken(data['token']);
          }

          // Save login state with user ID
          final userData = data['user'] ?? data['customer'];
          await _saveUserLoginState(phone, userData);

          // Save numeric user ID for server API calls (Safe parse for int/string)
          final prefs = await SharedPreferences.getInstance();
          final rawId = userData['id'];
          int numericId = 0;
          if (rawId is int) {
            numericId = rawId;
          } else if (rawId != null) {
            numericId = int.tryParse(rawId.toString()) ?? 0;
          }
          await prefs.setInt('current_user_id', numericId);
 
          // CRITICAL FIX: Save customer data to SharedPreferences for transaction saving
          await prefs.setString('customer_phone', phone);
          await prefs.setString('customer_name', userData['name'] ?? 'Unknown');
          await prefs.setString('customer_email', userData['email'] ?? '');
          await prefs.setString('customer_address', userData['address'] ?? '');
          await prefs.setString('customer_pan_card', userData['pan_card'] ?? '');
          // Store the merchant customer_id string (e.g. VM1, VM2)
          await prefs.setString('customer_id', userData['customer_id']?.toString() ?? userData['id']?.toString() ?? '');
          await prefs.setBool('customer_registered', true);

          print('✅ AuthService: Login successful for: $phone');
          print('✅ AuthService: Customer data saved to SharedPreferences');
          return {
            'success': true,
            'message': 'Login successful',
            'user': userData,
          };
        } else {
          return data;
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ AuthService: Login error: $e');
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  /// Save user login state to local storage
  static Future<void> _saveUserLoginState(String phone, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('💾 Saving login state...');
      print('   Phone: $phone');
      print('   UserData keys: ${userData.keys.join(", ")}');
      
      // Save all data with explicit awaits
      final success1 = await prefs.setBool(_isLoggedInKey, true);
      final success2 = await prefs.setString('user_phone', phone);
      final success3 = await prefs.setString('user_data', jsonEncode(userData));
      
      // Force commit to disk (critical for persistence)
      await prefs.commit();
      
      // Verify it was saved
      final savedIsLoggedIn = prefs.getBool(_isLoggedInKey);
      final savedPhone = prefs.getString('user_phone');
      
      if (success1 && success2 && success3 && savedIsLoggedIn == true && savedPhone == phone) {
        print('✅ AuthService: User login state saved AND verified');
        print('   Verified is_logged_in: $savedIsLoggedIn');
        print('   Verified user_phone: $savedPhone');
      } else {
        print('⚠️ AuthService: Login state saved but verification failed!');
        print('   success1=$success1, success2=$success2, success3=$success3');
        print('   savedIsLoggedIn=$savedIsLoggedIn, savedPhone=$savedPhone');
      }
    } catch (e) {
      print('❌ AuthService: Error saving user login state: $e');
    }
  }

  /// Save backend JWT token to local storage
  static Future<void> _saveBackendToken(String? token) async {
    if (token == null || token.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString('jwt_token', token);
      await prefs.commit(); // Force write to disk
      
      if (success) {
        print('✅ AuthService: Backend JWT token saved and committed (length: ${token.length})');
      } else {
        print('⚠️ AuthService: Token save returned false');
      }
    } catch (e) {
      print('❌ AuthService: Error saving backend token: $e');
    }
  }

  /// Get saved backend JWT token
  static Future<String?> getBackendToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      print('🔍 AuthService.getBackendToken() called');
      print('   Token exists: ${token != null}');
      if (token != null) {
        print('   Token preview: ${token.substring(0, min(30, token.length))}...');
      } else {
        print('   ⚠️ No token found in SharedPreferences!');
        // Debug: Check what keys exist
        final allKeys = prefs.getKeys();
        print('   Available keys: ${allKeys.take(10).join(", ")}');
      }
      
      return token;
    } catch (e) {
      print('❌ Error getting backend token: $e');
      return null;
    }
  }

  /// Get current logged in user data
  static Future<Map<String, dynamic>?> getCurrentLoggedInUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        return Map<String, dynamic>.from(userData);
      }
      return null;
    } catch (e) {
      print('❌ AuthService: Error getting current user: $e');
      return null;
    }
  }

  /// Check if server is reachable
  static Future<bool> isServerReachable() async {
    try {
      final response = await SecureHttpClient.get(
        '${ClientServerConfig.healthCheckEndpoint}',
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 400; // 400 is OK (missing user)
    } catch (e) {
      print('❌ AuthService: Server not reachable: $e');
      return false;
    }
  }

  /// Logout current user
  static Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove('user_phone');
      await prefs.remove('user_data');
      print('✅ AuthService: User logged out');
    } catch (e) {
      print('❌ AuthService: Error during logout: $e');
    }
  }

  // Additional methods for compatibility
  static Future<bool> validateMpin(String mpin) async {
    try {
      // Simple MPIN validation for production
      final prefs = await SharedPreferences.getInstance();
      final storedMpin = prefs.getString('user_mpin');
      return storedMpin == mpin;
    } catch (e) {
      print('❌ AuthService: MPIN validation error: $e');
      return false;
    }
  }


  static Future<Map<String, dynamic>> makeSecureRequest(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? body,
    String method = 'POST',
  }) async {
    try {
      final url = '${ClientServerConfig.baseUrl}$endpoint';
      final requestBody = body ?? data;
      final token = await getBackendToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await SecureHttpClient.post(
        url,
        headers: headers,
        body: requestBody != null ? jsonEncode(requestBody) : null,
      );

      final responseData = jsonDecode(response.body);
      
      // Handle Unauthorized/Forbidden - Don't auto-logout, let caller handle it
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('⚠️ AuthService: Unauthorized request (${response.statusCode}). Token may be invalid.');
        print('⚠️ Not logging out - allowing caller to handle authentication failure.');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Authentication required',
          'status_code': response.statusCode,
          'error_code': 'UNAUTHORIZED',
          'requires_reauth': true,
        };
      }

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed: ${response.statusCode}',
          'error_code': responseData['error_code'],
          'status_code': response.statusCode,
          ...responseData,
        };
      }
    } catch (e) {
      print('❌ AuthService.makeSecureRequest error: $e');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  /// Update FCM Token for the user
  static Future<bool> updateFcmToken(String phone, String token) async {
    try {
      print('🔔 AuthService: Updating FCM token for $phone');
      
      final result = await makeSecureRequest(
        '/notifications/register-token',
        body: {
          'phone': phone,
          'fcm_token': token,
          'device_type': 'mobile',
        },
      );

      return result['success'] == true;
    } catch (e) {
      print('❌ AuthService: Error updating FCM token: $e');
      return false;
    }
  }

}

/// Authentication states
enum AuthState {
  needsOnboarding,
  needsPhoneNumber,
  needsRegistration,
  needsOtpVerification,
  needsMpinSetup,
  needsMpinLogin,
  loggedIn,
}
