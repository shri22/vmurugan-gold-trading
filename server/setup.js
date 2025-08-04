// DATABASE SETUP SCRIPT
// Run this to create the database and tables

const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupDatabase() {
  console.log('🔧 Setting up Digi Gold Business Database...');

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
  });

  try {
    // Create database
    await connection.execute(`CREATE DATABASE IF NOT EXISTS digi_gold_business`);
    console.log('✅ Database created');

    // Use database
    await connection.execute(`USE digi_gold_business`);

    // Create customers table
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS customers (
        id INT PRIMARY KEY AUTO_INCREMENT,
        phone VARCHAR(15) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100),
        address TEXT,
        pan_card VARCHAR(10),
        device_id VARCHAR(100),
        registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        business_id VARCHAR(50) DEFAULT 'DIGI_GOLD_001',
        total_invested DECIMAL(12,2) DEFAULT 0.00,
        total_gold DECIMAL(10,4) DEFAULT 0.0000,
        transaction_count INT DEFAULT 0,
        last_transaction TIMESTAMP NULL,
        INDEX idx_phone (phone),
        INDEX idx_business (business_id),
        INDEX idx_registration (registration_date)
      )
    `);
    console.log('✅ Customers table created');

    // Add MPIN column if it doesn't exist
    try {
      await connection.execute(`
        ALTER TABLE customers ADD COLUMN mpin VARCHAR(4) NULL
      `);
      console.log('✅ MPIN column added to customers table');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('✅ MPIN column already exists');
      } else {
        console.log('⚠️ Error adding MPIN column:', error.message);
      }
    }

    // Create transactions table
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS transactions (
        id INT PRIMARY KEY AUTO_INCREMENT,
        transaction_id VARCHAR(100) UNIQUE NOT NULL,
        customer_phone VARCHAR(15),
        customer_name VARCHAR(100),
        type ENUM('BUY', 'SELL') NOT NULL,
        amount DECIMAL(12,2) NOT NULL,
        gold_grams DECIMAL(10,4) NOT NULL,
        gold_price_per_gram DECIMAL(10,2) NOT NULL,
        payment_method VARCHAR(50) NOT NULL,
        status ENUM('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED') NOT NULL,
        gateway_transaction_id VARCHAR(100),
        device_info TEXT,
        location TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        business_id VARCHAR(50) DEFAULT 'DIGI_GOLD_001',
        INDEX idx_transaction_id (transaction_id),
        INDEX idx_customer (customer_phone),
        INDEX idx_status (status),
        INDEX idx_timestamp (timestamp),
        INDEX idx_business (business_id),
        FOREIGN KEY (customer_phone) REFERENCES customers(phone) ON DELETE SET NULL
      )
    `);
    console.log('✅ Transactions table created');

    // Create analytics table
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS analytics (
        id INT PRIMARY KEY AUTO_INCREMENT,
        event VARCHAR(100) NOT NULL,
        data JSON,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        business_id VARCHAR(50) DEFAULT 'DIGI_GOLD_001',
        INDEX idx_event (event),
        INDEX idx_timestamp (timestamp),
        INDEX idx_business (business_id)
      )
    `);
    console.log('✅ Analytics table created');

    // Create admin users table (for future use)
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS admin_users (
        id INT PRIMARY KEY AUTO_INCREMENT,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role ENUM('ADMIN', 'MANAGER', 'VIEWER') DEFAULT 'VIEWER',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP NULL,
        is_active BOOLEAN DEFAULT TRUE,
        business_id VARCHAR(50) DEFAULT 'DIGI_GOLD_001'
      )
    `);
    console.log('✅ Admin users table created');

    // Insert sample data for testing
    await connection.execute(`
      INSERT IGNORE INTO customers (phone, name, email, address, pan_card, device_id) 
      VALUES 
      ('9999999999', 'Test Customer', 'test@example.com', 'Test Address', 'ABCDE1234F', 'test_device_001')
    `);

    await connection.execute(`
      INSERT IGNORE INTO analytics (event, data) 
      VALUES 
      ('database_setup', '{"setup_date": "${new Date().toISOString()}", "version": "1.0.0"}')
    `);

    console.log('✅ Sample data inserted');

    // Show database info
    const [tables] = await connection.execute(`SHOW TABLES`);
    console.log('\n📊 Database Tables:');
    tables.forEach(table => {
      console.log(`   - ${Object.values(table)[0]}`);
    });

    const [customerCount] = await connection.execute(`SELECT COUNT(*) as count FROM customers`);
    const [transactionCount] = await connection.execute(`SELECT COUNT(*) as count FROM transactions`);
    
    console.log('\n📈 Current Data:');
    console.log(`   - Customers: ${customerCount[0].count}`);
    console.log(`   - Transactions: ${transactionCount[0].count}`);

    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n🔑 Next Steps:');
    console.log('   1. Update your .env file with database credentials');
    console.log('   2. Set ADMIN_TOKEN in .env file');
    console.log('   3. Run: npm start');
    console.log('   4. Test API: http://localhost:3000/health');

  } catch (error) {
    console.error('❌ Error setting up database:', error);
  } finally {
    await connection.end();
  }
}

// Run setup
setupDatabase();
