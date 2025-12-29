# ✅ DEPLOYMENT CHECKLIST - WHAT'S REQUIRED NOW

## 🎯 IMMEDIATE ACTIONS REQUIRED

---

## **STEP 1: CREATE DATABASE TABLES** (5 minutes)

### **Run these SQL scripts:**

```bash
# 1. Create audit log table
sqlcmd -S DESKTOP-3QPE6QQ -d VMuruganGoldTrading \
  -i sql_server_api/CREATE_AUDIT_LOG_TABLE.sql

# 2. Create metal rates table
sqlcmd -S DESKTOP-3QPE6QQ -d VMuruganGoldTrading \
  -i sql_server_api/CREATE_METAL_RATES_TABLE.sql

# DO NOT create CREATE_OTP_TABLE.sql (Firebase handles OTP)
```

**Verify tables created:**
```sql
-- Check if tables exist
SELECT name FROM sys.tables WHERE name IN ('audit_log', 'metal_rates');

-- Should show:
-- audit_log
-- metal_rates
```

---

## **STEP 2: UPDATE .ENV FILE** (5 minutes)

### **Add/Update these settings:**

```env
# ========================================
# SECURITY SETTINGS
# ========================================

# JWT Secrets (generate 64-character random strings)
JWT_SECRET=your_64_character_random_secret_here_change_this_in_production
ADMIN_TOKEN=your_64_character_admin_token_here_change_this_in_production

# Admin Credentials
ADMIN_PASSWORD=YourSecurePassword123!

# ========================================
# PAYMENT SECURITY (DISABLE FOR NOW)
# ========================================

# Disable payment security until Flutter app is updated
ENABLE_PAYMENT_IP_WHITELIST=false
ENABLE_PAYMENT_SIGNATURE_VERIFICATION=false
ENABLE_GATEWAY_VERIFICATION=false

# Payment Gateway IPs (configure later)
PAYMENT_GATEWAY_IPS=127.0.0.1

# Payment Signature Secret (configure later)
PAYMENT_SIGNATURE_SECRET=your_payment_secret_here

# ========================================
# WORLDLINE PAYMENT GATEWAY
# ========================================
WORLDLINE_MERCHANT_ID=your_merchant_id
WORLDLINE_SECRET_KEY=your_secret_key
WORLDLINE_API_KEY=your_api_key
WORLDLINE_API_URL=https://api.worldline.com

# ========================================
# OMNIWARE PAYMENT GATEWAY
# ========================================
OMNIWARE_MERCHANT_ID=your_merchant_id
OMNIWARE_SECRET_KEY=your_secret_key
OMNIWARE_API_KEY=your_api_key
OMNIWARE_API_URL=https://api.omniware.com

# ========================================
# CORS & SECURITY
# ========================================
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# HMAC Validation (disable for now)
ENABLE_HMAC_VALIDATION=false

# ========================================
# ENVIRONMENT
# ========================================
NODE_ENV=development
```

**Generate secrets:**
```bash
# Generate JWT_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate ADMIN_TOKEN
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate PAYMENT_SIGNATURE_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## **STEP 3: RESTART SERVER** (1 minute)

```bash
cd sql_server_api
npm start
```

**Expected output:**
```
✅ Database connected successfully
✅ Firebase Admin initialized successfully
🚀 Server running on port 3001
```

**If errors:**
- Check database connection
- Check Firebase credentials
- Check .env file syntax

---

## **STEP 4: TEST BACKEND** (10 minutes)

### **Test 1: Admin Login**
```bash
curl -X POST http://localhost:3001/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YourSecurePassword123!"}'

# Expected: {"success":true,"token":"...","expiresIn":"24h"}
```

### **Test 2: Customer OTP (Firebase)**
```bash
# This just logs the request (Firebase handles actual OTP)
curl -X POST http://localhost:3001/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210"}'

# Expected: {"success":true,"message":"OTP will be sent via SMS"}
```

### **Test 3: MPIN Complexity**
```bash
# Get customer token first (use Firebase OTP flow)
# Then test weak MPIN rejection

curl -X POST http://localhost:3001/api/customers/9876543210/set-mpin \
  -H "Authorization: Bearer YOUR_CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_mpin":"1234"}'

