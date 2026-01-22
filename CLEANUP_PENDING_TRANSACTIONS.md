# Automated Cleanup of Abandoned PENDING Transactions

## Problem Solved

Previously, when customers initiated a payment but never completed it (abandoned the payment page), the transaction would stay as `PENDING` forever, causing confusion in reports and analytics.

## Solution

We now have an **automated cleanup system** that:

1. ✅ Checks all `PENDING` transactions older than 24 hours
2. ✅ Verifies each one with Omniware payment gateway
3. ✅ Marks as `FAILED` if not found in gateway (abandoned payment)
4. ✅ Keeps as `PENDING` if still processing in gateway
5. ✅ Flags for manual reconciliation if successful in gateway but not in database

## Files Created

### 1. `cleanup_pending_transactions.js`
**Purpose**: Automated daily cleanup script  
**What it does**: Checks all PENDING transactions older than 24 hours and updates their status

### 2. `expire_pending_now.js`
**Purpose**: Manual cleanup for specific transactions  
**What it does**: Immediately checks and updates a specific transaction

## How to Use

### ✅ Via Admin Portal (Recommended - Easiest!)

1. Open Admin Portal: `https://prodapi.vmuruganjewellery.co.in/admin_portal/`
2. Login with your credentials
3. Go to **Reports** → **Gateway Reconciliation** tab
4. Click the **🧹 Cleanup Abandoned Payments** button
5. Confirm the action
6. View the results instantly!

**Benefits:**
- ✅ One-click operation
- ✅ Visual results with detailed breakdown
- ✅ Shows exactly what was cleaned up
- ✅ Automatically refreshes transaction list
- ✅ No SSH or command line needed

### Automatic Daily Cleanup (Set It and Forget It)

Set up a cron job to run daily at 2 AM:

```bash
# Edit crontab
crontab -e

# Add this line:
0 2 * * * cd /root/sql_server_api && /usr/bin/node cleanup_pending_transactions.js >> /root/sql_server_api/logs/cleanup.log 2>&1
```

### Manual Cleanup via SSH (Advanced)

To run the full cleanup manually via command line:

```bash
cd /root/sql_server_api
node cleanup_pending_transactions.js
```

## Status Meanings

- **PENDING**: Payment initiated, waiting for completion
- **SUCCESS**: Payment completed successfully
- **FAILED**: Payment abandoned or failed (not found in gateway after 24 hours)
- **CANCELLED**: Payment cancelled by user or admin

## Benefits

1. ✅ **Cleaner Reports**: No more confusing PENDING transactions in analytics
2. ✅ **Accurate Metrics**: Revenue and transaction counts are accurate
3. ✅ **Better UX**: Admin portal shows real payment status
4. ✅ **Automated**: No manual intervention needed
5. ✅ **Safe**: Only marks as FAILED if confirmed not in gateway

## Example Output

```
🧹 Starting cleanup of abandoned PENDING transactions...

✅ Connected to database

📊 Found 3 PENDING transactions older than 24 hours

🔍 Checking: ORD_1769057831525_SILVER_295
   Customer: rajeswari (9585007471)
   Amount: ₹300 | Metal: SILVER
   Created: 2026-01-22 04:57:11
   ❌ FAILED - Not found in gateway (abandoned)

============================================================
📈 CLEANUP SUMMARY
============================================================
❌ Marked as FAILED (abandoned): 1
⏳ Still PENDING: 0
🔔 Needs Reconciliation: 0
============================================================

✅ Cleanup completed successfully!
```

## Monitoring

Check cleanup logs:
```bash
tail -f /root/sql_server_api/logs/cleanup.log
```

Check current PENDING transactions:
```sql
SELECT transaction_id, customer_name, amount, metal_type, 
       created_at, DATEDIFF(HOUR, created_at, GETDATE()) as hours_old
FROM transactions
WHERE status = 'PENDING' 
AND payment_method LIKE 'OMNIWARE%'
ORDER BY created_at DESC
```

## Next Steps

1. ✅ **Done**: Created cleanup scripts
2. ✅ **Done**: Tested on production
3. ⏳ **TODO**: Set up cron job for daily automatic cleanup
4. ⏳ **TODO**: Monitor for a week to ensure it works correctly
