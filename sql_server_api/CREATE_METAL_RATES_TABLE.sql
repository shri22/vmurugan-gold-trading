-- ========================================
-- METAL RATES TABLE CREATION
-- ========================================
-- This table stores current gold/silver rates
-- Updated from MJDATA or admin panel

USE VMuruganGoldTrading;
GO

-- Create metal_rates table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'metal_rates')
BEGIN
    CREATE TABLE metal_rates (
        id INT IDENTITY(1,1) PRIMARY KEY,
        metal_type NVARCHAR(10) NOT NULL,  -- 'GOLD' or 'SILVER'
        rate DECIMAL(10,2) NOT NULL,       -- Rate per gram
        source NVARCHAR(50) NOT NULL,      -- 'MJDATA', 'ADMIN', 'API'
        is_active BIT DEFAULT 1,
        notes NVARCHAR(500) NULL,
        created_at DATETIME2(3) DEFAULT SYSDATETIME(),
        updated_at DATETIME2(3) DEFAULT SYSDATETIME()
    );

    -- Create indexes for better query performance
    CREATE INDEX IX_metal_rates_type_active ON metal_rates (metal_type, is_active, updated_at DESC);
    CREATE INDEX IX_metal_rates_source ON metal_rates (source, updated_at DESC);

    PRINT '✅ Metal rates table created successfully';
END
ELSE
BEGIN
    PRINT '⚠️ Metal rates table already exists';
END
GO

-- Insert default rates (will be updated by MJDATA fetch)
IF NOT EXISTS (SELECT * FROM metal_rates WHERE metal_type = 'GOLD' AND is_active = 1)
BEGIN
    INSERT INTO metal_rates (metal_type, rate, source, notes) 
    VALUES ('GOLD', 6500, 'ADMIN', 'Default rate - will be updated from MJDATA');
    PRINT '✅ Inserted default GOLD rate';
END

IF NOT EXISTS (SELECT * FROM metal_rates WHERE metal_type = 'SILVER' AND is_active = 1)
BEGIN
    INSERT INTO metal_rates (metal_type, rate, source, notes) 
    VALUES ('SILVER', 85, 'ADMIN', 'Default rate - will be updated from MJDATA');
    PRINT '✅ Inserted default SILVER rate';
END
GO

-- View current rates
SELECT 
    id,
    metal_type,
    rate,
    source,
    is_active,
    notes,
    created_at,
    updated_at
FROM metal_rates
WHERE is_active = 1
ORDER BY metal_type, updated_at DESC;
GO

PRINT '✅ Metal rates table is ready for use';
GO
