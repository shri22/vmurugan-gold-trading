class OmniwareConfig {
  static const String merchantId = 'VMURUGAN_MERCHANT_ID';
  static const String apiKey = 'VMURUGAN_API_KEY';
  static const String salt = 'VMURUGAN_SALT_KEY';
  static const String paymentEndpoint = 'https://103.124.152.220:3001/api/payment/initiate';
  static const String statusEndpoint = 'https://103.124.152.220:3001/api/payment/status';
  
  static const bool isTestEnvironment = false; // Production mode
  static const bool isConfigured = true;
  static const List<String> availablePaymentMethods = ['netbanking', 'upi', 'card'];
}

class ServerConfig {
  static const String baseUrl = 'https://103.124.152.220:3001';
  static const String apiVersion = 'v1';
  static const bool useHttps = true;
  static const int timeout = 30000; // 30 seconds
}
