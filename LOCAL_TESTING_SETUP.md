# 📱 LOCAL TESTING SETUP - Test on Your Mobile

## 🚀 QUICK SETUP (30 Minutes)

### STEP 1: Install Local Server
1. **Download XAMPP:** https://www.apachefriends.org/download.html
2. **Install XAMPP** (choose Apache + MySQL + PHP)
3. **Start XAMPP Control Panel**
4. **Start Apache and MySQL** services

### STEP 2: Setup Database
1. **Open Browser:** http://localhost/phpmyadmin
2. **Create Database:** 
   - Click "New" 
   - Name: `vmurugan_gold_trading`
   - Collation: `utf8mb4_unicode_ci`
3. **Import Schema:**
   - Select database
   - Click "Import"
   - Choose `server_apis/database_schema.sql`
   - Click "Go"
4. **Verify Tables:** Should see 5 tables created

### STEP 3: Upload API Files
1. **Copy Files:** Copy entire `server_apis` folder to `C:\xampp\htdocs\`
2. **Rename Folder:** Rename to `vmurugan-api`
3. **Update Config:** Edit `C:\xampp\htdocs\vmurugan-api\config\database.php`

```php
<?php
// Local testing configuration
$host = 'localhost';
$dbname = 'vmurugan_gold_trading';
$username = 'root';  // Default XAMPP username
$password = '';      // Default XAMPP password (empty)

// Test Omniware config (won't work but APIs will respond)
$omniware_config = [
    'merchant_id' => 'TEST_MERCHANT_ID',
    'secret_key' => 'TEST_SECRET_KEY',
    'callback_url' => 'http://localhost/vmurugan-api/payment_callback.php',
];
?>
```

### STEP 4: Test APIs
1. **Open Browser:** http://localhost/vmurugan-api/
2. **Test Registration:** 
   - Open: http://localhost/vmurugan-api/user_register.php
   - Should show "Method not allowed" (this is correct)
3. **Test Portfolio:** 
   - Open: http://localhost/vmurugan-api/portfolio_get.php?user_id=1
   - Should show JSON error (this is correct - no user exists yet)

### STEP 5: Update App for Local Testing
Edit `lib/core/config/client_server_config.dart`:

```dart
class ClientServerConfig {
  // LOCAL TESTING CONFIGURATION
  static const String serverDomain = '10.0.2.2'; // Android emulator localhost
  // OR use your computer's IP address like '192.168.1.100'
  static const String apiPath = 'vmurugan-api';
  static const String protocol = 'http'; // HTTP for local testing
  
  static const String baseUrl = '$protocol://$serverDomain/$apiPath';
}
```

### STEP 6: Find Your Computer's IP Address
**Windows:**
```cmd
ipconfig
# Look for "IPv4 Address" under your network adapter
# Example: 192.168.1.100
```

**Use this IP in app config:**
```dart
static const String serverDomain = '192.168.1.100'; // Your actual IP
```

### STEP 7: Rebuild and Test App
```bash
flutter build apk --debug
```

### STEP 8: Install and Test
1. **Install APK** on your mobile
2. **Connect mobile to same WiFi** as your computer
3. **Test Registration:** Create new account
4. **Test Login:** Login with MPIN
5. **Test Portfolio:** Should load (empty initially)
6. **Test Purchase:** Try gold/silver purchase

---

## 📱 TESTING CHECKLIST

### ✅ Local Server Setup:
- [ ] XAMPP installed and running
- [ ] Apache service started (port 80)
- [ ] MySQL service started (port 3306)
- [ ] Database created and schema imported
- [ ] API files uploaded to htdocs

### ✅ Network Setup:
- [ ] Computer IP address identified
- [ ] Mobile connected to same WiFi
- [ ] Can access http://COMPUTER_IP/vmurugan-api/ from mobile browser

### ✅ App Configuration:
- [ ] client_server_config.dart updated with computer IP
- [ ] Protocol set to 'http' for local testing
- [ ] APK rebuilt with new configuration
- [ ] APK installed on mobile device

### ✅ Functionality Testing:
- [ ] App launches without errors
- [ ] Registration screen loads
- [ ] Can create new account
- [ ] Can login with MPIN
- [ ] Portfolio screen loads
- [ ] Can initiate gold purchase
- [ ] Can initiate silver purchase (shows ₹126.00)

---

## 🔧 TROUBLESHOOTING

### "Connection refused" Error:
- Check XAMPP Apache is running
- Verify computer IP address
- Ensure mobile on same WiFi network
- Try accessing http://COMPUTER_IP/vmurugan-api/ in mobile browser

### "Database connection failed":
- Check MySQL is running in XAMPP
- Verify database name is correct
- Check database_schema.sql was imported successfully

### "API not found (404)":
- Verify files are in C:\xampp\htdocs\vmurugan-api\
- Check folder name is exactly 'vmurugan-api'
- Ensure all PHP files are present

### App shows "Server not reachable":
- Verify IP address in client_server_config.dart
- Check mobile can access http://COMPUTER_IP in browser
- Ensure Windows Firewall allows Apache (port 80)

---

## 🎯 EXPECTED TEST RESULTS

### ✅ Successful Registration:
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "phone": "9876543210",
    "name": "Test User"
  }
}
```

### ✅ Successful Login:
- User ID saved in app
- Portfolio loads (empty initially)
- Navigation to main screen

### ✅ Portfolio Display:
- Shows 0.0000g gold
- Shows 0.0000g silver
- Shows ₹0.00 invested
- Recent transactions empty

### ✅ Gold Purchase:
- Shows current gold price
- Calculate quantity correctly
- Payment initiation (will fail - no real Omniware)
- Transaction recorded in database

### ✅ Silver Purchase:
- Shows ₹126.00 per gram (exact MJDTA price)
- Calculate quantity correctly
- Payment initiation
- Transaction recorded

---

## 🚀 READY TO TEST!

**After completing this setup, you'll be able to test the complete V Murugan Gold Trading app on your mobile device with:**

✅ **Real API Communication** - App talks to actual server  
✅ **Database Storage** - All data saved in MySQL  
✅ **User Registration** - Create and manage accounts  
✅ **Portfolio Management** - Track gold/silver holdings  
✅ **Transaction History** - Complete purchase records  
✅ **Exact Silver Pricing** - ₹126.00 from MJDTA  
✅ **Payment Integration** - Omniware gateway ready  

**This gives you a complete testing environment before deploying to the client's actual server! 🎉**
