# 🚀 VMUrugan Gold Trading - Deployment Guide

## 📋 Prerequisites

- Git installed
- Flutter SDK (3.0+)
- Firebase account
- Android Studio (for Android builds)

## 🔥 Firebase Configuration

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Create a project"
3. Project name: `vmurugan-gold-trading`
4. Enable Google Analytics
5. Click "Create project"

### 2. Enable Firestore
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode"
4. Select location: `asia-southeast1`

### 3. Get Configuration
1. Go to Project Settings (gear icon)
2. Scroll to "Your apps"
3. Click Web app icon `</>`
4. Register app: `VMUrugan Admin`
5. Copy the config object

### 4. Update App Configuration
Update `lib/core/config/firebase_config.dart`:
```dart
class FirebaseConfig {
  static const String projectId = 'your-project-id';
  static const String apiKey = 'your-api-key';
  static const String businessId = 'VMURUGAN_001';
}
```

### 5. Set Database Rules
Go to Firestore Database → Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## 📱 Mobile App Deployment

### Build APK
```bash
cd mobile/digi_gold
flutter clean
flutter pub get
flutter build apk --release
```

### APK Location
```
build/app/outputs/flutter-apk/app-release.apk
```

### Distribution
- Share APK directly for testing
- Upload to Google Play Store for production

## 🌐 Admin Portal Deployment

### Option 1: Local Hosting
1. Open `new_admin_portal.html` in web browser
2. Works immediately with Firebase connection

### Option 2: Web Server
1. Upload HTML files to web server
2. Configure HTTPS for security
3. Set up custom domain

### Option 3: Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

## 🔧 Environment Setup

### Development
- Use debug builds
- Enable Firebase test mode
- Use development API keys

### Production
- Use release builds
- Configure production Firebase rules
- Set up proper security

## 📊 Monitoring

### Firebase Console
- Monitor customer registrations
- Track app usage
- View error logs

### Admin Portal
- Real-time customer data
- Transaction monitoring
- Business analytics

## 🔒 Security Checklist

- [ ] Firebase rules configured
- [ ] API keys secured
- [ ] HTTPS enabled for admin portal
- [ ] App signing configured
- [ ] Data validation implemented

## 🎯 Testing

### Mobile App
1. Install APK on test device
2. Test customer registration
3. Verify data appears in admin portal
4. Test all core features

### Admin Portal
1. Open in web browser
2. Test Firebase connection
3. Verify customer data loading
4. Test refresh functionality

## 📞 Support

For deployment issues:
- Check Firebase console for errors
- Verify API keys and project IDs
- Test network connectivity
- Review app logs

---

**Deployment completed successfully!** 🎉
