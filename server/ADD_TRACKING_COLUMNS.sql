-- =====================================================
-- VMurugan Gold Trading - Database Schema Updates Part 2
-- Purpose: Add missing columns for transaction tracking
-- =====================================================

USE VMuruganGoldTrading;
GO

-- Add payment_year and payment_month to transactions table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_year')
BEGIN
    ALTER TABLE transactions
    ADD payment_year INT NULL;
    PRINT '✅ Added column: payment_year';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'payment_month')
BEGIN
    ALTER TABLE transactions
    ADD payment_month INT NULL;
    PRINT '✅ Added column: payment_month';
END
GO

-- Ensure device_info and location columns exist (they should, but just in case)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'device_info')
BEGIN
    ALTER TABLE transactions
    ADD device_info NVARCHAR(MAX) NULL;
    PRINT '✅ Added column: device_info';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'location')
BEGIN
    ALTER TABLE transactions
    ADD location NVARCHAR(MAX) NULL;
    PRINT '✅ Added column: location';
END
GO

PRINT '';
PRINT '=====================================================';
PRINT '✅ Database schema updates Part 2 completed successfully!';
PRINT '=====================================================';
