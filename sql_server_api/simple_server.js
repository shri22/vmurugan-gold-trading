// SIMPLE SQL SERVER API - NO SETUP SCRIPTS
console.log('🚀 Starting VMurugan SQL Server API...');

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

console.log('📋 Configuration:');
console.log('   Server:', process.env.SQL_SERVER);
console.log('   Database:', process.env.SQL_DATABASE);
console.log('   Username:', process.env.SQL_USERNAME);

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

let pool;

// Health check
app.get('/health', (req, res) => {
  console.log('📊 Health check requested');
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server API',
    database: process.env.SQL_DATABASE,
    server: process.env.SQL_SERVER
  });
});

// Test connection
app.get('/api/test-connection', async (req, res) => {
  console.log('🔗 Connection test requested');
  try {
    const result = await pool.request().query('SELECT @@VERSION as version, GETDATE() as current_datetime');
    res.json({
      success: true,
      message: 'SQL Server connection successful',
      server_info: result.recordset[0]
    });
  } catch (err) {
    console.error('❌ Connection test failed:', err.message);
    res.status(500).json({
      success: false,
      message: 'SQL Server connection failed',
      error: err.message
    });
  }
});

// Save customer
app.post('/api/customers', async (req, res) => {
  console.log('📝 Customer save requested:', req.body.phone, req.body.name);
  try {
    const { phone, name, email, address, pan_card, device_id, encrypted_mpin } = req.body;

    // Check if customer exists
    const existingCustomer = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query('SELECT phone FROM customers WHERE phone = @phone');

    if (existingCustomer.recordset.length > 0) {
      // Update existing customer
      await pool.request()
        .input('phone', sql.NVarChar, phone)
        .input('name', sql.NVarChar, name)
        .input('email', sql.NVarChar, email)
        .input('address', sql.NVarChar, address)
        .input('pan_card', sql.NVarChar, pan_card)
        .input('device_id', sql.NVarChar, device_id)
        .input('encrypted_mpin', sql.NVarChar, encrypted_mpin)
        .query(`
          UPDATE customers
          SET name = @name, email = @email, address = @address,
              pan_card = @pan_card, device_id = @device_id,
              encrypted_mpin = @encrypted_mpin, updated_at = GETDATE()
          WHERE phone = @phone
        `);
      
      console.log('✅ Customer updated:', phone);
    } else {
      // Insert new customer
      await pool.request()
        .input('phone', sql.NVarChar, phone)
        .input('name', sql.NVarChar, name)
        .input('email', sql.NVarChar, email)
        .input('address', sql.NVarChar, address)
        .input('pan_card', sql.NVarChar, pan_card)
        .input('device_id', sql.NVarChar, device_id)
        .input('encrypted_mpin', sql.NVarChar, encrypted_mpin)
        .query(`
          INSERT INTO customers (phone, name, email, address, pan_card, device_id, encrypted_mpin, business_id)
          VALUES (@phone, @name, @email, @address, @pan_card, @device_id, @encrypted_mpin, 'VMURUGAN_001')
        `);
      
      console.log('✅ Customer inserted:', phone);
    }

    res.json({
      success: true,
      message: 'Customer saved successfully to SQL Server',
      customer_id: phone
    });

  } catch (err) {
    console.error('❌ Error saving customer:', err.message);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save customer: ' + err.message
    });
  }
});

// Login verification
app.post('/api/login', async (req, res) => {
  console.log('🔐 Login verification requested:', req.body.phone);
  try {
    const { phone, encrypted_mpin } = req.body;

    // Get customer with encrypted MPIN
    const result = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query('SELECT phone, name, email, encrypted_mpin FROM customers WHERE phone = @phone');

    if (result.recordset.length === 0) {
      console.log('❌ Customer not found:', phone);
      return res.status(404).json({
        success: false,
        message: 'Customer not found. Please register first.'
      });
    }

    const customer = result.recordset[0];

    // Verify MPIN
    if (customer.encrypted_mpin === encrypted_mpin) {
      console.log('✅ Login successful for:', phone);
      res.json({
        success: true,
        message: 'Login successful',
        customer: {
          phone: customer.phone,
          name: customer.name,
          email: customer.email
        }
      });
    } else {
      console.log('❌ Invalid MPIN for:', phone);
      res.status(401).json({
        success: false,
        message: 'Invalid MPIN. Please try again.'
      });
    }

  } catch (err) {
    console.error('❌ Error during login:', err.message);
    res.status(500).json({
      success: false,
      message: 'Login failed: ' + err.message
    });
  }
});

