# Server-Side Changes Required for Monthly Payment Validation

## Overview
The Flutter app now implements proper monthly payment validation at the UI level. The server must support this by providing accurate `has_paid_this_month` data.

---

## ✅ What the App Now Does (Client-Side)

### 1. Navigation-Level Blocking
- **Before**: Users could reach payment screen even if they already paid
- **After**: Users are blocked at scheme details screen if `has_paid_this_month = true`

### 2. Amount Field Behavior
- **First Month**: Amount field is editable, user can enter any amount
- **Subsequent Months**: Amount field is READ-ONLY, pre-filled from `monthly_amount` in database

### 3. Validation Flow
```
User clicks "View Scheme"
  ↓
App fetches scheme data from: GET /schemes/{customerPhone}
  ↓
App checks: has_paid_this_month?
  ↓
If TRUE → Show blocking dialog, DON'T navigate
If FALSE → Navigate to payment screen with correct parameters
```

---

## 🔴 CRITICAL: Server Must Provide Accurate Data

### Required API Endpoint
**Endpoint**: `GET /schemes/{customerPhone}`

**Current Response** (example):
```json
{
  "success": true,
  "schemes": [
    {
      "scheme_id": "SCH123",
      "scheme_type": "GOLDPLUS",
      "monthly_amount": 5000,
      "created_at": "2024-11-15T10:30:00Z",
      "has_paid_this_month": 0  // ← CRITICAL FIELD
    }
  ]
}
```

### What `has_paid_this_month` Must Represent

**Value**: `0` or `1` (or `false`/`true`)

**Logic**: 
```sql
-- Pseudo-SQL for has_paid_this_month calculation
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM payments 
      WHERE scheme_id = s.scheme_id 
        AND customer_phone = s.customer_phone
        AND YEAR(payment_date) = YEAR(CURRENT_DATE)
        AND MONTH(payment_date) = MONTH(CURRENT_DATE)
        AND payment_status = 'SUCCESS'
    ) THEN 1
    ELSE 0
  END AS has_paid_this_month
FROM schemes s
WHERE s.customer_phone = ?
```

**Important**:
- Must check **CURRENT MONTH AND YEAR**
- Must check **SUCCESS** payments only
- Must update **IMMEDIATELY** after payment
- Must reset to `0` when month changes

---

## 📊 Database Schema Requirements

### Payments Table
Must have these columns to support monthly validation:

```sql
CREATE TABLE payments (
  payment_id VARCHAR(50) PRIMARY KEY,
  scheme_id VARCHAR(50),
  customer_phone VARCHAR(15),
  amount DECIMAL(10,2),
  payment_date DATETIME,
  payment_status VARCHAR(20), -- 'SUCCESS', 'FAILED', 'PENDING'
  payment_month INT,  -- Month number (1-12)
  payment_year INT,   -- Year (2024, 2025, etc.)
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_scheme_month (scheme_id, payment_year, payment_month),
  INDEX idx_customer_month (customer_phone, payment_year, payment_month)
);
```

### Schemes Table
Must have these columns:

```sql
CREATE TABLE schemes (
  scheme_id VARCHAR(50) PRIMARY KEY,
  customer_phone VARCHAR(15),
  scheme_type VARCHAR(20), -- 'GOLDPLUS', 'SILVERPLUS', 'GOLDFLEXI', 'SILVERFLEXI'
  monthly_amount DECIMAL(10,2),
  created_at DATETIME,
  -- ... other fields
);
```

---

## 🔧 Server-Side Implementation

### Option 1: Calculate on Query (Recommended)
Calculate `has_paid_this_month` dynamically when fetching schemes:

```javascript
// Node.js example
app.get('/schemes/:customerPhone', async (req, res) => {
  const { customerPhone } = req.params;
  const currentMonth = new Date().getMonth() + 1;
  const currentYear = new Date().getFullYear();
  
  const query = `
    SELECT 
      s.*,
      CASE 
        WHEN EXISTS (
          SELECT 1 
          FROM payments p
          WHERE p.scheme_id = s.scheme_id 
            AND p.customer_phone = s.customer_phone
            AND p.payment_year = ?
            AND p.payment_month = ?
            AND p.payment_status = 'SUCCESS'
        ) THEN 1
        ELSE 0
      END AS has_paid_this_month
    FROM schemes s
    WHERE s.customer_phone = ?
  `;
  
  const schemes = await db.query(query, [currentYear, currentMonth, customerPhone]);
  
  res.json({
    success: true,
    schemes: schemes
  });
});
```

### Option 2: Store in Database
Add `has_paid_this_month` column to schemes table and update it:

```javascript
// After successful payment
async function updateSchemePaymentStatus(schemeId, customerPhone) {
  const currentMonth = new Date().getMonth() + 1;
  const currentYear = new Date().getFullYear();
  
  // Update scheme
  await db.query(`
    UPDATE schemes 
    SET has_paid_this_month = 1,
        last_payment_date = NOW()
    WHERE scheme_id = ? AND customer_phone = ?
  `, [schemeId, customerPhone]);
}

// Reset monthly (run as cron job on 1st of each month)
async function resetMonthlyPaymentFlags() {
  await db.query(`
    UPDATE schemes 
    SET has_paid_this_month = 0
  `);
}
```

