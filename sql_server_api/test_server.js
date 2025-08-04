// SIMPLE TEST SERVER TO VERIFY API CONNECTIVITY
const express = require('express');
const sql = require('mssql');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

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

// Initialize connection
async function initDB() {
  try {
    pool = await sql.connect(sqlConfig);
    console.log('✅ Connected to SQL Server:', process.env.SQL_SERVER);
    return true;
  } catch (err) {
    console.error('❌ SQL Server connection failed:', err.message);
    return false;
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server Test API',
    database: process.env.SQL_DATABASE,
    server: process.env.SQL_SERVER
  });
});

// Test connection
app.get('/api/test-connection', async (req, res) => {
  try {
    const result = await pool.request().query('SELECT @@VERSION as version, GETDATE() as current_datetime');
    res.json({
      success: true,
      message: 'SQL Server connection successful',
      server_info: result.recordset[0]
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'SQL Server connection failed',
      error: err.message
    });
  }
});

// Save customer
app.post('/api/customers', async (req, res) => {
  try {
    const { phone, name, email, address, pan_card, device_id } = req.body;

    console.log('📝 Saving customer:', { phone, name, email });

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
        .query(`
          UPDATE customers 
          SET name = @name, email = @email, address = @address, 
              pan_card = @pan_card, device_id = @device_id, updated_at = GETDATE()
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
        .query(`
          INSERT INTO customers (phone, name, email, address, pan_card, device_id, business_id)
          VALUES (@phone, @name, @email, @address, @pan_card, @device_id, 'VMURUGAN_001')
        `);
      
      console.log('✅ Customer inserted:', phone);
    }

    res.json({
      success: true,
      message: 'Customer saved successfully to SQL Server',
      customer_id: phone
    });

  } catch (err) {
    console.error('❌ Error saving customer:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save customer',
      error: err.message 
    });
  }
});

// Save transaction
app.post('/api/transactions', async (req, res) => {
  try {
    const {
      transaction_id, customer_phone, customer_name, type, amount, gold_grams,
      gold_price_per_gram, payment_method, status, gateway_transaction_id,
      device_info, location
    } = req.body;

    console.log('💰 Saving transaction:', { transaction_id, customer_phone, amount, status });

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
    console.error('❌ Error saving transaction:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save transaction',
      error: err.message 
    });
  }
});

// Get customers
app.get('/api/customers', async (req, res) => {
  try {
    const result = await pool.request()
      .query('SELECT * FROM customers ORDER BY registration_date DESC');

    res.json({ 
      success: true, 
      customers: result.recordset,
      count: result.recordset.length 
    });

  } catch (err) {
    console.error('❌ Error getting customers:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get customers',
      error: err.message 
    });
  }
});

// Get transactions
app.get('/api/transactions', async (req, res) => {
  try {
    const { customer_phone, status, limit = 50 } = req.query;
    
    let query = 'SELECT TOP (@limit) * FROM transactions WHERE 1=1';
    const request = pool.request().input('limit', sql.Int, parseInt(limit));
    
    if (customer_phone) {
      query += ' AND customer_phone = @customer_phone';
      request.input('customer_phone', sql.NVarChar, customer_phone);
    }
    
    if (status) {
      query += ' AND status = @status';
      request.input('status', sql.NVarChar, status);
    }
    
    query += ' ORDER BY timestamp DESC';
    
    const result = await request.query(query);

    res.json({ 
      success: true, 
      transactions: result.recordset,
      count: result.recordset.length 
    });

  } catch (err) {
    console.error('❌ Error getting transactions:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get transactions',
      error: err.message 
    });
  }
});

// Start server
async function startServer() {
  const dbConnected = await initDB();
  
  if (!dbConnected) {
    console.error('❌ Failed to connect to SQL Server. Exiting...');
    process.exit(1);
  }
  
  app.listen(PORT, () => {
    console.log(`🚀 VMurugan SQL Server Test API running on port ${PORT}`);
    console.log(`📊 Health Check: http://localhost:${PORT}/health`);
    console.log(`🔗 Test Connection: http://localhost:${PORT}/api/test-connection`);
    console.log(`💾 Database: ${process.env.SQL_DATABASE} on ${process.env.SQL_SERVER}`);
    console.log(`📱 Ready to receive data from Flutter app!`);
  });
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  if (pool) {
    await pool.close();
  }
  process.exit(0);
});

startServer();