// Save transaction
app.post('/api/transactions', async (req, res) => {
  console.log('💰 Transaction save requested:', req.body.transaction_id);
  try {
    const {
      transaction_id, customer_phone, customer_name, type, amount, gold_grams,
      gold_price_per_gram, payment_method, status, gateway_transaction_id,
      device_info, location
    } = req.body;

    // Insert transaction
    await pool.request()
      .input('transaction_id', sql.NVarChar, transaction_id)
      .input('customer_phone', sql.NVarChar, customer_phone)
      .input('customer_name', sql.NVarChar, customer_name)
      .input('type', sql.NVarChar, type)
      .input('amount', sql.Decimal(12,2), amount)
      .input('gold_grams', sql.Decimal(10,4), gold_grams)
      .input('gold_price_per_gram', sql.Decimal(10,2), gold_price_per_gram)
      .input('payment_method', sql.NVarChar, payment_method)
      .input('status', sql.NVarChar, status)
      .input('gateway_transaction_id', sql.NVarChar, gateway_transaction_id)
      .input('device_info', sql.NVarChar, device_info)
      .input('location', sql.NVarChar, location)
      .query(`
        INSERT INTO transactions (
          transaction_id, customer_phone, customer_name, type, amount, gold_grams,
          gold_price_per_gram, payment_method, status, gateway_transaction_id,
          device_info, location, business_id
        ) VALUES (
          @transaction_id, @customer_phone, @customer_name, @type, @amount, @gold_grams,
          @gold_price_per_gram, @payment_method, @status, @gateway_transaction_id,
          @device_info, @location, 'VMURUGAN_001'
        )
      `);

    // Update customer stats if transaction is successful
    if (status === 'SUCCESS' && type === 'BUY') {
      await pool.request()
        .input('amount', sql.Decimal(12,2), amount)
        .input('gold_grams', sql.Decimal(10,4), gold_grams)
        .input('customer_phone', sql.NVarChar, customer_phone)
        .query(`
          UPDATE customers 
          SET total_invested = total_invested + @amount,
              total_gold = total_gold + @gold_grams,
              transaction_count = transaction_count + 1,
              last_transaction = GETDATE(),
              updated_at = GETDATE()
          WHERE phone = @customer_phone
        `);
      
      console.log('✅ Customer stats updated for:', customer_phone);
    }

    console.log('✅ Transaction saved:', transaction_id);

    res.json({
      success: true,
      message: 'Transaction saved successfully to SQL Server',
      transaction_id: transaction_id
    });

  } catch (err) {
    console.error('❌ Error saving transaction:', err.message);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save transaction: ' + err.message
    });
  }
});

// Get customers
app.get('/api/customers', async (req, res) => {
  console.log('👥 Customers list requested');
  try {
    const result = await pool.request()
      .query('SELECT * FROM customers ORDER BY registration_date DESC');

    console.log('✅ Found', result.recordset.length, 'customers');
    res.json({ 
      success: true, 
      customers: result.recordset,
      count: result.recordset.length 
    });

  } catch (err) {
    console.error('❌ Error getting customers:', err.message);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get customers: ' + err.message
    });
  }
});

// Start server
async function startServer() {
  try {
    console.log('🔗 Connecting to SQL Server...');
    pool = await sql.connect(sqlConfig);
    console.log('✅ Connected to SQL Server:', process.env.SQL_SERVER);
    
    app.listen(PORT, () => {
      console.log('🚀 VMurugan SQL Server API running on port', PORT);
      console.log('📊 Health Check: http://localhost:' + PORT + '/health');
      console.log('🔗 Test Connection: http://localhost:' + PORT + '/api/test-connection');
      console.log('💾 Database:', process.env.SQL_DATABASE, 'on', process.env.SQL_SERVER);
      console.log('📱 Ready to receive data from Flutter app!');
    });
    
  } catch (err) {
    console.error('❌ Failed to start server:', err.message);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  if (pool) {
    await pool.close();
  }
  process.exit(0);
});

startServer();
