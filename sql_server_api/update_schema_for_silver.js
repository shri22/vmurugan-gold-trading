// UPDATE SQL SERVER SCHEMA FOR SILVER SUPPORT
// Run this to add silver columns to existing database

const sql = require('mssql');
require('dotenv').config();

console.log('🔧 Updating SQL Server schema for silver support...');

async function updateSchema() {
  try {
    // SQL Server configuration
    const sqlConfig = {
      server: process.env.SQL_SERVER,
      port: parseInt(process.env.SQL_PORT) || 1433,
      database: process.env.SQL_DATABASE,
      user: process.env.SQL_USERNAME,
      password: process.env.SQL_PASSWORD,
      options: {
        encrypt: process.env.SQL_ENCRYPT === 'true',
        trustServerCertificate: process.env.SQL_TRUST_SERVER_CERTIFICATE === 'true',
        enableArithAbort: true,
        instanceName: process.env.SQL_INSTANCE || undefined
      }
    };

    console.log('\n🔗 Connecting to SQL Server...');
    const pool = await sql.connect(sqlConfig);
    console.log('✅ Connected successfully');

    // Check if silver columns already exist
    console.log('\n🔍 Checking existing schema...');
    
    const columnCheck = await pool.request().query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = 'transactions' 
      AND COLUMN_NAME IN ('silver_grams', 'transaction_type', 'metal_type')
    `);

    const existingColumns = columnCheck.recordset.map(row => row.COLUMN_NAME);
    console.log('Existing columns:', existingColumns);

    // Add silver_grams column if it doesn't exist
    if (!existingColumns.includes('silver_grams')) {
      console.log('\n➕ Adding silver_grams column...');
      await pool.request().query(`
        ALTER TABLE transactions 
        ADD silver_grams DECIMAL(10,4) DEFAULT 0.0000
      `);
      console.log('✅ silver_grams column added');
    } else {
      console.log('✅ silver_grams column already exists');
    }

    // Add transaction_type column if it doesn't exist
    if (!existingColumns.includes('transaction_type')) {
      console.log('\n➕ Adding transaction_type column...');
      await pool.request().query(`
        ALTER TABLE transactions 
        ADD transaction_type NVARCHAR(10) DEFAULT 'BUY'
      `);
      console.log('✅ transaction_type column added');
    } else {
      console.log('✅ transaction_type column already exists');
    }

    // Add metal_type column if it doesn't exist
    if (!existingColumns.includes('metal_type')) {
      console.log('\n➕ Adding metal_type column...');
      await pool.request().query(`
        ALTER TABLE transactions 
        ADD metal_type NVARCHAR(10) DEFAULT 'GOLD'
      `);
      console.log('✅ metal_type column added');
    } else {
      console.log('✅ metal_type column already exists');
    }

    // Update existing records to have proper metal_type
    console.log('\n🔄 Updating existing records...');
    const updateResult = await pool.request().query(`
      UPDATE transactions 
      SET metal_type = 'GOLD', 
          transaction_type = 'BUY'
      WHERE metal_type IS NULL OR metal_type = ''
    `);
    console.log(`✅ Updated ${updateResult.rowsAffected[0]} existing records`);

    // Create indexes for better performance
    console.log('\n📊 Creating indexes...');
    
    try {
      await pool.request().query(`
        CREATE INDEX IX_transactions_metal_type ON transactions(metal_type)
      `);
      console.log('✅ Index on metal_type created');
    } catch (e) {
      if (e.message.includes('already exists')) {
        console.log('✅ Index on metal_type already exists');
      } else {
        console.log('⚠️ Could not create metal_type index:', e.message);
      }
    }

    try {
      await pool.request().query(`
        CREATE INDEX IX_transactions_transaction_type ON transactions(transaction_type)
      `);
      console.log('✅ Index on transaction_type created');
    } catch (e) {
      if (e.message.includes('already exists')) {
        console.log('✅ Index on transaction_type already exists');
      } else {
        console.log('⚠️ Could not create transaction_type index:', e.message);
      }
    }

    // Show updated schema
    console.log('\n📋 Updated transactions table schema:');
    const schemaResult = await pool.request().query(`
      SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        COLUMN_DEFAULT
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = 'transactions'
      ORDER BY ORDINAL_POSITION
    `);

    schemaResult.recordset.forEach(col => {
      console.log(`   ${col.COLUMN_NAME}: ${col.DATA_TYPE} ${col.IS_NULLABLE === 'YES' ? 'NULL' : 'NOT NULL'} ${col.COLUMN_DEFAULT || ''}`);
    });

    // Test the new schema with a sample query
    console.log('\n🧪 Testing new schema...');
    const testResult = await pool.request().query(`
      SELECT TOP 5 
        transaction_id,
        customer_phone,
        amount,
        gold_grams,
        silver_grams,
        metal_type,
        transaction_type,
        status
      FROM transactions
      ORDER BY timestamp DESC
    `);

    console.log('✅ Schema test successful');
    console.log(`   Found ${testResult.recordset.length} transactions`);

    await pool.close();

    console.log('\n🎉 Schema update completed successfully!');
    console.log('\n✅ Your database now supports:');
    console.log('   - Gold transactions (existing)');
    console.log('   - Silver transactions (new)');
    console.log('   - Transaction types (BUY/SELL)');
    console.log('   - Metal types (GOLD/SILVER)');
    
    console.log('\n🚀 Next Steps:');
    console.log('   1. Restart your server: npm start');
    console.log('   2. Test new portfolio API: http://localhost:3001/api/portfolio?phone=YOUR_PHONE');
    console.log('   3. Test silver transactions in mobile app');

  } catch (error) {
    console.error('\n❌ Schema update failed:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Ensure SQL Server is running');
    console.log('   2. Check database connection');
    console.log('   3. Verify user has ALTER TABLE permissions');
    console.log('   4. Check if database exists');
    
    process.exit(1);
  }
}

updateSchema();
