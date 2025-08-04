// VMURUGAN SQL SERVER API BRIDGE
// Connects Flutter app to SQL Server database

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3001'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

app.use(express.json({ limit: '10mb' }));

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
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

// Global connection pool
let pool;

// Initialize SQL Server connection
async function initializeDatabase() {
  try {
    pool = await sql.connect(sqlConfig);
    console.log('✅ Connected to SQL Server:', process.env.SQL_SERVER);
    
    // Create database and tables if they don't exist
    await createDatabaseAndTables();
    
    return true;
  } catch (err) {
    console.error('❌ SQL Server connection failed:', err);
    return false;
  }
}

// Create database and tables
async function createDatabaseAndTables() {
  try {
    // Create database if not exists
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '${process.env.SQL_DATABASE}')
      BEGIN
        CREATE DATABASE [${process.env.SQL_DATABASE}]
      END
    `);
    
    // Use the database
    await pool.request().query(`USE [${process.env.SQL_DATABASE}]`);
    
    // Create customers table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='customers' AND xtype='U')
      BEGIN
        CREATE TABLE customers (
          id INT IDENTITY(1,1) PRIMARY KEY,
          phone NVARCHAR(15) UNIQUE NOT NULL,
          name NVARCHAR(100) NOT NULL,
          email NVARCHAR(100),
          address NVARCHAR(MAX),
          pan_card NVARCHAR(10),
          device_id NVARCHAR(100),
          encrypted_mpin NVARCHAR(255),
          registration_date DATETIME2 DEFAULT GETDATE(),
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          total_invested DECIMAL(12,2) DEFAULT 0.00,
          total_gold DECIMAL(10,4) DEFAULT 0.0000,
          transaction_count INT DEFAULT 0,
          last_transaction DATETIME2 NULL,
          created_at DATETIME2 DEFAULT GETDATE(),
          updated_at DATETIME2 DEFAULT GETDATE()
        )
        
        CREATE INDEX IX_customers_phone ON customers (phone)
        CREATE INDEX IX_customers_business ON customers (business_id)
      END
    `);
    
    // Create transactions table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='transactions' AND xtype='U')
      BEGIN
        CREATE TABLE transactions (
          id INT IDENTITY(1,1) PRIMARY KEY,
          transaction_id NVARCHAR(100) UNIQUE NOT NULL,
          customer_phone NVARCHAR(15),
          customer_name NVARCHAR(100),
          type NVARCHAR(10) NOT NULL CHECK (type IN ('BUY', 'SELL')),
          amount DECIMAL(12,2) NOT NULL,
          metal_grams DECIMAL(10,4) NOT NULL,
          metal_price_per_gram DECIMAL(10,2) NOT NULL,
          metal_type NVARCHAR(10) NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
          payment_method NVARCHAR(50) NOT NULL,
          status NVARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
          gateway_transaction_id NVARCHAR(100),
          device_info NVARCHAR(MAX),
          location NVARCHAR(MAX),
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          timestamp DATETIME2 DEFAULT GETDATE(),
          created_at DATETIME2 DEFAULT GETDATE()
        )
        
        CREATE INDEX IX_transactions_customer ON transactions (customer_phone)
        CREATE INDEX IX_transactions_status ON transactions (status)
        CREATE INDEX IX_transactions_timestamp ON transactions (timestamp)
      END
    `);
    
    // Create schemes table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='schemes' AND xtype='U')
      BEGIN
        CREATE TABLE schemes (
          id INT IDENTITY(1,1) PRIMARY KEY,
          scheme_id NVARCHAR(100) UNIQUE NOT NULL,
          customer_id NVARCHAR(100),
          customer_phone NVARCHAR(15),
          customer_name NVARCHAR(100),
          monthly_amount DECIMAL(12,2) NOT NULL,
          duration_months INT NOT NULL,
          scheme_type NVARCHAR(50) NOT NULL,
          metal_type NVARCHAR(10) NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
          status NVARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
          start_date DATETIME2 DEFAULT GETDATE(),
          end_date DATETIME2,
          total_amount DECIMAL(12,2),
          total_metal_grams DECIMAL(10,4) DEFAULT 0.0000,
          completed_installments INT DEFAULT 0,
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          created_at DATETIME2 DEFAULT GETDATE(),
          updated_at DATETIME2 DEFAULT GETDATE()
        )

        CREATE INDEX IX_schemes_customer ON schemes (customer_phone)
      END
    `);

    // Create scheme_installments table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='scheme_installments' AND xtype='U')
      BEGIN
        CREATE TABLE scheme_installments (
          id INT IDENTITY(1,1) PRIMARY KEY,
          installment_id NVARCHAR(100) UNIQUE NOT NULL,
          scheme_id NVARCHAR(100) NOT NULL,
          customer_phone NVARCHAR(15),
          installment_number INT NOT NULL,
          amount DECIMAL(12,2) NOT NULL,
          metal_grams DECIMAL(10,4) NOT NULL,
          metal_price_per_gram DECIMAL(10,2) NOT NULL,
          metal_type NVARCHAR(10) NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
          payment_method NVARCHAR(50),
          transaction_id NVARCHAR(100),
          status NVARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'CANCELLED')),
          due_date DATETIME2,
          paid_date DATETIME2,
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          created_at DATETIME2 DEFAULT GETDATE(),
          updated_at DATETIME2 DEFAULT GETDATE(),
          FOREIGN KEY (scheme_id) REFERENCES schemes(scheme_id)
        )

        CREATE INDEX IX_installments_scheme ON scheme_installments (scheme_id)
        CREATE INDEX IX_installments_customer ON scheme_installments (customer_phone)
        CREATE INDEX IX_installments_status ON scheme_installments (status)
      END
    `);

    // Create analytics table
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='analytics' AND xtype='U')
      BEGIN
        CREATE TABLE analytics (
          id INT IDENTITY(1,1) PRIMARY KEY,
          event NVARCHAR(100) NOT NULL,
          data NVARCHAR(MAX),
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          timestamp DATETIME2 DEFAULT GETDATE(),
          created_at DATETIME2 DEFAULT GETDATE()
        )
        
        CREATE INDEX IX_analytics_event ON analytics (event)
        CREATE INDEX IX_analytics_timestamp ON analytics (timestamp)
      END
    `);
    
    console.log('✅ Database and tables created/verified successfully');
  } catch (err) {
    console.error('❌ Error creating database/tables:', err);
    throw err;
  }
}

