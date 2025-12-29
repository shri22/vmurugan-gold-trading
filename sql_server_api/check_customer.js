// Quick script to check customer data
// Run: node check_customer.js

const sql = require('mssql');

const sqlConfig = {
    server: process.env.SQL_SERVER || 'DESKTOP-3QPE6QQ',
    port: parseInt(process.env.SQL_PORT) || 1433,
    database: process.env.SQL_DATABASE || 'VMuruganGoldTrading',
    user: process.env.SQL_USERNAME || 'sa',
    password: process.env.SQL_PASSWORD || 'git@#12345',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
    }
};

async function checkCustomerData() {
    try {
        console.log('🔗 Connecting to SQL Server...');
        const pool = await sql.connect(sqlConfig);
        console.log('✅ Connected!\n');

        const phone = '9715569313';

        // Check customer record
        console.log('👤 CUSTOMER RECORD:');
        console.log('='.repeat(80));
        const customerResult = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
        SELECT id, customer_id, phone, name, email
        FROM customers
        WHERE phone LIKE '%' + @phone + '%'
      `);
        console.table(customerResult.recordset);

        // Check transactions
        console.log('\n💰 TRANSACTIONS:');
        console.log('='.repeat(80));
        const txnResult = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
        SELECT 
          transaction_id,
          customer_phone,
          type,
          amount,
          gold_grams,
          silver_grams,
          status,
          scheme_id,
          metal_type,
          CONVERT(varchar, created_at, 120) as created_at
        FROM transactions
        WHERE customer_phone LIKE '%' + @phone + '%'
        ORDER BY created_at DESC
      `);
        console.table(txnResult.recordset);

        // Calculate totals
        console.log('\n📊 CALCULATED TOTALS:');
        console.log('='.repeat(80));
        const totalsResult = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
        SELECT 
          COUNT(*) as total_transactions,
          SUM(amount) as total_invested,
          SUM(gold_grams) as total_gold,
          SUM(silver_grams) as total_silver,
          SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful_txns
        FROM transactions
        WHERE customer_phone LIKE '%' + @phone + '%'
      `);
        console.table(totalsResult.recordset);

        // Check schemes
        console.log('\n🎯 SCHEMES:');
        console.log('='.repeat(80));
        const schemesResult = await pool.request()
            .input('phone', sql.NVarChar(15), phone)
            .query(`
        SELECT 
          scheme_id,
          customer_phone,
          scheme_type,
          metal_type,
          monthly_amount,
          status,
          total_invested,
          total_metal_accumulated
        FROM schemes
        WHERE customer_phone LIKE '%' + @phone + '%'
      `);
        console.table(schemesResult.recordset);

        // Check phone format variations
        console.log('\n📞 PHONE FORMAT VARIATIONS:');
        console.log('='.repeat(80));
        const phoneFormats = await pool.request()
            .query(`
        SELECT DISTINCT customer_phone
        FROM transactions
        WHERE customer_phone LIKE '%715569313%'
      `);
        console.table(phoneFormats.recordset);

        await pool.close();
        console.log('\n✅ Done!');

    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error(error);
    }
}

checkCustomerData();
