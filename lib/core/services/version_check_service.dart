import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';
import 'secure_http_client.dart';

class VersionCheckService {
  static Future<Map<String, dynamic>> checkVersion() async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('📱 Current App Version: $currentVersion');

      // 2. Fetch version config from server
      final response = await SecureHttpClient.get(
        '${ApiConfig.baseUrl}/app-config',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        if (config['success'] == true) {
          final platformConfig = Platform.isAndroid ? config['android'] : config['ios'];
          
          final minVersion = platformConfig['min_version'];
          final latestVersion = platformConfig['latest_version'];
          final updateUrl = platformConfig['update_url'];
          final isForceUpdate = platformConfig['is_force_update'] ?? false;
          final message = platformConfig['message'] ?? 'A new version is available. Please update to continue.';

          // 3. Compare versions
          bool needsUpdate = _isVersionLower(currentVersion, minVersion);
          
          return {
            'needsUpdate': needsUpdate,
            'currentVersion': currentVersion,
            'minVersion': minVersion,
            'latestVersion': latestVersion,
            'updateUrl': updateUrl,
            'isForceUpdate': isForceUpdate,
            'message': message,
          };
        }
      }
      return {'needsUpdate': false};
    } catch (e) {
      print('❌ Error checking app version: $e');
      return {'needsUpdate': false};
    }
  }

  /// Compares two version strings (e.g. "1.0.0" and "1.0.1")
  static bool _isVersionLower(String current, String required) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> requiredParts = required.split('.').map(int.parse).toList();

      for (int i = 0; i < requiredParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (currentPart < requiredParts[i]) return true;
        if (currentPart > requiredParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
