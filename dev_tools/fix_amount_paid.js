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

async function fixAmountPaid() {
    try {
        const pool = await sql.connect(sqlConfig);
        console.log('Fixing total_amount_paid in schemes...');
        
        await pool.request().query(`
            UPDATE schemes
            SET total_amount_paid = total_invested
            WHERE total_amount_paid != total_invested
        `);
        
        console.log("✅ Fixed total_amount_paid for all schemes.");
        await pool.close();
    } catch (e) {
        console.error("Error:", e.message);
    }
}

fixAmountPaid();
