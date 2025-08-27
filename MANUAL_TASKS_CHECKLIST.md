# ✅ VMurugan Gold Trading - Manual Tasks Checklist

## 🎯 **AFTER RUNNING complete_setup.bat**

The automated script has done most of the work, but you need to complete these manual tasks:

---

## 🔧 **MANUAL TASK 1: Configure SQL Server Password**

### **What to do:**
1. Open file: `C:\VMuruganAPI\sql_server_api\.env`
2. Find line: `SQL_PASSWORD=CHANGE_THIS_PASSWORD`
3. Replace with your actual SQL Server password

### **Options:**

#### **Option A: Use SA Account**
```env
SQL_USERNAME=sa
SQL_PASSWORD=YourActualSAPassword
```

#### **Option B: Use New User (Recommended)**
```env
SQL_USERNAME=vmurugan_user
SQL_PASSWORD=VMurugan@2025!
```

### **✅ How to verify:**
- Save the file
- The password should match your SQL Server setup

---

## 🔐 **MANUAL TASK 2: Enable SQL Server Authentication**

### **What to do:**
1. **Open SQL Server Management Studio (SSMS)**
2. **Connect to your SQL Server instance**
3. **Right-click on server name** → Select **"Properties"**
4. **Go to "Security" tab**
5. **Select "SQL Server and Windows Authentication mode"**
6. **Click "OK"**
7. **Restart SQL Server service**

### **How to restart SQL Server service:**
```bash
# Run as Administrator
net stop MSSQLSERVER
net start MSSQLSERVER

# OR for SQL Express
net stop "MSSQL$SQLEXPRESS"
net start "MSSQL$SQLEXPRESS"
```

### **✅ How to verify:**
- You should be able to login with SQL Server credentials
- Test: `sqlcmd -S localhost -U sa -P YourPassword`

---

## 🌐 **MANUAL TASK 3: Enable TCP/IP Protocol**

### **What to do:**
1. **Open SQL Server Configuration Manager**
   - Search for "SQL Server Configuration Manager" in Start menu
2. **Expand "SQL Server Network Configuration"**
3. **Click "Protocols for [Your Instance Name]"**
4. **Right-click "TCP/IP"** → Select **"Enable"**
5. **Right-click "TCP/IP"** → Select **"Properties"**
6. **Go to "IP Addresses" tab**
7. **Scroll to bottom and find "IPAll" section**
8. **Set "TCP Port" to 1433**
9. **Clear "TCP Dynamic Ports" (leave empty)**
10. **Click "OK"**
11. **Restart SQL Server service**

### **✅ How to verify:**
- Check if port 1433 is listening: `netstat -an | findstr :1433`

---

## 🗄️ **MANUAL TASK 4: Create Database and Tables**

### **What to do:**
1. **Open SQL Server Management Studio (SSMS)**
2. **Connect to your SQL Server**
3. **Open the file: `sql_server_setup.sql`**
4. **Execute the entire script** (F5 or click Execute)

### **What this script does:**
- ✅ Creates `VMuruganGoldTrading` database
- ✅ Creates `vmurugan_user` with password `VMurugan@2025!`
- ✅ Creates `customers` and `transactions` tables
- ✅ Creates indexes for performance
- ✅ Inserts test data
- ✅ Creates views and stored procedures

### **✅ How to verify:**
- Database `VMuruganGoldTrading` should appear in SSMS
- Tables `customers` and `transactions` should exist
- Test data should be inserted

---

## 🚀 **MANUAL TASK 5: Start the Servers**

