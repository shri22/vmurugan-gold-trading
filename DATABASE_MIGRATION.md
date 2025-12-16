# Database Changes Required for Monthly Payment Validation

## ✅ Current Schema Status

Your database **ALREADY HAS** the `schemes` table with most required fields.

---

## 🔴 REQUIRED: Add Missing Columns to `schemes` Table

### 1. Add `has_paid_this_month` Column

```sql
-- Add has_paid_this_month column to schemes table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'has_paid_this_month')
BEGIN
  ALTER TABLE schemes ADD has_paid_this_month BIT DEFAULT 0
  PRINT 'Added has_paid_this_month column to schemes table'
END
```

**Purpose**: Tracks if customer has paid for current month (0 = not paid, 1 = paid)

---

### 2. Add `last_payment_date` Column (Optional but Recommended)

```sql
-- Add last_payment_date column to schemes table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'last_payment_date')
BEGIN
  ALTER TABLE schemes ADD last_payment_date DATETIME2(3) NULL
  PRINT 'Added last_payment_date column to schemes table'
END
```

**Purpose**: Stores the date of last payment for reference

---

## 🔴 REQUIRED: Add Columns to `transactions` Table

Your `transactions` table already has `scheme_id` and `scheme_type`. You need to add:

### 1. Add `payment_month` Column

```sql
-- Add payment_month column to transactions table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_month')
BEGIN
  ALTER TABLE transactions ADD payment_month INT NULL
  PRINT 'Added payment_month column to transactions table'
END
```

**Purpose**: Stores month number (1-12) when payment was made

---

### 2. Add `payment_year` Column

```sql
-- Add payment_year column to transactions table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_year')
BEGIN
  ALTER TABLE transactions ADD payment_year INT NULL
  PRINT 'Added payment_year column to transactions table'
END
```

**Purpose**: Stores year (2024, 2025, etc.) when payment was made

---

## 📊 Create Indexes for Performance

```sql
-- Create index for fast monthly payment lookups
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_transactions_scheme_month')
BEGIN
  CREATE INDEX IX_transactions_scheme_month 
  ON transactions (scheme_id, payment_year, payment_month, status)
  PRINT 'Created index IX_transactions_scheme_month'
END

-- Create index for customer monthly lookups
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_transactions_customer_month')
BEGIN
  CREATE INDEX IX_transactions_customer_month 
  ON transactions (customer_phone, payment_year, payment_month, status)
  PRINT 'Created index IX_transactions_customer_month'
END
```

---

## 🔧 Complete Migration Script

**Copy and run this entire script in SQL Server Management Studio:**

```sql
USE VMuruganGoldTrading;
GO

PRINT '========================================';
PRINT 'Monthly Payment Validation - Database Migration';
PRINT '========================================';
PRINT '';

-- 1. Add has_paid_this_month to schemes table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'has_paid_this_month')
BEGIN
  ALTER TABLE schemes ADD has_paid_this_month BIT DEFAULT 0;
  PRINT '✅ Added has_paid_this_month column to schemes table';
END
ELSE
BEGIN
  PRINT '⏭️  has_paid_this_month column already exists';
END

-- 2. Add last_payment_date to schemes table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'last_payment_date')
BEGIN
  ALTER TABLE schemes ADD last_payment_date DATETIME2(3) NULL;
  PRINT '✅ Added last_payment_date column to schemes table';
END
ELSE
BEGIN
  PRINT '⏭️  last_payment_date column already exists';
END

-- 3. Add payment_month to transactions table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_month')
BEGIN
  ALTER TABLE transactions ADD payment_month INT NULL;
  PRINT '✅ Added payment_month column to transactions table';
END
ELSE
BEGIN
  PRINT '⏭️  payment_month column already exists';
END

-- 4. Add payment_year to transactions table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_year')
BEGIN
  ALTER TABLE transactions ADD payment_year INT NULL;
  PRINT '✅ Added payment_year column to transactions table';
END
ELSE
BEGIN
  PRINT '⏭️  payment_year column already exists';
END

-- 5. Update existing transactions with payment month/year
UPDATE transactions
SET 
  payment_month = MONTH(timestamp),
  payment_year = YEAR(timestamp)
WHERE payment_month IS NULL OR payment_year IS NULL;

PRINT '✅ Updated existing transactions with payment month/year';

-- 6. Create indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_transactions_scheme_month')
BEGIN
  CREATE INDEX IX_transactions_scheme_month 
  ON transactions (scheme_id, payment_year, payment_month, status);
  PRINT '✅ Created index IX_transactions_scheme_month';
END
ELSE
BEGIN
  PRINT '⏭️  Index IX_transactions_scheme_month already exists';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_transactions_customer_month')
BEGIN
  CREATE INDEX IX_transactions_customer_month 
  ON transactions (customer_phone, payment_year, payment_month, status);
  PRINT '✅ Created index IX_transactions_customer_month';
END
ELSE
BEGIN
  PRINT '⏭️  Index IX_transactions_customer_month already exists';
END

PRINT '';
PRINT '========================================';
PRINT '✅ Migration Complete!';
PRINT '========================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Update Node.js API to calculate has_paid_this_month';
PRINT '2. Update payment recording to set payment_month and payment_year';
PRINT '3. Set up monthly cron job to reset has_paid_this_month';
PRINT '';

-- Show table structure
PRINT 'Schemes table columns:';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'schemes'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT 'Transactions table columns (payment-related):';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'transactions' 
  AND COLUMN_NAME IN ('payment_month', 'payment_year', 'scheme_id', 'scheme_type', 'status')
ORDER BY ORDINAL_POSITION;
```

