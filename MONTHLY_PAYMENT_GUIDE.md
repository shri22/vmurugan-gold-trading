# Monthly Payment Restriction - How It Works & Troubleshooting

**Date:** December 6, 2025, 9:47 PM

---

## 📋 **How It Works**

### **For Gold Plus / Silver Plus Schemes:**

```
Customer Flow:
1. Customer joins Gold Plus scheme (pays ₹5000/month)
2. Makes FIRST payment on Dec 5, 2025
   ✅ Payment succeeds
   ✅ Transaction saved with scheme_id
   
3. Tries to pay AGAIN on Dec 20, 2025
   ❌ System checks: "Already paid in December 2025"
   ❌ Shows error: "You have already made your payment for this month"
   
4. Can pay again on Jan 1, 2026 onwards
   ✅ New month, payment allowed
```

---

## 🔧 **Technical Flow**

### **Step 1: Customer Makes Payment**
**File:** `buy_gold_screen.dart` (Line 658)

```dart
// Validation is called BEFORE payment
final validationResult = await SchemePaymentValidationService.validateSchemePayment(
  schemeId: widget.schemeId,      // e.g., "SCH_GOLDPLUS_123"
  customerPhone: customerPhone,    // e.g., "9876543210"
  amount: _selectedAmount,
);

if (!validationResult.canPay) {
  // Show error message
  return; // Stop payment
}
```

### **Step 2: Validation Service Checks**
**File:** `scheme_payment_validation_service.dart` (Line 84)

```dart
// Check if there's already a successful payment this month
final hasPaymentThisMonth = await _hasSuccessfulPaymentThisMonth(
  schemeId,
  customerPhone,
  currentMonth,  // e.g., 12 (December)
  currentYear,   // e.g., 2025
);

if (hasPaymentThisMonth) {
  return SchemePaymentValidationResult(
    canPay: false,
    message: 'You have already made your payment for this month.',
  );
}
```

### **Step 3: Server API Checks Database**
**File:** `server.js` (Line 2647)

```sql
SELECT COUNT(*) as payment_count
FROM transactions
WHERE customer_phone = @customer_phone
  AND scheme_id = @scheme_id
  AND payment_method = 'SCHEME_INVESTMENT'
  AND status = 'SUCCESS'
  AND MONTH(timestamp) = @month
  AND YEAR(timestamp) = @year
```

**If count > 0:** Payment already made this month ❌  
**If count = 0:** No payment this month, allow ✅

---

## ❓ **Why It's Not Working - Troubleshooting**

### **Issue 1: Server Not Restarted**
**Problem:** The fix is in code but server is still running old code.

**Solution:**
```bash
# Restart your Node.js server
pm2 restart vmurugan-api

# OR if running directly
# Stop server (Ctrl+C)
# Start again
node server.js
```

**Test:** Make API call to check:
```bash
curl "http://localhost:3001/api/schemes/YOUR_SCHEME_ID/payments/monthly-check?month=12&year=2025"
```

---

### **Issue 2: Transactions Not Saving scheme_id**
**Problem:** Old transactions don't have `scheme_id` column populated.

**Check Database:**
```sql
SELECT TOP 10
    transaction_id,
    customer_phone,
    scheme_id,
    payment_method,
    timestamp
FROM transactions
WHERE payment_method = 'SCHEME_INVESTMENT'
ORDER BY timestamp DESC;
```

**Expected:** `scheme_id` should have values like "SCH_GOLDPLUS_123"  
**If NULL:** Transactions aren't saving scheme_id properly

**Fix:** Check transaction saving code in `buy_gold_screen.dart` around line 874

---

### **Issue 3: Wrong Payment Method**
**Problem:** Transactions saved with different payment_method.

**Check:**
```sql
SELECT DISTINCT payment_method
FROM transactions
WHERE scheme_id IS NOT NULL;
```

**Expected:** Should be `'SCHEME_INVESTMENT'`  
**If different:** Update the query to match actual payment_method

---

