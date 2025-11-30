# Production Deployment Checklist

## 📋 Files to Deploy to Production Server

### **Backend (Node.js API) - `sql_server_api` folder**

Copy the entire `sql_server_api` folder to your Windows production server, or at minimum these critical files:

#### **✅ Required Files:**

1. **`server.js`** ⭐ CRITICAL
   - Main server file with updated Worldline configuration
   - Contains payment endpoints and merchant routing logic

2. **`worldline_config.js`** ⭐ NEW FILE - CRITICAL
   - Production merchant credentials (Gold: 779285, Silver: 779295)
   - Merchant selection logic based on metal type
   - **MUST be deployed alongside server.js**

3. **`package.json`**
   - Node.js dependencies list
   - Required for `npm install`

4. **`package-lock.json`**
   - Locked dependency versions
   - Ensures consistent package versions

5. **`.env`** (if exists)
   - Environment variables
   - Add: `WORLDLINE_ENVIRONMENT=PRODUCTION`

#### **📁 Optional but Recommended:**

- `logs/` folder - For payment logs
- `migrations/` folder - Database migration scripts
- `node_modules/` - Can be regenerated with `npm install`

---

## 🚀 Deployment Steps

### **Step 1: Backup Current Production**

```bash
# On Windows production server
cd C:\path\to\your\api
xcopy sql_server_api sql_server_api_backup_20251130 /E /I /H
```

### **Step 2: Copy Files to Production**

**Option A: Copy entire folder**
```bash
# From your Mac, use SCP or FTP to copy:
sql_server_api/server.js
sql_server_api/worldline_config.js
sql_server_api/package.json
sql_server_api/package-lock.json
```

**Option B: Manual copy**
- Use FileZilla, WinSCP, or similar FTP client
- Copy files to: `C:\path\to\your\api\sql_server_api\`

### **Step 3: Install Dependencies (if needed)**

```bash
# On Windows production server
cd C:\path\to\your\api\sql_server_api
npm install
```

### **Step 4: Set Environment Variable**

Create or update `.env` file in `sql_server_api` folder:

```env
WORLDLINE_ENVIRONMENT=PRODUCTION
```

### **Step 5: Restart Node.js Server**

```bash
# Stop current server (Ctrl+C or kill process)
# Then restart:
node server.js
```

Or if using PM2:
```bash
pm2 restart server
# or
pm2 reload server
```

### **Step 6: Verify Deployment**

1. **Check server is running:**
   ```bash
   # Should see: Server running on port 3001
   ```

2. **Test API endpoint:**
   ```bash
   curl https://api.vmuruganjewellery.co.in:3001/api/health
   ```

3. **Check logs:**
   ```bash
   # Look for: "Worldline configuration loaded successfully"
   ```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] `server.js` is updated on production server
- [ ] `worldline_config.js` exists in same folder as `server.js`
- [ ] `.env` has `WORLDLINE_ENVIRONMENT=PRODUCTION`
- [ ] Node.js server restarted successfully
- [ ] Server is running on port 3001
- [ ] No errors in server logs
- [ ] API health check responds
- [ ] Test Gold payment (should use Merchant 779285)
- [ ] Test Silver payment (should use Merchant 779295)

---

## 🔍 Troubleshooting

### **Error: Cannot find module './worldline_config'**

**Solution:** Ensure `worldline_config.js` is in the same folder as `server.js`

```bash
# Check files exist:
dir C:\path\to\your\api\sql_server_api\worldline_config.js
dir C:\path\to\your\api\sql_server_api\server.js
```

### **Error: WORLDLINE_ENVIRONMENT not set**

**Solution:** Create `.env` file with:
```env
WORLDLINE_ENVIRONMENT=PRODUCTION
```

### **Payment uses wrong merchant**

**Solution:** Check logs to verify metal type is being passed correctly:
```bash
# Look for: "Metal Type: gold" or "Metal Type: silver"
# Look for: "Using merchant: V MURUGAN JEWELLERY (779285)" or similar
```

---

## 📁 Production Server Structure

Your production server should have:

```
C:\path\to\your\api\
└── sql_server_api\
    ├── server.js              ⭐ UPDATED
    ├── worldline_config.js    ⭐ NEW
    ├── package.json
    ├── package-lock.json
    ├── .env                   (WORLDLINE_ENVIRONMENT=PRODUCTION)
    ├── node_modules\          (from npm install)
    └── logs\                  (payment logs)
```

---

## ⚠️ Important Security Notes

1. **Protect credentials:** `worldline_config.js` contains sensitive API keys and SALT values
2. **File permissions:** Ensure only authorized users can read these files
3. **Backup:** Keep a backup of old configuration before deploying
4. **SSL Certificate:** Install proper SSL certificate (current iOS has temporary exception)

---

## 📞 Support

If you encounter issues:
1. Check server logs in `sql_server_api/logs/`
2. Verify both files are in the same directory
3. Ensure Node.js server was restarted after deployment
4. Test with small amounts first

---

**Deployment Date:** _____________  
**Deployed By:** _____________  
**Server:** api.vmuruganjewellery.co.in:3001  
**Status:** [ ] Deployed [ ] Verified [ ] Tested

