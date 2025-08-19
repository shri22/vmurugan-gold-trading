# 🚀 V MURUGAN GOLD TRADING - CLIENT SERVER DEPLOYMENT GUIDE

## 📋 OVERVIEW
This guide helps deploy the V Murugan Gold Trading APIs on the client's own server with complete database setup.

---

## 🏢 STEP 1: SERVER REQUIREMENTS

### ✅ Minimum Requirements:
- **OS:** Linux (Ubuntu 20.04+) or Windows Server 2019+
- **Web Server:** Apache 2.4+ or Nginx 1.18+
- **PHP:** 7.4+ with extensions: mysql, json, curl, mbstring
- **Database:** MySQL 5.7+ or MariaDB 10.3+
- **SSL:** Certificate required for HTTPS (Let's Encrypt recommended)
- **RAM:** 2GB minimum, 4GB recommended
- **Storage:** 10GB minimum for database growth

### ✅ Domain Requirements:
- **Domain/Subdomain** pointing to server
- **SSL Certificate** installed and configured
- **HTTPS** enabled and forced

---

## 📁 STEP 2: FILE UPLOAD

### Upload Structure:
```
/var/www/html/vmurugan-api/  (Linux)
C:\inetpub\wwwroot\vmurugan-api\  (Windows)
├── config/
│   └── database.php
├── logs/ (create with 777 permissions)
├── user_register.php
├── user_login.php
├── portfolio_get.php
├── portfolio_update.php
├── transaction_create.php
├── transaction_update_status.php
├── transaction_history.php
├── payment_initiate.php
├── payment_callback.php
├── notification_send.php
├── notification_get.php
├── notification_mark_read.php
└── .htaccess
```

### Upload Methods:
1. **SCP/SFTP:** `scp -r server_apis/ user@server:/var/www/html/vmurugan-api/`
2. **FTP:** Use FileZilla/WinSCP to upload files
3. **cPanel:** Use File Manager to upload and extract

### Set Permissions (Linux):
```bash
sudo chown -R www-data:www-data /var/www/html/vmurugan-api/
sudo chmod -R 755 /var/www/html/vmurugan-api/
sudo chmod -R 777 /var/www/html/vmurugan-api/logs/
```

---

## 🗄️ STEP 3: DATABASE SETUP

### Create Database:
```sql
-- Connect to MySQL as root
mysql -u root -p

-- Create database
CREATE DATABASE vmurugan_gold_trading CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'vmurugan_user'@'localhost' IDENTIFIED BY 'SecurePassword123!';

-- Grant privileges
GRANT ALL PRIVILEGES ON vmurugan_gold_trading.* TO 'vmurugan_user'@'localhost';
FLUSH PRIVILEGES;

-- Use database
USE vmurugan_gold_trading;

-- Import schema
SOURCE /path/to/database_schema.sql;

-- Verify tables
SHOW TABLES;
```

### Expected Tables:
- ✅ `users` - User accounts and authentication
- ✅ `portfolio` - User gold/silver holdings
- ✅ `transactions` - Purchase/sale records
- ✅ `notifications` - User notifications
- ✅ `price_history` - Price tracking

---

## ⚙️ STEP 4: CONFIGURATION

### Update `config/database.php`:
```php
<?php
// Database configuration
$host = 'localhost';
$dbname = 'vmurugan_gold_trading';
$username = 'vmurugan_user';
$password = 'SecurePassword123!';

// Omniware configuration
$omniware_config = [
    'merchant_id' => 'CLIENT_ACTUAL_MERCHANT_ID',
    'secret_key' => 'CLIENT_ACTUAL_SECRET_KEY',
    'callback_url' => 'https://client-domain.com/vmurugan-api/payment_callback.php',
    'success_url' => 'https://client-domain.com/payment/success',
    'failure_url' => 'https://client-domain.com/payment/failure',
];
?>
```

### Replace Placeholders:
- `CLIENT_ACTUAL_MERCHANT_ID` → Client's Omniware merchant ID
- `CLIENT_ACTUAL_SECRET_KEY` → Client's Omniware secret key
- `client-domain.com` → Client's actual domain

---

## 🔧 STEP 5: WEB SERVER CONFIGURATION

### Apache Virtual Host:
```apache
<VirtualHost *:443>
    ServerName client-domain.com
    DocumentRoot /var/www/html/vmurugan-api
    
    SSLEngine on
    SSLCertificateFile /path/to/certificate.crt
    SSLCertificateKeyFile /path/to/private.key
    
    <Directory /var/www/html/vmurugan-api>
        AllowOverride All
        Require all granted
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # CORS headers for mobile app
    Header always set Access-Control-Allow-Origin "*"
    Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type"
</VirtualHost>
```

### Enable Required Modules:
```bash
sudo a2enmod rewrite
sudo a2enmod ssl
sudo a2enmod headers
sudo systemctl reload apache2
```

---

## 🔒 STEP 6: SSL CERTIFICATE

### Install Let's Encrypt:
```bash
# Ubuntu/Debian
sudo apt install certbot python3-certbot-apache

# Generate certificate
sudo certbot --apache -d client-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Verify HTTPS:
- Visit: `https://client-domain.com/vmurugan-api/`
- Should show directory listing or 403 (both are OK)
- SSL certificate should be valid

---

## 🧪 STEP 7: API TESTING

### Test Database Connection:
Create `test_connection.php`:
```php
<?php
require_once 'config/database.php';
try {
    $pdo = new PDO($dsn, $username, $password, $options);
    echo "✅ Database connection successful!";
} catch (PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage();
}
?>
```

### Test API Endpoints:
```bash
# Test user registration
curl -X POST https://client-domain.com/vmurugan-api/user_register.php \
-H "Content-Type: application/json" \
-d '{"phone":"9876543210","name":"Test User","email":"test@example.com","encrypted_mpin":"test123"}'

# Test portfolio get
curl https://client-domain.com/vmurugan-api/portfolio_get.php?user_id=1
```

---

## 📱 STEP 8: UPDATE MOBILE APP

### Update `lib/core/config/client_server_config.dart`:
```dart
class ClientServerConfig {
  // UPDATE THIS WITH CLIENT'S ACTUAL DOMAIN
  static const String serverDomain = 'client-domain.com';
  static const String apiPath = 'vmurugan-api';
  static const String protocol = 'https';
  
  static const String baseUrl = '$protocol://$serverDomain/$apiPath';
}
```

### Rebuild APK:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## ✅ STEP 9: PRODUCTION CHECKLIST

### Security:
- [ ] SSL certificate installed and working
- [ ] HTTPS forced (no HTTP access)
- [ ] Database user has minimal required privileges
- [ ] Strong database password set
- [ ] Error display disabled in PHP
- [ ] Sensitive files protected (.htaccess)

### Functionality:
- [ ] Database connection working
- [ ] All API endpoints responding
- [ ] User registration working
- [ ] User login working
- [ ] Portfolio operations working
- [ ] Transaction creation working
- [ ] Payment integration working

### Performance:
- [ ] PHP opcache enabled
- [ ] Database indexes created
- [ ] Log rotation configured
- [ ] Backup strategy in place

---

## 🔧 STEP 10: TROUBLESHOOTING

### Common Issues:

#### "Database connection failed"
- Check database credentials in `config/database.php`
- Verify MySQL service is running
- Check user privileges

#### "CORS error in app"
- Verify CORS headers in `.htaccess`
- Check web server configuration
- Ensure OPTIONS requests are handled

#### "SSL certificate error"
- Verify certificate installation
- Check certificate validity
- Ensure HTTPS is properly configured

#### "API not found (404)"
- Check file upload paths
- Verify web server document root
- Check .htaccess configuration

---

## 📞 SUPPORT

### Log Files:
- **Apache:** `/var/log/apache2/error.log`
- **PHP:** `/var/log/php_errors.log`
- **App:** `/var/www/html/vmurugan-api/logs/app.log`

### Monitoring:
- Monitor API response times
- Check database performance
- Monitor SSL certificate expiry
- Track error logs regularly

---

## 🎯 FINAL VERIFICATION

### Test Complete Flow:
1. **Register** new user via mobile app
2. **Login** with MPIN
3. **View** portfolio (should be empty initially)
4. **Purchase** gold/silver
5. **Check** portfolio update
6. **View** transaction history

### Expected Results:
- All operations complete successfully
- Data persists in database
- No errors in logs
- HTTPS connections secure

**🎉 Deployment Complete! The V Murugan Gold Trading app is now running on the client's server with secure data storage and payment integration.**
