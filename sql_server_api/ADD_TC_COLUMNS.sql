-- =====================================================
-- VMurugan Gold Trading - Add T&C Tracking Columns
-- Purpose: Add Terms & Conditions acceptance tracking
-- =====================================================

USE VMuruganGoldTrading;
GO

-- Add terms_accepted column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'terms_accepted')
BEGIN
    ALTER TABLE customers ADD terms_accepted BIT DEFAULT 0;
    PRINT '✅ Added column: terms_accepted';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: terms_accepted';
END
GO

-- Add terms_accepted_at column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'terms_accepted_at')
BEGIN
    ALTER TABLE customers ADD terms_accepted_at DATETIME2(3) NULL;
    PRINT '✅ Added column: terms_accepted_at';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: terms_accepted_at';
END
GO

-- Add terms_accepted_ip column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'terms_accepted_ip')
BEGIN
    ALTER TABLE customers ADD terms_accepted_ip NVARCHAR(45) NULL;
    PRINT '✅ Added column: terms_accepted_ip';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: terms_accepted_ip';
END
GO

-- Add is_active column if it doesn't exist (for deactivation feature)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'is_active')
BEGIN
    ALTER TABLE customers ADD is_active BIT DEFAULT 1;
    PRINT '✅ Added column: is_active';
END
ELSE
BEGIN
    PRINT 'ℹ️  Column already exists: is_active';
END
GO

-- Verify the columns were added
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customers'
    AND COLUMN_NAME IN ('terms_accepted', 'terms_accepted_at', 'terms_accepted_ip', 'is_active')
ORDER BY COLUMN_NAME;

PRINT '';
PRINT '=====================================================';
PRINT '✅ T&C and deactivation columns added successfully!';
PRINT '=====================================================';
