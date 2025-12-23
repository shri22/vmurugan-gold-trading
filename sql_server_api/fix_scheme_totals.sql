-- Script to recalculate scheme totals from transaction data
-- Run this on your SQL Server database to fix the investment and metal accumulated values

-- Update GOLD schemes
UPDATE s
SET 
    s.total_invested = COALESCE(txn_totals.total_amount, 0),
    s.total_metal_accumulated = COALESCE(txn_totals.total_grams, 0),
    s.completed_installments = COALESCE(txn_totals.payment_count, 0)
FROM schemes s
LEFT JOIN (
    SELECT 
        scheme_id,
        SUM(amount) as total_amount,
        SUM(gold_grams) as total_grams,
        COUNT(*) as payment_count
    FROM transactions
    WHERE scheme_id IS NOT NULL 
        AND status = 'SUCCESS'
        AND gold_grams > 0
    GROUP BY scheme_id
) txn_totals ON s.scheme_id = txn_totals.scheme_id
WHERE s.metal_type = 'GOLD';

-- Update SILVER schemes
UPDATE s
SET 
    s.total_invested = COALESCE(txn_totals.total_amount, 0),
    s.total_metal_accumulated = COALESCE(txn_totals.total_grams, 0),
    s.completed_installments = COALESCE(txn_totals.payment_count, 0)
FROM schemes s
LEFT JOIN (
    SELECT 
        scheme_id,
        SUM(amount) as total_amount,
        SUM(silver_grams) as total_grams,
        COUNT(*) as payment_count
    FROM transactions
    WHERE scheme_id IS NOT NULL 
        AND status = 'SUCCESS'
        AND silver_grams > 0
    GROUP BY scheme_id
) txn_totals ON s.scheme_id = txn_totals.scheme_id
WHERE s.metal_type = 'SILVER';

-- Verify the results
SELECT 
    scheme_id,
    scheme_type,
    metal_type,
    total_invested,
    total_metal_accumulated,
    completed_installments,
    status
FROM schemes
ORDER BY created_at DESC;
