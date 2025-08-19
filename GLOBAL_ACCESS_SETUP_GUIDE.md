# 🌍 VMurugan Gold Trading - Global Access Setup Guide

## 📋 **OVERVIEW**
This guide configures the VMurugan Gold Trading app for **worldwide access** using the client's existing **public static IP address**.

---

## 🎯 **PREREQUISITES**
- ✅ **Client has public static IP address** (e.g., 203.0.113.10)
- ✅ **Windows Server with Node.js installed**
- ✅ **SQL Server database configured**
- ✅ **VMurugan API server deployed**

---

## 🚀 **STEP-BY-STEP GLOBAL ACCESS CONFIGURATION**

### **STEP 1: Configure Server for Global Access**

#### **1.1 Update Server Binding**
```javascript
// In sql_server_api/server.js
// CRITICAL: Change from localhost to 0.0.0.0 for global access

// OLD (Local only):
app.listen(3001, 'localhost', () => {
  console.log('Server running locally only');
});

// NEW (Global access):
app.listen(3001, '0.0.0.0', () => {
  console.log('🌍 Server running with GLOBAL ACCESS on port 3001');
  console.log('🔗 Accessible from: http://YOUR_PUBLIC_IP:3001');
});
```

#### **1.2 Configure Windows Firewall**
```powershell
# Run as Administrator in PowerShell
# Allow global access to API port
New-NetFirewallRule -DisplayName "VMurugan API Global Access" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow -RemoteAddress Any

# Verify firewall rule
Get-NetFirewallRule -DisplayName "VMurugan API Global Access"
```

#### **1.3 Configure Router Port Forwarding (If Behind NAT)**
```bash
# Access router admin panel (usually 192.168.1.1 or 192.168.0.1)
# Add port forwarding rule:
External Port: 3001 → Internal IP: [SERVER_LOCAL_IP]:3001

# Example:
# External: 3001 → Internal: 192.168.1.100:3001
```

### **STEP 2: Update Mobile App Configuration**

#### **2.1 Configure Global Access Settings**
```dart
// Update lib/core/config/server_config.dart

class ServerConfig {
  // REPLACE WITH CLIENT'S ACTUAL PUBLIC IP
  static const String publicIP = '203.0.113.10'; // ← CLIENT'S REAL IP HERE
  
  // Set to false for global access
  static const bool isDevelopment = false; // ← IMPORTANT: Set to false
  
  // Global API port
  static const int globalApiPort = 3001;
  
  // Base URL for global access
  static String get baseUrl {
    if (isDevelopment) {
      return 'http://localhost:3000/api'; // Local development
    } else {
      return 'http://$publicIP:$globalApiPort/api'; // Global access
    }
  }
}
```

#### **2.2 Build Production APK**
```bash
# Navigate to Flutter project
cd E:\Projects\vmurugan-gold-trading

# VERIFY CONFIGURATION FIRST:
# Check lib/core/config/server_config.dart:
# - publicIP = 'CLIENT_ACTUAL_IP'
# - isDevelopment = false

# Clean and build
flutter clean
flutter pub get
flutter build apk --release

# APK location: build\app\outputs\flutter-apk\app-release.apk
```

### **STEP 3: Test Global Access**

#### **3.1 Server Connectivity Test**
```bash
# From server itself:
curl http://localhost:3001/health
# Expected: {"status":"OK",...}

# From server using public IP:
curl http://YOUR_PUBLIC_IP:3001/health
# Expected: Same response

# From external network:
# Use browser or curl from different network:
# http://YOUR_PUBLIC_IP:3001/health
```

#### **3.2 Mobile App Testing**
```bash
# Install production APK on test device
adb install build\app\outputs\flutter-apk\app-release.apk

# Test from different networks:
# 1. Home WiFi
# 2. Mobile data (4G/5G)
# 3. Office WiFi
# 4. Public WiFi

# Verify for each network:
✅ App opens
✅ Registration works
✅ Login works
✅ Portfolio loads
✅ Transactions work
```

---

## 🔧 **TROUBLESHOOTING GLOBAL ACCESS**

### **Issue 1: "Connection Refused"**
```bash
# Check if server is listening on all interfaces:
netstat -an | findstr :3001
# Should show: 0.0.0.0:3001 LISTENING (not 127.0.0.1:3001)

# If shows 127.0.0.1:3001, update server.js:
app.listen(3001, '0.0.0.0', callback);
```

### **Issue 2: "Timeout from External Networks"**
```bash
# Check Windows Firewall:
Get-NetFirewallRule -DisplayName "*3001*"

# Check router port forwarding:
# Ensure external port 3001 → internal server IP:3001

# Test port accessibility:
# Use online port checker: https://www.yougetsignal.com/tools/open-ports/
# Enter your public IP and port 3001
```

### **Issue 3: "App Can't Connect"**
```bash
# Verify mobile app configuration:
# Check lib/core/config/server_config.dart:
# - publicIP matches client's actual IP
# - isDevelopment = false
# - globalApiPort = 3001

# Rebuild APK after configuration changes:
flutter clean && flutter build apk --release
```

---

## ✅ **GLOBAL ACCESS VERIFICATION CHECKLIST**

### **Server Configuration**
- [ ] Server listens on 0.0.0.0:3001 (not localhost)
- [ ] Windows Firewall allows port 3001 globally
- [ ] Router port forwarding configured (if applicable)
- [ ] Health check accessible: http://PUBLIC_IP:3001/health

### **Mobile App Configuration**
- [ ] publicIP set to client's actual IP address
- [ ] isDevelopment = false
- [ ] Production APK built with correct configuration
- [ ] APK tested from multiple networks

### **Global Access Testing**
- [ ] Server accessible from external networks
- [ ] Mobile app connects from different WiFi networks
- [ ] Mobile app connects from mobile data
- [ ] All app features work globally
- [ ] Performance acceptable from different locations

---

## 🎉 **SUCCESS CONFIRMATION**

When global access is working correctly:

1. **Server Status**: `http://YOUR_PUBLIC_IP:3001/health` returns success from any network
2. **Mobile App**: Works from any WiFi/mobile data connection worldwide
3. **All Features**: Registration, login, trading, portfolio work globally
4. **Performance**: Response times under 2 seconds from most locations

**Your VMurugan Gold Trading app is now accessible worldwide! 🌍**

---

## 📞 **SUPPORT**

If you encounter issues:
1. Check this troubleshooting guide
2. Verify all configuration steps
3. Test from multiple networks
4. Contact technical support with specific error messages

*Document Version: 1.0*
*For VMurugan Gold Trading Global Access Setup*
