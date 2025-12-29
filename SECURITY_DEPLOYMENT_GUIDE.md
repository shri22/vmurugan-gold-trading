# Security Fixes Deployment Guide

## 📋 Overview

This guide walks you through deploying all 7 security fixes to your production environment.

---

## 🚀 Quick Start (Development)

### 1. Install Dependencies

```bash
cd sql_server_api
npm install
```

### 2. Create Environment File

```bash
cp .env.example .env
```

### 3. Edit `.env` File

Open `.env` and configure the following critical values:

```env
# Admin Credentials (CHANGE THESE!)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=YourSecurePassword123!

# JWT Secret (Use generated value below)
JWT_SECRET=e8a0632356c25703bd547ea1f5418eb38476027cc7de85cff02a1fc629e1c67c

# HMAC Secret (Use generated value below)
HMAC_SECRET=85cde316852ca6ab188dd7a7e3968e2df07a4c5f73e9c38e7778d82dcb520587c0531e794e27ef7cd5c854363dc9574bdd1aa6494e6de594a98803e883f492da

# Static Admin Token (Use generated value below)
ADMIN_TOKEN=a16b6f36e8b5597ec6edf14ebd6558fb9b66d80f0c4b2523cc6c7b65a268f62f

# Database (Update with your values)
SQL_SERVER=DESKTOP-3QPE6QQ
SQL_PASSWORD=your_sql_password

# Security Settings
NODE_ENV=development
ENABLE_HMAC_VALIDATION=false  # Enable after Flutter app is updated
```

### 4. Start Server

```bash
npm start
```

### 5. Test Admin Login

```bash
curl -X POST http://localhost:3001/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YourSecurePassword123!"}'
```

Expected response:
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h",
  "user": {
    "username": "admin",
    "role": "admin"
  }
}
```

---

## 🔐 Production Deployment

### Step 1: Generate Production Secrets

Run these commands to generate secure secrets:

```bash
# Generate JWT Secret (32 bytes = 64 hex characters)
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"

# Generate HMAC Secret (64 bytes = 128 hex characters)
node -e "console.log('HMAC_SECRET=' + require('crypto').randomBytes(64).toString('hex'))"

# Generate Admin Token (32 bytes = 64 hex characters)
node -e "console.log('ADMIN_TOKEN=' + require('crypto').randomBytes(32).toString('hex'))"
```

**⚠️ IMPORTANT:** Save these values securely! You'll need them for the `.env` file.

### Step 2: Create Production `.env` File

On your production server:

```bash
cd /path/to/vmurugan-gold-trading/sql_server_api
nano .env
```

Paste the following template and fill in your values:

```env
# ========================================
# PRODUCTION ENVIRONMENT VARIABLES
# ========================================

# Server Configuration
PORT=3001
HTTPS_PORT=443
NODE_ENV=production

# SQL Server Configuration
SQL_SERVER=your_sql_server_address
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=sa
SQL_PASSWORD=your_strong_sql_password
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true

# SSL Certificate Paths
SSL_CERT_PATH=../ssl/certificate.crt
SSL_KEY_PATH=../ssl/private.key

# Admin Authentication
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_very_strong_admin_password_here
JWT_SECRET=paste_generated_jwt_secret_here
JWT_EXPIRATION=24h
ADMIN_TOKEN=paste_generated_admin_token_here

# CORS Configuration (comma-separated, no spaces)
ALLOWED_ORIGINS=https://api.vmuruganjewellery.co.in,https://admin.vmuruganjewellery.co.in

# Rate Limiting
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW_MS=900000
PAYMENT_RATE_LIMIT_MAX=10
PAYMENT_RATE_LIMIT_WINDOW_MS=60000
OTP_RATE_LIMIT_MAX=5
OTP_RATE_LIMIT_WINDOW_MS=300000

# HMAC Request Signing
HMAC_SECRET=paste_generated_hmac_secret_here
HMAC_TIMESTAMP_TOLERANCE=300

# Security Features
ENABLE_HMAC_VALIDATION=false  # Enable after Flutter app update
ENABLE_RATE_LIMITING=true
ENABLE_ADMIN_TOKEN_VALIDATION=true

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json

