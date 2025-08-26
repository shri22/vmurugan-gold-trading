# SQL Server Setup for Windows Server Deployment

## 🗄️ **SQL Server Configuration Options**

You have **3 deployment scenarios** for SQL Server:

### **Option 1: Same Machine (Recommended)**
Deploy Node.js APIs on the same Windows machine where SQL Server is already running.

**Advantages:**
- ✅ No network latency
- ✅ Highest security (localhost connection)
- ✅ Easiest setup
- ✅ Best performance

**Configuration:**
```env
SQL_SERVER=localhost
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=DakData
SQL_PASSWORD=Test@123
```

### **Option 2: Network SQL Server**
Use your existing SQL Server from another machine on the network.

**Configuration:**
```env
SQL_SERVER=192.168.1.18
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=DakData
SQL_PASSWORD=Test@123
```

### **Option 3: Cloud SQL Server**
Use Azure SQL Database or AWS RDS for production.

## 🔧 **SQL Server Requirements Check**

### **1. Verify SQL Server is Running**
```cmd
# Check if SQL Server service is running
sc query MSSQLSERVER

# Or check with PowerShell
Get-Service -Name "MSSQLSERVER"
```

### **2. Test Connection**
```cmd
# Test connection with sqlcmd
sqlcmd -S localhost,1433 -U DakData -P Test@123 -Q "SELECT @@VERSION"

# Test from network (if using remote SQL Server)
sqlcmd -S 192.168.1.18,1433 -U DakData -P Test@123 -Q "SELECT @@VERSION"
```

### **3. Verify Database Exists**
```sql
-- Check if database exists
SELECT name FROM sys.databases WHERE name = 'VMuruganGoldTrading';

-- Check tables
USE VMuruganGoldTrading;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;
```

## 🌐 **Network Configuration**

### **For Public Access (Windows Server)**

#### **1. SQL Server Network Configuration**
```cmd
# Enable TCP/IP Protocol
# SQL Server Configuration Manager → SQL Server Network Configuration → Protocols → TCP/IP → Enable

# Set TCP Port to 1433
# TCP/IP Properties → IP Addresses → IPAll → TCP Port: 1433
```

#### **2. Windows Firewall**
```powershell
# Allow SQL Server through firewall
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

# Allow Node.js APIs
New-NetFirewallRule -DisplayName "Node.js API 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
New-NetFirewallRule -DisplayName "Node.js API 3001" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow
```

#### **3. SQL Server Authentication**
```sql
-- Enable SQL Server Authentication (if not already enabled)
-- SQL Server Management Studio → Server Properties → Security → SQL Server and Windows Authentication mode

-- Verify user exists
SELECT name FROM sys.sql_logins WHERE name = 'DakData';

-- Grant permissions if needed
USE VMuruganGoldTrading;
EXEC sp_addrolemember 'db_owner', 'DakData';
```

## 🚀 **Deployment Scenarios**

### **Scenario 1: Everything on Windows Server**
```
Windows Server (Public IP)
├── SQL Server (localhost:1433)
├── Node.js SQL API (0.0.0.0:3001)
└── Node.js Main API (0.0.0.0:3000)
```

**Pros:** Best performance, easiest management
**Cons:** Single point of failure

### **Scenario 2: Separate SQL Server**
```
Windows Server (Public IP)          SQL Server Machine
├── Node.js SQL API (0.0.0.0:3001) ←→ SQL Server (192.168.1.18:1433)
└── Node.js Main API (0.0.0.0:3000)
```

**Pros:** Better resource isolation
**Cons:** Network dependency

### **Scenario 3: Cloud SQL + Windows Server**
```
Windows Server (Public IP)          Azure SQL Database
├── Node.js SQL API (0.0.0.0:3001) ←→ SQL Server (cloud)
└── Node.js Main API (0.0.0.0:3000)
```

**Pros:** Managed database, high availability
**Cons:** Monthly cost, internet dependency

## 📋 **Pre-Deployment Checklist**

### **SQL Server Checklist**
- [ ] SQL Server is installed and running
- [ ] TCP/IP protocol is enabled
- [ ] Port 1433 is open in firewall
- [ ] SQL Server Authentication is enabled
- [ ] User 'DakData' exists with proper permissions
- [ ] Database 'VMuruganGoldTrading' exists
- [ ] Tables are created (customers, transactions, etc.)

### **Network Checklist**
- [ ] Windows Server has public IP
- [ ] Ports 3000, 3001 are open in firewall
- [ ] SQL Server is accessible from Node.js APIs
- [ ] Internet connectivity is stable

### **Application Checklist**
- [ ] Node.js is installed
- [ ] PM2 is installed
- [ ] Application files are copied
- [ ] Environment variables are configured
- [ ] Dependencies are installed

## 🧪 **Testing SQL Server Setup**

### **1. Test Local Connection**
```cmd
sqlcmd -S localhost -U DakData -P Test@123 -Q "SELECT GETDATE()"
```

### **2. Test Network Connection**
```cmd
sqlcmd -S YOUR_PUBLIC_IP -U DakData -P Test@123 -Q "SELECT GETDATE()"
```

### **3. Test from Node.js**
```javascript
// Test script
const sql = require('mssql');

const config = {
    server: 'localhost',
    port: 1433,
    database: 'VMuruganGoldTrading',
    user: 'DakData',
    password: 'Test@123',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

sql.connect(config).then(() => {
    console.log('✅ SQL Server connected successfully!');
    return sql.query('SELECT @@VERSION');
}).then(result => {
    console.log('SQL Server Version:', result.recordset[0]);
}).catch(err => {
    console.error('❌ SQL Server connection failed:', err);
});
```

## 🔒 **Security Best Practices**

### **1. SQL Server Security**
- Use strong passwords
- Limit user permissions
- Enable encryption for sensitive data
- Regular security updates

### **2. Network Security**
- Use VPN for remote access
- Implement IP whitelisting
- Monitor connection logs
- Regular firewall audits

### **3. Application Security**
- Use environment variables for secrets
- Implement rate limiting
- Add request validation
- Monitor API usage

## 📊 **Performance Optimization**

### **1. SQL Server Optimization**
```sql
-- Check database size
SELECT 
    DB_NAME() as DatabaseName,
    (SELECT SUM(size) FROM sys.database_files WHERE type = 0) * 8 / 1024 as DataSizeMB,
    (SELECT SUM(size) FROM sys.database_files WHERE type = 1) * 8 / 1024 as LogSizeMB;

-- Optimize indexes
EXEC sp_updatestats;
```

### **2. Connection Pool Settings**
```javascript
const config = {
    // ... other settings
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};
```

## 🆘 **Troubleshooting**

### **Common Issues**

#### **"Login failed for user 'DakData'"**
```sql
-- Check if user exists
SELECT name FROM sys.sql_logins WHERE name = 'DakData';

-- Reset password if needed
ALTER LOGIN DakData WITH PASSWORD = 'Test@123';
```

#### **"Cannot connect to SQL Server"**
- Check if SQL Server service is running
- Verify TCP/IP is enabled
- Check firewall settings
- Test with telnet: `telnet localhost 1433`

#### **"Database 'VMuruganGoldTrading' does not exist"**
```sql
-- Create database if missing
CREATE DATABASE VMuruganGoldTrading;
```

Your existing SQL Server setup should work perfectly with the Windows Server deployment!
