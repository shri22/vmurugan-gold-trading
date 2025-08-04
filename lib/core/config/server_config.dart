// SERVER CONFIGURATION
// Update these values to connect to your teammate's local server

class ServerConfig {
  // =============================================================================
  // UPDATE THESE VALUES WITH YOUR TEAMMATE'S SERVER DETAILS
  // =============================================================================
  
  // Your teammate's computer IP address
  // To find IP address on Windows: ipconfig
  // To find IP address on Mac/Linux: ifconfig
  static const String teammateIP = 'YOUR_TEAMMATE_IP'; // Replace with actual IP
  
  // Server port (usually 3000)
  static const int port = 3000;
  
  // Admin token (ask your teammate for this)
  static const String adminToken = 'VMURUGAN_ADMIN_2025';
  
  // =============================================================================
  // AUTOMATIC CONFIGURATION BASED ON PLATFORM
  // =============================================================================
  
  // Base URL for API calls
  static String get baseUrl {
    if (teammateIP == 'YOUR_TEAMMATE_IP') {
      // Default to localhost for testing
      return 'http://localhost:$port/api';
    }
    return 'http://$teammateIP:$port/api';
  }
  
  // Headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'admin-token': adminToken,
    'X-Business-ID': 'VMURUGAN_001',
  };
  
  // =============================================================================
  // COMMON IP CONFIGURATIONS FOR DIFFERENT SCENARIOS
  // =============================================================================
  
  static const Map<String, String> commonConfigs = {
    'android_emulator': 'http://10.0.2.2:3000/api',
    'ios_simulator': 'http://localhost:3000/api',
    'same_wifi_192_168_1': 'http://192.168.1.XXX:3000/api',
    'same_wifi_192_168_0': 'http://192.168.0.XXX:3000/api',
    'localhost': 'http://localhost:3000/api',
  };
  
  // =============================================================================
  // HELPER METHODS
  // =============================================================================
  
  /// Check if server is configured
  static bool get isConfigured => teammateIP != 'YOUR_TEAMMATE_IP';
  
  /// Get configuration status
  static Map<String, dynamic> get status => {
    'configured': isConfigured,
    'base_url': baseUrl,
    'teammate_ip': teammateIP,
    'port': port,
    'admin_token_set': adminToken.isNotEmpty,
  };
  
  /// Get setup instructions
  static List<String> get setupInstructions => [
    '1. Ask your teammate for their computer\'s IP address',
    '2. On Windows: Open Command Prompt and run "ipconfig"',
    '3. On Mac/Linux: Open Terminal and run "ifconfig"',
    '4. Look for IPv4 address (usually 192.168.x.x)',
    '5. Update teammateIP in server_config.dart',
    '6. Make sure you\'re on the same WiFi network',
    '7. Ask teammate to start their server: npm start',
    '8. Test connection from your app',
  ];
  
  /// Test server connection
  static Future<bool> testConnection() async {
    try {
      // Import http package at the top of file when using this method
      // final response = await http.get(
      //   Uri.parse('${baseUrl.replaceAll('/api', '')}/health'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // return response.statusCode == 200;
      return false; // Placeholder - implement when needed
    } catch (e) {
      print('Server connection test failed: $e');
      return false;
    }
  }
}