# Expected: {"success":false,"error":"MPIN too weak..."}
```

### **Test 4: Investment (Server Calculation)**
```bash
curl -X POST http://localhost:3001/api/schemes/SCHEME123/invest \
  -H "Authorization: Bearer YOUR_CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":1000,"transaction_id":"TXN123"}'

# Expected: Server calculates metal_grams and current_rate
# Response includes: {"investment":{"metal_grams":...,"current_rate":...}}
```

---

## **STEP 5: UPDATE FLUTTER APP** (CRITICAL - 2-3 hours)

### **File 1: lib/services/scheme_service.dart**

**REMOVE these parameters from investment functions:**

```dart
// BEFORE:
Future<Map<String, dynamic>> investInScheme({
  required String schemeId,
  required double amount,
  required double metalGrams,      // ← REMOVE THIS
  required double currentRate,     // ← REMOVE THIS
  required String transactionId,
}) async {
  // ...
  body: jsonEncode({
    'amount': amount,
    'metal_grams': metalGrams,    // ← REMOVE THIS
    'current_rate': currentRate,  // ← REMOVE THIS
    'transaction_id': transactionId,
  }),
}

// AFTER:
Future<Map<String, dynamic>> investInScheme({
  required String schemeId,
  required double amount,
  // REMOVED: metalGrams
  // REMOVED: currentRate
  required String transactionId,
}) async {
  // ...
  body: jsonEncode({
    'amount': amount,
    'transaction_id': transactionId,
    // Server will calculate metal_grams and current_rate
  }),
  
  // Get server-calculated values from response
  final data = jsonDecode(response.body);
  if (data['success']) {
    final metalGrams = data['investment']['metal_grams'];
    final currentRate = data['investment']['current_rate'];
    print('Server calculated: $metalGrams grams at ₹$currentRate/gram');
  }
  return data;
}
```

**Apply same changes to:**
- `investInScheme()`
- `flexiPayment()`
- Any other function that sends metal_grams/current_rate

---

### **File 2: lib/screens/investment_screen.dart**

**Update UI to show server-calculated values:**

```dart
// BEFORE:
final metalGrams = amount / currentRate;  // Client calculated

// AFTER:
// Don't calculate on client
// Get from server response after investment
final response = await investInScheme(
  schemeId: schemeId,
  amount: amount,
  transactionId: txnId,
);

if (response['success']) {
  final metalGrams = response['investment']['metal_grams'];
  final currentRate = response['investment']['current_rate'];
  
  // Show to user
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Investment Successful'),
      content: Text(
        'Amount: ₹$amount\n'
        'Metal Grams: $metalGrams\n'
        'Rate: ₹$currentRate/gram'
      ),
    ),
  );
}
```

---

### **File 3: lib/screens/mpin_screen.dart**

**Add MPIN strength validation:**

```dart
// Add MPIN validation
String? validateMPIN(String mpin) {
  // Check length
  if (mpin.length != 4) {
    return 'MPIN must be 4 digits';
  }
  
  // Check weak MPINs
  final weakMPINs = [
    '0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999',
    '1234', '4321', '0123', '3210', '2580', '1357', '2468', '9876', '5678', '8765'
  ];
  
  if (weakMPINs.contains(mpin)) {
    return 'MPIN too weak. Avoid sequential or repeated digits.';
  }
  
  // Check all same digits
  if (RegExp(r'^(\d)\1{3}$').hasMatch(mpin)) {
    return 'MPIN cannot have all same digits';
  }
  
  return null; // Valid
}

// Use in TextField
TextField(
  onChanged: (value) {
    setState(() {
      mpinError = validateMPIN(value);
    });
  },
  decoration: InputDecoration(
    errorText: mpinError,
  ),
)
```

---

### **File 4: Handle API Errors**

**Update error handling for new error messages:**

```dart
try {
  final response = await apiCall();
  
  if (!response['success']) {
    final error = response['error'] ?? response['message'];
    
    // Handle specific errors
    if (error.contains('MPIN too weak')) {
      showError('Please choose a stronger MPIN');
    } else if (error.contains('Too many attempts')) {
      showError('Too many attempts. Please try again later.');
    } else if (error.contains('Transaction already used')) {
      showError('This payment has already been processed');
    } else {
      showError(error);
    }
  }
} catch (e) {
  showError('Network error: $e');
}
```

---

## **STEP 6: TEST FLUTTER APP** (30 minutes)

### **Test Scenarios:**

1. **Investment Flow**
   - Make investment
   - Verify server calculates metal_grams
   - Verify correct rate used
   - Check response shows calculated values

2. **MPIN Setting**
   - Try weak MPIN (1234) → Should fail
   - Try strong MPIN (7294) → Should succeed
   - Try 4 times → Should rate limit

3. **Payment Flow**
   - Initiate payment
   - Complete payment
   - Verify callback works
   - Verify scheme created

4. **Authentication**
   - Firebase OTP flow
   - JWT token received
   - Token works for API calls

---

## **STEP 7: ENABLE PAYMENT SECURITY** (After app update)

### **Once Flutter app is deployed and users updated:**

```env
# Update .env
ENABLE_PAYMENT_IP_WHITELIST=true
ENABLE_PAYMENT_SIGNATURE_VERIFICATION=true
ENABLE_GATEWAY_VERIFICATION=true