// Admin authentication middleware
const authenticateAdmin = (req, res, next) => {
  const adminToken = req.headers['admin-token'];
  const validToken = process.env.ADMIN_TOKEN || 'VMURUGAN_ADMIN_2025';
  
  if (adminToken !== validToken) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
};

// Serve test page
app.get('/test_network_access.html', (req, res) => {
  res.sendFile(__dirname + '/test_network_access.html');
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server API Bridge',
    database: process.env.SQL_DATABASE,
    server: process.env.SQL_SERVER
  });
});

// Test SQL Server connection
app.get('/api/test-connection', async (req, res) => {
  try {
    const result = await pool.request().query('SELECT @@VERSION as version, GETDATE() as current_datetime');
    res.json({
      success: true,
      message: 'SQL Server connection successful',
      server_info: result.recordset[0]
    });
  } catch (err) {
    console.error('Connection test failed:', err);
    res.status(500).json({
      success: false,
      message: 'SQL Server connection failed',
      error: err.message
    });
  }
});

// Send OTP for login/registration
app.post('/api/auth/send-otp', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone } = req.body;

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // In production, send OTP via SMS service
    // For testing, we'll just log it and return success
    console.log(`📱 OTP for ${phone}: ${otp}`);

    // Store OTP in memory (in production, use Redis or database)
    global.otpStore = global.otpStore || {};
    global.otpStore[phone] = {
      otp: otp,
      timestamp: Date.now(),
      attempts: 0
    };

    res.json({
      success: true,
      message: 'OTP sent successfully',
      // For testing only - remove in production
      otp: otp
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
});

