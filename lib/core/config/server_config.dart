// Paynimo Payment Gateway Configuration
class PaynimoConfig {
  // Bank Test Credentials (Received from Bank)
  static const String merchantId = 'L3348'; // Test merchant ID from Worldline documentation
  static const String merchantCode = 'T1098761'; // Bank provided
  static const String schemeCode = 'FIRST'; // Bank provided
  static const String encryptionKey = '9221995309QQNRIO'; // Bank provided
  static const String encryptionIV = '6753042926GDVTTK'; // Bank provided

  // Environment Configuration
  static const bool isTestEnvironment = true; // Set to false for production
  static const String environment = isTestEnvironment ? 'test' : 'live';

  // Bank Test Configuration - STRICT LIMITS
  static const double minTestAmount = 1.0; // Bank requirement: ₹1 minimum
  static const double maxTestAmount = 10.0; // Bank requirement: ₹10 maximum
  static const String testCurrency = 'INR';

  // Worldline Device Configuration
  static const String deviceId = 'ANDROIDSH1'; // ANDROIDSH1 / ANDROIDSH2 / iOSSH1 / iOSSH2
  static const String paymentMode = 'all'; // all, netBanking, creditCard, debitCard, UPI, wallet

  // Bank Test Login Credentials
  static const String testBankLogin = 'test';
  static const String testBankPassword = 'test';

  // Test Environment URLs
  static const String testPaymentUrl = 'https://test.paynimo.com/api/paynimoV2.req';
  static const String testStatusUrl = 'https://test.paynimo.com/api/paynimoV2/paymentStatus.req';

  // Production Environment URLs
  static const String livePaymentUrl = 'https://www.paynimo.com/api/paynimoV2.req';
  static const String liveStatusUrl = 'https://www.paynimo.com/api/paynimoV2/paymentStatus.req';

  // Current Environment URLs
  static String get paymentUrl => isTestEnvironment ? testPaymentUrl : livePaymentUrl;
  static String get statusUrl => isTestEnvironment ? testStatusUrl : liveStatusUrl;

  // Backend Integration URLs
  static const String backendPaymentEndpoint = 'https://api.vmuruganjewellery.co.in:3001/api/paynimo/initiate';
  static const String backendCallbackEndpoint = 'https://api.vmuruganjewellery.co.in:3001/api/paynimo/callback';
  static const String backendStatusEndpoint = 'https://api.vmuruganjewellery.co.in:3001/api/paynimo/status';

  // Return URLs
  static const String successUrl = 'https://api.vmuruganjewellery.co.in:3001/payment/success';
  static const String failureUrl = 'https://api.vmuruganjewellery.co.in:3001/payment/failure';
  static const String cancelUrl = 'https://api.vmuruganjewellery.co.in:3001/payment/cancel';

  // Test Bank Credentials
  static const String testLoginId = 'test';
  static const String testPassword = 'test';

  // Available Payment Methods
  static const List<String> availablePaymentMethods = [
    'credit_card',
    'debit_card',
    'net_banking',
    'upi',
    'wallet'
  ];

  // Merchant Logo URL
  static const String merchantLogoUrl = 'https://www.paynimo.com/CompanyDocs/company-logo-vertical.png';

  // Custom Style Configuration
  static const Map<String, String> customStyle = {
    'PRIMARY_COLOR_CODE': '#45beaa',
    'SECONDARY_COLOR_CODE': '#FFFFFF',
    'BUTTON_COLOR_CODE_1': '#2d8c8c',
    'BUTTON_COLOR_CODE_2': '#FFFFFF'
  };

  // Configuration Validation
  static bool get isConfigured =>
    merchantCode.isNotEmpty &&
    schemeCode.isNotEmpty &&
    encryptionKey.isNotEmpty &&
    encryptionIV.isNotEmpty &&
    merchantId.isNotEmpty;

  // Test amount validation
  static bool isValidTestAmount(double amount) {
    return isTestEnvironment ?
      (amount >= minTestAmount && amount <= maxTestAmount) :
      amount > 0;
  }
}



class ServerConfig {
  static const String baseUrl = 'https://api.vmuruganjewellery.co.in:3001';
  static const String apiVersion = 'v1';
  static const bool useHttps = true;
  static const int timeout = 30000; // 30 seconds
}
