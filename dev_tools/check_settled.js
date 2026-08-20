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

async function checkSettled() {
    try {
        const pool = await sql.connect(sqlConfig);
        const phone = '9585007471';

        console.log('--- CHECKING SETTLED TRANSACTIONS ---');
        
        const result = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
                SELECT * 
                FROM settled_transactions
                WHERE customer_phone = @phone
            `);
        
        console.table(result.recordset);
        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

checkSettled();
