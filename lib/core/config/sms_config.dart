/// SMS Service Configuration
/// 
/// To enable real SMS functionality, you need to:
/// 1. Choose an SMS provider
/// 2. Get API credentials from the provider
/// 3. Update the configuration below
/// 4. Test the configuration

class SmsConfig {
  // Choose your SMS provider: 'textlocal', 'twilio', 'msg91', 'fast2sms'
  static const String provider = 'msg91';
  
  // =============================================================================
  // TEXTLOCAL CONFIGURATION (Popular in India)
  // =============================================================================
  // Sign up at: https://www.textlocal.in/
  // Get your API key from: https://control.textlocal.in/settings/
  static const String textlocalApiKey = 'YOUR_TEXTLOCAL_API_KEY'; // Replace with your actual API key
  static const String textlocalSender = 'VMGOLD'; // 6 characters max
  
  // =============================================================================
  // TWILIO CONFIGURATION (Global)
  // =============================================================================
  // Sign up at: https://www.twilio.com/
  // Get credentials from: https://console.twilio.com/
  static const String twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  static const String twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
  static const String twilioFromNumber = '+1234567890'; // Your Twilio phone number
  
  // =============================================================================
  // MSG91 CONFIGURATION (Popular in India)
  // =============================================================================
  // Sign up at: https://msg91.com/
  // Get API key from: https://control.msg91.com/user/index.php#api
  static const String msg91ApiKey = '462055Ay4yXIYzq68876e03P1'; // Your MSG91 Auth Key
  static const String msg91SenderId = 'VMGOLD'; // 6 characters max
  static const String msg91TemplateId = 'YOUR_TEMPLATE_ID'; // Replace with actual Template ID from MSG91
  
  // =============================================================================
  // FAST2SMS CONFIGURATION (Indian provider)
  // =============================================================================
  // Sign up at: https://www.fast2sms.com/
  // Get API key from: https://www.fast2sms.com/dashboard
  static const String fast2smsApiKey = 'YOUR_FAST2SMS_API_KEY';
  static const String fast2smsSenderId = 'VMGOLD'; // 6 characters max
  
  // =============================================================================
  // HELPER METHODS
  // =============================================================================
  
  /// Check if the current provider is configured
  static bool isConfigured() {
    switch (provider) {
      case 'textlocal':
        return textlocalApiKey != 'YOUR_TEXTLOCAL_API_KEY' && textlocalApiKey.isNotEmpty;
      case 'twilio':
        return twilioAccountSid != 'YOUR_TWILIO_ACCOUNT_SID' && 
               twilioAuthToken != 'YOUR_TWILIO_AUTH_TOKEN' &&
               twilioAccountSid.isNotEmpty && twilioAuthToken.isNotEmpty;
      case 'msg91':
        return msg91ApiKey != 'YOUR_MSG91_API_KEY' && msg91ApiKey.isNotEmpty;
      case 'fast2sms':
        return fast2smsApiKey != 'YOUR_FAST2SMS_API_KEY' && fast2smsApiKey.isNotEmpty;
      default:
        return false;
    }
  }
  
  /// Get configuration status
  static Map<String, dynamic> getStatus() {
    return {
      'provider': provider,
      'configured': isConfigured(),
      'providers': {
        'textlocal': {
          'name': 'TextLocal',
          'region': 'India',
          'website': 'https://www.textlocal.in/',
          'configured': textlocalApiKey != 'YOUR_TEXTLOCAL_API_KEY' && textlocalApiKey.isNotEmpty,
          'cost': 'Low cost, good for India',
        },
        'twilio': {
          'name': 'Twilio',
          'region': 'Global',
          'website': 'https://www.twilio.com/',
          'configured': twilioAccountSid != 'YOUR_TWILIO_ACCOUNT_SID' && 
                       twilioAuthToken != 'YOUR_TWILIO_AUTH_TOKEN' &&
                       twilioAccountSid.isNotEmpty && twilioAuthToken.isNotEmpty,
          'cost': 'Higher cost, excellent reliability',
        },
        'msg91': {
          'name': 'MSG91',
          'region': 'India',
          'website': 'https://msg91.com/',
          'configured': msg91ApiKey != 'YOUR_MSG91_API_KEY' && msg91ApiKey.isNotEmpty,
          'cost': 'Competitive pricing for India',
        },
        'fast2sms': {
          'name': 'Fast2SMS',
          'region': 'India',
          'website': 'https://www.fast2sms.com/',
          'configured': fast2smsApiKey != 'YOUR_FAST2SMS_API_KEY' && fast2smsApiKey.isNotEmpty,
          'cost': 'Very low cost for India',
        },
      },
    };
  }
  
  /// Get setup instructions for the current provider
  static String getSetupInstructions() {
    switch (provider) {
      case 'textlocal':
        return '''
TextLocal Setup Instructions:
1. Visit https://www.textlocal.in/
2. Create an account
3. Go to Settings > API Keys
4. Copy your API key
5. Update textlocalApiKey in sms_config.dart
6. Set your sender ID (max 6 characters)
        ''';
      case 'twilio':
        return '''
Twilio Setup Instructions:
1. Visit https://www.twilio.com/
2. Create an account
3. Go to Console Dashboard
4. Copy Account SID and Auth Token
5. Buy a phone number
6. Update credentials in sms_config.dart
        ''';
      case 'msg91':
        return '''
MSG91 Setup Instructions:
1. Visit https://msg91.com/
2. Create an account
3. Go to API section
4. Copy your API key
5. Set up sender ID
6. Update credentials in sms_config.dart
        ''';
      case 'fast2sms':
        return '''
Fast2SMS Setup Instructions:
1. Visit https://www.fast2sms.com/
2. Create an account
3. Go to Dashboard > API
4. Copy your API key
5. Update credentials in sms_config.dart
        ''';
      default:
        return 'Unknown provider: $provider';
    }
  }
}

/// SMS Configuration Instructions
/// 
/// STEP 1: Choose a Provider
/// - TextLocal: Best for India, low cost
/// - Twilio: Global, most reliable, higher cost
/// - MSG91: Good for India, competitive pricing
/// - Fast2SMS: Very low cost for India
/// 
/// STEP 2: Get API Credentials
/// - Sign up with your chosen provider
/// - Get API key/credentials
/// - Note down sender ID requirements
/// 
/// STEP 3: Update Configuration
/// - Update the provider variable above
/// - Add your API credentials
/// - Set appropriate sender ID
/// 
/// STEP 4: Test
/// - Run the app and test OTP sending
/// - Check SMS delivery
/// - Monitor costs and delivery rates
/// 
/// STEP 5: Production Considerations
/// - Set up proper error handling
/// - Monitor SMS delivery rates
/// - Set up billing alerts
/// - Consider backup providers