---

## 🎯 Payment Recording Requirements

### When Payment is Successful
The server MUST:

1. **Record payment** in payments table:
```sql
INSERT INTO payments (
  payment_id,
  scheme_id,
  customer_phone,
  amount,
  payment_date,
  payment_status,
  payment_month,
  payment_year
) VALUES (
  ?,  -- transaction_id from payment gateway
  ?,  -- scheme_id
  ?,  -- customer_phone
  ?,  -- amount
  NOW(),
  'SUCCESS',
  MONTH(NOW()),
  YEAR(NOW())
);
```

2. **Update scheme status** (if using Option 2):
```sql
UPDATE schemes 
SET has_paid_this_month = 1,
    last_payment_date = NOW()
WHERE scheme_id = ? AND customer_phone = ?;
```

3. **Return success response**:
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "payment_id": "TXN123456",
  "scheme_id": "SCH123"
}
```

---

## 🔄 Monthly Reset (CRITICAL)

### Automated Reset Required
On the 1st of every month, reset `has_paid_this_month` to `0`:

```javascript
// Cron job - runs at 00:01 on 1st of every month
// crontab: 1 0 1 * * node reset-monthly-flags.js

const cron = require('node-cron');

// Schedule: At 00:01 on day-of-month 1
cron.schedule('1 0 1 * *', async () => {
  console.log('Resetting monthly payment flags...');
  
  await db.query(`
    UPDATE schemes 
    SET has_paid_this_month = 0
    WHERE scheme_type IN ('GOLDPLUS', 'SILVERPLUS')
  `);
  
  console.log('Monthly payment flags reset complete');
});
```

**Alternative**: If using Option 1 (calculate on query), no reset needed as it's always calculated from current month.

---

## ✅ Testing Checklist

### Test Case 1: First Payment of Month
1. User joins GOLDPLUS scheme in December
2. Makes first payment in December
3. Server records payment with `payment_month=12, payment_year=2024`
4. Next API call shows `has_paid_this_month=1`
5. User is blocked from making another payment in December

### Test Case 2: New Month
1. January 1st arrives
2. Cron job resets `has_paid_this_month=0` (or query calculates it as 0)
3. User can now make January payment
4. After payment, `has_paid_this_month=1` again

### Test Case 3: Multiple Schemes
1. User has both GOLDPLUS and SILVERPLUS
2. Pays for GOLDPLUS in December
3. GOLDPLUS shows `has_paid_this_month=1`
4. SILVERPLUS still shows `has_paid_this_month=0`
5. User can still pay for SILVERPLUS

---

## 🚨 Common Pitfalls to Avoid

### ❌ Wrong: Checking only payment existence
```sql
-- DON'T DO THIS
SELECT COUNT(*) FROM payments WHERE scheme_id = ?
-- This doesn't check CURRENT MONTH
```

### ✅ Correct: Check current month and year
```sql
-- DO THIS
SELECT COUNT(*) FROM payments 
WHERE scheme_id = ? 
  AND payment_year = YEAR(CURRENT_DATE)
  AND payment_month = MONTH(CURRENT_DATE)
  AND payment_status = 'SUCCESS'
```

### ❌ Wrong: Not filtering by status
```sql
-- DON'T DO THIS
SELECT COUNT(*) FROM payments 
WHERE scheme_id = ? AND payment_month = ?
-- This includes FAILED payments
```

### ✅ Correct: Only count successful payments
```sql
-- DO THIS
SELECT COUNT(*) FROM payments 
WHERE scheme_id = ? 
  AND payment_month = ?
  AND payment_status = 'SUCCESS'
```

---

## 📝 Summary of Server Changes

### Required Changes:
1. ✅ Ensure `has_paid_this_month` is calculated correctly in `/schemes/{customerPhone}` API
2. ✅ Store `payment_month` and `payment_year` when recording payments
3. ✅ Set up monthly cron job to reset flags (if using stored flag approach)
4. ✅ Add indexes on `(scheme_id, payment_year, payment_month)` for performance

### Optional but Recommended:
- Add `last_payment_date` column to schemes table
- Add `payment_count` column to track total payments
- Add API endpoint to get payment history: `GET /schemes/{schemeId}/payments`

---

## 🔍 Verification

### How to Verify Server is Working Correctly:

1. **Test API Response**:
```bash
curl http://your-server.com/schemes/9876543210
```

Expected response:
```json
{
  "success": true,
  "schemes": [
    {
      "scheme_id": "SCH123",
      "scheme_type": "GOLDPLUS",
      "monthly_amount": 5000,
      "has_paid_this_month": 0  // ← Must be present and accurate
    }
  ]
}
```

2. **Test After Payment**:
- Make a payment
- Call API again
- `has_paid_this_month` should now be `1`

3. **Test Month Rollover**:
- Wait for 1st of next month (or manually change server date for testing)
- Call API
- `has_paid_this_month` should be `0` again

---

## 🎯 Final Notes

- The app now handles ALL UI-level validation
- Server just needs to provide accurate `has_paid_this_month` data
- No changes needed to payment processing logic
- No changes needed to scheme creation logic
- Only changes needed are in scheme fetching and payment recording

**If you have any questions about implementing these server changes, please let me know!**
