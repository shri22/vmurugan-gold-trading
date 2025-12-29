import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl => kReleaseMode 
    ? 'https://api.vmuruganjewellery.co.in:3001' 
    : 'http://192.168.29.150:3001';
    
  static const String apiVersion = 'v1';
  static bool get useHttps => kReleaseMode;
  static const int timeout = 30000; // 30 seconds
}
