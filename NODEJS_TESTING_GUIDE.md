# 🚀 NODE.JS TESTING GUIDE - Your Original Setup Extended

## ✅ **WHAT I'VE DONE**

### **Extended Your Existing Node.js Server:**
- ✅ **Kept your `sql_server_api/server.js`** - No changes to existing APIs
- ✅ **Added 3 new APIs** for portfolio management:
  - `GET /api/portfolio` - Get user's gold/silver holdings
  - `GET /api/transaction-history` - Get user's transaction history  
  - `POST /api/transaction-status` - Update transaction status
- ✅ **Updated mobile app** to use your Node.js server (port 3001)
- ✅ **Added silver support** to your SQL Server database

---

## 📱 **TESTING ON YOUR MOBILE - SAME AS BEFORE!**

### **STEP 1: Update Database Schema (One-time)**
```bash
cd sql_server_api
node update_schema_for_silver.js
```
**This adds silver columns to your existing SQL Server database.**

### **STEP 2: Start Your Server (Same as Always)**
```bash
cd sql_server_api
node server.js
```
**Your server will start on port 3001 as usual.**

### **STEP 3: Install Updated APK**
```bash
# APK Location: build\app\outputs\flutter-apk\app-debug.apk
# Install on your mobile device
```

### **STEP 4: Test Everything**
- ✅ **Registration** - Same as before
- ✅ **Login** - Same as before  
- ✅ **Portfolio** - Now shows gold + silver holdings
- ✅ **Gold Purchase** - Same as before
- ✅ **Silver Purchase** - New! Shows ₹126.00/gram
- ✅ **Transaction History** - Shows all purchases

---

## 🔧 **WHAT'S NEW IN YOUR SERVER**

### **New API Endpoints Added:**

#### **1. Get Portfolio**
```
GET http://localhost:3001/api/portfolio?user_id=1
GET http://localhost:3001/api/portfolio?phone=9876543210
```
**Response:**
```json
{
  "success": true,
  "portfolio": {
    "total_gold_grams": 5.25,
    "total_silver_grams": 10.50,
    "total_invested": 50000.00,
    "current_value": 52000.00,
    "profit_loss": 2000.00,
    "profit_loss_percentage": 4.00
  },
  "user": {
    "id": 1,
    "name": "John Doe",
    "phone": "9876543210"
  }
}
```

#### **2. Get Transaction History**
```
GET http://localhost:3001/api/transaction-history?phone=9876543210&limit=20
```

#### **3. Update Transaction Status**
```
POST http://localhost:3001/api/transaction-status
{
  "transaction_id": "TXN_123",
  "status": "SUCCESS"
}
```

---

## 🗄️ **DATABASE CHANGES**

### **New Columns Added to `transactions` Table:**
- ✅ **`silver_grams`** - Amount of silver purchased
- ✅ **`transaction_type`** - 'BUY' or 'SELL'
- ✅ **`metal_type`** - 'GOLD' or 'SILVER'

### **Your Existing Data:**
- ✅ **All existing transactions preserved**
- ✅ **Existing gold purchases still work**
- ✅ **New silver purchases supported**

---

## 📱 **APP CHANGES**

### **What's Different:**
- ✅ **Portfolio Screen** - Now shows gold + silver holdings
- ✅ **Silver Purchase** - New screen with ₹126.00/gram pricing
- ✅ **Transaction History** - Shows both gold and silver purchases
- ✅ **Same Login/Registration** - No changes to auth flow

### **What's the Same:**
- ✅ **Same server** (localhost:3001)
- ✅ **Same database** (your SQL Server)
- ✅ **Same testing workflow** (`node server.js`)
- ✅ **Same user accounts** (existing users still work)

---

## 🧪 **TESTING CHECKLIST**

