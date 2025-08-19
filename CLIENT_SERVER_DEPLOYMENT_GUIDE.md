# 🏢 V MURUGAN GOLD TRADING - CLIENT SERVER DEPLOYMENT GUIDE

## 📋 **OVERVIEW**
Complete deployment guide for setting up the V Murugan Gold Trading platform on the client's own server infrastructure using Node.js and Microsoft SQL Server.

---

## 🎯 **DEPLOYMENT PACKAGE CONTENTS**

### **✅ Server Files to Deploy:**
```
sql_server_api/
├── server.js ✅ (Extended Node.js API server)
├── package.json ✅ (Dependencies configuration)
├── package-lock.json ✅ (Dependency versions)
├── .env.example ✅ (Configuration template)
├── update_schema_for_silver.js ✅ (Database update script)
└── setup.js ✅ (Initial setup script)
```

### **✅ Database Files:**
```
database/
├── create_database.sql ✅ (Database creation script)
├── create_tables.sql ✅ (Table creation script)
└── sample_data.sql ✅ (Test data - optional)
```

### **✅ Mobile App:**
```
mobile/
└── app-release.apk ✅ (Production mobile app)
```

### **✅ Documentation:**
```
docs/
├── CLIENT_SERVER_DEPLOYMENT_GUIDE.md ✅ (This document)
├── API_DOCUMENTATION.md ✅ (API reference)
├── TROUBLESHOOTING_GUIDE.md ✅ (Common issues)
└── MAINTENANCE_GUIDE.md ✅ (Ongoing maintenance)
```

---

## 🏗️ **CLIENT SERVER REQUIREMENTS**

### **✅ Hardware Requirements:**
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4 cores | 8 cores |
| **RAM** | 8GB | 16GB |
| **Storage** | 100GB SSD | 500GB SSD |
| **Network** | 100 Mbps | 1 Gbps |

### **✅ Software Requirements:**
| Software | Version | Purpose |
|----------|---------|---------|
| **Windows Server** | 2019+ | Operating System |
| **Node.js** | 18.x LTS | API Server Runtime |
| **SQL Server** | 2017+ | Database Engine |
| **SSMS** | Latest | Database Management |
| **IIS** | 10+ | Web Server (Optional) |

