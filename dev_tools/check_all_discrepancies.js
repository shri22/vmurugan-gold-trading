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

async function checkDiscrepancies() {
    try {
        console.log('Connecting to Production SQL Server...');
        const pool = await sql.connect(sqlConfig);
        console.log('Connected! Checking for discrepancies...\n');

        const query = `
            WITH TxnTotals AS (
                SELECT 
                    customer_phone,
                    SUM(amount) as actual_success_amount,
                    SUM(gold_grams) as actual_success_gold
                FROM transactions
                WHERE status = 'SUCCESS'
                GROUP BY customer_phone
            )
            SELECT 
                c.customer_id,
                c.phone,
                c.name,
                c.total_invested as cached_total_invested,
                ISNULL(t.actual_success_amount, 0) as actual_success_amount,
                (c.total_invested - ISNULL(t.actual_success_amount, 0)) as difference
            FROM customers c
            LEFT JOIN TxnTotals t ON c.phone = t.customer_phone
            WHERE c.total_invested != ISNULL(t.actual_success_amount, 0)
            ORDER BY difference DESC
        `;

        const result = await pool.request().query(query);
        
        if (result.recordset.length === 0) {
            console.log("✅ All customers' cached totals match their actual successful transactions!");
        } else {
            console.log("⚠️ Found customers with discrepancies between their profile and actual transactions:");
            console.table(result.recordset);
        }

        await pool.close();
    } catch (e) {
        console.error("Error:", e.message);
    }
}

checkDiscrepancies();
