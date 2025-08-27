# 🚀 VMurugan Gold Trading - SQL Server Deployment Guide

## 🏗️ **Your Architecture (Corrected)**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │────│  Client Server  │────│ SQL Server API  │
│   (Mobile)      │    │   (Port 3000)   │    │   (Port 3001)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    ┌─────────┐            ┌─────────┐            ┌─────────┐
    │Firebase │            │ Proxy   │            │SQL Server│
    │Auth/DB  │            │ Layer   │            │Database │
    └─────────┘            └─────────┘            └─────────┘
```

## 📋 **What You Need to Deploy on Client Server**

### **Files to Deploy:**

1. **SQL Server API** (`sql_server_api/` folder)
   - `server.js` (main SQL Server API)
   - `package.json` (dependencies)
   - `.env` (configuration)

2. **Client Server** (`server/` folder)
   - `server_clean.js` (proxy server)
   - `package_clean.json` (dependencies)
   - `.env` (configuration)

3. **Database Setup**
   - SQL Server database
   - Tables creation script

---

## 🔧 **Step-by-Step Deployment**

### **STEP 1: Prepare Client Server**

#### **1.1 Create Deployment Directory**
```bash
# On client server
mkdir C:\VMuruganAPI
mkdir C:\VMuruganAPI\sql_server_api
mkdir C:\VMuruganAPI\server
```

#### **1.2 Copy SQL Server API Files**
Copy these files to `C:\VMuruganAPI\sql_server_api\`:
- `sql_server_api/package.json`
- `sql_server_api/server.js` (if exists, or create it)
- `sql_server_api/.env.template` → rename to `.env`

#### **1.3 Copy Client Server Files**
Copy these files to `C:\VMuruganAPI\server\`:
- `server/server_clean.js` → rename to `server.js`
- `server/package_clean.json` → rename to `package.json`

---

### **STEP 2: Configure SQL Server**

#### **2.1 Create .env for SQL Server API**
Create `C:\VMuruganAPI\sql_server_api\.env`:
```env
# Server Configuration
PORT=3001
NODE_ENV=production

# SQL Server Configuration
SQL_SERVER=localhost
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=sa
SQL_PASSWORD=YOUR_SQL_PASSWORD
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true
SQL_CONNECTION_TIMEOUT=30000
SQL_REQUEST_TIMEOUT=30000

# Security Configuration
ADMIN_TOKEN=VMURUGAN_ADMIN_2025

# CORS Configuration
ALLOWED_ORIGINS=*
```

#### **2.2 Create .env for Client Server**
Create `C:\VMuruganAPI\server\.env`:
```env
PORT=3000
SQL_API_URL=http://localhost:3001
```

---

### **STEP 3: Install Dependencies**

```bash
# Install SQL Server API dependencies
cd C:\VMuruganAPI\sql_server_api
npm install

# Install Client Server dependencies
cd C:\VMuruganAPI\server
npm install
```

---

### **STEP 4: Create SQL Server Database**

#### **4.1 Open SQL Server Management Studio (SSMS)**

#### **4.2 Create Database**
```sql
-- Create database
CREATE DATABASE VMuruganGoldTrading;
GO

USE VMuruganGoldTrading;
GO

-- Create Customers table
CREATE TABLE customers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    phone NVARCHAR(15) UNIQUE NOT NULL,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(100),
    address NVARCHAR(MAX),
    pan_card NVARCHAR(10),
    device_id NVARCHAR(100),
    registration_date DATETIME2 DEFAULT GETDATE(),
    business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
    total_invested DECIMAL(12,2) DEFAULT 0.00,
    total_gold DECIMAL(10,4) DEFAULT 0.0000,
    transaction_count INT DEFAULT 0,
    last_transaction DATETIME2 NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

-- Create Transactions table
CREATE TABLE transactions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id NVARCHAR(100) UNIQUE NOT NULL,
    customer_phone NVARCHAR(15),
    customer_name NVARCHAR(100),
    type NVARCHAR(10) NOT NULL CHECK (type IN ('BUY', 'SELL')),
    amount DECIMAL(12,2) NOT NULL,
    gold_grams DECIMAL(10,4) NOT NULL,
    gold_price_per_gram DECIMAL(10,2) NOT NULL,
    payment_method NVARCHAR(50) NOT NULL,
    status NVARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
    gateway_transaction_id NVARCHAR(100),
    device_info NVARCHAR(MAX),
    location NVARCHAR(MAX),
    business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
    timestamp DATETIME2 DEFAULT GETDATE(),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_phone) REFERENCES customers(phone)
);