### **✅ Network Requirements:**
- **✅ Static IP Address** (Client already has this)
- **Domain Name** (Optional but recommended)
- **SSL Certificate** (Let's Encrypt or Commercial)
- **Firewall Configuration** (Ports 80, 443, 1433, 3001)
- **Internet Connectivity** for mobile app access
- **Router/Firewall Port Forwarding** (If behind NAT)

---

## 🚀 **STEP-BY-STEP DEPLOYMENT**

### **STEP 1: SERVER PREPARATION**

#### **1.1 Install Node.js**
```bash
# Download from: https://nodejs.org/
# Choose: LTS version (18.x or 20.x)
# Installation path: C:\Program Files\nodejs\
# Verify installation:
node --version  # Should show v18.x.x or v20.x.x
npm --version   # Should show 9.x.x or 10.x.x
```

#### **1.2 Install SQL Server**
```bash
# Download: SQL Server 2019/2022 Developer or Standard Edition
# Installation Options:
- Mixed Mode Authentication: ✅ Enable
- sa password: Set strong password
- TCP/IP Protocol: ✅ Enable
- Default Port: 1433
- Windows Firewall: ✅ Allow SQL Server
```

#### **1.3 Install SQL Server Management Studio (SSMS)**
```bash
# Download from: Microsoft SSMS Download Page
# Install with default options
# Used for database management and monitoring
```

#### **1.4 Configure Windows Firewall for Global Access**
```bash
# Open Windows Firewall with Advanced Security
# Create Inbound Rules for GLOBAL ACCESS:
- Port 1433 (SQL Server) - RESTRICT to local network only
- Port 3001 (Node.js API) - ALLOW from anywhere (0.0.0.0/0)
- Port 80 (HTTP) - ALLOW from anywhere (for SSL redirect)
- Port 443 (HTTPS) - ALLOW from anywhere (for SSL access)

# PowerShell commands to configure firewall:
New-NetFirewallRule -DisplayName "VMurugan API Global" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow
New-NetFirewallRule -DisplayName "HTTP Global" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS Global" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "SQL Server Local Only" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -RemoteAddress LocalSubnet
```

### **STEP 2: UPLOAD APPLICATION FILES**

#### **2.1 Create Application Directory**
```bash
# Create directory structure:
C:\inetpub\vmurugan-api\
├── sql_server_api\
├── database\
├── logs\
└── backups\
```

#### **2.2 Upload Files**
**Method A: Remote Desktop**
```bash
# Connect to server via RDP
# Copy sql_server_api folder to C:\inetpub\vmurugan-api\
# Ensure all files are copied correctly
```

**Method B: FTP/SFTP**
```bash
# Use WinSCP, FileZilla, or similar
# Upload maintaining folder structure
# Set permissions: Full Control for IIS_IUSRS
```

**Method C: Git (Recommended)**
```bash
# On client's server:
cd C:\inetpub\
git clone https://github.com/your-repo/vmurugan-gold-trading.git vmurugan-api
cd vmurugan-api\sql_server_api
```

### **STEP 3: DATABASE SETUP**

#### **3.1 Create Database and User**
```sql
-- Connect to SQL Server as 'sa' or admin user
-- Open SQL Server Management Studio (SSMS)

-- Create database
CREATE DATABASE VMuruganGoldTrading
COLLATE SQL_Latin1_General_CP1_CI_AS;

-- Create dedicated user
CREATE LOGIN vmurugan_user WITH PASSWORD = 'ClientSecurePassword123!';
USE VMuruganGoldTrading;
CREATE USER vmurugan_user FOR LOGIN vmurugan_user;

-- Grant permissions
ALTER ROLE db_owner ADD MEMBER vmurugan_user;

-- Verify user creation
SELECT name FROM sys.database_principals WHERE type = 'S';
```

#### **3.2 Create Tables**
```sql
-- Use the database
USE VMuruganGoldTrading;

-- Create customers table
CREATE TABLE customers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    phone NVARCHAR(15) UNIQUE NOT NULL,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    encrypted_mpin NVARCHAR(255) NOT NULL,
    registration_date DATETIME DEFAULT GETDATE(),
    last_login DATETIME NULL,
    status NVARCHAR(20) DEFAULT 'ACTIVE'
);

-- Create transactions table
CREATE TABLE transactions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id NVARCHAR(50) UNIQUE NOT NULL,
    customer_phone NVARCHAR(15) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    gold_grams DECIMAL(10,4) DEFAULT 0.0000,
    silver_grams DECIMAL(10,4) DEFAULT 0.0000,
    transaction_type NVARCHAR(10) DEFAULT 'BUY',
    metal_type NVARCHAR(10) DEFAULT 'GOLD',
    status NVARCHAR(20) DEFAULT 'PENDING',
    payment_method NVARCHAR(50),
    gateway_transaction_id NVARCHAR(100),
    gold_price_per_gram DECIMAL(10,2),
    silver_price_per_gram DECIMAL(10,2),
    timestamp DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    callback_data NVARCHAR(MAX),
    FOREIGN KEY (customer_phone) REFERENCES customers(phone)
);

-- Create indexes for performance
CREATE INDEX IX_transactions_customer_phone ON transactions(customer_phone);
CREATE INDEX IX_transactions_status ON transactions(status);
CREATE INDEX IX_transactions_metal_type ON transactions(metal_type);
CREATE INDEX IX_transactions_timestamp ON transactions(timestamp);

-- Verify tables created
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
```

### **STEP 4: CONFIGURE APPLICATION**

#### **4.1 Create Environment Configuration**
```bash
# Navigate to application directory
cd C:\inetpub\vmurugan-api\sql_server_api

# Create .env file with client's configuration
```

#### **4.2 .env File Content**
```env
# SQL Server Configuration
SQL_SERVER=localhost
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=vmurugan_user
SQL_PASSWORD=ClientSecurePassword123!
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true
SQL_INSTANCE=

# Server Configuration
PORT=3001
NODE_ENV=production
ALLOWED_ORIGINS=*

# Admin Configuration
ADMIN_TOKEN=CLIENT_ADMIN_TOKEN_2025

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=logs/app.log

# Security Configuration
SESSION_SECRET=ClientSessionSecret2025
JWT_SECRET=ClientJWTSecret2025

# Business Configuration
APP_NAME=V Murugan Gold Trading
APP_VERSION=1.0.0
COMPANY_NAME=V Murugan Gold Trading
SUPPORT_EMAIL=support@vmurugan.com
SUPPORT_PHONE=+91-XXXXXXXXXX
```

#### **4.3 Install Dependencies**
```bash
# Navigate to application directory
cd C:\inetpub\vmurugan-api\sql_server_api

# Install Node.js dependencies
npm install

# Verify installation
npm list --depth=0
```

#### **4.4 Update Database Schema**
```bash
# Run database update script for silver support
node update_schema_for_silver.js

# Expected output:
# ✅ Connected to SQL Server successfully
# ✅ silver_grams column added
# ✅ transaction_type column added
# ✅ metal_type column added
# ✅ Schema update completed successfully
```

### **STEP 5: TEST SERVER INSTALLATION**

#### **5.1 Start Server**
```bash
# Navigate to application directory
cd C:\inetpub\vmurugan-api\sql_server_api

# Start server
node server.js

# Expected output:
# ✅ SQL Server connected successfully
# ✅ Server running on port 3001
# ✅ Database: VMuruganGoldTrading
# ✅ Environment: production
```

#### **5.2 Test API Endpoints**
```bash
# Test health check
curl http://localhost:3001/health

# Test database connection
curl http://localhost:3001/api/test-connection

# Test user registration
curl -X POST http://localhost:3001/api/customers \
-H "Content-Type: application/json" \
-d '{
  "phone": "9876543210",
  "name": "Test User",
  "email": "test@example.com",
  "encrypted_mpin": "test123"
}'

# Test portfolio (after user creation)
curl http://localhost:3001/api/portfolio?phone=9876543210
```

#### **5.3 Verify Database Operations**
```sql
-- Open SSMS and connect to database
USE VMuruganGoldTrading;

-- Check if test user was created
SELECT * FROM customers WHERE phone = '9876543210';

-- Check table structure
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'transactions'
ORDER BY ORDINAL_POSITION;
```

### **STEP 6: PRODUCTION DEPLOYMENT**

#### **6.1 Install Process Manager (PM2)**
```bash
# Install PM2 globally
npm install -g pm2

# Create PM2 ecosystem file
# Create file: ecosystem.config.js
```

#### **6.2 PM2 Configuration (ecosystem.config.js)**
```javascript
module.exports = {
  apps: [{
    name: 'vmurugan-api',
    script: 'server.js',
    cwd: 'C:\\inetpub\\vmurugan-api\\sql_server_api',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: 'C:\\inetpub\\vmurugan-api\\logs\\err.log',
    out_file: 'C:\\inetpub\\vmurugan-api\\logs\\out.log',
    log_file: 'C:\\inetpub\\vmurugan-api\\logs\\combined.log',
    time: true
  }]
};
```

#### **6.3 Start Production Service**
```bash
# Start application with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Install PM2 as Windows service
npm install -g pm2-windows-service
pm2-service-install

# Verify service is running
pm2 status
pm2 logs vmurugan-api
```

#### **6.4 Configure Windows Service (Alternative)**
```bash
# Install node-windows
npm install -g node-windows

# Create service installation script
# Create file: install-service.js
```

#### **6.5 Windows Service Script (install-service.js)**
```javascript
var Service = require('node-windows').Service;

// Create a new service object
var svc = new Service({
  name: 'VMurugan Gold Trading API',
  description: 'V Murugan Gold Trading Node.js API Server',
  script: 'C:\\inetpub\\vmurugan-api\\sql_server_api\\server.js',
  nodeOptions: [
    '--harmony',
    '--max_old_space_size=4096'
  ],
  env: {
    name: "NODE_ENV",
    value: "production"
  }
});

// Listen for the "install" event
svc.on('install', function(){
  console.log('Service installed successfully');
  svc.start();
});

// Listen for the "start" event
svc.on('start', function(){
  console.log('Service started successfully');
});

// Install the service
svc.install();
```

### **STEP 7: GLOBAL ACCESS CONFIGURATION**

#### **7.1 Configure Public IP Access**
```bash
# STEP 7.1: Verify Public IP Configuration
# Check your public IP address:
curl ifconfig.me
# OR visit: https://whatismyipaddress.com/

# Note down your public IP (e.g., 203.0.113.10)
# This will be used in mobile app configuration

# Test external connectivity:
# From another network, test: http://YOUR_PUBLIC_IP:3001/health
```

#### **7.2 Configure Router/Firewall Port Forwarding (If Behind NAT)**
```bash
# If server is behind router/firewall, configure port forwarding:
# Router Admin Panel → Port Forwarding → Add Rules:

External Port 80   → Internal IP 192.168.1.100:80   (HTTP)
External Port 443  → Internal IP 192.168.1.100:443  (HTTPS)
External Port 3001 → Internal IP 192.168.1.100:3001 (API Direct)

# Find internal IP of server:
ipconfig | findstr IPv4
```

#### **7.3 Configure IIS Reverse Proxy (Optional but Recommended)**
```xml
<!-- web.config for IIS -->
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="ReverseProxyInboundRule1" stopProcessing="true">
          <match url="(.*)" />
          <action type="Rewrite" url="http://localhost:3001/{R:1}" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

#### **7.4 SSL Certificate Configuration for Global Access**
```bash
# OPTION 1: Self-Signed Certificate (Quick Setup for IP Access)
# Generate self-signed certificate for IP address:
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=YOUR_PUBLIC_IP"

# OPTION 2: Let's Encrypt (Free - Requires Domain)
# If you have a domain pointing to your IP:
# Install Certbot for Windows
# Generate certificate: certbot certonly --standalone -d yourdomain.com

# OPTION 3: Commercial Certificate (Production Recommended)
# Purchase SSL certificate for your domain
# Install in IIS or configure in Node.js

# For immediate testing with IP address, use Option 1
```

#### **7.5 Configure Node.js for HTTPS (Global Access)**
```javascript
// Update server.js for HTTPS support
const https = require('https');
const fs = require('fs');

// SSL certificate configuration
const sslOptions = {
  key: fs.readFileSync('path/to/private-key.pem'),
  cert: fs.readFileSync('path/to/certificate.pem')
};

// Create HTTPS server
const httpsServer = https.createServer(sslOptions, app);
httpsServer.listen(443, '0.0.0.0', () => {
  console.log('🔒 HTTPS Server running on port 443 (Global Access)');
  console.log('🌍 Accessible from: https://YOUR_PUBLIC_IP/');
});

// Also keep HTTP server for redirect
const http = require('http');
const httpServer = http.createServer((req, res) => {
  res.writeHead(301, { "Location": "https://" + req.headers['host'] + req.url });
  res.end();
});
httpServer.listen(80, '0.0.0.0', () => {
  console.log('🔄 HTTP Server redirecting to HTTPS on port 80');
});

// Keep original server for direct API access
app.listen(3001, '0.0.0.0', () => {
  console.log('🚀 API Server running on port 3001 (Global Access)');
  console.log('🌍 Direct API Access: http://YOUR_PUBLIC_IP:3001/api');
});
```

#### **7.3 Firewall Configuration**
```bash
# Windows Firewall Rules:
# Inbound Rules:
- HTTP (Port 80) - If using IIS
- HTTPS (Port 443) - If using SSL
- Node.js API (Port 3001) - For direct access
- SQL Server (Port 1433) - For database access

# Outbound Rules:
- Allow all outbound traffic
- Or restrict to specific ports if needed
```

### **STEP 8: MOBILE APP GLOBAL ACCESS CONFIGURATION**

#### **8.1 Update App Configuration for Global Access**
```dart
// lib/core/config/global_server_config.dart
class GlobalServerConfig {
  // CLIENT'S PUBLIC SERVER CONFIGURATION
  // Replace with client's actual public IP address
  static const String publicIP = '203.0.113.10'; // CLIENT'S ACTUAL PUBLIC IP
  static const String serverDomain = ''; // Leave empty if no domain

  // Protocol and port configuration
  static const String protocol = 'https'; // Use HTTPS for security
  static const int httpsPort = 443; // Standard HTTPS port
  static const int apiPort = 3001; // Direct API access port

  // Environment configuration
  static const bool useDirectAPI = true; // true = use port 3001, false = use HTTPS
  static const bool isDevelopment = false; // Set to false for production

  // Automatically generated endpoints based on configuration
  static String get serverAddress {
    if (serverDomain.isNotEmpty) {
      return serverDomain; // Use domain if available
    } else {
      return publicIP; // Use public IP
    }
  }

  static String get baseUrl {
    if (useDirectAPI) {
      return 'http://$serverAddress:$apiPort/api'; // Direct API access
    } else {
      return '$protocol://$serverAddress/api'; // Through reverse proxy
    }
  }

  // API endpoints for global access
  static String get userRegisterEndpoint => '$baseUrl/customers';
  static String get userLoginEndpoint => '$baseUrl/login';
  static String get portfolioGetEndpoint => '$baseUrl/portfolio';
  static String get transactionCreateEndpoint => '$baseUrl/transactions';
  static String get transactionHistoryEndpoint => '$baseUrl/transaction-history';
  static String get transactionUpdateEndpoint => '$baseUrl/transaction-status';
  static String get healthCheckEndpoint => 'http://$serverAddress:$apiPort/health';

  // Connection testing
  static Map<String, String> get connectionInfo => {
    'server_address': serverAddress,
    'base_url': baseUrl,
    'protocol': useDirectAPI ? 'HTTP' : protocol.toUpperCase(),
    'port': useDirectAPI ? apiPort.toString() : httpsPort.toString(),
    'environment': isDevelopment ? 'Development' : 'Production',
    'access_type': 'Global Internet Access'
  };
}
```

#### **8.2 Update Server Configuration in App**
```dart
// Update lib/core/config/server_config.dart
class ServerConfig {
  // PRODUCTION CONFIGURATION FOR GLOBAL ACCESS
  static const String productionIP = '203.0.113.10'; // CLIENT'S PUBLIC IP
  static const String localIP = 'localhost'; // Keep for local development

  // Environment flag (set to false for global access)
  static const bool isDevelopment = false; // IMPORTANT: Set to false

  // Server ports
  static const int httpsPort = 443;
  static const int localPort = 3001;
  static const int globalApiPort = 3001; // Direct API access globally

  // Base URL for API calls
  static String get baseUrl {
    if (isDevelopment) {
      // Development mode - use local server
      return 'http://$localIP:$localPort/api';
    } else {
      // Production mode - use public IP for global access
      return 'http://$productionIP:$globalApiPort/api';
    }
  }

  // Headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'admin-token': 'CLIENT_ADMIN_TOKEN_2025',
    'X-Business-ID': 'VMURUGAN_001',
    'User-Agent': 'VMurugan-Mobile/1.0.0',
    'Accept': 'application/json',
  };

  // Connection status
  static Map<String, dynamic> get status => {
    'configured': true,
    'environment': isDevelopment ? 'development' : 'production',
    'base_url': baseUrl,
    'server_ip': isDevelopment ? localIP : productionIP,
    'port': isDevelopment ? localPort : globalApiPort,
    'global_access': !isDevelopment,
    'ssl_enabled': false, // Set to true when HTTPS is configured
  };
}
```

#### **8.3 Build Production APK for Global Access**
```bash
# Navigate to Flutter project directory
cd E:\Projects\vmurugan-gold-trading