# Logging
LOG_LEVEL=info
LOG_DIRECTORY=./logs
```

### Step 3: Set File Permissions

```bash
chmod 600 .env  # Only owner can read/write
chown your_user:your_group .env
```

### Step 4: Install Dependencies

```bash
npm install --production
```

### Step 5: Restart Server

```bash
# If using PM2
pm2 restart vmurugan-api

# If using systemd
sudo systemctl restart vmurugan-api

# If running manually
npm start
```

### Step 6: Verify Deployment

```bash
# Test health endpoint
curl https://api.vmuruganjewellery.co.in/health

# Test admin login
curl -X POST https://api.vmuruganjewellery.co.in/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_admin_password"}'

# Test admin route with JWT
curl https://api.vmuruganjewellery.co.in/api/admin/analytics/dashboard \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"

# Test rate limiting (should block after 5 attempts)
for i in {1..6}; do
  curl -X POST https://api.vmuruganjewellery.co.in/api/admin/login \
    -H "Content-Type: application/json" \
    -d '{"username":"wrong","password":"wrong"}'
  echo "Attempt $i"
done
```

---

## 🖥️ Admin Portal Update

### Update `admin_portal/index.html`

The admin portal needs to be updated to use JWT authentication instead of hardcoded credentials.

**Current Issues:**
- Hardcoded username/password in HTML
- Hardcoded admin-token in API calls
- No login form

**Required Changes:**
1. Remove hardcoded credentials
2. Add login form
3. Store JWT token in localStorage
4. Add token to all API requests
5. Handle token expiration
6. Add logout functionality

**Example Login Form:**

```html
<div id="loginSection" style="display: block;">
  <h2>Admin Login</h2>
  <form id="loginForm">
    <input type="text" id="username" placeholder="Username" required>
    <input type="password" id="password" placeholder="Password" required>
    <button type="submit">Login</button>
  </form>
</div>

<script>
document.getElementById('loginForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;
  
  try {
    const response = await fetch('https://api.vmuruganjewellery.co.in/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    
    const data = await response.json();
    
    if (data.success) {
      localStorage.setItem('adminToken', data.token);
      document.getElementById('loginSection').style.display = 'none';
      document.getElementById('dashboardSection').style.display = 'block';
      loadDashboard();
    } else {
      alert('Login failed: ' + data.message);
    }
  } catch (error) {
    alert('Login error: ' + error.message);
  }
});

