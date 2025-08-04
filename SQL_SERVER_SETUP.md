# SQL Server (SSMS) Setup Guide

## Overview

Your Flutter app is now configured to connect to your local SQL Server database! This guide will help you set up the connection between your APK and SQL Server Management Studio (SSMS).

## 📋 Required Information from You

Please provide the following details to complete the setup:

### 1. **SQL Server Connection Details**
- **Server Name/IP Address**: 
  - For local: `localhost` or `127.0.0.1`
  - For network: Your computer's IP address (e.g., `192.168.1.100`)
- **Port Number**: Usually `1433` (default)
- **Instance Name**: If using named instance (e.g., `SQLEXPRESS`)

### 2. **Database Authentication**
Choose one:
- **Windows Authentication** (recommended for local)
- **SQL Server Authentication** (username/password)

### 3. **Database Credentials** (if using SQL Authentication)
- **Username**: Your SQL Server login
- **Password**: Your SQL Server password

### 4. **Network Information**
- **Your Computer's IP Address**: For APK to connect from phone

## 🔧 SQL Server Configuration Steps

### Step 1: Enable TCP/IP Protocol

1. **Open SQL Server Configuration Manager**
   - Search "SQL Server Configuration Manager" in Windows
   - Or find it in: `Start Menu > Microsoft SQL Server > Configuration Tools`

2. **Enable TCP/IP**
   - Go to: `SQL Server Network Configuration > Protocols for [Instance]`
   - Right-click `TCP/IP` → `Enable`
   - Double-click `TCP/IP` → `IP Addresses` tab
   - Set `TCP Port` to `1433` for all IP addresses
   - Click `OK`

3. **Restart SQL Server Service**
   - Go to: `SQL Server Services`
   - Right-click `SQL Server ([Instance])` → `Restart`

### Step 2: Enable SQL Server Authentication (if needed)

1. **Open SQL Server Management Studio (SSMS)**
2. **Connect to your SQL Server instance**
3. **Right-click server name → Properties**
4. **Go to Security page**
5. **Select "SQL Server and Windows Authentication mode"**
6. **Click OK and restart SQL Server service**

### Step 3: Create SQL Server Login (if using SQL Auth)

1. **In SSMS, expand Security → Logins**
2. **Right-click Logins → New Login**
3. **Enter Login name** (e.g., `vmurugan_user`)
4. **Select "SQL Server authentication"**
5. **Enter password**
6. **Uncheck "Enforce password policy" for testing**
7. **Go to Server Roles → Check "sysadmin"** (for full access)
8. **Click OK**

### Step 4: Configure Windows Firewall

1. **Open Windows Defender Firewall**
2. **Click "Advanced settings"**
3. **Click "Inbound Rules" → "New Rule"**
4. **Select "Port" → Next**
5. **Select "TCP" → Enter port `1433`**
6. **Allow the connection**
7. **Apply to all profiles**
8. **Name it "SQL Server Port 1433"**

### Step 5: Find Your Computer's IP Address

**For Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" (usually starts with 192.168.x.x)

**For connecting from phone:**
- Both your computer and phone must be on the same WiFi network
- Use the IPv4 address from above

## ⚙️ Flutter App Configuration

### Step 1: Update Configuration File

Edit `lib/core/config/sql_server_config.dart`:

```dart
class SqlServerConfig {
  // Replace with your actual details
  static const String serverIP = '192.168.1.100'; // Your computer's IP
  static const int port = 1433;
  static const String databaseName = 'VMuruganGoldTrading';
  static const String username = 'vmurugan_user'; // Your SQL username
  static const String password = 'your_password'; // Your SQL password
  static const String instanceName = ''; // Leave empty for default, or 'SQLEXPRESS'
}
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Build and Test

```bash
flutter build apk
```

## 🧪 Testing the Connection

### Option 1: Use Test Page

Add this to your app to test the connection:

```dart
import 'package:flutter/material.dart';
import 'lib/features/testing/sql_server_test_page.dart';

// Add this button somewhere in your app
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SqlServerTestPage()),
    );
  },
  child: Text('Test SQL Server'),
)
```

### Option 2: Test from SSMS

1. **Open SSMS**
2. **Connect to your SQL Server**
3. **Run this query to test:**
```sql
SELECT @@VERSION as ServerVersion, GETDATE() as CurrentTime
```

## 📊 Database Schema

The app will automatically create these tables:

- **customers** - Customer information and statistics
- **transactions** - All buy/sell transactions  
- **schemes** - Investment schemes
- **analytics** - App usage analytics

## 🔍 Common Connection Strings

### For Default Instance:
```
Server=192.168.1.100,1433;Database=VMuruganGoldTrading;User Id=username;Password=password;TrustServerCertificate=true;
```

### For Named Instance (e.g., SQLEXPRESS):
```
Server=192.168.1.100\SQLEXPRESS,1433;Database=VMuruganGoldTrading;User Id=username;Password=password;TrustServerCertificate=true;
```

### For Windows Authentication:
```
Server=192.168.1.100,1433;Database=VMuruganGoldTrading;Trusted_Connection=true;TrustServerCertificate=true;
```

## 🚨 Troubleshooting

### Connection Issues

**"Cannot connect to server"**
- Check if SQL Server service is running
- Verify TCP/IP is enabled
- Check firewall settings
- Ensure correct IP address and port

**"Login failed"**
- Verify username and password
- Check if SQL Server authentication is enabled
- Ensure user has proper permissions

**"Network-related error"**
- Check if both devices are on same WiFi
- Verify firewall allows port 1433
- Try telnet test: `telnet YOUR_IP 1433`

### Network Issues

**"Timeout expired"**
- Check network connectivity
- Verify SQL Server is listening on correct port
- Try connecting from another computer first

**"Server not found"**
- Double-check IP address
- Ensure SQL Server Browser service is running (for named instances)
- Try using computer name instead of IP

## ✅ Verification Checklist

- [ ] SQL Server TCP/IP protocol enabled
- [ ] SQL Server service running
- [ ] Firewall configured (port 1433 open)
- [ ] SQL Server authentication enabled (if using SQL auth)
- [ ] User account created with proper permissions
- [ ] Flutter app configuration updated
- [ ] Both devices on same WiFi network
- [ ] Connection test successful

## 🎯 Benefits of SQL Server

- **Enterprise-grade database**
- **High performance and scalability**
- **Advanced SQL features**
- **Built-in backup and recovery**
- **Professional management tools (SSMS)**
- **Reporting and analytics capabilities**
- **ACID compliance**
- **Concurrent user support**

## 📞 Next Steps

1. **Provide your SQL Server details** using the format above
2. **I'll update the configuration** with your specific settings
3. **Test the connection** using the test page
4. **Build and deploy your APK**
5. **Verify data is being saved** in SSMS

## 📝 Example Configuration

Here's an example of what your configuration might look like:

```dart
// Example configuration
static const String serverIP = '192.168.1.105';
static const int port = 1433;
static const String databaseName = 'VMuruganGoldTrading';
static const String username = 'vmurugan_admin';
static const String password = 'SecurePassword123';
static const String instanceName = ''; // Default instance
```

Once you provide your SQL Server details, I'll update the configuration and your app will be ready to save data directly to your SQL Server database! 🚀