# IMPORTANT: Verify configuration before building
# Check lib/core/config/server_config.dart:
# - isDevelopment = false
# - productionIP = 'CLIENT_ACTUAL_PUBLIC_IP'

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK with global access configuration
flutter build apk --release --target-platform android-arm64

# APK location: build\app\outputs\flutter-apk\app-release.apk
# This APK will connect to the public IP address globally
```

#### **8.4 Global Access Testing Checklist**
```bash
# CRITICAL: Test from DIFFERENT NETWORKS to verify global access

# Test 1: Install APK on test device
adb install build\app\outputs\flutter-apk\app-release.apk

# Test 2: Connect to DIFFERENT WiFi networks and test:
# - Home WiFi network
# - Office WiFi network
# - Mobile data (4G/5G)
# - Public WiFi (coffee shop, etc.)
# - Different ISP networks

# Test 3: Complete user flow from each network:
✅ Server connectivity (Health check)
✅ User Registration
✅ User Login with MPIN
✅ Portfolio View (empty initially)
✅ Gold Purchase Flow
✅ Silver Purchase Flow (₹126.00/gram)
✅ Transaction History
✅ Portfolio Updates
✅ Data Persistence across networks

# Test 4: International access (if applicable):
✅ Test from different countries/regions
✅ Verify latency is acceptable
✅ Check for any geo-blocking issues

