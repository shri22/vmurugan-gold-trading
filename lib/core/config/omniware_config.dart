import 'api_config.dart';

/// Omniware Payment Gateway Configuration
/// 
/// This file contains the merchant credentials for Omniware payment gateway.
/// We have two separate merchant accounts:
/// - Gold Merchant (779285): For Gold Plus and Gold Flexi schemes
/// - Silver Merchant (779295): For Silver Plus and Silver Flexi schemes

class OmniwareConfig {
  // Environment configuration
  static const bool isProduction = true;
  static const String environment = isProduction ? 'LIVE' : 'TEST';
  
  // Gold Merchant Configuration
  static const String goldMerchantName = 'V MURUGAN JEWELLERY';
  static const String goldMerchantId = '779285';
  static const String goldApiKey = 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334';
  static const String goldSalt = '47cdd26963f53e3181f93adcf3af487ec28d7643';
  static const String goldEmail = 'sellamuthu19661234@gmail.com';
  
  // Silver Merchant Configuration
  static const String silverMerchantName = 'V MURUGAN NAGAI KADAI';
  static const String silverMerchantId = '779295';
  static const String silverApiKey = 'f1f7f413-3826-4980-ad4d-c22f64ad54d3';
  static const String silverSalt = '5ea7c9cb63d933192ac362722d6346e1efa67f7f';
  static const String silverEmail = 'gopinath24949991@gmail.com';
  
  // Common Configuration
  static const String currency = 'INR';
  static const String country = 'India';
  
  // Master API Configuration from ApiConfig
  static const String apiBaseUrl = ApiConfig.rawBaseUrl;
  
  // Return URLs (will be handled by the app)
  static const String returnUrl = 'https://vmuruganjewellery.co.in/payment/success';
  static const String returnUrlFailure = 'https://vmuruganjewellery.co.in/payment/failure';
  static const String returnUrlCancel = 'https://vmuruganjewellery.co.in/payment/cancel';
  
  /// Get merchant configuration based on metal type
  /// 
  /// [metalType] - 'gold' or 'silver'
  /// Returns a map with merchant credentials
  static Map<String, String> getMerchantConfig(String metalType) {
    final normalizedType = (metalType).toLowerCase();
    
    if (normalizedType == 'silver') {
      return {
        'merchantName': silverMerchantName,
        'merchantId': silverMerchantId,
        'apiKey': silverApiKey,
        'salt': silverSalt,
        'email': silverEmail,
      };
    }
    
    // Default to Gold merchant
    return {
      'merchantName': goldMerchantName,
      'merchantId': goldMerchantId,
      'apiKey': goldApiKey,
      'salt': goldSalt,
      'email': goldEmail,
    };
  }
  
  /// Get API key based on metal type
  static String getApiKey(String metalType) {
    return metalType.toLowerCase() == 'silver' ? silverApiKey : goldApiKey;
  }
  
  /// Get SALT based on metal type
  static String getSalt(String metalType) {
    return metalType.toLowerCase() == 'silver' ? silverSalt : goldSalt;
  }
  
  /// Get merchant ID based on metal type
  static String getMerchantId(String metalType) {
    return metalType.toLowerCase() == 'silver' ? silverMerchantId : goldMerchantId;
  }
  
  /// Get merchant email based on metal type
  static String getMerchantEmail(String metalType) {
    return metalType.toLowerCase() == 'silver' ? silverEmail : goldEmail;
  }
  
  /// Get merchant name based on metal type
  static String getMerchantName(String metalType) {
    return metalType.toLowerCase() == 'silver' ? silverMerchantName : goldMerchantName;
  }
}

