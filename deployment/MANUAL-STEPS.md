# 🚀 VMurugan API - Manual Windows Server Deployment

## 📋 **Step-by-Step Manual Deployment**

Since the automated scripts are having issues, here's the complete manual process:

### **Step 1: Install Node.js**

1. **Download Node.js**:
   - Go to [https://nodejs.org](https://nodejs.org)
   - Download **LTS version** (recommended)
   - Install with default settings

2. **Verify Installation**:
   ```cmd
   # Open Command Prompt and run:
   node --version
   npm --version
   ```

### **Step 2: Install PM2 (Process Manager)**

```cmd
# Open Command Prompt as Administrator and run:
npm install -g pm2
npm install -g pm2-windows-startup
pm2-startup install
```

### **Step 3: Create Application Directories**

```cmd
# Create main directory
mkdir C:\VMuruganAPI
mkdir C:\VMuruganAPI\sql_server_api
mkdir C:\VMuruganAPI\server
mkdir C:\VMuruganAPI\logs
```

### **Step 4: Configure Windows Firewall**

```cmd
# Run these commands as Administrator:
netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001
netsh advfirewall firewall add rule name="VMurugan Main API" dir=in action=allow protocol=TCP localport=3000
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443
```

### **Step 5: Copy Application Files**

**Copy your project files to the server:**

1. **SQL Server API**:
   - Copy everything from `E:\Projects\vmurugan-gold-trading\sql_server_api\*`
   - To: `C:\VMuruganAPI\sql_server_api\`

2. **Main Server**:
   - Copy everything from `E:\Projects\vmurugan-gold-trading\server\*`
   - To: `C:\VMuruganAPI\server\`

**Using Command Prompt:**
```cmd
# If copying from the same machine:
xcopy /E /I "E:\Projects\vmurugan-gold-trading\sql_server_api" "C:\VMuruganAPI\sql_server_api"
xcopy /E /I "E:\Projects\vmurugan-gold-trading\server" "C:\VMuruganAPI\server"
```

### **Step 6: Create Environment Files**

#### **6.1 SQL Server API Environment**
Create file: `C:\VMuruganAPI\sql_server_api\.env`

```env
# VMurugan SQL Server API - Production Configuration
PORT=3001
NODE_ENV=production
HOST=0.0.0.0

# SQL Server Configuration
SQL_SERVER=192.168.1.18
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=DakData
SQL_PASSWORD=Test@123
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true
SQL_CONNECTION_TIMEOUT=30000
SQL_REQUEST_TIMEOUT=30000

# Security Configuration
ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_production_jwt_secret_2025_secure_key

# CORS Configuration
ALLOWED_ORIGINS=*

# Business Configuration
BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMurugan Gold Trading

# Logging
LOG_LEVEL=info
LOG_FILE=C:\VMuruganAPI\logs\sql-api.log
```

#### **6.2 Main Server Environment**
Create file: `C:\VMuruganAPI\server\.env`

```env
# VMurugan Main Server - Production Configuration
PORT=3000
NODE_ENV=production
HOST=0.0.0.0

# Security Configuration
ADMIN_TOKEN=VMURUGAN_MAIN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_main_production_jwt_secret_2025

# CORS Configuration
ALLOWED_ORIGINS=*

# Logging
LOG_LEVEL=info
LOG_FILE=C:\VMuruganAPI\logs\main-server.log
```

### **Step 7: Install Dependencies**

```cmd
# Install SQL Server API dependencies
cd C:\VMuruganAPI\sql_server_api
npm install --production

# Install Main Server dependencies
cd C:\VMuruganAPI\server
npm install --production
```

### **Step 8: Start the APIs**

```cmd
# Start SQL Server API
cd C:\VMuruganAPI\sql_server_api
pm2 start server.js --name "vmurugan-sql-api"

# Start Main Server
cd C:\VMuruganAPI\server
pm2 start server.js --name "vmurugan-main-api"

# Save PM2 configuration
pm2 save
```

### **Step 9: Test the Deployment**

```cmd
# Check PM2 status
pm2 status

# Test APIs locally
curl http://localhost:3001/api/health
curl http://localhost:3000/health

# Test SQL Server connection
curl http://localhost:3001/api/test-connection
```

### **Step 10: Test Public Access**

Replace `YOUR_PUBLIC_IP` with your actual Windows Server public IP:

```cmd
# Test from external network
curl http://YOUR_PUBLIC_IP:3001/api/health
curl http://YOUR_PUBLIC_IP:3000/health
```

## 🔧 **Management Commands**

### **Check Status**
```cmd
pm2 status
pm2 logs
```

### **Start Services**
```cmd
pm2 start all
```

### **Stop Services**
```cmd
pm2 stop all
```

### **Restart Services**
```cmd
pm2 restart all
```

### **View Logs**
```cmd
# All logs
pm2 logs

# Specific service logs
pm2 logs vmurugan-sql-api
pm2 logs vmurugan-main-api
```

## 📱 **Update Flutter App**

After successful deployment, update your Flutter app configuration:

### **Update Configuration Files**

Replace `YOUR_WINDOWS_SERVER_PUBLIC_IP` with your actual public IP in these files:

1. **lib/core/config/sql_server_config.dart**:
```dart
static const String serverIP = 'YOUR_ACTUAL_PUBLIC_IP';
```

2. **lib/core/config/client_server_config.dart**:
```dart
static const String serverDomain = 'YOUR_ACTUAL_PUBLIC_IP';
```

3. **lib/core/config/server_config.dart**:
```dart
static const String localIP = 'YOUR_ACTUAL_PUBLIC_IP';
```

### **Build Production APK**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## 🌐 **Your APIs Will Be Accessible At**

- **SQL Server API**: `http://YOUR_PUBLIC_IP:3001/api/`
- **Main Server**: `http://YOUR_PUBLIC_IP:3000/`
- **Health Checks**: 
  - `http://YOUR_PUBLIC_IP:3001/api/health`
  - `http://YOUR_PUBLIC_IP:3000/health`
- **SQL Test**: `http://YOUR_PUBLIC_IP:3001/api/test-connection`

## 🆘 **Troubleshooting**

### **APIs Not Starting**
```cmd
# Check logs for errors
pm2 logs

# Check if ports are in use
netstat -ano | findstr :3001
netstat -ano | findstr :3000

# Restart services
pm2 restart all
```

### **SQL Connection Issues**
```cmd
# Test SQL Server connection manually
sqlcmd -S 192.168.1.18,1433 -U DakData -P Test@123 -Q "SELECT @@VERSION"

# Check if SQL Server is running
sc query MSSQLSERVER
```

### **Network Access Issues**
- Check Windows Firewall settings
- Verify public IP is correct
- Test from external network
- Check router/ISP firewall settings

## ✅ **Success Criteria**

Your deployment is successful when:
- [ ] `pm2 status` shows both services running
- [ ] `http://localhost:3001/api/health` returns OK
- [ ] `http://localhost:3000/health` returns OK
- [ ] `http://YOUR_PUBLIC_IP:3001/api/health` accessible externally
- [ ] Flutter app can connect and authenticate

**This manual process should work perfectly without any script issues!**
