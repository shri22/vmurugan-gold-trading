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

async function healthCheck() {
    try {
        const pool = await sql.connect(sqlConfig);
        console.log('--- SYSTEM HEALTH CHECK ---\n');

        // Check 1: Stuck PENDING transactions
        const pendingResult = await pool.request().query(`
            SELECT COUNT(*) as count, MAX(created_at) as oldest_pending
            FROM transactions 
            WHERE status = 'PENDING' AND created_at < DATEADD(hour, -2, GETDATE())
        `);
        console.log("1. Stuck PENDING Transactions (Older than 2 hours):");
        console.table(pendingResult.recordset);

        // Check 2: Total Amount Paid vs Total Invested discrepancy
        const amountPaidResult = await pool.request().query(`
            SELECT TOP 5 customer_phone, scheme_id, total_invested, total_amount_paid
            FROM schemes
            WHERE total_invested != total_amount_paid
        `);
        if (amountPaidResult.recordset.length > 0) {
            console.log("\n2. Discrepancy between total_invested and total_amount_paid in Schemes:");
            console.table(amountPaidResult.recordset);
        } else {
            console.log("\n2. No discrepancy found in total_amount_paid.");
        }

        // Check 3: Missing metal rates today
        const tableCheck = await pool.request().query(`
            SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'metal_rates'
        `);
        if (tableCheck.recordset.length > 0) {
            const ratesResult = await pool.request().query(`
                SELECT COUNT(*) as count 
                FROM metal_rates 
                WHERE CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)
            `);
            console.log("\n3. Metal rates updated today:");
            console.log(ratesResult.recordset[0].count > 0 ? "✅ Yes" : "❌ No");
        } else {
            console.log("\n3. Metal rates table: ⚠️ Table 'metal_rates' does not exist in the database (Rates are dynamic/scraped from MJDTA/TheJewellersAssociation directly).");
        }

        await pool.close();
    } catch (e) {
        console.error("Error:", e.message);
    }
}

healthCheck();
