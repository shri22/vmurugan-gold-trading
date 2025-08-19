# 📱 Play Store Publishing Guide - Gold Trading App

## 🎯 **Pre-Publishing Checklist**

### **1. App Bundle Preparation**

#### **Build Release APK/AAB**
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK if needed
flutter build apk --release
```

#### **App Signing**
- **Option 1**: Let Google Play manage signing (recommended)
- **Option 2**: Upload your own signing key

### **2. Required Information for Omniware Team**

#### **📋 Complete Details to Share:**

**App Information:**
- **App Name**: Gold Trading - Investment Platform
- **Package Name**: `com.vmurugan.goldtrading`
- **Version**: 1.0.0 (1)
- **Target Audience**: Adults (18+)

**URLs Required:**
- **Website URL**: `https://yourdomain.com`
- **Privacy Policy**: `https://yourdomain.com/privacy-policy`
- **Terms of Service**: `https://yourdomain.com/terms-of-service`
- **App Store URL**: `https://play.google.com/store/apps/details?id=com.vmurugan.goldtrading`

**Technical URLs:**
- **Payment Success URL**: `https://yourdomain.com/payment/success`
- **Payment Failure URL**: `https://yourdomain.com/payment/failure`
- **Payment Callback URL**: `https://yourdomain.com/api/payment/callback`
- **Payment Status API**: `https://yourdomain.com/api/payment/status/{orderId}`

**Business Information:**
- **Business Name**: V Murugan Gold Trading
- **Business Type**: Gold Trading & Investment Platform
- **Business Registration**: [Your registration number]
- **Contact Email**: business@yourdomain.com
- **Contact Phone**: +91-XXXXXXXXXX
- **Business Address**: [Complete business address]

**Test Credentials:**
- **Test User Phone**: +91-9876543210
- **Test MPIN**: 1234
- **Test Amount Range**: ₹100 - ₹10,000

## 🏪 **Play Store Console Setup**

### **3. App Information**

#### **App Details**
```
App Name: Gold Trading - Investment Platform
Short Description: Secure digital gold investment platform with real-time prices
Full Description: 
Invest in digital gold with our secure and user-friendly platform. 
Features:
• Real-time gold prices from MJDTA Chennai
• Secure payment gateway integration
• UPI payments (Google Pay, PhonePe)
• Portfolio tracking and management
• Instant buy/sell transactions
• Firebase-powered security
• 24/7 customer support

Category: Finance
Tags: gold, investment, trading, finance, UPI, payments
```

#### **Content Rating**
- **Target Age Group**: Adults (18+)
- **Content Rating**: Everyone
- **Questionnaire**: Answer all questions honestly

### **4. Store Listing Assets**

#### **Required Graphics**
1. **App Icon**: 512x512 PNG (high-res)
2. **Feature Graphic**: 1024x500 PNG
3. **Phone Screenshots**: 8 screenshots minimum
4. **Tablet Screenshots**: 8 screenshots (if supporting tablets)

#### **Screenshot Requirements**
- **Resolution**: 1080x1920 (portrait) or 1920x1080 (landscape)
- **Format**: PNG or JPEG
- **Content**: Show key app features

**Suggested Screenshots:**
1. Login/Registration screen
2. Dashboard with gold prices
3. Buy gold screen
4. Payment options screen
5. Portfolio/holdings screen
6. Transaction history
7. Profile/settings screen
8. Payment success screen

### **5. App Content & Compliance**

#### **Privacy Policy (Required)**
Must include:
- Data collection practices
- How user data is used
- Third-party integrations (Firebase, Omniware)
- User rights and controls
- Contact information

#### **Data Safety Section**
Declare:
- **Personal Info**: Name, email, phone
- **Financial Info**: Payment information, purchase history
- **App Activity**: App interactions, in-app search history
- **Device Info**: Device identifiers

#### **Permissions Justification**
- **INTERNET**: For API calls and payments
- **ACCESS_NETWORK_STATE**: Check network connectivity
- **CAMERA**: For QR code scanning (UPI payments)
- **READ_PHONE_STATE**: For device identification
- **RECEIVE_SMS**: For OTP verification

### **6. Release Management**

#### **Internal Testing**
1. Upload AAB to internal testing
2. Add test users (up to 100)
3. Test all features thoroughly
4. Fix any issues found

#### **Closed Testing (Alpha/Beta)**
1. Create closed testing track
2. Add external testers
3. Gather feedback
4. Iterate based on feedback

#### **Production Release**
1. Complete all compliance requirements
2. Upload final AAB
3. Set rollout percentage (start with 5-10%)
4. Monitor crash reports and reviews

## 🔐 **Security & Compliance**

### **7. Financial App Requirements**

#### **Google Play Requirements for Finance Apps**
- **Privacy Policy**: Mandatory and comprehensive
- **Secure Authentication**: Implemented (Firebase Auth + MPIN)
- **Data Encryption**: All sensitive data encrypted
- **PCI Compliance**: Payment gateway handles this
- **Regular Security Updates**: Commit to regular updates

#### **Indian Regulations**
- **RBI Guidelines**: Ensure compliance with digital payment norms
- **GST Compliance**: For gold trading transactions
- **KYC Requirements**: Implement user verification
- **AML Compliance**: Anti-money laundering measures

### **8. Testing Checklist**

#### **Functional Testing**
- [ ] User registration/login works
- [ ] Gold price updates correctly
- [ ] Buy gold flow complete
- [ ] Payment integration working
- [ ] UPI payments functional
- [ ] Portfolio updates correctly
- [ ] Notifications working
- [ ] Error handling proper

#### **Security Testing**
- [ ] MPIN encryption secure
- [ ] API calls use HTTPS
- [ ] Payment data not stored locally
- [ ] Session management secure
- [ ] Input validation working

#### **Performance Testing**
- [ ] App loads quickly
- [ ] Smooth navigation
- [ ] No memory leaks
- [ ] Battery usage optimized
- [ ] Network usage efficient

## 🚀 **Launch Strategy**

### **9. Pre-Launch**
1. **Soft Launch**: Release to limited users
2. **Marketing Preparation**: Social media, website ready
3. **Customer Support**: Support team trained
4. **Monitoring Setup**: Analytics and crash reporting

### **10. Launch Day**
1. **Release to Production**: 100% rollout
2. **Monitor Metrics**: Downloads, crashes, reviews
3. **Customer Support**: Be ready for user queries
4. **Marketing Push**: Announce launch

### **11. Post-Launch**
1. **Monitor Reviews**: Respond to user feedback
2. **Track Metrics**: User engagement, retention
3. **Bug Fixes**: Quick response to issues
4. **Feature Updates**: Regular improvements

## 📞 **Support Contacts**

### **Google Play Console Support**
- **Help Center**: https://support.google.com/googleplay/android-developer
- **Policy Support**: For policy-related questions
- **Technical Support**: For console issues

### **Omniware Integration Support**
- **Technical Team**: For payment gateway issues
- **Account Manager**: For business queries
- **Documentation**: API integration guides

## 📋 **Final Checklist Before Submission**

- [ ] App tested thoroughly on multiple devices
- [ ] All store listing assets ready
- [ ] Privacy policy and terms published
- [ ] Payment gateway integration tested
- [ ] Omniware team provided all required information
- [ ] App bundle signed and uploaded
- [ ] Content rating completed
- [ ] Data safety section filled
- [ ] Release notes written
- [ ] Marketing materials ready

---

**Next Steps**: 
1. Set up your domain and server APIs
2. Contact Omniware team with the provided information
3. Complete Play Store listing preparation
4. Submit for review
