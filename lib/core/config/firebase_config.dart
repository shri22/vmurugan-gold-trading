// FIREBASE CONFIGURATION FOR VMURUGAN
// Update these values after setting up your Firebase project

class FirebaseConfig {
  // TODO: Replace with your actual Firebase project details
  // Get these from Firebase Console > Project Settings
  
  // Example values (replace with your actual values):
  // static const String projectId = 'vmurugan-gold-trading-12345';
  // static const String apiKey = 'AIzaSyC1234567890abcdefghijklmnopqrstuvwxyz';

  // ✅ CONFIGURED FOR VMURUGAN FIREBASE PROJECT
  static const String projectId = 'vmurugan-gold-trading';
  static const String apiKey = 'AIzaSyCaS4pdX3a_JFdL0PolTHYnpebg5ppbgs0';

  // EXAMPLE: After you get your values, it should look like:
  // static const String projectId = 'vmurugan-gold-trading-a1b2c';
  // static const String apiKey = 'AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  
  // Firestore database URL (auto-generated based on project ID)
  static String get firestoreUrl => 
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  
  // Business configuration
  static const String businessId = 'VMURUGAN_001';
  static const String businessName = 'VMUrugan Gold Trading';
  static const String adminToken = 'VMURUGAN_ADMIN_2025';
  
  // Validation
  static bool get isConfigured {
    return projectId != 'YOUR_FIREBASE_PROJECT_ID' && 
           apiKey != 'YOUR_FIREBASE_API_KEY' &&
           projectId.isNotEmpty && 
           apiKey.isNotEmpty;
  }
  
  // Configuration status
  static Map<String, dynamic> get status {
    if (isConfigured) {
      return {
        'configured': true,
        'message': 'Firebase is properly configured',
        'project_id': projectId,
        'business_id': businessId,
      };
    } else {
      return {
        'configured': false,
        'message': 'Firebase configuration required',
        'instructions': [
          '1. Go to https://console.firebase.google.com/',
          '2. Create project: $businessName',
          '3. Enable Firestore Database',
          '4. Copy Project ID and API Key',
          '5. Update firebase_config.dart',
        ],
      };
    }
  }
  
  // Headers for API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  
  // Collection names
  static const String customersCollection = 'customers';
  static const String transactionsCollection = 'transactions';
  static const String analyticsCollection = 'analytics';
  static const String priceHistoryCollection = 'price_history';
  
  // Test data for development
  static const Map<String, dynamic> testCustomer = {
    'phone': '9999999999',
    'name': 'Test Customer',
    'email': 'test@vmurugan.com',
    'address': 'Test Address, Chennai',
    'pan_card': 'ABCDE1234F',
    'device_id': 'test_device_001',
  };
}

// Firebase setup instructions
class FirebaseSetupInstructions {
  static const String setupGuide = '''
🔥 FIREBASE SETUP FOR VMURUGAN

1. CREATE FIREBASE PROJECT:
   - Go to: https://console.firebase.google.com/
   - Click "Create a project"
   - Name: "vmurugan-gold-trading"
   - Enable Google Analytics: Yes

2. ENABLE FIRESTORE:
   - Go to "Firestore Database"
   - Click "Create database"
   - Start in test mode
   - Choose location: asia-south1

3. GET CONFIGURATION:
   - Go to Project Settings (gear icon)
   - Copy Project ID
   - Copy Web API Key

4. UPDATE APP:
   - Open: lib/core/config/firebase_config.dart
   - Replace projectId with your Project ID
   - Replace apiKey with your API Key

5. TEST CONNECTION:
   - Build and run app
   - Register test customer
   - Check Firestore console for data

6. SECURE RULES (PRODUCTION):
   - Update Firestore security rules
   - Enable authentication
   - Restrict access by user roles

Your VMUrugan app will then save all data permanently to Firebase! 🚀
''';

  static void printInstructions() {
    print(setupGuide);
  }
}
