# 🏦 Omniware Payment Gateway Integration

## Overview

This document describes the integration of Omniware Payment Gateway into the VMurugan Gold Trading application. The integration provides secure payment processing for gold and silver purchases through multiple payment methods.

## 📋 Integration Details

### **Testing Environment Credentials**
- **Merchant Name**: Rohith Test
- **Merchant ID**: 291499
- **Registered Email**: rsn7rohith@gmail.com
- **API Key**: fb6bca86-b429-4abf-a42f-824bdd29022e
- **SALT**: 80c67bfdf027da08de88ab5ba903fecafaab8f6d

### **Resources**
- **Developer Docs**: https://omniware.in/developer.html
- **Merchant Portal**: https://mrm.omniware.in/
- **Testing Environment**: Only Net Banking available
- **Live Environment**: All payment methods available

## 🏗️ Architecture

### **Files Created/Modified**

#### **Configuration**
- `lib/core/config/server_config.dart` - Added OmniwareConfig class
- `OMNIWARE_INTEGRATION.md` - This documentation file

#### **Services**
- `lib/features/payment/services/omniware_payment_service.dart` - Core Omniware integration
- `lib/features/payment/services/enhanced_payment_service.dart` - Unified payment service

#### **Models**
- `lib/features/payment/models/payment_model.dart` - Added Omniware models and payment methods

#### **Screens**
- `lib/features/payment/screens/enhanced_payment_screen.dart` - New payment selection UI
- `lib/features/payment/screens/payment_gateway_config_screen.dart` - Configuration management
- `lib/features/gold/screens/buy_gold_screen.dart` - Updated with enhanced payment

## 🔧 Configuration

### **Environment Setup**

The integration supports both testing and live environments:

```dart
// Testing Environment (Current)
static const bool isTestEnvironment = true;
static const String testBaseUrl = 'https://test.omniware.in';

// Live Environment (Future)
static const bool isTestEnvironment = false;
static const String liveBaseUrl = 'https://omniware.in';
```

### **Available Payment Methods**

#### **Testing Environment**
- ✅ Net Banking (Only method available)

#### **Live Environment**
- ✅ Net Banking
- ✅ UPI
- ✅ Credit/Debit Cards
- ✅ Digital Wallets
- ✅ EMI

## 💳 Payment Flow

### **1. Payment Initiation**
```dart
final response = await omniwareService.initiatePayment(
  transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
  amount: 2000.0,
  customerName: 'Customer Name',
  customerEmail: 'customer@email.com',
  customerPhone: '+919876543210',
  description: 'Gold Purchase - 0.216g',
  paymentMethod: 'netbanking',
);
```

### **2. Payment Processing**
1. User selects payment method
2. System generates secure hash
3. API call to Omniware gateway
4. User redirected to payment page
5. Payment completion/cancellation
6. Status verification
7. Transaction recording

### **3. Status Verification**
```dart
final status = await omniwareService.checkPaymentStatus(transactionId);
if (status.isSuccess) {
  // Process successful payment
} else if (status.isFailed) {
  // Handle failed payment
}
```

## 🔐 Security Features

### **Hash Generation**
- SHA256 hash for request security
- Salt-based encryption
- Timestamp validation
- Merchant ID verification

### **Data Protection**
- Encrypted API communication
- Secure credential storage
- Transaction logging
- Error handling

## 🎯 Usage Examples

### **Basic Payment**
```dart
// Initialize service
final paymentService = EnhancedPaymentService();

// Create payment request
final request = PaymentRequest(
  transactionId: 'TXN_123456789',
  amount: 5000.0,
  merchantName: 'VMurugan Gold Trading',
  merchantUpiId: 'vmuruganjew2127@fbl',
  description: 'Gold Purchase - 0.540g',
  method: PaymentMethod.omniwareNetbanking,
);

// Process payment
final response = await paymentService.processPayment(request: request);
```

### **Payment Status Check**
```dart
final status = await paymentService.verifyPaymentStatus(
  'TXN_123456789',
  PaymentMethod.omniwareNetbanking,
);
```

## 🧪 Testing

### **Test Connection**
```dart
// Test gateway connectivity
final testResponse = await omniwareService.initiatePayment(
  transactionId: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
  amount: 1.0,
  customerName: 'Test Customer',
  customerEmail: 'test@vmuruganjewellery.co.in',
  customerPhone: '+919677944711',
  description: 'Connection Test',
  paymentMethod: 'netbanking',
);
```

### **Configuration Screen**
Access the configuration screen to:
- View current settings
- Test connection
- Copy credentials
- Check available methods

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentGatewayConfigScreen(),
  ),
);
```

## 🚀 Deployment Steps

### **1. Testing Phase**
1. ✅ Configure testing credentials
2. ✅ Test net banking payments
3. ✅ Verify transaction flow
4. ✅ Test error handling

### **2. Live Deployment**
1. Update `isTestEnvironment` to `false`
2. Replace with live credentials
3. Test all payment methods
4. Monitor transaction success rates

### **3. Credential Update**
```dart
// Update in lib/core/config/server_config.dart
class OmniwareConfig {
  static const bool isTestEnvironment = false; // Change to false
  static const String merchantId = 'LIVE_MERCHANT_ID';
  static const String apiKey = 'LIVE_API_KEY';
  static const String salt = 'LIVE_SALT';
}
```

## 📊 Monitoring

### **Transaction Tracking**
- All transactions logged to database
- Gateway transaction ID mapping
- Status change tracking
- Error logging

### **Success Metrics**
- Payment success rate
- Method-wise performance
- Error categorization
- User experience metrics

## 🔄 Migration from UPI-only

### **Backward Compatibility**
- Existing UPI methods still available
- Gradual migration to gateway
- User preference settings
- Fallback mechanisms

### **Enhanced Features**
- Multiple payment options
- Better success rates
- Professional payment pages
- Automated status checking

## 🛠️ Troubleshooting

### **Common Issues**

#### **Configuration Errors**
```
Error: Omniware configuration is incomplete
Solution: Check API key and salt in OmniwareConfig
```

#### **Hash Mismatch**
```
Error: Invalid hash
Solution: Verify salt and hash generation logic
```

#### **Network Issues**
```
Error: Connection timeout
Solution: Check internet connectivity and gateway status
```

### **Debug Mode**
Enable detailed logging:
```dart
print('🚀 OmniwarePaymentService: Initiating payment...');
print('🔐 Generated payment hash: ${hash.substring(0, 20)}...');
print('📡 Payment API Response: ${response.statusCode}');
```

## 📞 Support

### **Technical Support**
- **Developer Docs**: https://omniware.in/developer.html
- **Merchant Portal**: https://mrm.omniware.in/
- **Integration Issues**: Check logs and configuration

### **Business Support**
- **VMurugan Support**: +91 9677944711
- **Email**: vmuruganjewellery@gmail.com
- **Hours**: 9 AM - 6 PM (Mon-Sat)

## 🔮 Future Enhancements

### **Planned Features**
- Subscription payments for schemes
- Refund processing
- Multi-currency support
- Advanced analytics

### **Integration Improvements**
- Webhook support
- Real-time notifications
- Enhanced error handling
- Performance optimization

---

**Note**: This integration is currently in testing mode with only Net Banking available. All payment methods will be available once moved to live environment with actual credentials.
