# ✅ CLIENT SERVER DEPLOYMENT CHECKLIST

## 📋 PRE-DEPLOYMENT REQUIREMENTS

### Client Server Information:
- [ ] **Server IP/Domain:** ________________
- [ ] **SSH/RDP Access:** Username: _______ Password: _______
- [ ] **Web Server:** Apache / Nginx (circle one)
- [ ] **PHP Version:** _______ (minimum 7.4 required)
- [ ] **MySQL Version:** _______ (minimum 5.7 required)
- [ ] **SSL Certificate:** Available / Needs Setup (circle one)

### Client Credentials:
- [ ] **Omniware Merchant ID:** ________________
- [ ] **Omniware Secret Key:** ________________
- [ ] **Database Password:** ________________ (create strong password)

---

## 🚀 DEPLOYMENT STEPS

### STEP 1: Server Access
- [ ] Connect to client's server via SSH/RDP
- [ ] Verify web server is running
- [ ] Check PHP and MySQL services
- [ ] Confirm domain points to server

### STEP 2: File Upload
- [ ] Create directory: `/var/www/html/vmurugan-api/`
- [ ] Upload all 14 PHP files
- [ ] Upload `.htaccess` file
- [ ] Upload `database_schema.sql`
- [ ] Create `logs/` directory with 777 permissions
- [ ] Set proper file permissions (755 for folders, 644 for files)

### STEP 3: Database Setup
- [ ] Connect to MySQL as root
- [ ] Create database: `vmurugan_gold_trading`
- [ ] Create user: `vmurugan_user`
- [ ] Set strong password for database user
- [ ] Grant ALL privileges to user
- [ ] Import `database_schema.sql`
- [ ] Verify 5 tables created: users, portfolio, transactions, notifications, price_history

### STEP 4: Configuration
- [ ] Edit `config/database.php`
- [ ] Update database credentials
- [ ] Update Omniware merchant ID
- [ ] Update Omniware secret key
- [ ] Update callback URLs with client's domain
- [ ] Save configuration file

### STEP 5: Web Server Configuration
- [ ] Configure virtual host for client's domain
- [ ] Enable required modules (rewrite, ssl, headers)
- [ ] Configure CORS headers
- [ ] Set up security headers
- [ ] Restart web server

### STEP 6: SSL Certificate
- [ ] Install SSL certificate (Let's Encrypt recommended)
- [ ] Configure HTTPS virtual host
- [ ] Force HTTPS redirects
- [ ] Test SSL certificate validity
- [ ] Set up auto-renewal for certificate

### STEP 7: API Testing
- [ ] Test database connection
- [ ] Test user registration API
- [ ] Test user login API
- [ ] Test portfolio get API
- [ ] Test transaction creation API
- [ ] Test payment initiation API
- [ ] Verify all APIs return proper JSON responses

### STEP 8: Mobile App Configuration
- [ ] Update `client_server_config.dart` with client's domain
- [ ] Change `serverDomain` from 'client-domain.com' to actual domain
- [ ] Ensure `protocol` is set to 'https'
- [ ] Rebuild APK with new configuration
- [ ] Test app connectivity to server

### STEP 9: End-to-End Testing
- [ ] Install updated APK on test device
- [ ] Register new user via app
- [ ] Login with MPIN
- [ ] Check portfolio loads (empty initially)
- [ ] Test gold purchase flow
- [ ] Verify portfolio updates
- [ ] Check transaction history
- [ ] Test silver purchase flow
- [ ] Verify payment integration

### STEP 10: Production Readiness
- [ ] Disable PHP error display
- [ ] Enable error logging
- [ ] Set up log rotation
- [ ] Configure database backups
- [ ] Monitor server resources
- [ ] Document admin credentials
- [ ] Provide client with admin access

---

## 🔧 CONFIGURATION TEMPLATES

### Database Configuration Template:
```php
$host = 'localhost';
$dbname = 'vmurugan_gold_trading';
$username = 'vmurugan_user';
$password = 'CLIENT_DB_PASSWORD_HERE';

$omniware_config = [
    'merchant_id' => 'CLIENT_OMNIWARE_MERCHANT_ID_HERE',
    'secret_key' => 'CLIENT_OMNIWARE_SECRET_KEY_HERE',
    'callback_url' => 'https://CLIENT_DOMAIN_HERE/vmurugan-api/payment_callback.php',
];
```

### App Configuration Template:
```dart
static const String serverDomain = 'CLIENT_DOMAIN_HERE';
static const String apiPath = 'vmurugan-api';
static const String protocol = 'https';
```

---

## 🧪 TESTING COMMANDS

### Test Database Connection:
```bash
mysql -u vmurugan_user -p vmurugan_gold_trading
```

### Test API Endpoints:
```bash
# User Registration
curl -X POST https://CLIENT_DOMAIN/vmurugan-api/user_register.php \
-H "Content-Type: application/json" \
-d '{"phone":"9876543210","name":"Test User","email":"test@example.com","encrypted_mpin":"test123"}'

# Portfolio Get
curl https://CLIENT_DOMAIN/vmurugan-api/portfolio_get.php?user_id=1
```

### Test SSL Certificate:
```bash
openssl s_client -connect CLIENT_DOMAIN:443 -servername CLIENT_DOMAIN
```

---

## 📊 POST-DEPLOYMENT VERIFICATION

### Database Verification:
- [ ] Users table exists and is empty
- [ ] Portfolio table exists and is empty
- [ ] Transactions table exists and is empty
- [ ] Sample user can be inserted
- [ ] Database user has correct privileges

### API Verification:
- [ ] All 12 API endpoints respond with 200 status
- [ ] CORS headers present in responses
- [ ] Error responses return proper JSON format
- [ ] Authentication works correctly
- [ ] Data persistence verified

### Security Verification:
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] SSL certificate valid and trusted
- [ ] Sensitive files protected (config, logs)
- [ ] Database credentials secure
- [ ] Error messages don't expose sensitive info

### App Integration Verification:
- [ ] App connects to server successfully
- [ ] User registration works end-to-end
- [ ] Login authentication works
- [ ] Portfolio data loads correctly
- [ ] Transactions save to database
- [ ] Payment flow initiates correctly

---

## 📞 HANDOVER TO CLIENT

### Provide Client With:
- [ ] **Server Admin Credentials**
- [ ] **Database Admin Credentials**
- [ ] **API Documentation** (API_DOCUMENTATION.md)
- [ ] **Deployment Guide** (DEPLOYMENT_GUIDE.md)
- [ ] **Updated APK** with server configuration
- [ ] **Backup Instructions**
- [ ] **Monitoring Guidelines**
- [ ] **Support Contact Information**

### Client Training:
- [ ] How to access server logs
- [ ] How to backup database
- [ ] How to monitor API performance
- [ ] How to update Omniware settings
- [ ] How to renew SSL certificate
- [ ] Emergency contact procedures

---

## 🎯 SUCCESS CRITERIA

### Technical Success:
- ✅ All APIs deployed and functional
- ✅ Database properly configured and secured
- ✅ SSL certificate installed and working
- ✅ Mobile app connects successfully
- ✅ End-to-end user flow works
- ✅ Payment integration functional

### Business Success:
- ✅ Client can register users
- ✅ Users can purchase gold/silver
- ✅ Portfolio tracking works
- ✅ Transaction history available
- ✅ Payment processing secure
- ✅ Data stored on client's server

**🎉 DEPLOYMENT COMPLETE!**

**Client now has full control over their gold trading platform with secure server-side data storage and payment processing.**
