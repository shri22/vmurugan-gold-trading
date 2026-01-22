/**
 * Cleanup Script: Auto-expire abandoned PENDING transactions
 * 
 * This script checks PENDING transactions older than 24 hours and verifies
 * them with Omniware gateway. If not found, marks them as EXPIRED.
 * 
 * Run via cron: node cleanup_pending_transactions.js
 */

const sql = require('mssql');
const axios = require('axios');
const crypto = require('crypto');

// Database configuration
const dbConfig = {
    server: process.env.SQL_SERVER || 'localhost',
    port: parseInt(process.env.SQL_PORT) || 1433,
    database: process.env.SQL_DATABASE || 'VMuruganGoldTrading',
    user: process.env.SQL_USERNAME || 'sa',
    password: process.env.SQL_PASSWORD || 'VMurugan@2025#SQL',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

// Omniware credentials
const MERCHANTS = {
    GOLD: {
        merchantId: '779285',
        apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
        salt: '47cdd26963f53e3181f93adcf3af487ec28d7643'
    },
    SILVER: {
        merchantId: '779295',
        apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
        salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f'
    }
};

const OMNIWARE_API_URL = 'https://pgbiz.omniware.in';

function generateHash(params, salt) {
    const sortedKeys = Object.keys(params).sort();
    let hashString = salt;
    sortedKeys.forEach(key => {
        const value = params[key];
        if (value !== null && value !== undefined && value !== '') {
            const sanitizedValue = String(value)
                .replace(/[\r\n]+/g, ' ')
                .replace(/\s+/g, ' ')
                .trim();
            hashString += '|' + sanitizedValue;
        }
    });
    return crypto.createHash('sha512').update(hashString).digest('hex').toUpperCase();
}

async function checkTransactionInGateway(orderId, metalType) {
    const merchant = MERCHANTS[metalType.toUpperCase()];
    if (!merchant) {
        console.log(`⚠️ Unknown metal type: ${metalType}`);
        return { exists: false, status: 'unknown' };
    }

    const params = {
        api_key: merchant.apiKey,
        order_id: orderId
    };
    params.hash = generateHash(params, merchant.salt);

    try {
        const response = await axios.post(
            `${OMNIWARE_API_URL}/v2/paymentstatus`,
            new URLSearchParams(params).toString(),
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        if (response.data && response.data.data) {
            const transaction = Array.isArray(response.data.data) ? response.data.data[0] : response.data.data;
            return {
                exists: true,
                status: transaction.response_code === 0 ? 'success' : 'pending',
                gatewayData: transaction
            };
        } else if (response.data && response.data.error && response.data.error.code === 1028) {
            // Transaction not found in gateway
            return { exists: false, status: 'not_found' };
        }
    } catch (error) {
        console.log(`⚠️ Error checking ${orderId}:`, error.message);
        return { exists: false, status: 'error' };
    }

    return { exists: false, status: 'unknown' };
}

async function cleanupPendingTransactions() {
    console.log('🧹 Starting cleanup of abandoned PENDING transactions...\n');

    try {
        // Connect to database
        const pool = await sql.connect(dbConfig);
        console.log('✅ Connected to database\n');

        // Find PENDING transactions older than 24 hours
        const cutoffTime = new Date();
        cutoffTime.setHours(cutoffTime.getHours() - 24);

        const result = await pool.request()
            .input('cutoff', sql.DateTime, cutoffTime)
            .query(`
                SELECT transaction_id, metal_type, amount, customer_name, customer_phone, created_at
                FROM transactions
                WHERE status = 'PENDING'
                AND created_at < @cutoff
                AND payment_method LIKE 'OMNIWARE%'
                ORDER BY created_at DESC
            `);

        const pendingTransactions = result.recordset;
        console.log(`📊 Found ${pendingTransactions.length} PENDING transactions older than 24 hours\n`);

        if (pendingTransactions.length === 0) {
            console.log('✅ No cleanup needed!');
            await pool.close();
            return;
        }

        let expiredCount = 0;
        let stillPendingCount = 0;
        let successCount = 0;

        for (const txn of pendingTransactions) {
            console.log(`\n🔍 Checking: ${txn.transaction_id}`);
            console.log(`   Customer: ${txn.customer_name} (${txn.customer_phone})`);
            console.log(`   Amount: ₹${txn.amount} | Metal: ${txn.metal_type}`);
            console.log(`   Created: ${txn.created_at}`);

            const gatewayStatus = await checkTransactionInGateway(txn.transaction_id, txn.metal_type);

            if (!gatewayStatus.exists) {
                // Transaction not found in gateway - mark as EXPIRED
                await pool.request()
                    .input('txn_id', sql.VarChar(100), txn.transaction_id)
                    .query(`
                        UPDATE transactions
                        SET status = 'FAILED',
                            updated_at = GETDATE()
                        WHERE transaction_id = @txn_id
                    `);
                console.log(`   ❌ FAILED - Not found in gateway (abandoned)`);
                expiredCount++;
            } else if (gatewayStatus.status === 'success') {
                console.log(`   ✅ SUCCESS - Found in gateway (needs manual reconciliation)`);
                successCount++;
            } else {
                console.log(`   ⏳ Still PENDING in gateway`);
                stillPendingCount++;
            }

            // Small delay to avoid rate limiting
            await new Promise(resolve => setTimeout(resolve, 500));
        }

        console.log('\n' + '='.repeat(60));
        console.log('📈 CLEANUP SUMMARY');
        console.log('='.repeat(60));
        console.log(`❌ Marked as FAILED (abandoned): ${expiredCount}`);
        console.log(`⏳ Still PENDING: ${stillPendingCount}`);
        console.log(`🔔 Needs Reconciliation: ${successCount}`);
        console.log('='.repeat(60));

        await pool.close();
        console.log('\n✅ Cleanup completed successfully!');

    } catch (error) {
        console.error('❌ Cleanup failed:', error.message);
        process.exit(1);
    }
}

// Run cleanup
cleanupPendingTransactions().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});
