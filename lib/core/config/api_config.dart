import 'package:flutter/foundation.dart';

class ApiConfig {
  // PRODUCTION DOMAIN - Update this one variable to reflect across the entire app
  static const String domain = 'prodapi.vmuruganjewellery.co.in';
  static const String port = '443';
  
  // Base URLs built from the domain
  static const String baseUrl = 'https://$domain/api';
  static const String rawBaseUrl = 'https://$domain'; // Without /api suffix
     
  static const String apiVersion = 'v1';
  static bool get useHttps => true; // Always HTTPS
  static const int timeout = 30000; // 30 seconds
}