---

## 🔄 Update Your `server.js` File

Add this to your `createTablesIfNotExist()` function (around line 440):

```javascript
// Add has_paid_this_month column to schemes table
await pool.request().query(`
  IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'has_paid_this_month')
  BEGIN
    ALTER TABLE schemes ADD has_paid_this_month BIT DEFAULT 0
    PRINT 'Added has_paid_this_month column to schemes table'
  END
`);

// Add last_payment_date column to schemes table
await pool.request().query(`
  IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'last_payment_date')
  BEGIN
    ALTER TABLE schemes ADD last_payment_date DATETIME2(3) NULL
    PRINT 'Added last_payment_date column to schemes table'
  END
`);

// Add payment_month column to transactions table
await pool.request().query(`
  IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_month')
  BEGIN
    ALTER TABLE transactions ADD payment_month INT NULL
    PRINT 'Added payment_month column to transactions table'
  END
`);

// Add payment_year column to transactions table
await pool.request().query(`
  IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_year')
  BEGIN
    ALTER TABLE transactions ADD payment_year INT NULL
    PRINT 'Added payment_year column to transactions table'
  END
`);

// Update existing transactions with payment month/year
await pool.request().query(`
  UPDATE transactions
  SET 
    payment_month = MONTH(timestamp),
    payment_year = YEAR(timestamp)
  WHERE payment_month IS NULL OR payment_year IS NULL
`);

// Create indexes for performance
await pool.request().query(`
  IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_transactions_scheme_month')
  BEGIN
    CREATE INDEX IX_transactions_scheme_month 
    ON transactions (scheme_id, payment_year, payment_month, status)
    PRINT 'Created index IX_transactions_scheme_month'
  END
`);

await pool.request().query(`
  IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_transactions_customer_month')
  BEGIN
    CREATE INDEX IX_transactions_customer_month 
    ON transactions (customer_phone, payment_year, payment_month, status)
    PRINT 'Created index IX_transactions_customer_month'
  END
`);
```

---

## 📝 Summary

### New Columns Added:

**schemes table:**
- `has_paid_this_month` (BIT) - Tracks current month payment status
- `last_payment_date` (DATETIME2) - Last payment date

**transactions table:**
- `payment_month` (INT) - Month of payment (1-12)
- `payment_year` (INT) - Year of payment (2024, 2025, etc.)

### New Indexes:
- `IX_transactions_scheme_month` - Fast scheme monthly lookups
- `IX_transactions_customer_month` - Fast customer monthly lookups

---

## ✅ Verification

After running the migration, verify with:

```sql
-- Check schemes table
SELECT TOP 5 
  scheme_id, 
  customer_phone, 
  scheme_type, 
  has_paid_this_month, 
  last_payment_date 
FROM schemes;

-- Check transactions table
SELECT TOP 5 
  transaction_id, 
  scheme_id, 
  payment_month, 
  payment_year, 
  status 
FROM transactions 
WHERE scheme_id IS NOT NULL;
```

---

**Run the migration script and you're ready to go!** 🚀
