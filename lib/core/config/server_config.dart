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

/// Omniware Payment Gateway Configuration
class OmniwareConfig {
  // =============================================================================
  // OMNIWARE PAYMENT GATEWAY CREDENTIALS (TESTING ENVIRONMENT)
  // =============================================================================

  // Testing Environment Credentials
  static const String merchantName = 'Rohith Test';
  static const String merchantId = '291499';
  static const String registeredEmail = 'rsn7rohith@gmail.com';
  static const String apiKey = 'fb6bca86-b429-4abf-a42f-824bdd29022e';
  static const String salt = '80c67bfdf027da08de88ab5ba903fecafaab8f6d';

  // Environment URLs (Updated based on actual Omniware endpoints)
  static const String testBaseUrl = 'https://sandbox.omniware.in';  // Updated sandbox URL
  static const String liveBaseUrl = 'https://api.omniware.in';       // Updated live URL
  static const String merchantPortalUrl = 'https://mrm.omniware.in/';
  static const String developerDocsUrl = 'https://omniware.in/developer.html';

  // Current environment (true for testing, false for live)
  static const bool isTestEnvironment = true;

  // =============================================================================
  // DYNAMIC CONFIGURATION BASED ON ENVIRONMENT
  // =============================================================================

  /// Get base URL based on environment
  static String get baseUrl => isTestEnvironment ? testBaseUrl : liveBaseUrl;

  /// Get payment endpoint
  static String get paymentEndpoint => '$baseUrl/api/payment/initiate';

  /// Get payment status endpoint
  static String get statusEndpoint => '$baseUrl/api/payment/status';

  /// Get refund endpoint
  static String get refundEndpoint => '$baseUrl/api/payment/refund';

  // =============================================================================
  // PAYMENT CONFIGURATION
  // =============================================================================

  /// Available payment methods in test environment
  static const List<String> testPaymentMethods = ['netbanking'];

  /// Available payment methods in live environment
  static const List<String> livePaymentMethods = [
    'netbanking',
    'upi',
    'card',
    'wallet',
    'emi'
  ];

  /// Get available payment methods based on environment
  static List<String> get availablePaymentMethods =>
      isTestEnvironment ? testPaymentMethods : livePaymentMethods;

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Get environment status
  static Map<String, dynamic> get status => {
    'environment': isTestEnvironment ? 'testing' : 'live',
    'base_url': baseUrl,
    'merchant_id': merchantId,
    'merchant_name': merchantName,
    'available_methods': availablePaymentMethods,
    'api_key_set': apiKey.isNotEmpty,
    'salt_set': salt.isNotEmpty,
  };

  /// Get setup instructions
  static List<String> get setupInstructions => [
    '1. Testing Environment is currently active',
    '2. Only Net Banking is available in testing',
    '3. Use provided test credentials for integration',
    '4. Check developer docs: $developerDocsUrl',
    '5. Access merchant portal: $merchantPortalUrl',
    '6. Switch to live environment when ready',
    '7. Update credentials for live environment',
    '8. All payment methods available in live mode',
  ];

  /// Validate configuration
  static bool get isConfigured =>
      merchantId.isNotEmpty &&
      apiKey.isNotEmpty &&
      salt.isNotEmpty;
}