// Verify OTP and login/register
app.post('/api/auth/verify-otp', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone, otp } = req.body;

    // Check OTP
    const storedOtpData = global.otpStore?.[phone];
    if (!storedOtpData) {
      return res.status(400).json({
        success: false,
        message: 'OTP not found or expired'
      });
    }

    // Check if OTP is expired (5 minutes)
    if (Date.now() - storedOtpData.timestamp > 5 * 60 * 1000) {
      delete global.otpStore[phone];
      return res.status(400).json({
        success: false,
        message: 'OTP expired'
      });
    }

    // Check OTP attempts
    if (storedOtpData.attempts >= 3) {
      delete global.otpStore[phone];
      return res.status(400).json({
        success: false,
        message: 'Too many attempts. Please request new OTP'
      });
    }

    // Verify OTP
    if (storedOtpData.otp !== otp) {
      storedOtpData.attempts++;
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // OTP verified, clear it
    delete global.otpStore[phone];

    // Check if customer exists
    const customerResult = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query('SELECT * FROM customers WHERE phone = @phone');

    let customer = customerResult.recordset[0];
    let isNewUser = false;

    if (!customer) {
      // New user - create basic customer record
      isNewUser = true;
      const customerId = `CUST_${Date.now()}`;

      await pool.request()
        .input('phone', sql.NVarChar, phone)
        .input('name', sql.NVarChar, 'New User') // Default name
        .input('email', sql.NVarChar, '')
        .input('address', sql.NVarChar, '')
        .input('business_id', sql.NVarChar, 'VMURUGAN_001')
        .query(`
          INSERT INTO customers (
            phone, name, email, address, business_id
          ) VALUES (
            @phone, @name, @email, @address, @business_id
          )
        `);

      // Get the newly created customer
      const newCustomerResult = await pool.request()
        .input('phone', sql.NVarChar, phone)
        .query('SELECT * FROM customers WHERE phone = @phone');

      customer = newCustomerResult.recordset[0];
    }

    res.json({
      success: true,
      message: 'Login successful',
      isNewUser: isNewUser,
      customer: {
        customer_id: customer.id || customer.customer_id, // Use id if customer_id doesn't exist
        phone: customer.phone,
        name: customer.name,
        email: customer.email,
        registration_date: customer.registration_date
      }
    });

  } catch (error) {
    console.error('❌ Error verifying OTP:', error);
    console.error('❌ Stack trace:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP',
      error: error.message
    });
  }
});

// Login with MPIN
app.post('/api/login', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('encrypted_mpin').notEmpty().withMessage('MPIN required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone, encrypted_mpin } = req.body;

    // Check if customer exists
    const customerResult = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query('SELECT * FROM customers WHERE phone = @phone');

    if (customerResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const customer = customerResult.recordset[0];

    // Check if customer has MPIN set
    if (!customer.encrypted_mpin) {
      return res.status(400).json({
        success: false,
        message: 'MPIN not set. Please complete registration first.'
      });
    }

    // Verify MPIN
    if (customer.encrypted_mpin !== encrypted_mpin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid MPIN'
      });
    }

    // Login successful
    res.json({
      success: true,
      message: 'Login successful',
      customer: {
        customer_id: customer.customer_id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email,
        registration_date: customer.registration_date
      }
    });

  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
});

// Save customer
app.post('/api/customers', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('name').isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('email').isEmail().withMessage('Invalid email')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone, name, email, address, pan_card, device_id, encrypted_mpin } = req.body;

    // Check if customer exists
    const existingCustomer = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query('SELECT phone FROM customers WHERE phone = @phone');

    if (existingCustomer.recordset.length > 0) {
      // Update existing customer
      const updateQuery = encrypted_mpin
        ? `UPDATE customers
           SET name = @name, email = @email, address = @address,
               pan_card = @pan_card, device_id = @device_id, encrypted_mpin = @encrypted_mpin, updated_at = GETDATE()
           WHERE phone = @phone`
        : `UPDATE customers
           SET name = @name, email = @email, address = @address,
               pan_card = @pan_card, device_id = @device_id, updated_at = GETDATE()
           WHERE phone = @phone`;

      const request = pool.request()
        .input('phone', sql.NVarChar, phone)
        .input('name', sql.NVarChar, name)
        .input('email', sql.NVarChar, email)
        .input('address', sql.NVarChar, address)
        .input('pan_card', sql.NVarChar, pan_card)
        .input('device_id', sql.NVarChar, device_id);

      if (encrypted_mpin) {
        request.input('encrypted_mpin', sql.NVarChar, encrypted_mpin);
      }

      await request.query(updateQuery);
    } else {
      // Insert new customer
      const insertQuery = encrypted_mpin
        ? `INSERT INTO customers (phone, name, email, address, pan_card, device_id, encrypted_mpin, business_id)
           VALUES (@phone, @name, @email, @address, @pan_card, @device_id, @encrypted_mpin, 'VMURUGAN_001')`
        : `INSERT INTO customers (phone, name, email, address, pan_card, device_id, business_id)
           VALUES (@phone, @name, @email, @address, @pan_card, @device_id, 'VMURUGAN_001')`;

      const request = pool.request()
        .input('phone', sql.NVarChar, phone)
        .input('name', sql.NVarChar, name)
        .input('email', sql.NVarChar, email)
        .input('address', sql.NVarChar, address)
        .input('pan_card', sql.NVarChar, pan_card)
        .input('device_id', sql.NVarChar, device_id);

      if (encrypted_mpin) {
        request.input('encrypted_mpin', sql.NVarChar, encrypted_mpin);
      }

      await request.query(insertQuery);
    }

    res.json({
      success: true,
      message: 'Customer saved successfully to SQL Server',
      customer_id: phone
    });

  } catch (err) {
    console.error('Error saving customer:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save customer',
      error: err.message 
    });
  }
});