# Test 5: Network troubleshooting:
# If connection fails, check:
# - Server is running: curl http://PUBLIC_IP:3001/health
# - Firewall allows port 3001: telnet PUBLIC_IP 3001
# - Router port forwarding configured
# - ISP doesn't block the port
```

---

## 🌍 **GLOBAL ACCESS VERIFICATION**

### **✅ Step-by-Step Global Access Testing**

#### **Step 1: Verify Server is Accessible Globally**
```bash
# From the server itself, test local access:
curl http://localhost:3001/health
# Expected: {"status":"OK","timestamp":"..."}

# From the server, test public IP access:
curl http://YOUR_PUBLIC_IP:3001/health
# Expected: Same response as above

# From external network, test global access:
# Use online tools or different network:
# - https://www.whatsmyip.org/port-scanner/
# - Enter your public IP and port 3001
# - Should show "Open" status
```

#### **Step 2: Test from Different Locations**
```bash
# Test from multiple external networks:

# Method 1: Use online HTTP testing tools
# - https://httpstatus.io/
# - Enter: http://YOUR_PUBLIC_IP:3001/health
# - Should return 200 OK

# Method 2: Ask friends/colleagues to test
# Send them: http://YOUR_PUBLIC_IP:3001/health
# They should see the health check response

# Method 3: Use mobile data
# Disconnect from WiFi, use mobile data
# Test the URL in mobile browser
```

#### **Step 3: Mobile App Global Testing**
```bash
# Install the production APK on test devices
# Test from different networks:

