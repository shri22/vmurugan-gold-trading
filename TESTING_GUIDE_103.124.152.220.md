# 🧪 VMurugan Gold Trading - Testing Guide
## Server IP: 103.124.152.220

---

## 🎯 **QUICK TEST - Start Here**

### **1. Basic Server Health Check**
Open your browser and visit:
```
http://103.124.152.220:3000/health
```
**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-27T...",
  "server": "VMurugan Client Server",
  "sql_api": "http://localhost:3001"
}
```

### **2. SQL Server API Health Check**
```
http://103.124.152.220:3001/health
```
**Expected Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-01-27T...",
  "service": "VMurugan SQL Server API",
  "database": "VMuruganGoldTrading",
  "server": "localhost"
}
```

---

## 🌐 **WEB DASHBOARD TESTING**

### **Step 1: Open Testing Dashboard**
1. Open `test_server_apis.html` in your browser
2. The IP should be pre-filled: `103.124.152.220`
3. Port should be: `3000`
4. Protocol: `HTTP`
5. Click **"Update Configuration"**

### **Step 2: Run All Tests**
Click these buttons in order:
1. ✅ **Test Server Health** - Should show green status
2. ✅ **Test CORS Headers** - Should work without errors
3. ✅ **Test User Registration** - Should create test user
4. ✅ **Test User Login** - Should authenticate successfully

---

## 💻 **COMMAND LINE TESTING**

### **Windows Command Prompt Tests:**

#### **Test 1: Server Health**
```cmd
curl http://103.124.152.220:3000/health
```

#### **Test 2: User Registration**
```cmd
curl -X POST http://103.124.152.220:3000/api/customers ^
  -H "Content-Type: application/json" ^
  -d "{\"phone\":\"9876543210\",\"name\":\"Test User\",\"email\":\"test@example.com\",\"address\":\"Test Address\",\"pan_card\":\"ABCDE1234F\",\"device_id\":\"test123\"}"
```

#### **Test 3: User Login**
```cmd
curl -X POST http://103.124.152.220:3000/api/login ^
  -H "Content-Type: application/json" ^
  -d "{\"phone\":\"9876543210\",\"encrypted_mpin\":\"1234\"}"
```

#### **Test 4: Payment Callback (Simulate Bank)**
```cmd
curl -X POST http://103.124.152.220:3000/api/payment/callback ^
  -H "Content-Type: application/json" ^
  -d "{\"orderId\":\"TEST123\",\"status\":\"success\",\"amount\":1000}"
```

---

## 📱 **MOBILE APP TESTING**

### **Step 1: Update App Configuration**
Your app is already configured with the correct IP. Verify in:
```dart
// lib/core/config/client_server_config.dart
static const String serverDomain = '103.124.152.220'; ✅
static const int serverPort = 3000; ✅
```

### **Step 2: Build and Install App**
```bash
# Build release APK
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### **Step 3: Test App Functions**
1. **Open App** → Should load VMurugan logo
2. **Register User** → Use phone: `9876543210`, name: `Test User`
3. **Login** → Use phone: `9876543210`, MPIN: `1234`
4. **Dashboard** → Should load without errors
5. **Gold Trading** → Test buy/sell operations
6. **Portfolio** → Should display user holdings

---

## 🔗 **DIRECT URL TESTING**

### **Payment URLs (For Bank Whitelisting):**
Test these URLs in your browser:

#### **1. Payment Success Page**
```
http://103.124.152.220:3000/payment/success
```
Should show: "✅ Payment Successful!"

#### **2. Payment Failure Page**
```
http://103.124.152.220:3000/payment/failure
```
Should show: "❌ Payment Failed!"

#### **3. Payment Cancel Page**
```
http://103.124.152.220:3000/payment/cancel
```
Should show: "⚠️ Payment Cancelled!"

---

## 🏦 **BANK INTEGRATION TESTING**

### **URLs to Provide to Bank:**
```
Callback URL:    http://103.124.152.220:3000/api/payment/callback
Success URL:     http://103.124.152.220:3000/payment/success
Failure URL:     http://103.124.152.220:3000/payment/failure
Cancel URL:      http://103.124.152.220:3000/payment/cancel
Status Check:    http://103.124.152.220:3000/api/payment/status/{orderId}
```

### **Test Payment Flow:**
1. **Initiate Payment:**
```cmd
curl -X POST http://103.124.152.220:3000/api/payment/initiate ^
  -H "Content-Type: application/json" ^
  -d "{\"amount\":1000,\"user_id\":\"9876543210\",\"transaction_id\":\"TXN_TEST_123\"}"
