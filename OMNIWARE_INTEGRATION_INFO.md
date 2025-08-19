# 🏦 Omniware Payment Gateway Integration - Complete Information

## 📋 **Information for Omniware Team**

### **1. App & Website Details**

#### **Application Information**
- **App Name**: Gold Trading - Investment Platform
- **Package Name**: `com.vmurugan.goldtrading`
- **App Version**: 1.0.0
- **Platform**: Android (Flutter)
- **Target Audience**: Adults (18+)

#### **Website & URLs**
- **Website URL**: `https://yourdomain.com` *(Replace with your actual domain)*
- **App Store URL**: `https://play.google.com/store/apps/details?id=com.vmurugan.goldtrading`
- **Privacy Policy**: `https://yourdomain.com/privacy-policy`
- **Terms of Service**: `https://yourdomain.com/terms-of-service`

#### **Business Information**
- **Business Name**: V Murugan Gold Trading
- **Business Type**: Digital Gold Trading & Investment Platform
- **Industry**: Financial Services - Gold Trading
- **Contact Email**: business@yourdomain.com *(Replace with actual email)*
- **Contact Phone**: +91-XXXXXXXXXX *(Replace with actual number)*
- **Business Address**: [Your complete business address]

### **2. Technical Integration URLs**

#### **Payment Flow URLs**
- **Payment Success URL**: `https://yourdomain.com/payment/success`
- **Payment Failure URL**: `https://yourdomain.com/payment/failure`
- **Payment Cancel URL**: `https://yourdomain.com/payment/cancel`

#### **API Endpoints (Your Server)**
- **Payment Initiation**: `https://yourdomain.com/api/payment/initiate`
- **Payment Callback**: `https://yourdomain.com/api/payment/callback`
- **Payment Status**: `https://yourdomain.com/api/payment/status/{orderId}`
- **Transaction Verification**: `https://yourdomain.com/api/payment/verify`

### **3. Test Credentials & Demo Access**

#### **App Testing**
- **APK Download**: Available upon request
- **Test User Phone**: +91-9876543210
- **Test MPIN**: 1234
- **Test Amount Range**: ₹100 - ₹10,000

#### **Demo Scenarios**
1. **Gold Purchase Flow**:
   - Login with test credentials
   - Navigate to "Buy Gold"
   - Select amount (₹500 recommended)
   - Choose payment method
   - Complete payment flow

2. **Payment Methods Available**:
   - Net Banking (via Omniware)
   - UPI (Google Pay, PhonePe)
   - UPI QR Code
   - Generic UPI Apps

### **4. Technical Specifications**

#### **App Architecture**
- **Frontend**: Flutter (Dart)
- **Backend**: PHP/Node.js (Your choice)
- **Database**: MySQL/PostgreSQL
- **Authentication**: Firebase Auth + MPIN
- **Payment Gateway**: Omniware Integration

#### **Security Features**
- **Encryption**: SHA256 hash verification
- **Authentication**: Multi-factor (Phone + MPIN)
- **Data Protection**: Firebase security rules
- **Payment Security**: PCI DSS compliant via Omniware

#### **Integration Method**
- **Type**: Server-to-Server + Mobile SDK
- **Hash Algorithm**: SHA256
- **Response Format**: JSON
- **Callback Method**: HTTP POST webhook

## 🔧 **Server Setup Requirements**

### **5. APIs You Need to Implement**

#### **A. Payment Initiation API**
```
Endpoint: POST /api/payment/initiate
Purpose: Initialize payment with Omniware
Required: SSL certificate, domain verification
```

#### **B. Payment Callback API**
```
Endpoint: POST /api/payment/callback
Purpose: Receive payment status from Omniware
Required: Hash verification, database updates
```

#### **C. Payment Status API**
```
Endpoint: GET /api/payment/status/{orderId}
Purpose: Check payment status for app
Required: Order validation, status response
```

### **6. Server Requirements**

#### **Infrastructure**
- **SSL Certificate**: Mandatory (HTTPS only)
- **Domain**: Registered domain (not IP address)
- **Server**: Linux/Windows with web server
- **Database**: MySQL/PostgreSQL for transactions
- **PHP/Node.js**: For API development

#### **Security**
- **Firewall**: Allow Omniware callback IPs
- **Hash Verification**: SHA256 implementation
- **Data Encryption**: Sensitive data protection
- **Access Logs**: Transaction logging

## 📱 **Play Store Publishing**

### **7. App Store Information**

#### **Store Listing**
- **Category**: Finance
- **Content Rating**: Everyone
- **Target SDK**: Android 14 (API 34)
- **Min SDK**: Android 6.0 (API 23)

#### **Required Documents**
- **Privacy Policy**: Comprehensive data usage policy
- **Terms of Service**: User agreement and T&C
- **Data Safety**: Google Play data disclosure
- **Content Rating**: Age-appropriate content certification

### **8. Compliance Requirements**

#### **Financial App Compliance**
- **RBI Guidelines**: Digital payment compliance
- **PCI DSS**: Payment card industry standards
- **KYC/AML**: Customer verification requirements
- **GST**: Tax compliance for gold trading

#### **Google Play Policies**
- **Financial Services Policy**: Compliance required
- **User Data Policy**: Privacy and data protection
- **Restricted Content**: Financial app guidelines
- **Developer Policy**: Google Play developer terms

## 🚀 **Next Steps**

### **9. Immediate Actions Required**

#### **For You (App Developer)**
1. **Set up domain and hosting** with SSL certificate
2. **Implement server APIs** using provided templates
3. **Create privacy policy and terms** of service
4. **Prepare Play Store assets** (screenshots, descriptions)
5. **Test app thoroughly** with all payment flows

#### **For Omniware Team**
1. **Review provided information** and app details
2. **Provide test credentials** for integration testing
3. **Whitelist your domain** and callback URLs
4. **Share API documentation** and integration guide
5. **Schedule integration testing** session

### **10. Timeline**

#### **Phase 1: Server Setup (1-2 weeks)**
- Domain and hosting setup
- API development and testing
- SSL certificate installation
- Database schema implementation

#### **Phase 2: Integration Testing (1 week)**
- Omniware test credentials
- End-to-end payment testing
- Error handling verification
- Security testing

#### **Phase 3: Play Store Submission (1 week)**
- App bundle preparation
- Store listing completion
- Policy compliance verification
- Submission and review

#### **Phase 4: Go Live (1 week)**
- Live credentials from Omniware
- Production deployment
- Final testing and monitoring
- Launch and marketing

## 📞 **Contact Information**

### **Development Team**
- **Technical Lead**: [Your name and contact]
- **Project Manager**: [PM contact details]
- **Business Owner**: [Business contact]

### **For Omniware Team**
- **Primary Contact**: [Your business email]
- **Technical Contact**: [Your technical email]
- **Phone**: [Your business phone]
- **Preferred Communication**: Email/WhatsApp/Phone

---

**Note**: Replace all placeholder information (yourdomain.com, contact details, etc.) with your actual business information before sharing with Omniware team.

**Files Included**:
- Complete deployment guide (`docs/DEPLOYMENT_GUIDE.md`)
- Server API templates (`server_apis/`)
- Database schema (`server_apis/database_schema.sql`)
- Play Store guide (`docs/PLAY_STORE_GUIDE.md`)
- Working APK with all features integrated
