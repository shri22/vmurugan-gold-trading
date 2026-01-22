const sql = require('mssql');

const dbConfig = {
    server: 'localhost',
    port: 1433,
    database: 'VMuruganGoldTrading',
    user: 'sa',
    password: 'VMurugan@2025#SQL',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

async function insertMissingTransaction() {
    console.log('📝 Inserting missing transaction for reconciliation sync...');

    try {
        const pool = await sql.connect(dbConfig);

        // Transaction Details
        const txn = {
            transaction_id: 'ORD_1764701054336_GOLD_779285',
            gateway_transaction_id: 'FEUPII9D8FE2C0E7C',
            customer_phone: '9715569313',
            customer_name: 'shrikanth',
            amount: 10.00,
            gold_grams: 0.001,
            gold_price_per_gram: 8000,
            metal_type: 'GOLD',
            status: 'SUCCESS',
            created_at: '2025-12-03 00:14:48',
            payment_method: 'OMNIWARE_UPI'
        };

        const result = await pool.request()
            .input('tid', sql.NVarChar(100), txn.transaction_id)
            .input('gtid', sql.NVarChar(100), txn.gateway_transaction_id)
            .input('phone', sql.NVarChar(15), txn.customer_phone)
            .input('name', sql.NVarChar(100), txn.customer_name)
            .input('amt', sql.Decimal(18, 2), txn.amount)
            .input('grams', sql.Decimal(18, 4), txn.gold_grams)
            .input('price', sql.Decimal(18, 2), txn.gold_price_per_gram)
            .input('metal', sql.NVarChar(20), txn.metal_type)
            .input('status', sql.NVarChar(20), txn.status)
            .input('dt', sql.DateTime, txn.created_at)
            .input('method', sql.NVarChar(50), txn.payment_method)
            .query(`
                IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = @tid)
                BEGIN
                    INSERT INTO transactions (
                        transaction_id, gateway_transaction_id, customer_phone, customer_name,
                        amount, gold_grams, gold_price_per_gram, metal_type, status,
                        created_at, updated_at, payment_method, type, business_id, is_credited
                    ) VALUES (
                        @tid, @gtid, @phone, @name,
                        @amt, @grams, @price, @metal, @status,
                        @dt, @dt, @method, 'BUY', '779285', 1
                    )
                    SELECT '✅ Transaction inserted successfully' as message
                END
                ELSE
                BEGIN
                    SELECT '⚠️ Transaction already exists' as message
                END
            `);

        console.log(result.recordset[0].message);
        await pool.close();
    } catch (err) {
        console.error('❌ Error inserting transaction:', err.message);
    }
}

insertMissingTransaction();
