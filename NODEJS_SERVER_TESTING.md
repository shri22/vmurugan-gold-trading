# 🚀 VMurugan Gold Trading - Node.js Server Testing

## ✅ **Your Current Setup**
- **Node.js Server** running on your public IP
- **Port 3000** (default) or 3001 if configured
- **MySQL Database** for data storage
- **Flutter Mobile App** connecting to Node.js server

---

## 🎯 **NEXT STEPS - Since Public IP is Working**

### **STEP 1: Update Mobile App Configuration**

Edit `lib/core/config/client_server_config.dart`:
```dart
// Replace with your actual public IP
static const String serverDomain = 'YOUR_ACTUAL_PUBLIC_IP'; 
// Example: static const String serverDomain = '203.192.123.45';

static const int serverPort = 3000; // Your Node.js server port
static const String protocol = 'http'; // Use 'https' for production
```

### **STEP 2: Test Your Node.js Server**

**Method 1: Web Dashboard**
```bash
# Open in browser
open test_server_apis.html
# Enter your public IP and test all endpoints
```

**Method 2: Command Line**
```bash
# Quick test
python quick_server_test.py YOUR_PUBLIC_IP

# Manual test
curl http://YOUR_PUBLIC_IP:3000/health
```

**Method 3: Direct API Testing**
```bash
# Test server health
curl -X GET http://YOUR_PUBLIC_IP:3000/health

# Test user registration
curl -X POST http://YOUR_PUBLIC_IP:3000/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543210",
    "name": "Test User", 
    "email": "test@example.com",
    "address": "Test Address",
    "pan_card": "ABCDE1234F",
    "device_id": "test123",
    "mpin": "1234"
  }'

# Test user login
curl -X POST http://YOUR_PUBLIC_IP:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543210",
    "encrypted_mpin": "1234"
  }'
```

---

## 🧪 **Your Node.js API Endpoints**

Based on your `server.js`, these endpoints are available:

### **Health Check**
- `GET /health` - Server status

### **User Management**
- `POST /api/customers` - Register new user
- `POST /api/login` - User login with MPIN
- `POST /api/auth/send-otp` - Send OTP for verification
- `POST /api/auth/verify-otp` - Verify OTP

### **Transaction Management**
- `POST /api/transactions` - Create new transaction
- `PUT /api/transaction-status` - Update transaction status
- `GET /api/transaction-history` - Get user transaction history

### **Admin APIs**
- `GET /api/admin/customers` - Get all customers (admin only)
- `GET /api/admin/transactions` - Get all transactions (admin only)
- `GET /api/admin/stats` - Get business statistics (admin only)

---

## 📱 **Test Mobile App**

### **Rebuild App with New Server Config**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### **Test Complete User Flow**
1. **Open App** → VMurugan logo should appear
2. **Register User** → Use test data from API tests
3. **Login** → Use phone + MPIN
4. **Dashboard** → Should load successfully
5. **Gold Trading** → Test buy/sell operations
6. **Transaction History** → Verify data persistence

---

## ✅ **Success Indicators**

Your system is working correctly when:

- ✅ `/health` returns `{"status": "OK"}`
- ✅ User registration creates database record
- ✅ User login authenticates successfully
- ✅ Mobile app connects without errors
- ✅ Transactions save to database
- ✅ All API responses are proper JSON

---

## 🔧 **Common Issues & Solutions**

### **Issue: Connection Refused**
```bash
# Check if Node.js server is running
ps aux | grep node

# Check if port is open
netstat -tulpn | grep :3000

# Restart server if needed
cd server && node server.js
```

### **Issue: Database Connection Error**
```bash
# Check MySQL service
sudo systemctl status mysql

# Test database connection
mysql -u root -p -e "SHOW DATABASES;"
```

### **Issue: CORS Errors**
- Verify CORS is configured in your `server.js`
- Check `ALLOWED_ORIGINS` environment variable
- Test from same network first

### **Issue: Mobile App Can't Connect**
- Verify IP address in app configuration
- Check firewall allows port 3000
- Test API endpoints manually first

---

## 🚀 **Production Deployment**

### **For Production, Set Up:**

1. **Domain Name** (recommended over IP)
```dart
static const String serverDomain = 'api.vmurugan.com';
```

2. **SSL Certificate**
```bash
# Install Let's Encrypt
sudo certbot --nginx -d api.vmurugan.com
```

3. **Environment Variables**
```bash
# Create .env file
DB_HOST=localhost
DB_USER=vmurugan_user
DB_PASSWORD=secure_password
DB_NAME=digi_gold_business
ALLOWED_ORIGINS=https://vmurugan.com,https://app.vmurugan.com
ADMIN_TOKEN=secure_admin_token_2025
```

4. **Process Manager**
```bash
# Install PM2 for production
npm install -g pm2
pm2 start server.js --name "vmurugan-api"
pm2 startup
pm2 save
```

---

## 📊 **Testing Checklist**

- [ ] **Server Health** - `/health` responds
- [ ] **User Registration** - Creates user in database
- [ ] **User Login** - Authenticates with MPIN
- [ ] **OTP System** - Sends and verifies OTP
- [ ] **Transaction Creation** - Saves to database
- [ ] **Transaction History** - Retrieves user data
- [ ] **Admin APIs** - Work with admin token
- [ ] **Mobile App** - Connects and functions
- [ ] **Database** - All tables created and accessible
- [ ] **Security** - Rate limiting and validation active

---

## 🎉 **You're Ready!**

Once all tests pass, your **VMurugan Gold Trading Platform** is ready for:
- Customer onboarding
- Gold trading operations  
- Business growth
- Play Store submission

**Your Node.js server with public IP is the foundation for a successful gold trading business! 🏆**
