-- =====================================================
-- VMurugan Gold Trading - Database Schema Updates Part 3
-- Purpose: Add transaction_id to schemes table to prevent reuse
-- =====================================================

USE VMuruganGoldTrading;
GO

-- Add transaction_id to schemes table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'transaction_id')
BEGIN
    ALTER TABLE schemes
    ADD transaction_id NVARCHAR(100) NULL;
    PRINT '✅ Added column: transaction_id to schemes table';
END
GO

-- Add index on transaction_id for performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('schemes') AND name = 'idx_schemes_transaction_id')
BEGIN
    CREATE INDEX idx_schemes_transaction_id ON schemes(transaction_id);
    PRINT '✅ Created index: idx_schemes_transaction_id';
END
GO

PRINT '';
PRINT '=====================================================';
PRINT '✅ Database schema updates Part 3 completed successfully!';
PRINT '=====================================================';
