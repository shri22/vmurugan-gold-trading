-- =====================================================
-- VMurugan Gold Trading - Database Schema Updates
-- Purpose: Add missing columns for silver transactions
-- =====================================================

USE VMuruganGoldTrading;
GO

-- Add silver-related columns to transactions table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'silver_grams')
BEGIN
    ALTER TABLE transactions
    ADD silver_grams DECIMAL(10,4) NULL;
    PRINT '✅ Added column: silver_grams';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: silver_grams';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'silver_price_per_gram')
BEGIN
    ALTER TABLE transactions
    ADD silver_price_per_gram DECIMAL(10,2) NULL;
    PRINT '✅ Added column: silver_price_per_gram';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: silver_price_per_gram';
END
GO

-- Add total_amount_paid to schemes table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'total_amount_paid')
BEGIN
    ALTER TABLE schemes
    ADD total_amount_paid DECIMAL(10,2) DEFAULT 0;
    PRINT '✅ Added column: total_amount_paid';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: total_amount_paid';
END
GO

PRINT '';
PRINT '=====================================================';
PRINT '✅ Database schema updates completed successfully!';
PRINT '=====================================================';
