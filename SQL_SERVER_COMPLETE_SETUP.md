# Complete SQL Server Setup Guide

## ✅ Configuration Complete!

Your Flutter app is now configured to connect to your SQL Server database with these details:

- **Server IP**: `192.168.31.129`
- **Username**: `DakData`
- **Password**: `Test@123`
- **Database**: `VMuruganGoldTrading`
- **Port**: `1433`

## 🚀 Quick Start

### Step 1: Set Up SQL Server API Bridge

1. **Navigate to the API folder**:
   ```bash
   cd sql_server_api
   ```

2. **Run the setup script**:
   ```bash
   node setup.js
   ```

3. **Start the API server**:
   ```bash
   npm start
   ```

   You should see:
   ```
   🚀 VMurugan SQL Server API running on port 3001
   📊 Health Check: http://localhost:3001/health
   💾 Database: VMuruganGoldTrading on 192.168.31.129
   ```

### Step 2: Test the Connection

Open your browser and visit:
- **Health Check**: `http://localhost:3001/health`
- **Connection Test**: `http://localhost:3001/api/test-connection`

### Step 3: Build and Test Flutter APK

```bash
flutter pub get
flutter build apk
```

## 📊 What Happens Automatically

### Database Creation
The API server will automatically:
- ✅ Create `VMuruganGoldTrading` database (if it doesn't exist)
- ✅ Create all required tables:
  - `customers` - Customer information and statistics
  - `transactions` - All buy/sell transactions
  - `schemes` - Investment schemes
  - `analytics` - App usage analytics

### Table Structure
```sql
-- Customers table
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
)

-- Transactions table
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
    created_at DATETIME2 DEFAULT GETDATE()
)
```

## 🔧 SQL Server Prerequisites

### 1. Enable TCP/IP Protocol
1. Open **SQL Server Configuration Manager**
2. Go to **SQL Server Network Configuration** > **Protocols for [Instance]**
3. Right-click **TCP/IP** → **Enable**
4. Double-click **TCP/IP** → **IP Addresses** tab
5. Set **TCP Port** to `1433` for all IP addresses
6. **Restart SQL Server service**

### 2. Enable SQL Server Authentication
1. Open **SQL Server Management Studio (SSMS)**
2. Right-click server → **Properties** → **Security**
3. Select **"SQL Server and Windows Authentication mode"**
4. **Restart SQL Server service**

### 3. Configure Windows Firewall
1. Open **Windows Defender Firewall** → **Advanced settings**
2. **Inbound Rules** → **New Rule** → **Port** → **TCP** → `1433`
3. **Allow the connection** → **Apply to all profiles**

## 📱 Flutter App Configuration

Your app is already configured with:

```dart
// lib/core/config/sql_server_config.dart
static const String serverIP = '192.168.31.129';
static const String username = 'DakData';
static const String password = 'Test@123';
static const String databaseName = 'VMuruganGoldTrading';

// lib/core/services/api_service.dart
static const String storageMode = 'sqlserver'; // ✅ Set to SQL Server
```

## 🧪 Testing Your Setup

### 1. Test SQL Server API
```bash
# In sql_server_api folder
npm start

# Test in browser:
# http://localhost:3001/health
# http://localhost:3001/api/test-connection
```

### 2. Test Flutter App
Add this test page to your app:

```dart
import 'lib/features/testing/sql_server_test_page.dart';

// Add button to navigate to test page
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

### 3. Verify Data in SSMS
1. Open **SQL Server Management Studio**
2. Connect to your server (`192.168.31.129`)
3. Expand **Databases** → **VMuruganGoldTrading**
4. Check tables: `customers`, `transactions`, `schemes`, `analytics`

## 📊 API Endpoints

Your Flutter app will use these endpoints:

- **POST** `/api/customers` - Save customer
- **GET** `/api/customers/:phone` - Get customer by phone
- **GET** `/api/customers` - Get all customers
- **POST** `/api/transactions` - Save transaction
- **GET** `/api/transactions` - Get transactions
- **GET** `/api/admin/dashboard` - Get dashboard data

## 🔍 Troubleshooting

### API Server Won't Start
```bash
# Check if port 3001 is available
netstat -an | findstr :3001

# Check SQL Server connection
sqlcmd -S 192.168.31.129 -U DakData -P Test@123
```

### Flutter App Can't Connect
1. **Check API server is running** on port 3001
2. **Verify both devices on same WiFi**
3. **Test API manually**: `http://192.168.31.129:3001/health`
4. **Check firewall** allows port 3001

### SQL Server Connection Issues
1. **Verify SQL Server is running**
2. **Check TCP/IP is enabled**
3. **Test credentials in SSMS**
4. **Verify firewall allows port 1433**

## 📈 Data Flow

```
Flutter APK → HTTP Request → Node.js API (Port 3001) → SQL Server (Port 1433) → Database
```

1. **Flutter app** sends HTTP requests to API server
2. **Node.js API** receives requests and connects to SQL Server
3. **SQL Server** stores/retrieves data from database
4. **API** returns JSON response to Flutter app

## 🎯 Benefits

- ✅ **Enterprise Database** - Professional SQL Server
- ✅ **Real-time Data** - Immediate synchronization
- ✅ **SSMS Management** - Full database management tools
- ✅ **Backup & Recovery** - Built-in SQL Server features
- ✅ **Scalability** - Supports multiple users
- ✅ **Advanced Queries** - Complex reporting capabilities
- ✅ **Data Integrity** - ACID compliance

## 🚀 Production Deployment

For production use:

1. **Use HTTPS** instead of HTTP
2. **Implement proper authentication**
3. **Set up SSL certificates**
4. **Configure production database**
5. **Set up automated backups**
6. **Monitor performance**

## 📞 Support

If you encounter issues:

1. **Check API server logs** in terminal
2. **Verify SQL Server connection** in SSMS
3. **Test API endpoints** in browser
4. **Check Flutter app logs** for errors
5. **Ensure network connectivity** between devices

Your SQL Server integration is now complete! 🎉

## 🔄 Next Steps

1. **Start the API server**: `cd sql_server_api && npm start`
2. **Build Flutter APK**: `flutter build apk`
3. **Test customer registration** from your app
4. **Verify data appears** in SQL Server Management Studio
5. **Test all app features** (transactions, schemes, etc.)

All customer data and transactions will now be saved directly to your SQL Server database! 🚀
