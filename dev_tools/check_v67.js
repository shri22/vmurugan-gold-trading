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

async function checkV67() {
    try {
        console.log('Connecting to Production SQL Server...');
        const pool = await sql.connect(sqlConfig);
        console.log('Connected!');

        console.log('\n--- CUSTOMERS ---');
        const cust = await pool.request().query("SELECT * FROM customers WHERE customer_id = 'V67' OR id = 67 OR customer_id LIKE '%67'");
        console.table(cust.recordset);

        if (cust.recordset.length > 0) {
            const phone = cust.recordset[0].phone;
            const customer_id = cust.recordset[0].customer_id;
            console.log('\n--- SCHEMES DETAILS ---');
            const scheme_details = await pool.request().query(`
                SELECT * FROM schemes WHERE customer_phone LIKE '%9788880152%'
            `);
            console.table(scheme_details.recordset);
        } else {
            console.log("No customer found matching V67 or 67");
            
            console.log("\nTrying transactions directly for V67 or 67...");
            const txns = await pool.request().query("SELECT * FROM transactions WHERE transaction_id LIKE '%V67%' OR scheme_id LIKE '%V67%'");
            console.table(txns.recordset);
        }

        await pool.close();
    } catch (e) {
        console.error("Failed to connect or run query:", e.message);
    }
}

checkV67();
