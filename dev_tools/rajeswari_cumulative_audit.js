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

async function runAudit() {
    try {
        const pool = await sql.connect(sqlConfig);
        console.log('🔗 Connected to SQL Server');

        const result = await pool.request()
            .input('phone', sql.NVarChar(15), '9585007471')
            .query(`
                SELECT 
                    transaction_id, 
                    amount, 
                    gold_grams, 
                    gold_price_per_gram, 
                    CONVERT(varchar, created_at, 120) as created_at
                FROM transactions
                WHERE customer_phone = @phone 
                  AND status = 'SUCCESS' 
                  AND metal_type = 'GOLD'
                ORDER BY created_at ASC
            `);

        const txns = result.recordset;
        let cumulativeGrams = 0;
        let cumulativeAmount = 0;

        const auditTrail = txns.map((t, idx) => {
            cumulativeGrams += t.gold_grams;
            cumulativeAmount += t.amount;
            return {
                index: idx + 1,
                date: t.created_at,
                order_id: t.transaction_id,
                amount: t.amount,
                rate: t.gold_price_per_gram,
                grams: t.gold_grams,
                cum_grams: parseFloat(cumulativeGrams.toFixed(4)),
                cum_amount: cumulativeAmount
            };
        });

        console.log('\n--- DETAILED TRANSACTION-BY-TRANSACTION CUMULATIVE AUDIT ---');
        
        // Print the last 25 transactions to see the recent build-up
        console.log('\nShowing recent 25 transactions leading up to June 6th:');
        console.table(auditTrail.slice(-25));

        // Let's also output the full report to a text file for the user to download
        const fs = require('fs');
        const reportPath = '/Users/admin/Documents/Win-Projects/AntiGravity/vmurugan-gold-trading/sql_server_api/rajeswari_full_audit.txt';
        
        let fileContent = '================================================================================\n';
        fileContent += 'FULL TRANSACTION AUDIT REPORT FOR RAJESWARI (9585007471)\n';
        fileContent += 'Generated on: ' + new Date().toISOString() + '\n';
        fileContent += '================================================================================\n\n';
        fileContent += String('Index').padEnd(6) + ' | ' +
                       String('Date/Time').padEnd(21) + ' | ' +
                       String('Transaction ID').padEnd(30) + ' | ' +
                       String('Amount').padEnd(8) + ' | ' +
                       String('Rate').padEnd(8) + ' | ' +
                       String('Grams').padEnd(8) + ' | ' +
                       String('Cum. Grams').padEnd(12) + ' | ' +
                       String('Cum. Amount').padEnd(12) + '\n';
        fileContent += '-'.repeat(120) + '\n';

        auditTrail.forEach(t => {
            fileContent += String(t.index).padEnd(6) + ' | ' +
                           String(t.date).padEnd(21) + ' | ' +
                           String(t.order_id).padEnd(30) + ' | ' +
                           String(t.amount).padEnd(8) + ' | ' +
                           String(t.rate).padEnd(8) + ' | ' +
                           String(t.grams.toFixed(3)).padEnd(8) + ' | ' +
                           String(t.cum_grams.toFixed(3)).padEnd(12) + ' | ' +
                           String(t.cum_amount).padEnd(12) + '\n';
        });
        
        fs.writeFileSync(reportPath, fileContent);
        console.log(`\n✅ Saved complete 84-transaction audit trail to:\n${reportPath}`);

        await pool.close();
    } catch (e) {
        console.error(e.message);
    }
}

runAudit();