# Network 1: Home WiFi
# Network 2: Office WiFi
# Network 3: Mobile Data (4G/5G)
# Network 4: Public WiFi
# Network 5: Friend's network

# For each network, verify:
✅ App opens successfully
✅ Registration works
✅ Login works
✅ API calls succeed
✅ Data loads properly
✅ Transactions process
```

#### **Step 4: Performance Testing**
```bash
# Test response times from different locations:
# Acceptable response times:
# - Local network: < 100ms
# - Same country: < 500ms
# - International: < 2000ms

# Use tools like:
# - ping YOUR_PUBLIC_IP
# - curl -w "@curl-format.txt" http://YOUR_PUBLIC_IP:3001/health
```

### **✅ Common Global Access Issues and Solutions**

#### **Issue 1: "Connection Refused" from External Networks**
```bash
# Cause: Firewall blocking external access
# Solution:
1. Check Windows Firewall rules
2. Verify router port forwarding
3. Check ISP firewall settings
4. Test with firewall temporarily disabled

# Verification:
netstat -an | findstr :3001  # Should show 0.0.0.0:3001 LISTENING
```

#### **Issue 2: "Timeout" from Mobile App**
```bash
# Cause: Server not binding to all interfaces
# Solution: Ensure server listens on 0.0.0.0, not localhost

