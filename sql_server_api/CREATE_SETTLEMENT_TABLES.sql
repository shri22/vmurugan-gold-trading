-- =============================================
-- SETTLEMENT TRACKING TABLES
-- =============================================

-- 1. Table for aggregate settlement batches
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'settlement_batches')
BEGIN
    CREATE TABLE settlement_batches (
        batch_id INT PRIMARY KEY IDENTITY(1,1),
        settlement_id BIGINT UNIQUE,
        bank_reference NVARCHAR(100),
        payout_amount DECIMAL(18, 2),
        sale_amount DECIMAL(18, 2),
        tax_on_tdr DECIMAL(18, 2) DEFAULT 0,
        tdr_amount DECIMAL(18, 2) DEFAULT 0,
        settlement_datetime DATETIME,
        merchant_id NVARCHAR(50),
        metal_type NVARCHAR(10), -- 'GOLD' or 'SILVER'
        status NVARCHAR(20) DEFAULT 'PENDING',
        reconciled_count INT DEFAULT 0,
        total_count INT DEFAULT 0,
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_settlement_batches_date ON settlement_batches(settlement_datetime);
END

-- 2. Table for individual settled transactions (Bank side)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'settled_transactions')
BEGIN
    CREATE TABLE settled_transactions (
        id INT PRIMARY KEY IDENTITY(1,1),
        settlement_id BIGINT,
        gateway_transaction_id NVARCHAR(100),
        order_id NVARCHAR(100),
        gross_amount DECIMAL(18, 2),
        net_amount DECIMAL(18, 2),
        tdr_amount DECIMAL(18, 2),
        transaction_date DATETIME,
        customer_phone NVARCHAR(20),
        customer_name NVARCHAR(100),
        is_reconciled BIT DEFAULT 0,
        internal_transaction_id NVARCHAR(100), -- Link to our transactions table
        created_at DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_settled_transactions_order_id ON settled_transactions(order_id);
    CREATE INDEX IX_settled_transactions_settlement_id ON settled_transactions(settlement_id);
END

-- 3. Add settlement link fields to main transactions table if not already there
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'settlement_id')
BEGIN
    ALTER TABLE transactions ADD settlement_id BIGINT;
    ALTER TABLE transactions ADD settlement_reference NVARCHAR(100);
    ALTER TABLE transactions ADD settlement_date DATETIME;
END
GO
