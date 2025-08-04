// Add encrypted_mpin column to customers table
const sql = require('mssql');
require('dotenv').config();

async function addMpinColumn() {
  try {
    console.log('🔧 Adding encrypted_mpin column to customers table...');

    // SQL Server configuration
    const sqlConfig = {
      server: process.env.SQL_SERVER,
      port: parseInt(process.env.SQL_PORT) || 1433,
      database: process.env.SQL_DATABASE,
      user: process.env.SQL_USERNAME,
      password: process.env.SQL_PASSWORD,
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
      }
    };

    // Connect to SQL Server
    const pool = await sql.connect(sqlConfig);
    console.log('✅ Connected to SQL Server');

    // Check if column already exists
    const checkColumnQuery = `
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = 'customers' AND COLUMN_NAME = 'encrypted_mpin'
    `;
    
    const columnExists = await pool.request().query(checkColumnQuery);
    
    if (columnExists.recordset.length > 0) {
      console.log('✅ encrypted_mpin column already exists');
    } else {
      // Add the column
      const addColumnQuery = `
        ALTER TABLE customers 
        ADD encrypted_mpin NVARCHAR(255) NULL
      `;
      
      await pool.request().query(addColumnQuery);
      console.log('✅ encrypted_mpin column added successfully');
    }

    // Close connection
    await pool.close();
    console.log('🎉 Database update completed!');

  } catch (err) {
    console.error('❌ Error adding encrypted_mpin column:', err.message);
    process.exit(1);
  }
}

addMpinColumn();
