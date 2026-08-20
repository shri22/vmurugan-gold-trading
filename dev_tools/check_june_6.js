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

async function checkJune6() {
    try {
        const pool = await sql.connect(sqlConfig);
        const result = await pool.request()
            .input('txid', sql.NVarChar(100), 'ORD_1780770558394_GOLD_285')
            .query(`
                SELECT transaction_id, customer_phone, customer_name, type, amount, metal_type, 
                       gold_grams, gold_price_per_gram, status, gateway_transaction_id, 
                       scheme_id, is_credited, CONVERT(varchar, created_at, 120) as created_at
                FROM transactions
                WHERE transaction_id = @txid
            `);
        console.log(JSON.stringify(result.recordset, null, 2));
        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

checkJune6();
