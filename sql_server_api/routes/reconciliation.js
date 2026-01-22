const express = require('express');
const router = express.Router();
const sql = require('mssql');
const axios = require('axios');
const crypto = require('crypto');

// Omniware Credentials (Gold only for now as per test)
const MERCHANTS = {
    GOLD: {
        merchantId: '779285',
        apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
        salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
        name: 'V MURUGAN JEWELLERY'
    },
    SILVER: {
        merchantId: '779295',
        apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
        salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
        name: 'V MURUGAN NAGAI KADAI'
    }
};

const OMNIWARE_API_URL = 'https://pgbiz.omniware.in';

function generateHash(params, salt) {
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

/**
 * Trigger Fetch from Omniware for a date range
 */
router.post('/fetch', async (req, res) => {
    const { date_from, date_to, metal_type } = req.body; // DD-MM-YYYY
    const type = (metal_type || 'GOLD').toUpperCase();
    const merchant = MERCHANTS[type];

    if (!date_from || !date_to) {
        return res.status(400).json({ success: false, error: 'date_from and date_to are required (DD-MM-YYYY)' });
    }

    try {
        console.log(`📡 Fetching settlements for ${type} from ${date_from} to ${date_to}...`);

        // 1. Get Aggregate Settlements
        const summaryParams = {
            api_key: merchant.apiKey,
            date_from,
            date_to
        };
        summaryParams.hash = generateHash(summaryParams, merchant.salt);

        const summaryRes = await axios.post(
            `${OMNIWARE_API_URL}/v2/getsettlements`,
            new URLSearchParams(summaryParams).toString(),
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        if (summaryRes.data.error) {
            return res.status(400).json({ success: false, error: summaryRes.data.error.message });
        }

        const batches = summaryRes.data.data;
        if (!batches || batches.length === 0) {
            return res.json({ success: true, message: 'No settlements found for this period.', count: 0 });
        }

        const pool = await sql.connect();

        for (const batch of batches) {
            // Save Batch
            await pool.request()
                .input('sid', sql.BigInt, batch.settlement_id)
                .input('ref', sql.NVarChar, batch.bank_reference)
                .input('payout', sql.Decimal(18, 2), batch.payout_amount)
                .input('sale', sql.Decimal(18, 2), batch.sale_amount)
                .input('dt', sql.DateTime, batch.settlement_datetime)
                .input('metal', sql.NVarChar, type)
                .query(`
                    IF NOT EXISTS (SELECT 1 FROM settlement_batches WHERE settlement_id = @sid)
                    BEGIN
                        INSERT INTO settlement_batches (settlement_id, bank_reference, payout_amount, sale_amount, settlement_datetime, metal_type, status)
                        VALUES (@sid, @ref, @payout, @sale, @dt, @metal, 'PENDING')
                    END
                    ELSE
                    BEGIN
                        UPDATE settlement_batches 
                        SET bank_reference = @ref, payout_amount = @payout, sale_amount = @sale, settlement_datetime = @dt
                        WHERE settlement_id = @sid
                    END
                `);

            // 2. Fetch Details for this batch
            const detailParams = {
                api_key: merchant.apiKey,
                settlement_id: batch.settlement_id
            };
            detailParams.hash = generateHash(detailParams, merchant.salt);

            const detailRes = await axios.post(
                `${OMNIWARE_API_URL}/v2/getsettlementdetails`,
                new URLSearchParams(detailParams).toString(),
                { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
            );

            if (detailRes.data.data) {
                const txns = detailRes.data.data;
                for (const tx of txns) {
                    await pool.request()
                        .input('sid', sql.BigInt, batch.settlement_id)
                        .input('gtid', sql.NVarChar, tx.transaction_id)
                        .input('oid', sql.NVarChar, tx.order_id)
                        .input('gross', sql.Decimal(18, 2), tx.gross_transaction_amount)
                        .input('tdr', sql.Decimal(18, 2), tx.tdr_amount)
                        .input('txdt', sql.DateTime, tx.transaction_date)
                        .input('phone', sql.NVarChar, tx.customer_phone)
                        .input('name', sql.NVarChar, tx.customer_name)
                        .query(`
                            IF NOT EXISTS (SELECT 1 FROM settled_transactions WHERE gateway_transaction_id = @gtid OR order_id = @oid)
                            BEGIN
                                INSERT INTO settled_transactions (settlement_id, gateway_transaction_id, order_id, gross_amount, tdr_amount, transaction_date, customer_phone, customer_name)
                                VALUES (@sid, @gtid, @oid, @gross, @tdr, @txdt, @phone, @name)
                            END
                        `);
                }
            }
        }

        res.json({ success: true, message: `Successfully fetched ${batches.length} settlement batches.` });

    } catch (err) {
        console.error('Reconciliation Fetch Error:', err.message);
        res.status(500).json({ success: false, error: err.message });
    }
});

/**
 * List settlement batches
 */
router.get('/batches', async (req, res) => {
    try {
        const pool = await sql.connect();
        const result = await pool.request().query("SELECT * FROM settlement_batches ORDER BY settlement_datetime DESC");
        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

/**
 * Get Batch Details with Reconciliation Status
 */
router.get('/batch/:id', async (req, res) => {
    try {
        const pool = await sql.connect();

        // 1. Get settled transactions (Bank side)
        const bankTxns = await pool.request()
            .input('sid', sql.BigInt, req.params.id)
            .query(`
                SELECT st.*, 
                       sb.metal_type,
                       t.status as internal_status, 
                       t.transaction_id as internal_id,
                       t.is_credited as internal_credited
                FROM settled_transactions st
                JOIN settlement_batches sb ON st.settlement_id = sb.settlement_id
                LEFT JOIN transactions t ON st.order_id = t.transaction_id OR st.gateway_transaction_id = t.gateway_transaction_id
                WHERE st.settlement_id = @sid
            `);

        res.json({ success: true, data: bankTxns.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

/**
 * Update Batch Status (e.g., Mark as RECONCILED)
 */
router.post('/batch/:id/status', async (req, res) => {
    const { status } = req.body;
    try {
        const pool = await sql.connect();
        await pool.request()
            .input('sid', sql.BigInt, req.params.id)
            .input('status', sql.NVarChar, status)
            .query("UPDATE settlement_batches SET status = @status, updated_at = GETDATE() WHERE settlement_id = @sid");

        res.json({ success: true, message: `Batch status updated to ${status}` });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

/**
 * Get Transactions that are SUCCESS but not yet found in any settlement batch
 */
router.get('/unsettled', async (req, res) => {
    try {
        const pool = await sql.connect();

        // Find successful transactions from the last 30 days that aren't in settled_transactions
        const result = await pool.request()
            .query(`
                SELECT t.transaction_id, t.gateway_transaction_id, t.customer_name, 
                       t.customer_phone, t.amount, t.metal_type, t.created_at, t.payment_method
                FROM transactions t
                WHERE t.status = 'SUCCESS'
                AND t.created_at >= DATEADD(day, -30, GETDATE())
                AND NOT EXISTS (
                    SELECT 1 FROM settled_transactions st 
                    WHERE st.order_id = t.transaction_id 
                    OR st.gateway_transaction_id = t.gateway_transaction_id
                )
                ORDER BY t.created_at DESC
            `);

        res.json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

module.exports = router;
