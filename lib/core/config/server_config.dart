import 'package:flutter/foundation.dart';
import 'api_config.dart';
 
class ServerConfig {
  static const String baseUrl = ApiConfig.baseUrl; // Source of Truth from ApiConfig
  static const String apiVersion = ApiConfig.apiVersion;
  static const bool useHttps = true;
  static const int timeout = ApiConfig.timeout; // 30 seconds
}
