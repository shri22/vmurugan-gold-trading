
const sql = require('mssql');
require('dotenv').config();

const sqlConfig = {
    server: process.env.SQL_SERVER || 'DESKTOP-3QPE6QQ',
    port: parseInt(process.env.SQL_PORT) || 1433,
    database: process.env.SQL_DATABASE || 'VMuruganGoldTrading',
    user: process.env.SQL_USERNAME || 'sa',
    password: process.env.SQL_PASSWORD || 'git@#12345',
    options: {
        encrypt: process.env.SQL_ENCRYPT === 'true',
        trustServerCertificate: true,
        useUTC: false
    }
};

async function checkTransactions() {
    try {
        let pool = await sql.connect(sqlConfig);
        let result = await pool.request().query("SELECT transaction_id, amount, created_at, status FROM transactions WHERE created_at >= '2026-01-01' AND created_at < '2026-02-01' AND status = 'SUCCESS' ORDER BY created_at ASC");

        console.log('--- Successful Transactions in Jan 2026 ---');
        result.recordset.forEach(t => {
            console.log(`${t.created_at.toISOString()} | ${t.transaction_id} | ${t.amount}`);
        });

        // Group by Date
        const grouped = {};
        result.recordset.forEach(t => {
            const date = new Date(t.created_at.getTime() + (5.5 * 60 * 60 * 1000)).toISOString().split('T')[0]; // Adjust for IST
            grouped[date] = (grouped[date] || 0) + parseFloat(t.amount || 0);
        });

        console.log('\n--- Totals Grouped by Transaction Date (IST) ---');
        Object.keys(grouped).sort().forEach(date => {
            console.log(`${date}: ${grouped[date]}`);
        });

        // Group by Settlement Date using the logic in server.js
        function calculateSettlementDate(txnDate) {
            if (!txnDate) return 'N/A';
            let date = new Date(txnDate);
            // IST adjustment if needed, but the server uses new Date(txnDate)
            date.setDate(date.getDate() + 1);
            while (isNonSettlementDay(date)) {
                date.setDate(date.getDate() + 1);
            }
            return date.toISOString().split('T')[0];
        }

        function isNonSettlementDay(date) {
            const day = date.getDay();
            const dateNum = date.getDate();
            if (day === 0) return true;
            if (day === 6) {
                const weekNum = Math.ceil(dateNum / 7);
                if (weekNum === 2 || weekNum === 4) return true;
            }
            const holidays = [
                '2025-01-26', '2025-08-15', '2025-10-02', '2025-12-25',
                '2026-01-26', '2026-08-15', '2026-10-02', '2026-12-25'
            ];
            if (holidays.includes(date.toISOString().split('T')[0])) return true;
            return false;
        }

        const settled = {};
        result.recordset.forEach(t => {
            const sDate = calculateSettlementDate(t.created_at);
            settled[sDate] = (settled[sDate] || 0) + parseFloat(t.amount || 0);
        });

        console.log('\n--- Totals Grouped by SETTLEMENT Date (T+1 logic) ---');
        Object.keys(settled).sort().forEach(date => {
            console.log(`${date}: ${settled[date]}`);
        });

        await sql.close();
    } catch (err) {
        console.error(err);
    }
}

checkTransactions();
