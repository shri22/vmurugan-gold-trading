-- Check transactions for customer 9715569313
-- Run this query in SQL Server Management Studio (SSMS)

USE VMuruganGoldTrading;
GO

-- 1. Check what phone format is stored in customers table
SELECT id, customer_id, phone, name, email
FROM customers
WHERE phone LIKE '%9715569313%'
   OR phone LIKE '%715569313%';

-- 2. Check all transactions for this customer
SELECT 
    transaction_id,
    customer_phone,
    customer_name,
    type,
    amount,
    gold_grams,
    silver_grams,
    status,
    scheme_id,
    scheme_type,
    created_at,
    metal_type
FROM transactions
WHERE customer_phone LIKE '%9715569313%'
   OR customer_phone LIKE '%715569313%'
ORDER BY created_at DESC;

-- 3. Check schemes for this customer
SELECT 
    scheme_id,
    customer_phone,
    customer_name,
    scheme_type,
    metal_type,
    monthly_amount,
    status,
    total_invested,
    total_metal_accumulated,
    created_at
FROM schemes
WHERE customer_phone LIKE '%9715569313%'
   OR customer_phone LIKE '%715569313%';

-- 4. Calculate actual totals from transactions
SELECT 
    customer_phone,
    COUNT(*) as total_transactions,
    SUM(amount) as total_invested,
    SUM(gold_grams) as total_gold,
    SUM(silver_grams) as total_silver,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful_transactions
FROM transactions
WHERE (customer_phone LIKE '%9715569313%' OR customer_phone LIKE '%715569313%')
GROUP BY customer_phone;

-- 5. Check for phone format variations
SELECT DISTINCT customer_phone
FROM transactions
WHERE customer_phone LIKE '%715569313%';
