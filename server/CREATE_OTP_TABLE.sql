-- ========================================
-- OTP STORAGE TABLE CREATION
-- ========================================
-- This table stores OTPs for customer authentication

USE VMuruganGoldTrading;
GO

-- Create otp_storage table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'otp_storage')
BEGIN
    CREATE TABLE otp_storage (
        id INT IDENTITY(1,1) PRIMARY KEY,
        phone NVARCHAR(15) NOT NULL,
        otp_code NVARCHAR(6) NOT NULL,
        expires_at DATETIME2(3) NOT NULL,
        is_used BIT DEFAULT 0,
        attempts INT DEFAULT 0,
        created_at DATETIME2(3) DEFAULT SYSDATETIME(),
        used_at DATETIME2(3) NULL
    );

    -- Create indexes for better query performance
    CREATE INDEX IX_otp_phone ON otp_storage (phone, expires_at DESC);
    CREATE INDEX IX_otp_expires ON otp_storage (expires_at);

    PRINT '✅ OTP storage table created successfully';
END
ELSE
BEGIN
    PRINT '⚠️ OTP storage table already exists';
END
GO

-- View current OTPs (for testing)
SELECT 
    id,
    phone,
    otp_code,
    expires_at,
    is_used,
    attempts,
    created_at,
    CASE 
        WHEN expires_at < SYSDATETIME() THEN 'EXPIRED'
        WHEN is_used = 1 THEN 'USED'
        ELSE 'VALID'
    END as status
FROM otp_storage
WHERE created_at > DATEADD(HOUR, -24, SYSDATETIME())
ORDER BY created_at DESC;
GO

PRINT '✅ OTP storage table is ready for use';
GO