// Save transaction
app.post('/api/transactions', [
  body('transaction_id').notEmpty().withMessage('Transaction ID required'),
  body('customer_phone').isMobilePhone('en-IN').withMessage('Invalid customer phone'),
  body('amount').isFloat({ min: 0 }).withMessage('Invalid amount'),
  body('gold_grams').isFloat({ min: 0 }).withMessage('Invalid gold grams')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

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
    }

    res.json({
      success: true,
      message: 'Transaction saved successfully to SQL Server',
      transaction_id: transaction_id
    });

  } catch (err) {
    console.error('Error saving transaction:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save transaction',
      error: err.message 
    });
  }
});

// Get customer by phone
app.get('/api/customers/:phone', async (req, res) => {
  try {
    const { phone } = req.params;
    const result = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .query('SELECT * FROM customers WHERE phone = @phone');

    if (result.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    res.json({ success: true, customer: result.recordset[0] });

  } catch (err) {
    console.error('Error getting customer:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get customer',
      error: err.message 
    });
  }
});

// Get all customers
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
    console.error('Error getting customers:', err);
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
    console.error('Error getting transactions:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get transactions',
      error: err.message 
    });
  }
});

// Get dashboard data
app.get('/api/admin/dashboard', authenticateAdmin, async (req, res) => {
  try {
    // Get statistics
    const statsResult = await pool.request().query(`
      SELECT 
        COUNT(DISTINCT customer_phone) as total_customers,
        COUNT(*) as total_transactions,
        SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) as total_revenue,
        SUM(CASE WHEN status = 'SUCCESS' THEN gold_grams ELSE 0 END) as total_gold_sold
      FROM transactions
    `);

    // Get recent transactions
    const transactionsResult = await pool.request().query(`
      SELECT TOP 20 * FROM transactions ORDER BY timestamp DESC
    `);

    // Get customers
    const customersResult = await pool.request().query(`
      SELECT TOP 50 * FROM customers ORDER BY registration_date DESC
    `);

    res.json({
      success: true,
      data: {
        stats: statsResult.recordset[0] || {},
        recent_transactions: transactionsResult.recordset,
        customers: customersResult.recordset
      }
    });

  } catch (err) {
    console.error('Error getting dashboard data:', err);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to get dashboard data',
      error: err.message 
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Start server
async function startServer() {
  const dbConnected = await initializeDatabase();
  
  if (!dbConnected) {
    console.error('❌ Failed to connect to SQL Server. Please check your configuration.');
    process.exit(1);
  }
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 VMurugan SQL Server API running on port ${PORT}`);
    console.log(`📊 Health Check: http://localhost:${PORT}/health`);
    console.log(`🔗 Test Connection: http://localhost:${PORT}/api/test-connection`);
    console.log(`🌐 Network Access: http://192.168.29.139:${PORT}/health`);
    console.log(`💾 Database: ${process.env.SQL_DATABASE} on ${process.env.SQL_SERVER}`);
    console.log(`📱 Mobile can access: http://192.168.29.139:${PORT}`);
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

module.exports = app;
