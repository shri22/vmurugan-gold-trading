-- ============================================
-- Delete Customer and All Dependent Records
-- ============================================
-- This script safely deletes a customer and all related data
-- Replace '8050646077' with the actual phone number you want to delete

USE VMuruganGoldTrading;
GO

-- Declare the customer phone number to delete
DECLARE @CustomerPhone VARCHAR(20) = '8050646077'; -- CHANGE THIS TO YOUR TEST PHONE NUMBER

PRINT '========================================';
PRINT 'Starting Customer Deletion Process';
PRINT '========================================';
PRINT 'Customer Phone: ' + @CustomerPhone;
PRINT '';

-- Begin Transaction for safety
BEGIN TRANSACTION;

BEGIN TRY
    -- Step 1: Delete from transactions table
    PRINT 'Step 1: Deleting transactions...';
    DELETE FROM transactions 
    WHERE customer_phone = @CustomerPhone;
    PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' transaction(s)';
    PRINT '';

    -- Step 2: Delete from schemes table
    PRINT 'Step 2: Deleting schemes...';
    DELETE FROM schemes 
    WHERE customer_phone = @CustomerPhone;
    PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' scheme(s)';
    PRINT '';

    -- Step 3: Delete from payments table (if exists)
    IF OBJECT_ID('payments', 'U') IS NOT NULL
    BEGIN
        PRINT 'Step 3: Deleting payments...';
        DELETE FROM payments 
        WHERE customer_phone = @CustomerPhone;
        PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' payment(s)';
        PRINT '';
    END

    -- Step 4: Delete from customers table
    PRINT 'Step 4: Deleting customer record...';
    DELETE FROM customers 
    WHERE phone = @CustomerPhone;
    PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' customer record(s)';
    PRINT '';

    -- Step 5: Delete from notifications table (if exists)
    IF OBJECT_ID('notifications', 'U') IS NOT NULL
    BEGIN
        PRINT 'Step 5: Deleting notifications...';
        DELETE FROM notifications 
        WHERE customer_phone = @CustomerPhone;
        PRINT '✅ Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' notification(s)';
        PRINT '';
    END

    -- Commit the transaction
    COMMIT TRANSACTION;
    
    PRINT '========================================';
    PRINT '✅ Customer Deletion Complete!';
    PRINT '========================================';
    PRINT '';
    PRINT 'All records for customer ' + @CustomerPhone + ' have been deleted.';
    PRINT 'You can now test the registration flow with this phone number.';
    PRINT '';

END TRY
BEGIN CATCH
    -- Rollback on error
    ROLLBACK TRANSACTION;
    
    PRINT '========================================';
    PRINT '❌ ERROR: Customer Deletion Failed!';
    PRINT '========================================';
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT '';
    PRINT 'No data was deleted. Transaction rolled back.';
END CATCH;

GO

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify the customer is deleted

DECLARE @CustomerPhone VARCHAR(20) = '8050646077'; -- CHANGE THIS TO YOUR TEST PHONE NUMBER

PRINT '========================================';
PRINT 'Verification: Checking for remaining records';
PRINT '========================================';
PRINT '';

-- Check customers table
SELECT 'Customers' AS TableName, COUNT(*) AS RecordCount 
FROM customers 
WHERE phone = @CustomerPhone

UNION ALL

-- Check transactions table
SELECT 'Transactions' AS TableName, COUNT(*) AS RecordCount 
FROM transactions 
WHERE customer_phone = @CustomerPhone

UNION ALL

-- Check schemes table
SELECT 'Schemes' AS TableName, COUNT(*) AS RecordCount 
FROM schemes 
WHERE customer_phone = @CustomerPhone;

PRINT '';
PRINT 'If all counts are 0, the customer has been successfully deleted.';