// Update API fetch function
async function apiFetch(endpoint, options = {}) {
  const token = localStorage.getItem('adminToken');
  
  const response = await fetch(`https://api.vmuruganjewellery.co.in${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers
    }
  });
  
  if (response.status === 401) {
    // Token expired, redirect to login
    localStorage.removeItem('adminToken');
    location.reload();
  }
  
  return response.json();
}
</script>
```

---

## 📱 Flutter App Update (HMAC)

### Step 1: Add Crypto Dependency

Add to `pubspec.yaml`:

```yaml
dependencies:
  crypto: ^3.0.3
```

Run:
```bash
flutter pub get
```

### Step 2: Use HMAC Helper

The HMAC helper has been created at `lib/core/utils/hmac_helper.dart`.

Update your API service to use it:

```dart
import 'package:vmurugan_gold_trading/core/utils/hmac_helper.dart';

// In your API service
Future<Response> makePayment({
  required Map<String, dynamic> paymentData,
  required String customerId,
}) async {
  // Generate signed headers
  final headers = HMACHelper.generateSignedHeaders(
    data: paymentData,
    customerId: customerId,
  );
  
  // Make request with signature
  return await http.post(
    Uri.parse('$baseUrl/api/payments/worldline/token'),
    headers: {
      'Content-Type': 'application/json',
      ...headers,  // Add HMAC headers
    },
    body: jsonEncode(paymentData),
  );
}
```

### Step 3: Update HMAC Secret

In `lib/core/utils/hmac_helper.dart`, update the secret:

```dart
static const String _HMAC_SECRET = 'paste_your_production_hmac_secret_here';
```

**⚠️ Security Note:** In production, use `flutter_dotenv` or similar to load this from environment variables.

### Step 4: Enable HMAC Validation on Server

After deploying the updated Flutter app:

```bash
# Update .env on server
ENABLE_HMAC_VALIDATION=true

# Restart server
pm2 restart vmurugan-api
```

---

## 🧪 Testing

### Test Admin Authentication

```bash
# Test login
curl -X POST https://api.vmuruganjewellery.co.in/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}'

# Save token from response
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Test protected route
curl https://api.vmuruganjewellery.co.in/api/admin/analytics/dashboard \
  -H "Authorization: Bearer $TOKEN"

# Test token verification
curl https://api.vmuruganjewellery.co.in/api/admin/verify \
  -H "Authorization: Bearer $TOKEN"
```

### Test Rate Limiting

```bash
# Test OTP rate limiting (should block after 5 attempts)
for i in {1..6}; do
  curl -X POST https://api.vmuruganjewellery.co.in/api/auth/send-otp \
    -H "Content-Type: application/json" \
    -d '{"phone":"9999999999"}'
  echo "\nAttempt $i"
  sleep 1
done
```

### Test CORS

```bash
# Test from unauthorized origin (should fail in production)
curl https://api.vmuruganjewellery.co.in/api/admin/analytics/dashboard \
  -H "Origin: https://malicious-site.com" \
  -H "Authorization: Bearer $TOKEN" \
  -v
```

---

## 📊 Monitoring

### View Security Logs

```bash
# View all security logs
tail -f sql_server_api/logs/security_*.log

# View failed login attempts
grep "Failed admin login" sql_server_api/logs/security_*.log

# View unauthorized access attempts
grep "Unauthorized admin access" sql_server_api/logs/security_*.log

# View HMAC validation failures
grep "Invalid HMAC signature" sql_server_api/logs/security_*.log
```

### Monitor Rate Limiting

```bash
# View rate limit blocks
grep "Too many" sql_server_api/logs/general_*.log
```

---

## 🔄 Rollback Plan

If something goes wrong:

### 1. Restore Previous Version

```bash
# If using git
git checkout HEAD~1 sql_server_api/server.js

# Restart server
pm2 restart vmurugan-api
```

### 2. Disable Security Features

Edit `.env`:

```env
ENABLE_HMAC_VALIDATION=false
ENABLE_RATE_LIMITING=false
ENABLE_ADMIN_TOKEN_VALIDATION=false
```

Restart server:

```bash
pm2 restart vmurugan-api
```

### 3. Use Legacy Admin Token

If JWT login fails, use the static admin-token:

```bash
curl https://api.vmuruganjewellery.co.in/api/admin/analytics/dashboard \
  -H "admin-token: your_admin_token_here"
```

---

## ✅ Post-Deployment Checklist

- [ ] `.env` file created with production values
- [ ] All secrets are strong and unique
- [ ] File permissions set correctly (600 for `.env`)
- [ ] Dependencies installed
- [ ] Server restarted successfully
- [ ] Health endpoint responds
- [ ] Admin login works
- [ ] JWT token works for admin routes
- [ ] Rate limiting is active
- [ ] CORS is restricted to allowed origins
- [ ] Security logs are being written
- [ ] Admin portal updated (if applicable)
- [ ] Flutter app updated with HMAC (if enabling)
- [ ] All tests pass
- [ ] Monitoring is active

---

## 🆘 Troubleshooting

### Issue: "Invalid or missing admin credentials"

**Solution:** Check that:
1. JWT token is valid and not expired
2. Token is sent in `Authorization: Bearer <token>` header
3. Or static `admin-token` header is correct

### Issue: "Too many requests"

**Solution:** Rate limit triggered. Wait for the window to reset or adjust limits in `.env`.

### Issue: "Not allowed by CORS"

**Solution:** Add your origin to `ALLOWED_ORIGINS` in `.env`:
```env
ALLOWED_ORIGINS=https://yourdomain.com,https://api.yourdomain.com
```

### Issue: "Invalid signature"

**Solution:** Check that:
1. HMAC secret matches between client and server
2. Timestamp is current (within 5 minutes)
3. Request data matches signature

### Issue: Server won't start

**Solution:** Check logs:
```bash
tail -f sql_server_api/logs/general_*.log
```

Common causes:
- Missing `.env` file
- Invalid JWT_SECRET format
- Port already in use

---

## 📞 Support

For issues or questions:
1. Check security logs: `sql_server_api/logs/security_*.log`
2. Check general logs: `sql_server_api/logs/general_*.log`
3. Review this guide
4. Contact system administrator

---

**Last Updated:** 2025-12-26
**Version:** 1.0.0