-- Create indexes
CREATE INDEX IX_customers_phone ON customers (phone);
CREATE INDEX IX_transactions_customer ON transactions (customer_phone);
CREATE INDEX IX_transactions_status ON transactions (status);

-- Insert test data
INSERT INTO customers (phone, name, email, address, pan_card, device_id)
VALUES ('9999999999', 'Test Customer', 'test@vmurugan.com', 'Test Address, Chennai', 'ABCDE1234F', 'test_device_001');

PRINT 'Database created successfully!';
```

---

### **STEP 5: Start Servers**

#### **5.1 Start SQL Server API (Port 3001)**
```bash
cd C:\VMuruganAPI\sql_server_api
node server.js
```

#### **5.2 Start Client Server (Port 3000)**
```bash
# Open new terminal
cd C:\VMuruganAPI\server
node server.js
```

#### **5.3 Using PM2 (Recommended for Production)**
```bash
# Install PM2 globally
npm install -g pm2

# Start SQL Server API
cd C:\VMuruganAPI\sql_server_api
pm2 start server.js --name "vmurugan-sql-api"

# Start Client Server
cd C:\VMuruganAPI\server
pm2 start server.js --name "vmurugan-client"

# Save PM2 configuration
pm2 save
pm2 startup

# Check status
pm2 status
```

---

### **STEP 6: Test Deployment**

#### **6.1 Test SQL Server API (Port 3001)**
```bash
# Test health
curl http://YOUR_PUBLIC_IP:3001/health

# Test database connection
curl http://YOUR_PUBLIC_IP:3001/api/test-connection
```

#### **6.2 Test Client Server (Port 3000)**
```bash
# Test health
curl http://YOUR_PUBLIC_IP:3000/health

# Test customer registration
curl -X POST http://YOUR_PUBLIC_IP:3000/api/customers \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","name":"Test User","email":"test@example.com","address":"Test Address","pan_card":"ABCDE1234F","device_id":"test123"}'
```

---

### **STEP 7: Payment Integration URLs**

For bank whitelisting, provide these URLs:

#### **Payment URLs (Port 3000 - Client Server)**
```
http://YOUR_PUBLIC_IP:3000/api/payment/callback
http://YOUR_PUBLIC_IP:3000/payment/success
http://YOUR_PUBLIC_IP:3000/payment/failure
http://YOUR_PUBLIC_IP:3000/payment/cancel
http://YOUR_PUBLIC_IP:3000/api/payment/status/{orderId}
```

---

## 🔧 **Configuration Files Summary**

### **SQL Server API (.env)**
```env
PORT=3001
SQL_SERVER=localhost
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=sa
SQL_PASSWORD=YOUR_SQL_PASSWORD
ADMIN_TOKEN=VMURUGAN_ADMIN_2025
```

### **Client Server (.env)**
```env
PORT=3000
SQL_API_URL=http://localhost:3001
```

### **Mobile App Configuration**
Update `lib/core/config/client_server_config.dart`:
```dart
static const String serverDomain = 'YOUR_PUBLIC_IP';
static const int serverPort = 3000;
static const String protocol = 'http';
```

---

## ✅ **Deployment Checklist**

- [ ] **SQL Server** installed and running
- [ ] **Database** created with tables
- [ ] **SQL Server API** deployed (port 3001)
- [ ] **Client Server** deployed (port 3000)
- [ ] **Dependencies** installed (npm install)
- [ ] **Environment files** configured
- [ ] **Firewall** allows ports 3000 and 3001
- [ ] **Services** started (PM2 recommended)
- [ ] **Health checks** passing
- [ ] **Mobile app** updated with public IP

---

## 🚀 **Start Commands**

### **Manual Start**
```bash
# Terminal 1: SQL Server API
cd C:\VMuruganAPI\sql_server_api
node server.js

# Terminal 2: Client Server
cd C:\VMuruganAPI\server
node server.js
```

### **PM2 Start (Recommended)**
```bash
pm2 start C:\VMuruganAPI\sql_server_api\server.js --name "vmurugan-sql-api"
pm2 start C:\VMuruganAPI\server\server.js --name "vmurugan-client"
pm2 save
```

**Your SQL Server deployment is now ready! 🏆**
