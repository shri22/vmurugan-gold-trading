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

async function checkSchemeTxns() {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('scheme_id', sql.NVarChar(100), 'GF_P6')
            .query(`
                SELECT 
                    customer_phone,
                    COUNT(*) as txn_count,
                    SUM(amount) as total_amount,
                    SUM(gold_grams) as total_gold
                FROM transactions
                WHERE scheme_id = @scheme_id AND status = 'SUCCESS'
                GROUP BY customer_phone;
                
                SELECT 
                    SUM(amount) as total_amount_all,
                    SUM(gold_grams) as total_gold_all
                FROM transactions
                WHERE scheme_id = @scheme_id AND status = 'SUCCESS';
            `);
        console.log("Transactions for scheme GF_P6 grouped by customer phone:");
        console.table(result.recordsets[0]);
        console.log("Overall totals for scheme GF_P6 from transactions table:");
        console.table(result.recordsets[1]);
        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

checkSchemeTxns();
