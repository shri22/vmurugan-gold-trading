# 🚀 VMurugan Gold Trading - Windows Server Deployment Checklist

## 📋 **Pre-Deployment Requirements**

### **Windows Server Requirements**
- [ ] Windows Server 2016/2019/2022 or Windows 10/11
- [ ] Administrator access
- [ ] Public IP address assigned
- [ ] Internet connectivity
- [ ] At least 2GB RAM, 20GB disk space

### **Current Setup Verification**
- [ ] SQL Server is running on `192.168.1.18:1433`
- [ ] Database `VMuruganGoldTrading` exists
- [ ] User `DakData` with password `Test@123` works
- [ ] Node.js APIs work locally on `192.168.1.18:3001`

## 🚀 **Deployment Steps**

### **Step 1: Prepare Windows Server**
```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to project directory
cd E:\Projects\vmurugan-gold-trading\deployment

# 3. Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Run deployment script
.\windows-deploy.ps1
```

**What the script does:**
- ✅ Installs Node.js and PM2
- ✅ Creates application directories
- ✅ Configures Windows Firewall
- ✅ Sets up environment files
- ✅ Tests SQL Server connection
- ✅ Creates startup scripts

### **Step 2: Copy Application Files**
```powershell
# Copy SQL Server API
Copy-Item -Path "E:\Projects\vmurugan-gold-trading\sql_server_api\*" -Destination "C:\VMuruganAPI\sql_server_api\" -Recurse -Force

# Copy Main Server
Copy-Item -Path "E:\Projects\vmurugan-gold-trading\server\*" -Destination "C:\VMuruganAPI\server\" -Recurse -Force

# Copy deployment scripts
Copy-Item -Path "E:\Projects\vmurugan-gold-trading\deployment\start-production.bat" -Destination "C:\VMuruganAPI\" -Force
Copy-Item -Path "E:\Projects\vmurugan-gold-trading\deployment\stop-production.bat" -Destination "C:\VMuruganAPI\" -Force
```

### **Step 3: Configure SQL Server Connection**
Edit `C:\VMuruganAPI\sql_server_api\.env`:
```env
# Choose one option:

# Option A: SQL Server on same Windows Server
SQL_SERVER=localhost

# Option B: SQL Server on your current machine (recommended)
SQL_SERVER=192.168.1.18

# Option C: SQL Server on different network machine
SQL_SERVER=YOUR_SQL_SERVER_IP
```

### **Step 4: Start Production Services**
```cmd
# Run as Administrator
C:\VMuruganAPI\start-production.bat
```

### **Step 5: Test Deployment**
```cmd
# Test SQL Server API
curl http://localhost:3001/api/health
curl http://YOUR_PUBLIC_IP:3001/api/health

# Test Main Server
curl http://localhost:3000/health
curl http://YOUR_PUBLIC_IP:3000/health

# Test SQL connection
curl http://YOUR_PUBLIC_IP:3001/api/test-connection
```

## 📱 **Update Flutter App**

### **Step 6: Update Configuration Files**
Replace `YOUR_WINDOWS_SERVER_PUBLIC_IP` with your actual public IP in:

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

### **Step 7: Build Production APK**
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or build debug APK for testing
flutter build apk --debug
```

## 🌐 **Public Access Configuration**

### **Your APIs will be accessible at:**
- **SQL Server API**: `http://YOUR_PUBLIC_IP:3001/api/`
- **Main Server**: `http://YOUR_PUBLIC_IP:3000/`
- **Health Check**: `http://YOUR_PUBLIC_IP:3001/api/health`
- **SQL Test**: `http://YOUR_PUBLIC_IP:3001/api/test-connection`

### **Flutter App Endpoints:**
- **Customer API**: `http://YOUR_PUBLIC_IP:3001/api/customers/`
- **Transaction API**: `http://YOUR_PUBLIC_IP:3001/api/transactions/`
- **Authentication**: `http://YOUR_PUBLIC_IP:3001/api/auth/`

## 🔧 **Management Commands**

### **Service Management**
```cmd
# Start all services
pm2 start all

# Stop all services
pm2 stop all

# Restart all services
pm2 restart all

# View service status
pm2 status

# View logs
pm2 logs

# View specific service logs
pm2 logs vmurugan-sql-api
pm2 logs vmurugan-main-api
```

### **Quick Scripts**
- **Start**: `C:\VMuruganAPI\start-production.bat`
- **Stop**: `C:\VMuruganAPI\stop-production.bat`

## 🔒 **Security Checklist**

- [ ] Windows Firewall configured (ports 3000, 3001, 80, 443)
- [ ] SQL Server authentication secured
- [ ] Strong passwords used
- [ ] Admin tokens configured
- [ ] CORS origins configured
- [ ] Regular Windows Updates enabled

## 📊 **Monitoring & Maintenance**

### **Daily Checks**
- [ ] Services are running: `pm2 status`
- [ ] APIs responding: Test health endpoints
- [ ] SQL Server accessible: Test database connection
- [ ] Disk space available: Check C:\ drive

### **Weekly Maintenance**
- [ ] Review PM2 logs for errors
- [ ] Check Windows Event Viewer
- [ ] Monitor server performance
- [ ] Backup database

## 🆘 **Troubleshooting**

### **APIs Not Starting**
```cmd
# Check PM2 logs
pm2 logs

# Restart services
pm2 restart all

# Check if ports are in use
netstat -ano | findstr :3001
netstat -ano | findstr :3000
```

### **SQL Connection Issues**
```cmd
# Test SQL Server connection
sqlcmd -S localhost -U DakData -P Test@123 -Q "SELECT @@VERSION"

# Check SQL Server service
sc query MSSQLSERVER
```

### **Network Issues**
```cmd
# Test from external network
curl http://YOUR_PUBLIC_IP:3001/api/health

# Check firewall rules
Get-NetFirewallRule -DisplayName "*VMurugan*"
```

## ✅ **Success Criteria**

Your deployment is successful when:
- [ ] Both APIs respond to health checks
- [ ] SQL Server connection test passes
- [ ] APIs accessible from external network
- [ ] Flutter app connects successfully
- [ ] Customer registration/login works
- [ ] Transaction APIs function properly

## 📞 **Support Information**

### **Log Locations**
- PM2 Logs: `C:\Users\%USERNAME%\.pm2\logs\`
- Application Logs: `C:\VMuruganAPI\logs\`
- Windows Event Logs: Event Viewer → Application

### **Configuration Files**
- SQL API Config: `C:\VMuruganAPI\sql_server_api\.env`
- Main Server Config: `C:\VMuruganAPI\server\.env`
- PM2 Config: `C:\Users\%USERNAME%\.pm2\`

### **Important URLs**
- Health Check: `http://YOUR_PUBLIC_IP:3001/api/health`
- SQL Test: `http://YOUR_PUBLIC_IP:3001/api/test-connection`
- Customer API: `http://YOUR_PUBLIC_IP:3001/api/customers/`

**🎉 Once completed, your VMurugan Gold Trading APIs will be publicly accessible and ready for production use!**
