# Worldline Payment Troubleshooting Guide

## 🔴 Current Issues

### Issue 1: Blank White Screen on Worldline Payment Page
**Symptom:** Payment page shows "Worldline Payment" header but blank white content area

**Possible Causes:**
1. **Server not restarted** - New `worldline_config.js` not loaded
2. **Production credentials not activated** - Worldline merchant accounts might not be live yet
3. **Merchant configuration mismatch** - Production merchant might require different settings than test
4. **SSL certificate issue** - Worldline might be blocking due to invalid SSL

### Issue 2: Amount Limit Still ₹10
**Status:** ✅ FIXED in code (not yet deployed)
**Fix:** Updated validation from ₹1-₹10 to ₹1-₹10,00,000

---

## 🔧 Immediate Actions Required

### Step 1: Restart Node.js Server (CRITICAL)

The new `worldline_config.js` file won't be loaded until you restart the server.

**On your Windows production server:**

```bash
# Stop the current server (Ctrl+C or kill process)
# Then restart:
cd C:\path\to\your\api\sql_server_api
node server.js
```

**Or if using PM2:**
```bash
pm2 restart server
```

### Step 2: Verify Merchant Accounts are Active

Contact Worldline support to confirm:
- [ ] Merchant 779285 (Gold) is **LIVE** and activated
- [ ] Merchant 779295 (Silver) is **LIVE** and activated
- [ ] Both merchants are configured for **production** (not UAT/test)
- [ ] API credentials are correct and active

**Worldline Support:**
- Login to: Worldline Merchant Portal
- Check merchant status: Should show "ACTIVE" or "LIVE"
- Verify API keys are for production environment

### Step 3: Check Server Logs

After restarting, check the logs for:

```bash
# Look for these messages:
✅ "Using merchant: V MURUGAN JEWELLERY (779285)" 
✅ "Metal Type: gold"
✅ "Merchant Code: 779285"

# Or for silver:
✅ "Using merchant: V MURUGAN NAGAI KADAI (779295)"
✅ "Metal Type: silver"
✅ "Merchant Code: 779295"
```

**If you see errors like:**
```
❌ "Cannot find module './worldline_config'"
```
**Solution:** Ensure `worldline_config.js` is in the same folder as `server.js`

---

## 🧪 Testing Steps

### Test 1: Verify Server Configuration

1. **Check files exist:**
   ```bash
   dir C:\path\to\your\api\sql_server_api\server.js
   dir C:\path\to\your\api\sql_server_api\worldline_config.js
   ```

2. **Restart server and check startup logs:**
   ```bash
   node server.js
   # Should see: Server running on port 3001
   ```

3. **Test API endpoint:**
   ```bash
   curl https://api.vmuruganjewellery.co.in:3001/api/health
   ```

### Test 2: Test Payment with Small Amount

1. Open the app
2. Try to buy ₹100 worth of gold
3. Check if amount validation allows it (should work now)
4. Proceed to payment
5. Check if Worldline page loads properly

### Test 3: Check Merchant Selection

**For Gold:**
1. Join Gold Plus scheme
2. Proceed to payment
3. Check server logs - should show Merchant 779285

**For Silver:**
1. Join Silver Plus scheme
2. Proceed to payment
3. Check server logs - should show Merchant 779295

---

## 🔍 Debugging the Blank Screen

### Check 1: Flutter App Logs

Look for errors in the app logs:
```
❌ "Token request failed"
❌ "Failed to get payment token"
❌ "Worldline SDK initialization failed"
```

### Check 2: Server Logs

Check `sql_server_api/logs/worldline_*.log` for:
```
🔥 ===== WORLDLINE TOKEN REQUEST STARTED =====
🏪 Using merchant: V MURUGAN JEWELLERY (779285)
✅ Token generated successfully
```

### Check 3: Network Request

In the app, check if the token request is successful:
- Open payment screen
- Check debug logs
- Look for "✅ Token received successfully"

If token request fails:
- Server might not be running
- `worldline_config.js` might not be loaded
- Merchant credentials might be incorrect

---

## 🚨 Common Errors and Solutions

### Error: "Amount must be between 1 and 10"
**Solution:** Server needs to be restarted with updated code

### Error: "Cannot find module './worldline_config'"
**Solution:** Copy `worldline_config.js` to same folder as `server.js`

### Error: "Merchant not found"
**Solution:** Check `WORLDLINE_ENVIRONMENT` is set to `PRODUCTION` in `.env`

### Error: Blank white screen on payment page
**Possible Solutions:**
1. Restart server to load new configuration
2. Verify merchant accounts are activated with Worldline
3. Check if production credentials are correct
4. Contact Worldline support to verify merchant status

---

## 📞 Next Steps

1. **Restart your Node.js server** (most important!)
2. **Test with ₹100** to see if amount validation works
3. **Check server logs** to verify merchant selection
4. **Contact Worldline** if blank screen persists after restart

---

## 📋 Checklist

Before testing:
- [ ] `server.js` updated on production server
- [ ] `worldline_config.js` exists in same folder
- [ ] Node.js server restarted
- [ ] Server logs show no errors
- [ ] Merchant accounts verified as ACTIVE with Worldline

---

**Last Updated:** 2025-11-30  
**Status:** Awaiting server restart and merchant verification

