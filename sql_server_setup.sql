-- ========================================
-- VMurugan Gold Trading - SQL Server Setup
-- ========================================
-- Run this script in SQL Server Management Studio (SSMS)
-- Make sure to run as Administrator

USE master;
GO

PRINT '🏆 VMurugan Gold Trading - Database Setup Starting...';
PRINT '======================================================';

-- ========================================
-- STEP 1: Create Database
-- ========================================
PRINT '';
PRINT '📁 STEP 1: Creating Database...';

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'VMuruganGoldTrading')
BEGIN
    CREATE DATABASE VMuruganGoldTrading;
    PRINT '✅ Database VMuruganGoldTrading created successfully';
END
ELSE
BEGIN
    PRINT '⚠️  Database VMuruganGoldTrading already exists - skipping';
END
GO

-- ========================================
-- STEP 2: Create Application User
-- ========================================
PRINT '';
PRINT '👤 STEP 2: Creating Application User...';

USE master;
GO

-- Create login if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'vmurugan_user')
BEGIN
    CREATE LOGIN vmurugan_user WITH PASSWORD = 'VMurugan@2025!';
    PRINT '✅ Login vmurugan_user created successfully';
END
ELSE
BEGIN
    PRINT '⚠️  Login vmurugan_user already exists - skipping';
END
GO

-- Switch to application database
USE VMuruganGoldTrading;
GO

-- Create user if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'vmurugan_user')
BEGIN
    CREATE USER vmurugan_user FOR LOGIN vmurugan_user;
    PRINT '✅ User vmurugan_user created in database';
END
ELSE
BEGIN
    PRINT '⚠️  User vmurugan_user already exists in database - skipping';
END
GO

-- Grant permissions
IF IS_ROLEMEMBER('db_owner', 'vmurugan_user') = 0
BEGIN
    ALTER ROLE db_owner ADD MEMBER vmurugan_user;
    PRINT '✅ Granted db_owner permissions to vmurugan_user';
END
ELSE
BEGIN
    PRINT '⚠️  User vmurugan_user already has db_owner permissions - skipping';
END
GO

-- ========================================
-- STEP 3: Create Tables
-- ========================================
PRINT '';
PRINT '📋 STEP 3: Creating Tables...';

-- Create Customers table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='customers' AND xtype='U')
BEGIN
    CREATE TABLE customers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        phone NVARCHAR(15) UNIQUE NOT NULL,
        name NVARCHAR(100) NOT NULL,
        email NVARCHAR(100),
        address NVARCHAR(MAX),
        pan_card NVARCHAR(10),
        device_id NVARCHAR(100),
        registration_date DATETIME2 DEFAULT GETDATE(),
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        total_invested DECIMAL(12,2) DEFAULT 0.00,
        total_gold DECIMAL(10,4) DEFAULT 0.0000,
        transaction_count INT DEFAULT 0,
        last_transaction DATETIME2 NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    
    -- Create indexes for customers table
    CREATE INDEX IX_customers_phone ON customers (phone);
    CREATE INDEX IX_customers_business ON customers (business_id);
    CREATE INDEX IX_customers_registration ON customers (registration_date);
    
    PRINT '✅ Customers table created with indexes';
END
ELSE
BEGIN
    PRINT '⚠️  Customers table already exists - skipping';
END
GO

-- Create Transactions table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='transactions' AND xtype='U')
BEGIN
    CREATE TABLE transactions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        transaction_id NVARCHAR(100) UNIQUE NOT NULL,
        customer_phone NVARCHAR(15),
        customer_name NVARCHAR(100),
        type NVARCHAR(10) NOT NULL CHECK (type IN ('BUY', 'SELL')),
        amount DECIMAL(12,2) NOT NULL,
        gold_grams DECIMAL(10,4) NOT NULL,
        gold_price_per_gram DECIMAL(10,2) NOT NULL,
        payment_method NVARCHAR(50) NOT NULL,
        status NVARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
        gateway_transaction_id NVARCHAR(100),
        device_info NVARCHAR(MAX),
        location NVARCHAR(MAX),
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        timestamp DATETIME2 DEFAULT GETDATE(),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (customer_phone) REFERENCES customers(phone)
    );
    
    -- Create indexes for transactions table
    CREATE INDEX IX_transactions_customer ON transactions (customer_phone);
    CREATE INDEX IX_transactions_status ON transactions (status);
    CREATE INDEX IX_transactions_timestamp ON transactions (timestamp);
    CREATE INDEX IX_transactions_type ON transactions (type);
    CREATE INDEX IX_transactions_business ON transactions (business_id);
    
    PRINT '✅ Transactions table created with indexes';
END
ELSE
BEGIN
    PRINT '⚠️  Transactions table already exists - skipping';
END
GO

-- ========================================
-- STEP 4: Insert Test Data
-- ========================================
PRINT '';
PRINT '🧪 STEP 4: Inserting Test Data...';