# In server.js, use:
app.listen(3001, '0.0.0.0', () => {
  console.log('Server listening on all interfaces');
});

# NOT:
app.listen(3001, 'localhost', () => { ... }); // This only allows local access
```

#### **Issue 3: "SSL/Certificate Errors"**
```bash
# Cause: HTTPS configuration issues
# Solution: For testing, use HTTP first, then add HTTPS

# Quick test without SSL:
# Update mobile app to use: http://YOUR_PUBLIC_IP:3001/api
# Once working, then configure HTTPS
```

#### **Issue 4: "ISP Blocking Ports"**
```bash
# Cause: Some ISPs block non-standard ports
# Solution: Use standard ports (80, 443) with reverse proxy

# Test if port is blocked:
telnet YOUR_PUBLIC_IP 3001  # From external network
# If fails, try port 80 or 443
```

---

## 🧪 **TESTING AND VALIDATION**

### **✅ Server Testing Checklist**
- [ ] Node.js server starts without errors
- [ ] SQL Server connection successful
- [ ] All API endpoints respond correctly
- [ ] Database operations work (CRUD)
- [ ] Error handling functions properly
- [ ] Logging system operational
- [ ] Performance acceptable under load

### **✅ Database Testing Checklist**
- [ ] Database created successfully
- [ ] Tables created with correct schema
- [ ] Indexes created for performance
- [ ] User permissions configured correctly
- [ ] Backup and restore procedures tested
- [ ] Data integrity constraints working
- [ ] Transaction isolation levels appropriate

### **✅ Mobile App Testing Checklist**
- [ ] App connects to server successfully
- [ ] User registration works end-to-end
- [ ] Login authentication functional
- [ ] Portfolio displays correctly
- [ ] Gold purchase flow complete
- [ ] Silver purchase flow complete
- [ ] Transaction history accurate
- [ ] Data synchronization working
- [ ] Error handling user-friendly

### **✅ Security Testing Checklist**
- [ ] SQL injection protection verified
- [ ] Input validation working
- [ ] Authentication mechanisms secure
- [ ] HTTPS encryption enabled
- [ ] Firewall rules configured
- [ ] Database access restricted
- [ ] Admin interfaces protected
- [ ] Sensitive data encrypted

---

## 🔒 **SECURITY CONFIGURATION**

### **✅ Database Security**
```sql
-- Remove unnecessary permissions
REVOKE ALL ON VMuruganGoldTrading FROM public;

-- Grant only required permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON customers TO vmurugan_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON transactions TO vmurugan_user;

-- Enable SQL Server audit
CREATE SERVER AUDIT VMurugan_Audit
TO FILE (FILEPATH = 'C:\inetpub\vmurugan-api\logs\audit\');

-- Enable database audit specification
CREATE DATABASE AUDIT SPECIFICATION VMurugan_DB_Audit
FOR SERVER AUDIT VMurugan_Audit
ADD (SELECT, INSERT, UPDATE, DELETE ON customers BY vmurugan_user),
ADD (SELECT, INSERT, UPDATE, DELETE ON transactions BY vmurugan_user);

-- Enable auditing
ALTER SERVER AUDIT VMurugan_Audit WITH (STATE = ON);
ALTER DATABASE AUDIT SPECIFICATION VMurugan_DB_Audit WITH (STATE = ON);
```

### **✅ Application Security**
```javascript
// Additional security middleware for server.js
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});

// Security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  }
}));

// Apply rate limiting to API routes
app.use('/api/', limiter);
```

### **✅ Network Security**
```bash
# Windows Firewall Advanced Configuration
# Create specific rules for:

# Allow Node.js API (Port 3001)
netsh advfirewall firewall add rule name="VMurugan API" dir=in action=allow protocol=TCP localport=3001