### **What to do:**
1. **Navigate to:** `C:\VMuruganAPI\`
2. **Double-click:** `start_servers.bat`
3. **Two command windows should open:**
   - SQL Server API (Port 3001)
   - Client Server (Port 3000)

### **Expected output:**

#### **SQL Server API Window:**
```
🚀 VMurugan SQL Server API Starting...
📡 Connecting to SQL Server...
✅ SQL Server connected successfully
📋 Creating tables if not exist...
✅ Tables created successfully
🚀 VMurugan SQL Server API running on port 3001
```

#### **Client Server Window:**
```
🚀 VMurugan Client Server Starting...
✅ SQL API connection verified
🚀 Client Server running on port 3000
💳 Payment endpoints ready
```

### **✅ How to verify:**
- Both windows should show success messages
- No error messages should appear

---

## 🧪 **MANUAL TASK 6: Test Everything**

### **What to do:**
1. **Run test script:** Double-click `C:\VMuruganAPI\test_servers.bat`
2. **Test web dashboard:** Open `test_server_apis.html` in browser
3. **Test mobile app:** Build and install APK

### **Expected results:**

#### **Test Script Output:**
```
Testing SQL Server API (Port 3001)...
{"status":"OK","timestamp":"...","service":"VMurugan SQL Server API"}

Testing Client Server (Port 3000)...
{"status":"healthy","timestamp":"...","server":"VMurugan Client Server"}

Testing External Access...
{"status":"healthy","timestamp":"..."}
```

#### **Web Dashboard:**
- All API tests should show ✅ green checkmarks
- User registration should work
- Login should work

#### **Mobile App:**
- App should connect to server
- Registration and login should work
- Dashboard should load

### **✅ How to verify:**
- All tests return JSON responses
- No connection errors
- Mobile app functions properly

---

## 🔍 **TROUBLESHOOTING GUIDE**

### **Issue 1: SQL Server Connection Failed**
```
❌ SQL Server connection failed: Failed to connect to localhost:1433
```

**Solutions:**
1. ✅ Check if SQL Server service is running
2. ✅ Verify TCP/IP protocol is enabled
3. ✅ Check firewall allows port 1433
4. ✅ Verify username/password in .env file
5. ✅ Enable Mixed Mode Authentication

### **Issue 2: Port Already in Use**
```
❌ Error: listen EADDRINUSE :::3000
```

**Solutions:**
1. ✅ Check what's using the port: `netstat -ano | findstr :3000`
2. ✅ Kill the process: `taskkill /PID [ProcessID] /F`
3. ✅ Restart the server

### **Issue 3: External Access Not Working**
```
❌ Cannot access http://103.124.152.220:3000
```

**Solutions:**
1. ✅ Check Windows Firewall rules
2. ✅ Check router/network firewall
3. ✅ Verify public IP is correct
4. ✅ Test from local network first

### **Issue 4: Database Permission Errors**
```
❌ The user does not have permission to perform this action
```

**Solutions:**
1. ✅ Run SQL setup script as administrator
2. ✅ Grant proper permissions to user
3. ✅ Use SA account temporarily

---

## 📋 **COMPLETION CHECKLIST**

Mark each task as complete:

- [ ] **Task 1:** SQL Server password configured in .env file
- [ ] **Task 2:** Mixed Mode Authentication enabled
- [ ] **Task 3:** TCP/IP protocol enabled and configured
- [ ] **Task 4:** Database and tables created successfully
- [ ] **Task 5:** Both servers started and running
- [ ] **Task 6:** All tests passing

### **When all tasks are complete:**

✅ **Your servers should be accessible at:**
- Client Server: `http://103.124.152.220:3000`
- SQL Server API: `http://103.124.152.220:3001`

✅ **Payment URLs for bank:**
- Callback: `http://103.124.152.220:3000/api/payment/callback`
- Success: `http://103.124.152.220:3000/payment/success`
- Failure: `http://103.124.152.220:3000/payment/failure`

✅ **Mobile app should connect and work properly**

✅ **Web testing dashboard should show all green checkmarks**

---

## 🎉 **SUCCESS!**

Once all manual tasks are completed, your **VMurugan Gold Trading platform** will be:

🏆 **Fully operational on your public IP**
🏆 **Ready for bank integration**
🏆 **Ready for mobile app testing**
🏆 **Ready for Play Store submission**

**Congratulations! Your gold trading platform is live! 🚀**
