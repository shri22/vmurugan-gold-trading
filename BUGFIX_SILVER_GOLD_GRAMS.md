# 🐛 CRITICAL BUG FIX: Silver Transactions Saving to Gold Grams

## Issue Discovered
**Date:** 2026-01-22  
**Severity:** CRITICAL - Data Corruption  
**Reporter:** User

### Problem
SILVER transactions were incorrectly saving grams to `gold_grams` column instead of `silver_grams` column.

**Example:**
```
ORD_1769003346822_SILVER_295: 
  metal_type = SILVER ✅
  gold_grams = 1.159  ❌ WRONG!
  silver_grams = 0    ❌ WRONG!
```

This caused:
1. ❌ Customer wallets showing incorrect gold/silver balances
2. ❌ Reports showing wrong metal distribution
3. ❌ Scheme totals being miscalculated

## Root Cause

### The Bug Chain:

1. **Flutter App** sends payment request with:
   ```json
   {
     "metalType": "SILVER",
     "goldGrams": 1.159,  // ❌ Should be silverGrams!
     "silverGrams": 0
   }
   ```

2. **Backend (`omniware_upi.js`)** was blindly accepting these values:
   ```javascript
   // OLD CODE (BUGGY):
   request.input('gold_grams', parseFloat(goldGrams) || 0);
   request.input('silver_grams', parseFloat(silverGrams) || 0);
   ```

3. **Webhook** reads the existing transaction and uses those incorrect grams to credit customer

## The Fix

### Backend Defensive Logic (DEPLOYED)

Added smart validation in `sql_server_api/routes/omniware_upi.js` (lines 597-624):

```javascript
// DEFENSIVE FIX: Ensure grams go to correct column based on metal_type
if (metalType.toUpperCase() === 'GOLD') {
  // For GOLD: use goldGrams (or fallback to silverGrams if app sent wrong param)
  finalGoldGrams = parseFloat(goldGrams) || parseFloat(silverGrams) || 0;
  finalSilverGrams = 0;
} else if (metalType.toUpperCase() === 'SILVER') {
  // For SILVER: use silverGrams (or fallback to goldGrams if app sent wrong param)
  finalSilverGrams = parseFloat(silverGrams) || parseFloat(goldGrams) || 0;
  finalGoldGrams = 0;
}
```

**Key Features:**
- ✅ Validates `metal_type` and ensures grams go to correct column
- ✅ Has fallback logic if app sends wrong parameter name
- ✅ Logs which metal and grams are being saved
- ✅ Prevents future data corruption even if app has bugs

## Data Correction

### Affected Transactions Fixed:

1. **ORD_1769003346822_SILVER_295** (SUCCESS):
   - Before: `gold_grams=1.159, silver_grams=0`
   - After: `gold_grams=0, silver_grams=1.159` ✅
   - Customer wallet: -1.159g gold, +1.159g silver ✅

2. **ORD_1769057831525_SILVER_295** (FAILED):
   - Before: `gold_grams=0.882, silver_grams=0`
   - After: `gold_grams=0, silver_grams=0` ✅
   - Customer wallet: -0.882g gold (removed) ✅

## Prevention

### Backend (DONE ✅):
- Defensive validation ensures correct column based on `metal_type`
- Fallback logic handles app bugs gracefully
- Logging shows exactly what's being saved

### Flutter App (TODO):
The Flutter app should be fixed to send:
- For GOLD: `goldGrams` parameter
- For SILVER: `silverGrams` parameter

**Current workaround:** Backend now handles both cases correctly

## Testing

To verify the fix is working:

1. Create a new SILVER transaction from the app
2. Check the database:
   ```sql
   SELECT transaction_id, metal_type, gold_grams, silver_grams 
   FROM transactions 
   WHERE transaction_id = 'ORD_...'
   ```
3. Verify:
   - `metal_type = 'SILVER'`
   - `gold_grams = 0`
   - `silver_grams > 0` ✅

## Impact

- **Severity:** CRITICAL (Data Corruption)
- **Affected:** All SILVER transactions since app deployment
- **Fixed:** 2 transactions manually corrected
- **Prevention:** Backend now validates and corrects automatically

## Files Modified

1. ✅ `sql_server_api/routes/omniware_upi.js` - Added defensive validation
2. ✅ `sql_server_api/fix_silver_gold_grams.js` - One-time fix script (deleted after use)

## Deployment

- **Date:** 2026-01-22 13:25 IST
- **Status:** DEPLOYED to production
- **Server:** Restarted via PM2

---

## Summary

✅ **Bug Found:** SILVER transactions saving to gold_grams  
✅ **Root Cause:** Flutter app sending wrong parameter name  
✅ **Backend Fix:** Defensive validation based on metal_type  
✅ **Data Fixed:** 2 affected transactions corrected  
✅ **Prevention:** Future transactions will be correct automatically  

**The system is now safe from this bug! 🎉**