### **Issue 4: App Using Old APK**
**Problem:** You're testing with old APK that doesn't have validation code.

**Solution:**
```bash
# Rebuild and install new APK
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

### **Issue 5: Testing with FLEXI Scheme**
**Problem:** FLEXI schemes (Gold Flexi, Silver Flexi) have NO monthly restrictions.

**Check:** Make sure you're testing with:
- ✅ Gold Plus
- ✅ Silver Plus

**NOT:**
- ❌ Gold Flexi (allows unlimited payments)
- ❌ Silver Flexi (allows unlimited payments)

---

## 🧪 **How to Test Properly**

### **Test Case 1: First Payment (Should Work)**
```
1. Open Gold Plus scheme
2. Click "Pay Monthly Installment"
3. Enter amount (e.g., ₹5000)
4. Complete payment
5. ✅ Should succeed
```

### **Test Case 2: Second Payment Same Month (Should Block)**
```
1. Open same Gold Plus scheme
2. Click "Pay Monthly Installment" again
3. Enter amount
4. Try to pay
5. ❌ Should show error:
   "You have already made your payment for this month.
    Please pay next month."
```

### **Test Case 3: Payment Next Month (Should Work)**
```
1. Wait until next month OR change system date
2. Open Gold Plus scheme
3. Click "Pay Monthly Installment"
4. Complete payment
5. ✅ Should succeed
```

---

## 🔍 **Debug Steps**

### **Step 1: Check Server Logs**
```bash
# Watch server logs
tail -f /path/to/server/logs

# Look for:
"📊 Checking monthly payment for scheme: SCH_XXX, Month: 12, Year: 2025"
```

### **Step 2: Check App Logs**
```bash
# Run app with logs
flutter run

# Look for:
"🔍 BUY GOLD: Starting validation..."
"🔍 BUY GOLD: Validation result: ..."
```

### **Step 3: Test API Directly**
```bash
# Test monthly check endpoint
curl "http://YOUR_SERVER:3001/api/schemes/SCH_GOLDPLUS_123/payments/monthly-check?month=12&year=2025"

# Expected response:
{
  "success": true,
  "has_payment": true,  // or false
  "payment_count": 1,   // or 0
  "message": "Payment found for this month"
}
```

---

## 📊 **Database Schema Check**

### **Transactions Table Should Have:**
```sql
CREATE TABLE transactions (
    transaction_id NVARCHAR(100),
    customer_phone NVARCHAR(15),
    scheme_id NVARCHAR(100),      -- ✅ This column is REQUIRED
    payment_method NVARCHAR(50),  -- Should be 'SCHEME_INVESTMENT'
    status NVARCHAR(20),          -- Should be 'SUCCESS'
    timestamp DATETIME,
    ...
);
```

**If scheme_id column is missing:**
```sql
ALTER TABLE transactions
ADD scheme_id NVARCHAR(100);
```

---

## ✅ **Checklist**

Before reporting "not working", verify:

- [ ] Server restarted after code changes
- [ ] Using NEW APK (rebuilt after fix)
- [ ] Testing with PLUS scheme (not FLEXI)
- [ ] Database has `scheme_id` column
- [ ] Transactions are saving with `scheme_id`
- [ ] Payment method is 'SCHEME_INVESTMENT'
- [ ] Checking logs for validation messages

---

## 🎯 **Quick Fix Commands**

```bash
# 1. Restart server
pm2 restart vmurugan-api

# 2. Rebuild app
cd /Users/admin/Documents/Win-Projects/AntiGravity/vmurugan-gold-trading
flutter build apk --release

# 3. Install new APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 4. Test
# Make payment → Try again → Should block
```

---

## 📞 **Still Not Working?**

**Send me:**
1. Server logs when making payment
2. App logs showing validation
3. Database query result:
   ```sql
   SELECT * FROM transactions 
   WHERE scheme_id IS NOT NULL 
   ORDER BY timestamp DESC;
   ```

**I'll help debug!** 🔧
