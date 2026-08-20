const sql = require('mssql');

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

async function runFix() {
    try {
        console.log('Connecting to Production SQL Server...');
        const pool = await sql.connect(sqlConfig);
        console.log('Connected! Running fix...');

        // 1. Fix Schemes
        await pool.request().query(`
            UPDATE s
            SET 
                s.total_invested = COALESCE(txn.total_amount, 0),
                s.total_metal_accumulated = COALESCE(txn.total_metal, 0),
                s.completed_installments = COALESCE(txn.payment_count, 0)
            FROM schemes s
            LEFT JOIN (
                SELECT 
                    scheme_id,
                    SUM(amount) as total_amount,
                    SUM(CASE WHEN metal_type = 'GOLD' THEN gold_grams ELSE silver_grams END) as total_metal,
                    COUNT(*) as payment_count
                FROM transactions
                WHERE status = 'SUCCESS'
                GROUP BY scheme_id
            ) txn ON s.scheme_id = txn.scheme_id;
        `);
        console.log("✅ Schemes fixed.");

        // 2. Fix Customers
        await pool.request().query(`
            UPDATE c
            SET 
                c.total_invested = COALESCE(s_totals.total_amount, 0),
                c.total_gold = COALESCE(s_totals.total_gold, 0),
                c.total_silver = COALESCE(s_totals.total_silver, 0),
                c.transaction_count = COALESCE(s_totals.total_txns, 0)
            FROM customers c
            LEFT JOIN (
                SELECT 
                    customer_phone,
                    SUM(amount) as total_amount,
                    SUM(gold_grams) as total_gold,
                    SUM(silver_grams) as total_silver,
                    COUNT(*) as total_txns
                FROM transactions
                WHERE status = 'SUCCESS'
                GROUP BY customer_phone
            ) s_totals ON c.phone = s_totals.customer_phone;
        `);
        console.log("✅ Customers fixed.");

        console.log("🎉 All discrepancies resolved.");

        await pool.close();
    } catch (e) {
        console.error("Error:", e.message);
    }
}

runFix();