# Allow SQL Server (Port 1433) - Restrict to specific IPs if possible
netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433

# Block all other unnecessary ports
# Configure Windows Defender or third-party antivirus
# Enable Windows Update automatic installation
```

---

## 📊 **MONITORING AND MAINTENANCE**

### **✅ Performance Monitoring**
```javascript
// Add to server.js for basic monitoring
const os = require('os');

// Health check endpoint with system info
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cpu: os.loadavg(),
    platform: os.platform(),
    version: process.version
  });
});

// API response time logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} - ${res.statusCode} - ${duration}ms`);
  });
  next();
});
```

### **✅ Database Monitoring**
```sql
-- Create monitoring views
CREATE VIEW v_system_health AS
SELECT 
    DB_NAME() as database_name,
    (SELECT COUNT(*) FROM customers) as total_customers,
    (SELECT COUNT(*) FROM transactions) as total_transactions,
    (SELECT COUNT(*) FROM transactions WHERE status = 'SUCCESS') as successful_transactions,
    (SELECT SUM(amount) FROM transactions WHERE status = 'SUCCESS') as total_revenue,
    GETDATE() as last_updated;

-- Create performance monitoring query
SELECT 
    sqltext.TEXT,
    req.session_id,
    req.status,
    req.command,
    req.cpu_time,
    req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
WHERE req.database_id = DB_ID('VMuruganGoldTrading');
```

### **✅ Backup Strategy**
```sql
-- Full database backup (Daily)
BACKUP DATABASE VMuruganGoldTrading 
TO DISK = 'C:\inetpub\vmurugan-api\backups\VMuruganGoldTrading_Full.bak'
WITH FORMAT, INIT, COMPRESSION;

-- Transaction log backup (Every 15 minutes)
BACKUP LOG VMuruganGoldTrading 
TO DISK = 'C:\inetpub\vmurugan-api\backups\VMuruganGoldTrading_Log.trn'
WITH COMPRESSION;

-- Create backup maintenance plan
-- Use SQL Server Agent to schedule automated backups
```

### **✅ Log Management**
```bash
# Create log rotation script (PowerShell)
# Save as: rotate-logs.ps1

$LogPath = "C:\inetpub\vmurugan-api\logs"
$MaxAge = 30 # days
$MaxSize = 100MB

