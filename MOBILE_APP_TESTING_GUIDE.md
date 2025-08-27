# 📱 VMurugan Gold Trading - Node.js Server Testing Guide

## 🎯 **Testing Your Public IP Node.js Server**

Since your **Node.js server with public IP is working**, follow these steps to test the complete system:

---

## **STEP 1: Update App Configuration**

### 1.1 Update Server IP in App
```dart
// File: lib/core/config/client_server_config.dart
static const String serverDomain = 'YOUR_ACTUAL_PUBLIC_IP'; // Replace with your IP
```

**Example:**
```dart
static const String serverDomain = '203.192.123.45'; // Your actual public IP
```

### 1.2 Rebuild the App
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

---

## **STEP 2: Server API Testing**

### 2.1 Open API Testing Dashboard
1. Open `test_server_apis.html` in your browser
2. Enter your **public IP address**
3. Set port to **3000** (default Node.js port, or 3001 if configured)
4. Choose **HTTP** for testing, **HTTPS** for production

### 2.2 Test Server Health
1. Click **"Test Server Health"** 
2. Should return: `{"status": "OK", "message": "Server is running"}`
3. Green indicator = Server is online ✅

### 2.3 Test All APIs
Run these tests in order:
- ✅ **Server Health** - Basic connectivity
- ✅ **CORS Headers** - Cross-origin requests
- ✅ **User Registration** - Create test user
- ✅ **User Login** - Authenticate user
- ✅ **Portfolio Get** - Fetch user portfolio
- ✅ **Transaction Create** - Create gold purchase
- ✅ **Transaction History** - View transaction list

---

## **STEP 3: Mobile App Testing**

### 3.1 Install Updated APK
```bash
# Install on Android device/emulator
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 3.2 Test User Registration Flow
1. **Open App** → Should show VMurugan logo
2. **Register New User:**
   - Phone: `9876543210`
   - Name: `Test User`
   - Email: `test@example.com`
   - MPIN: `1234`
3. **Verify:** User created successfully

### 3.3 Test Login Flow
1. **Login with:**
   - Phone: `9876543210`
   - MPIN: `1234`
2. **Verify:** Redirected to dashboard

### 3.4 Test Gold Trading Features
1. **Dashboard:** Should load portfolio (empty initially)
2. **Buy Gold:**
   - Select gold type
   - Enter quantity (e.g., 1 gram)
   - Confirm purchase
3. **Portfolio:** Should show purchased gold
4. **Transaction History:** Should show purchase record

### 3.5 Test Payment Integration
1. **Make Purchase** → Should redirect to payment gateway
2. **Payment Success** → Should update portfolio
3. **Payment Failure** → Should show error message

---

## **STEP 4: Network Testing**

### 4.1 Test from Different Networks
- ✅ **WiFi Network** - Test app connectivity
- ✅ **Mobile Data** - Test 4G/5G connectivity
- ✅ **Different Locations** - Test from various places

### 4.2 Test Server Accessibility
```bash
# Test server from command line
curl -X GET http://YOUR_PUBLIC_IP:3001/health

# Expected response:
{"status":"OK","message":"Server is running"}
```

### 4.3 Test Node.js API Endpoints
```bash
# Test server health
curl -X GET http://YOUR_PUBLIC_IP:3000/health

# Test user registration
curl -X POST http://YOUR_PUBLIC_IP:3000/api/customers \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","name":"Test User","email":"test@example.com","address":"Test Address","pan_card":"ABCDE1234F","device_id":"test123","mpin":"1234"}'

# Test user login
curl -X POST http://YOUR_PUBLIC_IP:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","encrypted_mpin":"1234"}'
```

---

## **STEP 5: Performance Testing**

### 5.1 Load Testing
- Test with **multiple users** simultaneously
- Check **response times** under load
- Monitor **server resources** (CPU, memory)

### 5.2 Stress Testing
- Test with **high transaction volume**
- Verify **database performance**
- Check **error handling** under stress

---

## **STEP 6: Security Testing**

### 6.1 SSL/HTTPS Setup (Production)
```bash
# Install SSL certificate (Let's Encrypt)
sudo certbot --nginx -d yourdomain.com

# Update app config for HTTPS
static const String protocol = 'https';
```

### 6.2 Security Checklist
- ✅ **HTTPS enabled** (for production)
- ✅ **CORS configured** properly
- ✅ **Rate limiting** active
- ✅ **Input validation** working
- ✅ **SQL injection** protection
- ✅ **XSS protection** enabled

---

## **STEP 7: Production Deployment**

### 7.1 Domain Setup (Recommended)
```bash
# Instead of IP, use domain name
static const String serverDomain = 'api.vmurugan.com';
static const String protocol = 'https';
```

### 7.2 SSL Certificate
```bash
# Install SSL certificate
sudo certbot --nginx -d api.vmurugan.com
```

### 7.3 Firewall Configuration
```bash
# Allow only necessary ports
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 3001  # Your app port
sudo ufw enable
```

---

## **STEP 8: Monitoring & Maintenance**

### 8.1 Server Monitoring
- Monitor **server uptime**
- Check **API response times**
- Monitor **database performance**
- Track **error rates**

### 8.2 App Analytics
- Track **user registrations**
- Monitor **transaction success rates**
- Analyze **user behavior**
- Monitor **crash reports**

---

## **🚨 Troubleshooting Common Issues**

### Issue 1: App Can't Connect to Server
**Solution:**
1. Check if server is running: `curl http://YOUR_IP:3001/health`
2. Verify firewall allows port 3001
3. Check app configuration has correct IP
4. Test from same network first

### Issue 2: CORS Errors
**Solution:**
1. Update server CORS settings
2. Add your domain to allowed origins
3. Check preflight OPTIONS requests

### Issue 3: Database Connection Errors
**Solution:**
1. Verify MySQL is running
2. Check database credentials
3. Test database connection manually
4. Check database user permissions

### Issue 4: Payment Integration Issues
**Solution:**
1. Verify Omniware credentials
2. Check callback URLs
3. Test with Omniware sandbox first
4. Monitor payment logs

---

## **✅ Success Criteria**

Your system is ready for production when:

- ✅ **Server Health** returns 200 OK
- ✅ **All APIs** respond correctly
- ✅ **Mobile app** connects successfully
- ✅ **User registration** works end-to-end
- ✅ **Gold trading** flow completes
- ✅ **Payment integration** functional
- ✅ **Portfolio tracking** accurate
- ✅ **Transaction history** displays
- ✅ **SSL certificate** installed (production)
- ✅ **Performance** meets requirements

---

## **🎉 Next Steps After Testing**

1. **Play Store Submission** - Upload APK to Google Play Console
2. **Marketing Launch** - Promote your gold trading platform
3. **User Onboarding** - Guide first customers through registration
4. **Customer Support** - Set up support channels
5. **Business Growth** - Scale based on user feedback

**Your VMurugan Gold Trading Platform is ready for business! 🏆**