# Add real payment gateway IPs
PAYMENT_GATEWAY_IPS=203.192.241.0,203.192.241.1,203.192.241.2

# Add real secrets
PAYMENT_SIGNATURE_SECRET=your_real_secret_from_gateway
WORLDLINE_SECRET_KEY=your_real_worldline_key
OMNIWARE_SECRET_KEY=your_real_omniware_key
```

**Restart server:**
```bash
npm restart
```

---

## **STEP 8: MONITOR & VERIFY** (Ongoing)

### **Check Audit Logs:**
```sql
-- View recent audit logs
SELECT TOP 100 * FROM audit_log 
ORDER BY timestamp DESC;

-- Check for security issues
SELECT * FROM audit_log 
WHERE action LIKE '%FAIL%' OR action LIKE '%ERROR%'
ORDER BY timestamp DESC;
```

### **Check Metal Rates:**
```sql
-- View current rates
SELECT * FROM metal_rates 
WHERE is_active = 1
ORDER BY updated_at DESC;

-- Verify rates are being updated
SELECT metal_type, rate, source, updated_at 
FROM metal_rates 
ORDER BY updated_at DESC;
```

### **Monitor Server Logs:**
```bash
# Check for errors
tail -f sql_server_api/logs/server_*.log

# Check security logs
tail -f sql_server_api/logs/security_*.log
```

---

## 📋 COMPLETE CHECKLIST

### **Backend (Now)**
- [ ] Create audit_log table
- [ ] Create metal_rates table
- [ ] Update .env file
- [ ] Generate JWT secrets
- [ ] Disable payment security (temporary)
- [ ] Restart server
- [ ] Test admin login
- [ ] Test MPIN complexity
- [ ] Test investment calculation

### **Flutter App (Next)**
- [ ] Remove metal_grams from investment requests
- [ ] Remove current_rate from investment requests
- [ ] Get values from server response
- [ ] Add MPIN strength validation
- [ ] Update error handling
- [ ] Test all flows
- [ ] Deploy to Play Store/App Store

### **Production (After App Update)**
- [ ] Enable payment IP whitelist
- [ ] Enable payment signature verification
- [ ] Configure real payment gateway IPs
- [ ] Add real payment secrets
- [ ] Test payment callbacks
- [ ] Monitor audit logs
- [ ] Force minimum app version

---

## ⏱️ TIME ESTIMATES

| Task | Time | Priority |
|------|------|----------|
| Create database tables | 5 min | 🔴 NOW |
| Update .env | 5 min | 🔴 NOW |
| Restart server | 1 min | 🔴 NOW |
| Test backend | 10 min | 🔴 NOW |
| Update Flutter app | 2-3 hours | 🟡 URGENT |
| Test Flutter app | 30 min | 🟡 URGENT |
| Deploy app | 1-2 days | 🟡 URGENT |
| Enable payment security | 10 min | 🟢 LATER |

**Total Time:** ~1 week (including app deployment)

---

## 🎯 PRIORITY ORDER

**TODAY:**
1. ✅ Create database tables
2. ✅ Update .env
3. ✅ Restart server
4. ✅ Test backend

**THIS WEEK:**
5. ⚠️ Update Flutter app
6. ⚠️ Test thoroughly
7. ⚠️ Deploy to stores

**NEXT WEEK:**
8. ⚠️ Wait for user updates
9. ⚠️ Enable payment security
10. ✅ Monitor and verify

---

**Start with Step 1 (Database Tables) NOW!** 🚀
