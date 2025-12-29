-- ========================================
-- AUDIT LOG TABLE CREATION
-- ========================================
-- This table tracks all critical actions performed in the system
-- for security auditing and compliance

USE VMuruganGoldTrading;
GO

-- Create audit_log table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'audit_log')
BEGIN
    CREATE TABLE audit_log (
        id INT IDENTITY(1,1) PRIMARY KEY,
        action NVARCHAR(100) NOT NULL,
        customer_id NVARCHAR(50) NULL,
        admin_username NVARCHAR(50) NULL,
        resource_id NVARCHAR(100) NULL,
        ip_address NVARCHAR(50) NULL,
        user_agent NVARCHAR(500) NULL,
        request_body NVARCHAR(MAX) NULL,
        timestamp DATETIME2(3) DEFAULT SYSDATETIME(),
        created_at DATETIME2(3) DEFAULT SYSDATETIME()
    );

    -- Create indexes for better query performance
    CREATE INDEX IX_audit_log_customer ON audit_log (customer_id);
    CREATE INDEX IX_audit_log_admin ON audit_log (admin_username);
    CREATE INDEX IX_audit_log_action ON audit_log (action);
    CREATE INDEX IX_audit_log_timestamp ON audit_log (timestamp);
    CREATE INDEX IX_audit_log_resource ON audit_log (resource_id);

    PRINT '✅ Audit log table created successfully';
END
ELSE
BEGIN
    PRINT '⚠️ Audit log table already exists';
END
GO

-- Verify table creation
SELECT 
    COUNT(*) as total_audit_records,
    MIN(timestamp) as first_record,
    MAX(timestamp) as last_record
FROM audit_log;
GO

PRINT '✅ Audit log table is ready for use';
GO

-- Sample query to view recent audit logs
SELECT TOP 100
    id,
    action,
    customer_id,
    admin_username,
    resource_id,
    ip_address,
    timestamp
FROM audit_log
ORDER BY timestamp DESC;
GO
