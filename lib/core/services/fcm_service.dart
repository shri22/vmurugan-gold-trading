import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔔 User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔔 FCM Token: $token');
        await _saveTokenLocally(token);
        // We will send this to backend when user is logged in
      }

      // 3. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔔 FCM Token Refreshed: $newToken');
        await _saveTokenLocally(newToken);
        await _sendTokenToBackend(newToken);
      });

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Foreground Message received: ${message.notification?.title}');
        // TODO: Show local notification (Snackbar or Dialog)
      });
    }
  }

  static Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final user = await AuthService.getCurrentLoggedInUser();
      if (user != null && user['phone'] != null) {
        // Only send if user is logged in
        await AuthService.updateFcmToken(user['phone'], token);
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }
  
  // Call this after successful login
  static Future<void> registerTokenOnLogin() async {
    final token = await getStoredToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    } else {
      // Try to get token again
       String? token = await _firebaseMessaging.getToken();
       if (token != null) {
         await _saveTokenLocally(token);
         await _sendTokenToBackend(token);
       }
    }
  }
}