### **✅ Server Setup:**
- [ ] Run `node update_schema_for_silver.js` (one-time)
- [ ] Start server: `node server.js`
- [ ] Verify server running: http://localhost:3001/health
- [ ] Test new portfolio API: http://localhost:3001/api/portfolio?phone=YOUR_PHONE

### **✅ Mobile App Testing:**
- [ ] Install updated APK on mobile
- [ ] Connect mobile to same WiFi as computer
- [ ] Register new user (or use existing account)
- [ ] Login with MPIN
- [ ] Check portfolio loads (shows gold + silver)
- [ ] Test gold purchase (same as before)
- [ ] Test silver purchase (new - shows ₹126.00)
- [ ] Check transaction history (shows all purchases)

### **✅ Database Verification:**
- [ ] Open SQL Server Management Studio (SSMS)
- [ ] Check `transactions` table has new columns
- [ ] Verify existing data is preserved
- [ ] Check new silver transactions are saved

---

## 🔄 **TESTING WORKFLOW (Same as Before!)**

### **1. Start Server:**
```bash
cd E:\Projects\vmurugan-gold-trading\sql_server_api
node server.js
```

### **2. Check Server Status:**
```
✅ Server running on port 3001
✅ Connected to SQL Server
✅ Database: [your database name]
```

### **3. Test on Mobile:**
- Install APK
- Register/Login
- Test gold purchase
- Test silver purchase (NEW!)
- Check portfolio
- View transaction history

### **4. Check Database:**
- Open SSMS
- Check `transactions` table
- Verify new records saved

---

## 🎯 **EXPECTED RESULTS**

### **✅ Portfolio Screen:**
```
Gold Holdings: 2.5000g
Silver Holdings: 7.9365g (NEW!)
Total Invested: ₹25,000
Current Value: ₹26,250
Profit/Loss: +₹1,250 (+5.0%)
```

### **✅ Silver Purchase:**
```
Silver Price: ₹126.00/gram (exact MJDTA price)
Purchase Amount: ₹1,000
Quantity: 7.9365g
Payment: Net Banking (Omniware)
```

### **✅ Transaction History:**
```
1. Gold Purchase - 2.5g - ₹16,250 - SUCCESS
2. Silver Purchase - 7.9365g - ₹1,000 - SUCCESS (NEW!)
```

---

## 🚨 **TROUBLESHOOTING**

### **"Schema update failed":**
- Check SQL Server is running
- Verify database connection in .env file
- Ensure user has ALTER TABLE permissions

### **"Portfolio API not found":**
- Restart server: `node server.js`
- Check server logs for errors
- Verify new APIs are loaded

### **"App can't connect":**
- Check mobile on same WiFi
- Verify server running on port 3001
- Test: http://COMPUTER_IP:3001/health in mobile browser

### **"Silver purchase fails":**
- Check database schema updated
- Verify `silver_grams` column exists
- Check server logs for SQL errors

---

## 🎉 **SUCCESS! YOU CAN NOW TEST:**

### **✅ Everything You Had Before:**
- User registration and login
- Gold purchases and portfolio
- Transaction history
- SQL Server database storage

### **✅ Plus New Silver Features:**
- Silver purchases at ₹126.00/gram
- Combined gold + silver portfolio
- Complete transaction history
- Enhanced database schema

**Your familiar testing workflow (`node server.js`) now supports both gold and silver trading! 🚀**

---

## 📞 **NEED HELP?**

### **Check These First:**
1. **Server Logs** - Look for errors in terminal
2. **Database Connection** - Verify .env file settings
3. **Mobile Network** - Ensure same WiFi as computer
4. **API Responses** - Test endpoints in browser

### **Common Commands:**
```bash
# Update database schema (one-time)
node update_schema_for_silver.js

# Start server (same as always)
node server.js

# Test server health
curl http://localhost:3001/health

# Test portfolio API
curl http://localhost:3001/api/portfolio?phone=9876543210
```

**Your original Node.js + SQL Server setup is now enhanced with complete gold and silver trading capabilities! 🎯**
