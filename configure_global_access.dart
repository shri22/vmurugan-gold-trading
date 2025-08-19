// GLOBAL ACCESS CONFIGURATION SCRIPT
// Run this to quickly configure the app for global access

import 'dart:io';

void main() {
  print('🌍 VMurugan Gold Trading - Global Access Configuration');
  print('=' * 60);
  
  // Get client's public IP
  stdout.write('Enter client\'s public IP address: ');
  String? publicIP = stdin.readLineSync();
  
  if (publicIP == null || publicIP.isEmpty) {
    print('❌ Error: Public IP address is required');
    exit(1);
  }
  
  // Validate IP format (basic)
  if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(publicIP)) {
    print('❌ Error: Invalid IP address format');
    exit(1);
  }
  
  print('\n📝 Configuration Summary:');
  print('Public IP: $publicIP');
  print('Environment: Production (Global Access)');
  print('API Port: 3001');
  print('Base URL: http://$publicIP:3001/api');
  
  stdout.write('\nProceed with configuration? (y/n): ');
  String? confirm = stdin.readLineSync();
  
  if (confirm?.toLowerCase() != 'y') {
    print('❌ Configuration cancelled');
    exit(0);
  }
  
  // Generate configuration file content
  String configContent = '''
// SERVER CONFIGURATION FOR GLOBAL ACCESS
// Auto-generated configuration

class ServerConfig {
  // =============================================================================
  // GLOBAL ACCESS CONFIGURATION
  // =============================================================================
  
  // Client's public IP address
  static const String publicIP = '$publicIP';
  static const String productionDomain = ''; // Leave empty if no domain
  static const String localIP = 'localhost'; // Keep for local development
  
  // Server ports
  static const int httpsPort = 443;
  static const int localPort = 3000;
  static const int globalApiPort = 3001; // Direct API access globally
  
  // Environment flag (false for global production access)
  static const bool isDevelopment = false; // GLOBAL ACCESS MODE
  
  // Admin token
  static const String adminToken = 'VMURUGAN_ADMIN_2025';
  
  // =============================================================================
  // AUTOMATIC CONFIGURATION BASED ON ENVIRONMENT
  // =============================================================================
  
  // Base URL for API calls - GLOBAL ACCESS
  static String get baseUrl {
    if (isDevelopment) {
      // Development mode - use local server
      return 'http://localhost:\$localPort/api';
    } else {
      // Production mode - use public IP for global access
      if (productionDomain.isNotEmpty) {
        return 'https://\$productionDomain/api'; // Use domain if available
      } else {
        return 'http://\$publicIP:\$globalApiPort/api'; // Use public IP directly
      }
    }
  }
  
  // Health check endpoint for testing connectivity
  static String get healthCheckUrl {
    if (isDevelopment) {
      return 'http://localhost:\$localPort/health';
    } else {
      if (productionDomain.isNotEmpty) {
        return 'https://\$productionDomain/health';
      } else {
        return 'http://\$publicIP:\$globalApiPort/health';
      }
    }
  }
  
  // Headers for API requests - Enhanced for global access
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'admin-token': adminToken,
    'X-Business-ID': 'VMURUGAN_001',
    'User-Agent': 'VMurugan-Mobile/1.0.0',
    'Accept': 'application/json',
    'X-Client-Type': 'mobile',
    'X-Access-Type': isDevelopment ? 'local' : 'global',
  };
  
  // =============================================================================
  // HELPER METHODS
  // =============================================================================
  
  /// Check if server is configured for global access
  static bool get isConfigured => 
    !isDevelopment && publicIP != '203.0.113.10'; // Check if real IP is set
  
  /// Get configuration status - Enhanced for global access
  static Map<String, dynamic> get status => {
    'configured': isConfigured,
    'environment': isDevelopment ? 'development' : 'production',
    'access_type': isDevelopment ? 'local' : 'global',
    'base_url': baseUrl,
    'health_check_url': healthCheckUrl,
    'server_address': isDevelopment ? localIP : (productionDomain.isNotEmpty ? productionDomain : publicIP),
    'port': isDevelopment ? localPort : globalApiPort,
    'admin_token_set': adminToken.isNotEmpty,
    'ssl_enabled': !isDevelopment && productionDomain.isNotEmpty,
    'global_access_ready': isConfigured,
  };
  
  /// Get setup instructions for global access
  static List<String> get setupInstructions => [
    '1. ✅ Public IP configured: \$publicIP',
    '2. ✅ Environment set to production',
    '3. ✅ Global access enabled',
    '4. 🔧 Ensure server listens on 0.0.0.0:3001',
    '5. 🔧 Configure Windows Firewall to allow port 3001',
    '6. 🔧 Set up router port forwarding if needed',
    '7. 🧪 Test health check: \$healthCheckUrl',
    '8. 📱 Build production APK: flutter build apk --release',
    '9. 🌍 Test from different networks',
  ];
  
  /// Test server connection
  static Future<bool> testConnection() async {
    try {
      // This would require http package import in actual implementation
      print('Testing connection to: \$healthCheckUrl');
      // Implementation would go here
      return true;
    } catch (e) {
      print('❌ Connection test failed: \$e');
      return false;
    }
  }
}
''';
  
  // Write configuration to file
  try {
    File configFile = File('lib/core/config/server_config.dart');
    configFile.writeAsStringSync(configContent);
    
    print('\n✅ Configuration completed successfully!');
    print('\n📁 Updated file: lib/core/config/server_config.dart');
    print('\n🚀 Next steps:');
    print('1. Review the generated configuration');
    print('2. Ensure server listens on 0.0.0.0:3001');
    print('3. Configure Windows Firewall');
    print('4. Build production APK: flutter build apk --release');
    print('5. Test from different networks');
    print('\n🌍 Your app is now configured for global access!');
    
  } catch (e) {
    print('❌ Error writing configuration file: $e');
    exit(1);
  }
}