# Rotate application logs
Get-ChildItem $LogPath -Filter "*.log" | 
Where-Object { $_.Length -gt $MaxSize -or $_.LastWriteTime -lt (Get-Date).AddDays(-$MaxAge) } |
ForEach-Object {
    $NewName = $_.Name + "." + (Get-Date -Format "yyyyMMdd")
    Rename-Item $_.FullName $NewName
    Compress-Archive -Path ($LogPath + "\" + $NewName) -DestinationPath ($LogPath + "\" + $NewName + ".zip")
    Remove-Item ($LogPath + "\" + $NewName)
}

# Schedule this script to run daily via Task Scheduler
```

---

## 🚨 **TROUBLESHOOTING GUIDE**

### **Common Issues and Solutions**

#### **Issue: "Cannot connect to SQL Server"**
```bash
# Check SQL Server service status
services.msc → SQL Server (MSSQLSERVER) → Status: Running

# Check TCP/IP protocol
SQL Server Configuration Manager → SQL Server Network Configuration → Protocols → TCP/IP: Enabled

# Check firewall
Windows Firewall → Allow an app → SQL Server: Checked

# Test connection
sqlcmd -S localhost -U vmurugan_user -P ClientSecurePassword123!
```

#### **Issue: "Node.js server won't start"**
```bash
# Check Node.js installation
node --version
npm --version

# Check dependencies
cd C:\inetpub\vmurugan-api\sql_server_api
npm install

# Check .env file
type .env

# Check port availability
netstat -an | findstr :3001

# Start with verbose logging
node server.js --verbose
```

#### **Issue: "Mobile app can't connect"**
```bash
# Check server is running
curl http://server-ip:3001/health

# Check firewall allows port 3001
telnet server-ip 3001

# Check mobile app configuration
# Verify serverDomain and serverPort in client_server_config.dart

# Check network connectivity
ping server-ip
```

#### **Issue: "Database operations fail"**
```sql
-- Check user permissions
USE VMuruganGoldTrading;
SELECT 
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    o.name AS object_name,
    p.permission_name,
    p.state_desc AS permission_state
FROM sys.database_permissions p
LEFT JOIN sys.objects o ON p.major_id = o.object_id
LEFT JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.name = 'vmurugan_user';

-- Check table existence
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;

-- Check data integrity
DBCC CHECKDB('VMuruganGoldTrading');
```

#### **Issue: "Performance problems"**
```sql
-- Check database performance
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    COUNT(*) AS QueriesExecuted,
    SUM(total_worker_time) AS TotalCPUTime,
    SUM(total_elapsed_time) AS TotalElapsedTime,
    AVG(total_elapsed_time) AS AvgElapsedTime
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE DB_NAME(st.dbid) = 'VMuruganGoldTrading'
GROUP BY database_id;

-- Check index usage
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1;
```

---

## 📞 **SUPPORT AND MAINTENANCE**

### **✅ Support Contacts**
- **Technical Support**: [Your Contact Information]
- **Emergency Support**: [24/7 Contact if available]
- **Documentation**: [Link to online documentation]
- **Updates**: [How to get updates and patches]

### **✅ Maintenance Schedule**
| Task | Frequency | Description |
|------|-----------|-------------|
| **Database Backup** | Daily | Full backup at 2 AM |
| **Log Rotation** | Daily | Archive logs older than 30 days |
| **Security Updates** | Monthly | Windows and SQL Server updates |
| **Performance Review** | Monthly | Check system performance metrics |
| **Health Check** | Weekly | Verify all services running |
| **Backup Verification** | Weekly | Test backup restore procedure |

### **✅ Emergency Procedures**
```bash
# Server Down
1. Check Windows services (SQL Server, PM2)
2. Check event logs for errors
3. Restart services if needed
4. Contact support if issues persist

# Database Issues
1. Check SQL Server service status
2. Review SQL Server error logs
3. Run DBCC CHECKDB for corruption
4. Restore from backup if necessary

# Application Issues
1. Check PM2 process status: pm2 status
2. Review application logs: pm2 logs
3. Restart application: pm2 restart vmurugan-api
4. Check .env configuration

# Network Issues
1. Check firewall settings
2. Verify port accessibility
3. Test DNS resolution
4. Check SSL certificate validity
```

---

## ✅ **DEPLOYMENT COMPLETION CHECKLIST**

### **✅ Pre-Deployment**
- [ ] Client server meets hardware requirements
- [ ] All required software installed
- [ ] Network configuration completed
- [ ] SSL certificate obtained (if using HTTPS)
- [ ] Backup strategy planned

### **✅ Deployment**
- [ ] Application files uploaded
- [ ] Database created and configured
- [ ] Environment variables set
- [ ] Dependencies installed
- [ ] Database schema updated
- [ ] Initial testing completed

### **✅ Production Setup**
- [ ] Process manager configured (PM2 or Windows Service)
- [ ] Firewall rules configured
- [ ] SSL certificate installed
- [ ] Monitoring tools configured
- [ ] Backup procedures implemented
- [ ] Log rotation configured

### **✅ Testing**
- [ ] Server health check passes
- [ ] Database connectivity verified
- [ ] All API endpoints functional
- [ ] Mobile app connects successfully
- [ ] End-to-end user flow tested
- [ ] Performance testing completed

### **✅ Documentation**
- [ ] Server configuration documented
- [ ] Database credentials secured
- [ ] Admin procedures documented
- [ ] Troubleshooting guide provided
- [ ] Support contacts established
- [ ] Maintenance schedule created

### **✅ Handover**
- [ ] Client training completed
- [ ] Admin access provided
- [ ] Documentation delivered
- [ ] Support procedures explained
- [ ] Emergency contacts shared
- [ ] Go-live approval obtained

---

## 🎉 **DEPLOYMENT COMPLETE**

Upon successful completion of this deployment guide, the client will have:

### **✅ Complete Infrastructure**
- **Self-hosted Node.js API server** running on their infrastructure
- **Microsoft SQL Server database** with all user and transaction data
- **Mobile application** connecting directly to their server
- **Full data ownership** and control

### **✅ Business Capabilities**
- **User registration and authentication** system
- **Gold and silver trading** platform
- **Portfolio management** and tracking
- **Transaction history** and reporting
- **Real-time price integration** (MJDTA silver prices)

### **✅ Technical Features**
- **Scalable architecture** that can grow with business
- **Secure data storage** with encryption and access controls
- **Automated backups** and disaster recovery
- **Performance monitoring** and alerting
- **Professional support** and maintenance procedures

### **✅ Ongoing Support**
- **Technical documentation** for system administration
- **Troubleshooting guides** for common issues
- **Maintenance procedures** for ongoing operations
- **Update and upgrade** pathways
- **Professional support** contacts and procedures

**The V Murugan Gold Trading platform is now successfully deployed and ready for production use! 🚀**

---

*Document Version: 1.0*  
*Last Updated: [Current Date]*  
*Prepared by: [Your Name/Company]*  
*Client: V Murugan Gold Trading*
