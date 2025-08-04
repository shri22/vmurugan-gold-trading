// SQL SERVER API SETUP SCRIPT
// Run this to install dependencies and test the connection

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔧 Setting up VMurugan SQL Server API...');

async function setup() {
  try {
    console.log('\n📦 Installing dependencies...');
    execSync('npm install', { stdio: 'inherit' });
    console.log('✅ Dependencies installed');

    // Now require modules after installation
    const sql = require('mssql');
    require('dotenv').config();

    // SQL Server configuration
    const sqlConfig = {
      server: process.env.SQL_SERVER,
      port: parseInt(process.env.SQL_PORT) || 1433,
      database: 'master', // Connect to master first to create database
      user: process.env.SQL_USERNAME,
      password: process.env.SQL_PASSWORD,
      options: {
        encrypt: process.env.SQL_ENCRYPT === 'true',
        trustServerCertificate: process.env.SQL_TRUST_SERVER_CERTIFICATE === 'true',
        enableArithAbort: true,
        instanceName: process.env.SQL_INSTANCE || undefined
      }
    };

    console.log('\n🔗 Testing SQL Server connection...');
    console.log(`Server: ${process.env.SQL_SERVER}:${process.env.SQL_PORT}`);
    console.log(`Username: ${process.env.SQL_USERNAME}`);
    console.log(`Database: ${process.env.SQL_DATABASE}`);

    // Test connection
    const pool = await sql.connect(sqlConfig);
    console.log('✅ SQL Server connection successful');

    // Test query
    const result = await pool.request().query('SELECT @@VERSION as version, GETDATE() as current_datetime');
    console.log('✅ SQL Server version:', result.recordset[0].version.split('\n')[0]);

    // Check if target database exists
    const dbCheck = await pool.request()
      .input('dbname', sql.NVarChar, process.env.SQL_DATABASE)
      .query('SELECT name FROM sys.databases WHERE name = @dbname');

    if (dbCheck.recordset.length === 0) {
      console.log(`\n📊 Creating database: ${process.env.SQL_DATABASE}`);
      await pool.request().query(`CREATE DATABASE [${process.env.SQL_DATABASE}]`);
      console.log('✅ Database created successfully');
    } else {
      console.log(`✅ Database ${process.env.SQL_DATABASE} already exists`);
    }

    await pool.close();

    console.log('\n🎉 Setup completed successfully!');
    console.log('\n🚀 Next Steps:');
    console.log('   1. Run: npm start');
    console.log('   2. Test API: http://localhost:3001/health');
    console.log('   3. Test connection: http://localhost:3001/api/test-connection');
    console.log('   4. Build Flutter APK and test');

    console.log('\n📱 Flutter Configuration:');
    console.log('   - Server IP: ' + process.env.SQL_SERVER);
    console.log('   - API Port: 3001');
    console.log('   - Database: ' + process.env.SQL_DATABASE);

  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Check SQL Server is running');
    console.log('   2. Verify TCP/IP is enabled');
    console.log('   3. Check username/password');
    console.log('   4. Ensure firewall allows port 1433');
    console.log('   5. Verify SQL Server authentication is enabled');
    
    process.exit(1);
  }
}

setup();
