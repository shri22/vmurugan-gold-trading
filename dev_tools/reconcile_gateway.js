const sql = require('mssql');
const axios = require('axios');
const crypto = require('crypto');

const sqlConfig = {
    server: '193.203.160.3',
    port: 1433,
    database: 'VMuruganGoldTrading',
    user: 'sa',
    password: 'VMurugan@2025#SQL',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
    }
};

const OMNIWARE_CONFIG = {
    GOLD: {
        merchantId: '779285',
        apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
        salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
    },
    SILVER: {
        merchantId: '779295',
        apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
        salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
    }
};

function generateOmniwareHash(params, salt) {
    const sortedKeys = Object.keys(params).sort();
    let hashString = salt;
    sortedKeys.forEach(key => {
        const value = params[key];
        if (value !== null && value !== undefined && value !== '') {
            hashString += '|' + String(value).trim();
        }
    });
    return crypto.createHash('sha512').update(hashString).digest('hex').toUpperCase();
}

async function checkGatewayStatus(orderId, metalType) {
    const config = OMNIWARE_CONFIG[metalType.toUpperCase()];
    if (!config) return { status: 'UNKNOWN_METAL' };

    const params = {
        api_key: config.apiKey,
        order_id: orderId
    };
    params.hash = generateOmniwareHash(params, config.salt);

    try {
        const response = await axios.post(
            'https://pgbiz.omniware.in/v2/paymentstatus',
            new URLSearchParams(params).toString(),
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        if (response.data && response.data.data) {
            const data = Array.isArray(response.data.data) ? response.data.data[0] : response.data.data;
            return {
                status: data.response_code === 0 ? 'SUCCESS' : 'PENDING/FAILED',
                responseCode: data.response_code,
                gatewayTxnId: data.transaction_id,
                amount: data.amount,
                description: data.description
            };
        } else if (response.data && response.data.error && response.data.error.code === 1028) {
            return { status: 'NOT_FOUND_IN_GATEWAY' };
        }
        return { status: 'GATEWAY_ERROR', raw: response.data };
    } catch (error) {
        return { status: 'AXIOS_ERROR', error: error.message };
    }
}

async function reconcile() {
    try {
        const pool = await sql.connect(sqlConfig);
        const phone = '9585007471';

        console.log('Fetching non-success transactions for 9585007471...');
        const result = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
                SELECT transaction_id, amount, metal_type, status, 
                       CONVERT(varchar, created_at, 120) as created_at
                FROM transactions
                WHERE customer_phone = @phone AND status IN ('FAILED', 'PENDING')
                ORDER BY created_at DESC
            `);
        
        const txns = result.recordset;
        console.log(`Found ${txns.length} transactions to verify.\n`);

        const reconciliationResults = [];

        for (const txn of txns) {
            console.log(`Checking gateway for order: ${txn.transaction_id}...`);
            const gw = await checkGatewayStatus(txn.transaction_id, txn.metal_type);
            reconciliationResults.push({
                transaction_id: txn.transaction_id,
                db_status: txn.status,
                db_amount: txn.amount,
                metal: txn.metal_type,
                created_at: txn.created_at,
                gw_status: gw.status,
                gw_amount: gw.amount || 'N/A',
                gw_txn_id: gw.gatewayTxnId || 'N/A',
                gw_description: gw.description || 'N/A'
            });
            // Sleep a little to prevent rate limiting
            await new Promise(r => setTimeout(r, 200));
        }

        console.log('\n================================================================================');
        console.log('RECONCILIATION REPORT (READ-ONLY)');
        console.log('================================================================================');
        console.table(reconciliationResults);

        // Highlight any that are actually SUCCESS
        const anomalies = reconciliationResults.filter(r => r.gw_status === 'SUCCESS');
        if (anomalies.length > 0) {
            console.log('\n⚠️ WARNING: The following transactions are marked FAILED/PENDING in DB, but are SUCCESS in Gateway!');
            console.table(anomalies);
        } else {
            console.log('\n✅ No anomalies found! All database FAILED/PENDING transactions match gateway status.');
        }

        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

reconcile();
