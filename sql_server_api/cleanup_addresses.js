const sql = require('mssql');

const dbConfig = {
    server: 'localhost',
    port: 1433,
    database: 'VMuruganGoldTrading',
    user: 'sa',
    password: 'VMurugan@2025#SQL',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
    }
};

async function cleanupAddresses() {
    console.log('🧹 Scanning database for addresses with newlines...');

    try {
        const pool = await sql.connect(dbConfig);

        // Find customers with newlines in address
        const result = await pool.request().query("SELECT phone, name, address FROM customers WHERE address LIKE '%' + CHAR(10) + '%' OR address LIKE '%' + CHAR(13) + '%'");

        const customers = result.recordset;
        console.log(`📊 Found ${customers.length} customers with newlines in their address.`);

        if (customers.length === 0) {
            console.log('✅ No customers found with newlines. Database is clean!');
            await pool.close();
            return;
        }

        for (const customer of customers) {
            console.log(`🔍 Fixing address for: ${customer.name} (${customer.phone})`);

            // Clean the address: replace newlines with space and fix multiple spaces
            const cleanedAddress = customer.address
                .replace(/[\r\n]+/g, ' ')
                .replace(/\s+/g, ' ')
                .trim();

            await pool.request()
                .input('phone', sql.NVarChar(15), customer.phone)
                .input('cleaned', sql.NVarChar(sql.MAX), cleanedAddress)
                .query("UPDATE customers SET address = @cleaned, updated_at = GETDATE() WHERE phone = @phone");

            console.log(`   ✅ Original: "${customer.address.replace(/\n/g, '\\n').replace(/\r/g, '\\r')}"`);
            console.log(`   ✅ Cleaned:  "${cleanedAddress}"`);
        }

        console.log('\n✨ Database cleanup completed successfully!');
        await pool.close();
    } catch (err) {
        console.error('❌ Error during cleanup:', err.message);
    }
}

cleanupAddresses();
