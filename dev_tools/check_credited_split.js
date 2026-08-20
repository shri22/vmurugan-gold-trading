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

async function checkCreditedSplit() {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('phone', sql.NVarChar(15), '9585007471')
            .query(`
                SELECT 
                    ISNULL(is_credited, 0) as credited_flag,
                    COUNT(*) as txn_count,
                    SUM(amount) as total_amount,
                    SUM(gold_grams) as total_gold,
                    SUM(silver_grams) as total_silver
                FROM transactions
                WHERE customer_phone = @phone AND status = 'SUCCESS'
                GROUP BY ISNULL(is_credited, 0)
            `);
        console.log("SUCCESS Transactions grouped by is_credited status:");
        console.table(result.recordset);
        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

checkCreditedSplit();