-- Insert test customer
IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = '9999999999')
BEGIN
    INSERT INTO customers (phone, name, email, address, pan_card, device_id)
    VALUES ('9999999999', 'Test Customer', 'test@vmurugan.com', 'Test Address, Chennai', 'ABCDE1234F', 'test_device_001');
    PRINT '✅ Test customer inserted';
END
ELSE
BEGIN
    PRINT '⚠️  Test customer already exists - skipping';
END
GO

-- Insert test transaction
IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = 'TEST_TXN_001')
BEGIN
    INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount, 
        gold_grams, gold_price_per_gram, payment_method, status
    )
    VALUES (
        'TEST_TXN_001', '9999999999', 'Test Customer', 'BUY', 5000.00,
        1.0000, 5000.00, 'GATEWAY', 'SUCCESS'
    );
    PRINT '✅ Test transaction inserted';
END
ELSE
BEGIN
    PRINT '⚠️  Test transaction already exists - skipping';
END
GO

-- ========================================
-- STEP 5: Create Views for Reporting
-- ========================================
PRINT '';
PRINT '📊 STEP 5: Creating Views...';

-- Customer summary view
IF NOT EXISTS (SELECT * FROM sys.views WHERE name = 'customer_summary')
BEGIN
    EXEC('
    CREATE VIEW customer_summary AS
    SELECT 
        c.id,
        c.phone,
        c.name,
        c.email,
        c.registration_date,
        c.total_invested,
        c.total_gold,
        c.transaction_count,
        c.last_transaction,
        COALESCE(SUM(t.amount), 0) as calculated_invested,
        COALESCE(SUM(t.gold_grams), 0) as calculated_gold
    FROM customers c
    LEFT JOIN transactions t ON c.phone = t.customer_phone AND t.status = ''SUCCESS''
    GROUP BY c.id, c.phone, c.name, c.email, c.registration_date, 
             c.total_invested, c.total_gold, c.transaction_count, c.last_transaction
    ');
    PRINT '✅ Customer summary view created';
END
ELSE
BEGIN
    PRINT '⚠️  Customer summary view already exists - skipping';
END
GO

-- ========================================
-- STEP 6: Create Stored Procedures
-- ========================================
PRINT '';
PRINT '⚙️  STEP 6: Creating Stored Procedures...';

-- Procedure to update customer totals
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateCustomerTotals')
BEGIN
    EXEC('
    CREATE PROCEDURE UpdateCustomerTotals
        @customer_phone NVARCHAR(15)
    AS
    BEGIN
        UPDATE customers 
        SET 
            total_invested = COALESCE((
                SELECT SUM(amount) 
                FROM transactions 
                WHERE customer_phone = @customer_phone 
                AND status = ''SUCCESS'' 
                AND type = ''BUY''
            ), 0),
            total_gold = COALESCE((
                SELECT SUM(gold_grams) 
                FROM transactions 
                WHERE customer_phone = @customer_phone 
                AND status = ''SUCCESS''
            ), 0),
            transaction_count = COALESCE((
                SELECT COUNT(*) 
                FROM transactions 
                WHERE customer_phone = @customer_phone 
                AND status = ''SUCCESS''
            ), 0),
            last_transaction = (
                SELECT MAX(timestamp) 
                FROM transactions 
                WHERE customer_phone = @customer_phone 
                AND status = ''SUCCESS''
            ),
            updated_at = GETDATE()
        WHERE phone = @customer_phone;
    END
    ');
    PRINT '✅ UpdateCustomerTotals procedure created';
END
ELSE
BEGIN
    PRINT '⚠️  UpdateCustomerTotals procedure already exists - skipping';
END
GO

-- ========================================
-- STEP 7: Verify Setup
-- ========================================
PRINT '';
PRINT '✅ STEP 7: Verifying Setup...';

-- Check tables
SELECT 
    'customers' as table_name,
    COUNT(*) as record_count
FROM customers
UNION ALL
SELECT 
    'transactions' as table_name,
    COUNT(*) as record_count
FROM transactions;

-- Check user permissions
SELECT 
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    r.name AS role_name
FROM sys.database_role_members rm
JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name = 'vmurugan_user';

PRINT '';
PRINT '========================================';
PRINT '🎉 DATABASE SETUP COMPLETED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';
PRINT '📋 Summary:';
PRINT '   ✅ Database: VMuruganGoldTrading';
PRINT '   ✅ User: vmurugan_user (password: VMurugan@2025!)';
PRINT '   ✅ Tables: customers, transactions';
PRINT '   ✅ Views: customer_summary';
PRINT '   ✅ Procedures: UpdateCustomerTotals';
PRINT '   ✅ Test data inserted';
PRINT '';
PRINT '🔧 Next Steps:';
PRINT '   1. Update .env file with user credentials';
PRINT '   2. Start your Node.js servers';
PRINT '   3. Test the API endpoints';
PRINT '';
PRINT '💡 Connection String for .env:';
PRINT '   SQL_USERNAME=vmurugan_user';
PRINT '   SQL_PASSWORD=VMurugan@2025!';
PRINT '';
PRINT '🏆 Your VMurugan Gold Trading database is ready!';
GO
