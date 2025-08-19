# 🚀 Gold Trading App - Complete Deployment Guide

## 📋 **Overview**
This guide covers the complete deployment process for the Gold Trading App with Omniware Payment Gateway integration.

## 🏗️ **Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │────│   Your Server   │────│ Omniware Gateway│
│   (Android)     │    │   (Backend)     │    │   (Payment)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    ┌─────────┐            ┌─────────┐            ┌─────────┐
    │Firebase │            │Database │            │ Banks   │
    │Auth/DB  │            │(MySQL)  │            │& UPI    │
    └─────────┘            └─────────┘            └─────────┘
```

## 🎯 **Phase 1: Server Setup & APIs**

### **1.1 Required Server APIs**

Create these APIs on your server for Omniware integration:

#### **A. Payment Initiation API**
```
POST /api/payment/initiate
```

#### **B. Payment Status Check API**
```
GET /api/payment/status/{transactionId}
```

#### **C. Payment Callback/Webhook API**
```
POST /api/payment/callback
```

#### **D. Gold Price API**
```
GET /api/gold/prices
```

### **1.2 Server Requirements**

- **SSL Certificate**: HTTPS required for payment gateway
- **Domain**: Registered domain (not IP address)
- **Server**: Linux/Windows with PHP/Node.js/Python
- **Database**: MySQL/PostgreSQL for transaction storage
- **Firewall**: Allow Omniware IPs for callbacks

## 🔧 **Phase 2: Omniware Integration Setup**

### **2.1 Information Required by Omniware Team**

#### **Website/App Details:**
- **App Name**: Gold Trading App
- **Package Name**: `com.vmurugan.goldtrading`
- **Website URL**: `https://yourdomain.com`
- **App Store URL**: `https://play.google.com/store/apps/details?id=com.vmurugan.goldtrading`

#### **Technical URLs:**
- **Success URL**: `https://yourdomain.com/payment/success`
- **Failure URL**: `https://yourdomain.com/payment/failure`
- **Callback URL**: `https://yourdomain.com/api/payment/callback`

#### **Business Information:**
- **Business Name**: V Murugan Gold Trading
- **Business Type**: Gold Trading/Investment
- **Contact Email**: your-business@email.com
- **Contact Phone**: +91-XXXXXXXXXX

### **2.2 Test Credentials Setup**

For testing phase, you'll receive:
- **Merchant ID**: TEST_MERCHANT_ID
- **Secret Key**: TEST_SECRET_KEY
- **API Key**: TEST_API_KEY

## 📱 **Phase 3: Play Store Preparation**

### **3.1 App Store Requirements**

#### **A. App Information**
- **App Title**: "Gold Trading - Investment App"
- **Short Description**: "Secure gold trading and investment platform"
- **Full Description**: Detailed app features and benefits
- **Category**: Finance
- **Content Rating**: Everyone

#### **B. Required Assets**
- **App Icon**: 512x512 PNG
- **Feature Graphic**: 1024x500 PNG
- **Screenshots**: 8 screenshots (phone + tablet)
- **Privacy Policy URL**: Required for finance apps

#### **C. App Bundle Requirements**
- **Target SDK**: Android 14 (API 34)
- **Min SDK**: Android 6.0 (API 23)
- **App Bundle**: AAB format (not APK)
- **Signing**: App signing by Google Play

### **3.2 Compliance Requirements**

#### **Financial App Requirements:**
- **Privacy Policy**: Mandatory
- **Terms of Service**: Required
- **Data Safety**: Detailed data usage disclosure
- **Permissions**: Justify all permissions used

## 🌐 **Phase 4: Server API Implementation**

### **4.1 Payment Initiation API**

```php
<?php
// /api/payment/initiate
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$input = json_decode(file_get_contents('php://input'), true);

$merchantId = 'YOUR_MERCHANT_ID';
$secretKey = 'YOUR_SECRET_KEY';
$amount = $input['amount'];
$orderId = 'ORD_' . time();

// Generate hash
$hashString = $merchantId . '|' . $orderId . '|' . $amount . '|' . $secretKey;
$hash = hash('sha256', $hashString);

$response = [
    'status' => 'success',
    'merchantId' => $merchantId,
    'orderId' => $orderId,
    'amount' => $amount,
    'hash' => $hash,
    'paymentUrl' => 'https://sandbox.omniware.in/payment/initiate'
];

echo json_encode($response);
?>
```

### **4.2 Payment Callback API**

```php
<?php
// /api/payment/callback
$input = json_decode(file_get_contents('php://input'), true);

$orderId = $input['orderId'];
$status = $input['status'];
$transactionId = $input['transactionId'];
$amount = $input['amount'];

// Verify hash
$receivedHash = $input['hash'];
$calculatedHash = hash('sha256', $orderId . '|' . $status . '|' . $amount . '|' . $secretKey);

if ($receivedHash === $calculatedHash) {
    // Update database
    updatePaymentStatus($orderId, $status, $transactionId);
    
    // Send response
    echo json_encode(['status' => 'success']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid hash']);
}
?>
```

## 🔐 **Phase 5: Security Configuration**

### **5.1 SSL Certificate**
- Install SSL certificate on your domain
- Ensure all APIs are accessible via HTTPS
- Test SSL configuration

### **5.2 Firewall Configuration**
```bash
# Allow Omniware IPs (get actual IPs from Omniware team)
sudo ufw allow from 203.192.XXX.XXX
sudo ufw allow from 203.192.XXX.XXX
```

### **5.3 Environment Variables**
```env
# .env file
OMNIWARE_MERCHANT_ID=your_merchant_id
OMNIWARE_SECRET_KEY=your_secret_key
OMNIWARE_API_KEY=your_api_key
OMNIWARE_ENVIRONMENT=test  # or 'live'
```

## 📋 **Phase 6: Testing Checklist**

### **6.1 Server Testing**
- [ ] All APIs accessible via HTTPS
- [ ] Payment initiation working
- [ ] Callback receiving data
- [ ] Hash verification working
- [ ] Database updates successful

### **6.2 App Testing**
- [ ] Payment flow complete
- [ ] UPI payments working
- [ ] Error handling proper
- [ ] Success/failure redirects
- [ ] Transaction history updated

### **6.3 Integration Testing**
- [ ] End-to-end payment flow
- [ ] Multiple payment methods
- [ ] Edge cases handled
- [ ] Performance testing
- [ ] Security testing

## 🚀 **Phase 7: Go-Live Process**

### **7.1 Pre-Launch**
1. Complete testing with Omniware team
2. Get live credentials from Omniware
3. Update app configuration
4. Submit app to Play Store
5. Prepare marketing materials

### **7.2 Launch**
1. Switch to live environment
2. Monitor transactions
3. Customer support ready
4. Marketing campaign launch
5. Performance monitoring

## 📞 **Support & Contacts**

### **Omniware Support**
- **Email**: support@omniware.in
- **Phone**: +91-XXXXXXXXXX
- **Documentation**: https://omniware.in/developer.html

### **Play Store Support**
- **Developer Console**: https://play.google.com/console
- **Support**: Google Play Developer Support

## 📚 **Additional Resources**

- [Omniware API Documentation](https://omniware.in/developer.html)
- [Google Play Console Guide](https://developer.android.com/distribute/console)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Firebase Setup Guide](https://firebase.google.com/docs/android/setup)

---

**Next Steps**: Follow Phase 1 to set up your server APIs, then contact Omniware team with the required information.
