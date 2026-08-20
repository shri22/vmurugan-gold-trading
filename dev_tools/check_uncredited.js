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

async function checkUncredited() {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('phone', sql.NVarChar(15), '9585007471')
            .query(`
                SELECT transaction_id, amount, metal_type, gold_grams, silver_grams, 
                       status, is_credited, CONVERT(varchar, created_at, 120) as created_at
                FROM transactions
                WHERE customer_phone = @phone AND status = 'SUCCESS' AND (is_credited IS NULL OR is_credited = 0)
                ORDER BY created_at DESC
            `);
        console.log("Uncredited successful transactions:");
        console.table(result.recordset);
        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

checkUncredited();
