-- ============================================
-- NOTIFICATION SYSTEM - DATABASE SCHEMA
-- ============================================
-- Run this script on your production SQL Server database
-- to create the notifications table and indexes

-- Create notifications table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'notifications')
BEGIN
    CREATE TABLE notifications (
        notification_id NVARCHAR(50) PRIMARY KEY,
        user_id NVARCHAR(15) NOT NULL,  -- customer phone
        type NVARCHAR(50) NOT NULL,
        title NVARCHAR(200) NOT NULL,
        message NVARCHAR(MAX) NOT NULL,
        is_read BIT DEFAULT 0,
        created_at DATETIME DEFAULT GETDATE(),
        read_at DATETIME NULL,
        data NVARCHAR(MAX) NULL,  -- JSON data
        priority NVARCHAR(20) DEFAULT 'normal',
        image_url NVARCHAR(500) NULL,
        action_url NVARCHAR(500) NULL,
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        sent_by NVARCHAR(50) DEFAULT 'SYSTEM',  -- 'SYSTEM' or 'ADMIN'
        
        -- Indexes for performance
        INDEX idx_user_notifications (user_id, created_at DESC),
        INDEX idx_unread (user_id, is_read),
        INDEX idx_type (type),
        INDEX idx_created_at (created_at DESC),
        INDEX idx_business (business_id)
    );
    
    PRINT '✅ Notifications table created successfully';
END
ELSE
BEGIN
    PRINT '⚠️ Notifications table already exists';
END
GO

-- Verify table creation
SELECT 
    COUNT(*) as total_notifications,
    SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_count,
    SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count
FROM notifications;
GO

PRINT '✅ Notification system database setup complete!';
PRINT '';
PRINT '📋 Next Steps:';
PRINT '1. Restart your Node.js server (sql_server_api)';
PRINT '2. Test notification sending from admin panel';
PRINT '3. Verify notifications appear in customer app';
GO