```

2. **Simulate Bank Callback:**
```cmd
curl -X POST http://103.124.152.220:3000/api/payment/callback ^
  -H "Content-Type: application/json" ^
  -d "{\"orderId\":\"TXN_TEST_123\",\"status\":\"success\",\"transactionId\":\"BANK_TXN_456\",\"amount\":1000}"
```

3. **Check Payment Status:**
```cmd
curl http://103.124.152.220:3000/api/payment/status/TXN_TEST_123
```

---

## 🌍 **NETWORK TESTING**

### **Test from Different Networks:**

#### **1. WiFi Network**
- Connect to WiFi
- Test app functionality
- Check API response times

#### **2. Mobile Data (4G/5G)**
- Switch to mobile data
- Test all app features
- Verify connectivity

#### **3. Different Locations**
- Test from different cities
- Check server accessibility
- Monitor performance

---

## 🔍 **TROUBLESHOOTING**

### **Common Issues & Solutions:**

#### **Issue 1: Connection Refused**
```
Error: Connection refused to 103.124.152.220:3000
```
**Solutions:**
1. Check if server is running
2. Verify firewall allows port 3000
3. Test from server machine first

#### **Issue 2: CORS Errors**
```
Error: CORS policy blocked
```
**Solutions:**
1. Check server CORS configuration
2. Verify allowed origins
3. Test with browser developer tools

#### **Issue 3: Database Connection Error**
```
Error: SQL Server connection failed
```
**Solutions:**
1. Check SQL Server is running
2. Verify database credentials
3. Test SQL Server API separately

#### **Issue 4: Payment Integration Issues**
```
Error: Payment callback not received
```
**Solutions:**
1. Check callback URL accessibility
2. Verify bank can reach your server
3. Test callback endpoint manually

---

## 📊 **PERFORMANCE TESTING**

### **Load Testing:**
```bash
# Test with multiple concurrent requests
for /L %i in (1,1,10) do curl http://103.124.152.220:3000/health
```

### **Response Time Testing:**
```bash
# Measure response time
curl -w "@curl-format.txt" -o /dev/null -s http://103.124.152.220:3000/health
```

---

## ✅ **SUCCESS CRITERIA**

Your system is working correctly when:

- ✅ **Server Health**: Returns 200 OK
- ✅ **User Registration**: Creates user successfully
- ✅ **User Login**: Authenticates correctly
- ✅ **Mobile App**: Connects without errors
- ✅ **Payment URLs**: All accessible
- ✅ **Database**: Stores data correctly
- ✅ **Performance**: Response time < 2 seconds

---

## 🚀 **NEXT STEPS AFTER TESTING**

### **If All Tests Pass:**
1. ✅ **Update Play Store listing** with your server details
2. ✅ **Provide bank URLs** for whitelisting
3. ✅ **Build release APK** for Play Store
4. ✅ **Submit app** for review
5. ✅ **Monitor performance** after launch

### **If Tests Fail:**
1. 🔧 **Check server status** on 103.124.152.220
2. 🔧 **Verify firewall settings** for ports 3000 and 3001
3. 🔧 **Test SQL Server connection** locally
4. 🔧 **Review server logs** for errors
5. 🔧 **Contact server administrator** if needed

---

## 📞 **SUPPORT**

### **For Testing Issues:**
- **Server IP**: 103.124.152.220
- **Client Server Port**: 3000
- **SQL Server API Port**: 3001
- **Database**: VMuruganGoldTrading

### **Quick Test Commands:**
```bash
# Test client server
curl http://103.124.152.220:3000/health

# Test SQL server API
curl http://103.124.152.220:3001/health

# Test payment callback
curl -X POST http://103.124.152.220:3000/api/payment/callback -H "Content-Type: application/json" -d "{\"orderId\":\"TEST\",\"status\":\"success\"}"
```

**🎯 Your VMurugan Gold Trading platform is ready for comprehensive testing! 🏆**
