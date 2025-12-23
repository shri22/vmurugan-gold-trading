-- ============================================
-- VMurugan Gold Trading - Database Fix Script
-- Purpose: Recalculate all scheme and customer totals from transaction data
-- ============================================

PRINT '🔧 Starting database recalculation...'
PRINT ''

-- ============================================
-- PART 1: Update GOLD Schemes
-- ============================================
PRINT '📊 Updating GOLD schemes...'

UPDATE s
SET 
    s.total_invested = COALESCE(txn_totals.total_amount, 0),
    s.total_metal_accumulated = COALESCE(txn_totals.total_grams, 0),
    s.completed_installments = COALESCE(txn_totals.payment_count, 0),
    s.updated_at = SYSDATETIME()
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
        AND (gold_grams > 0 OR metal_type = 'GOLD')
    GROUP BY scheme_id
) txn_totals ON s.scheme_id = txn_totals.scheme_id
WHERE s.metal_type = 'GOLD';

PRINT '✅ GOLD schemes updated'
PRINT ''

-- ============================================
-- PART 2: Update SILVER Schemes
-- ============================================
PRINT '📊 Updating SILVER schemes...'

UPDATE s
SET 
    s.total_invested = COALESCE(txn_totals.total_amount, 0),
    s.total_metal_accumulated = COALESCE(txn_totals.total_grams, 0),
    s.completed_installments = COALESCE(txn_totals.payment_count, 0),
    s.updated_at = SYSDATETIME()
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
        AND (silver_grams > 0 OR metal_type = 'SILVER')
    GROUP BY scheme_id
) txn_totals ON s.scheme_id = txn_totals.scheme_id
WHERE s.metal_type = 'SILVER';

PRINT '✅ SILVER schemes updated'
PRINT ''

-- ============================================
-- PART 3: Verify Scheme Updates
-- ============================================
PRINT '📋 Verification Report - Schemes:'
PRINT ''

SELECT 
    scheme_type,
    metal_type,
    COUNT(*) as total_schemes,
    SUM(total_invested) as total_investment,
    SUM(total_metal_accumulated) as total_metal,
    AVG(completed_installments) as avg_installments
FROM schemes
GROUP BY scheme_type, metal_type
ORDER BY scheme_type, metal_type;

PRINT ''
PRINT '============================================'
PRINT '✅ Database recalculation completed!'
PRINT '============================================'
PRINT ''
PRINT '📊 Summary of changes:'
SELECT 
    COUNT(*) as total_schemes_updated,
    SUM(CASE WHEN total_invested > 0 THEN 1 ELSE 0 END) as schemes_with_investment,
    SUM(CASE WHEN total_metal_accumulated > 0 THEN 1 ELSE 0 END) as schemes_with_metal
FROM schemes;

PRINT ''
PRINT '💡 Next steps:'
PRINT '1. Refresh the admin portal in your browser'
PRINT '2. All reports should now show correct totals'
PRINT '3. Future payments will automatically update these values'
