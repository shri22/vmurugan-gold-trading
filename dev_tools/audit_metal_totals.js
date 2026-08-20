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

async function auditMetalTotals() {
    try {
        const pool = await sql.connect(sqlConfig);
        const phone = '9585007471';

        console.log('--- AUDITING METAL TOTALS (READ-ONLY) ---');
        
        // 1. Current stored values in Database
        const dbState = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
                SELECT name, total_gold as customer_total_gold, total_silver as customer_total_silver
                FROM customers
                WHERE phone = @phone;
                
                SELECT scheme_id, scheme_type, metal_type, total_invested, total_amount_paid, total_metal_accumulated
                FROM schemes
                WHERE customer_phone = @phone;
            `);
        
        console.log('\nStored in Customers Table:');
        console.table(dbState.recordsets[0]);
        console.log('Stored in Schemes Table:');
        console.table(dbState.recordsets[1]);

        // 2. Calculated sums from SUCCESS transactions
        const calculated = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
                SELECT 
                    metal_type,
                    SUM(amount) as sum_amount,
                    SUM(gold_grams) as sum_gold_grams,
                    SUM(silver_grams) as sum_silver_grams,
                    COUNT(*) as success_count
                FROM transactions
                WHERE customer_phone = @phone AND status = 'SUCCESS'
                GROUP BY metal_type;
                
                SELECT 
                    scheme_id,
                    metal_type,
                    SUM(amount) as sum_amount,
                    SUM(gold_grams) as sum_gold_grams,
                    SUM(silver_grams) as sum_silver_grams,
                    COUNT(*) as success_count
                FROM transactions
                WHERE customer_phone = @phone AND status = 'SUCCESS' AND scheme_id IS NOT NULL
                GROUP BY scheme_id, metal_type;
            `);

        console.log('\nCalculated from SUCCESS Transactions (Grouped by Metal Type):');
        console.table(calculated.recordsets[0]);
        console.log('Calculated from SUCCESS Transactions (Grouped by Scheme):');
        console.table(calculated.recordsets[1]);

        // 3. June 2026 transactions specifically
        const juneTxns = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
                SELECT transaction_id, type, amount, metal_type, gold_grams, status, scheme_id,
                       CONVERT(varchar, created_at, 120) as created_at
                FROM transactions
                WHERE customer_phone = @phone AND created_at >= '2026-06-01'
                ORDER BY created_at ASC;
            `);
        
        console.log('\nJune 2026 Transactions:');
        console.table(juneTxns.recordset);

        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

auditMetalTotals();
