# Remaining Fixes for Transaction Save

## Status: Transactions ARE Being Saved ✅
The core authentication issue is FIXED. Transactions are now being saved to the database.

## Remaining Issues to Fix:

### 1. Create-After-Payment Missing Admin Token (CRITICAL)
**Location:** 
- `lib/features/silver/screens/buy_silver_screen.dart` line 1347-1350
- `lib/features/gold/screens/buy_gold_screen.dart` (check if same issue)

**Issue:** Manual headers without admin token
**Fix:** Use `await SqlServerService._getHeaders()` or add admin token manually

### 2. Analytics Endpoint 404
**Location:** `lib/core/services/customer_service.dart` line 358
**Issue:** `/api/analytics` endpoint doesn't exist
**Fix:** Either create endpoint or remove analytics call

### 3. Database Schema Issues

#### A. Missing Columns in transactions table:
- `silver_grams` DECIMAL(10,4)
- `silver_price_per_gram` DECIMAL(10,2)

#### B. Missing Column in schemes table:
- `total_amount_paid` DECIMAL(10,2) DEFAULT 0

#### C. Null Fields Issue:
Fields coming as null:
- `payment_year`
- `payment_month`
- `installment_number`
- `location`
- `device_info`

**Root Cause:** These fields are not being passed from the app or not being saved by the backend.

### 4. Incorrect Values Being Saved

#### A. Gold/Silver Grams Mismatch
**Issue:** Values shown in app differ from database values
**Cause:** Backend calculates server-side, but app might be showing different calculation

#### B. Silver Data Saved as Gold
**Issue:** Silver transactions save data into gold_gram/gold_price_per_gram columns
**Cause:** Backend doesn't detect metal type correctly for silver

#### C. Zero Values for Silver
**Issue:** silver_grams and silver_price_per_gram saved as 0.00
**Cause:** Backend not calculating silver values

## Implementation Order:

### Phase 1: Database Schema (DO FIRST)
```sql
-- Add missing columns to transactions table
ALTER TABLE transactions
ADD silver_grams DECIMAL(10,4) NULL,
    silver_price_per_gram DECIMAL(10,2) NULL;

-- Add missing column to schemes table
ALTER TABLE schemes
ADD total_amount_paid DECIMAL(10,2) DEFAULT 0;
```

### Phase 2: Fix Create-After-Payment Headers
Update both buy_gold_screen.dart and buy_silver_screen.dart to include admin token.

### Phase 3: Fix Backend Metal Detection
Update flexi-payment endpoint to:
1. Detect metal type from scheme_id (SF_* = silver, GF_* = gold)
2. Save to correct columns (silver_grams vs gold_grams)
3. Calculate correct metal amounts

### Phase 4: Fix Null Fields
Ensure app passes:
- location (from GPS)
- device_info (from device)
- payment_year, payment_month (from current date)
- installment_number (for PLUS schemes)

### Phase 5: Fix Analytics (Optional)
Either create endpoint or remove call.

## Next Steps:
1. Run SQL schema updates
2. Fix create-after-payment headers
3. Fix backend metal detection logic
4. Test both gold and silver payments
5. Verify all fields are saved correctly
