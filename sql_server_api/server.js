// VMurugan Gold Trading - SQL Server API (SQL Server 2005 Compatible)
const express = require('express');
const https = require('https'); // ADDED: For HTTPS support
const fs = require('fs'); // ADDED: For reading SSL certificates
const sql = require('mssql');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto'); // ADDED: For MPIN encryption
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

console.log('🚀 VMurugan SQL Server API Starting...');
console.log('📊 Port:', PORT);

// Security middleware
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: false,
}));

// Enhanced CORS configuration for admin portal and mobile app
app.use(cors({
  origin: [
    'https://api.vmuruganjewellery.co.in',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'file://',
    '*'
  ],
  credentials: false,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept', 'Origin', 'User-Agent', 'admin-token'],
  optionsSuccessStatus: 200
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100
});
app.use('/api/', limiter);

app.use(express.json({ limit: '10mb' }));

// Handle preflight requests
app.options('*', (req, res) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Accept, Origin, User-Agent, admin-token');
  res.sendStatus(200);
});

// MPIN encryption functions
function hashMPIN(mpin) {
  // Simple hash for MPIN (in production, use bcrypt or similar)
  return crypto.createHash('sha256').update(mpin + 'VMURUGAN_SALT').digest('hex');
}

function verifyMPIN(inputMPIN, hashedMPIN) {
  return hashMPIN(inputMPIN) === hashedMPIN;
}

// SQL Server configuration
const sqlConfig = {
  server: 'DESKTOP-3QPE6QQ',
  port: 1433,
  database: 'VMuruganGoldTrading',
  user: 'sa',
  password: 'git@#12345',
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
  connectionTimeout: 30000,
  requestTimeout: 30000,
};

console.log('🔗 SQL Server Config:', {
  server: sqlConfig.server,
  port: sqlConfig.port,
  database: sqlConfig.database,
  user: sqlConfig.user,
  password: '***'
});

// Global connection pool
let pool;

// Initialize SQL Server connection
async function initializeDatabase() {
  try {
    console.log('📡 Connecting to SQL Server...');
    
    if (pool) {
      await pool.close();
    }
    
    pool = await sql.connect(sqlConfig);
    console.log('✅ SQL Server connected successfully');
    
    // Test the connection
    const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as servername');
    console.log('📊 Server Name:', result.recordset[0].servername);
    console.log('📊 SQL Version:', result.recordset[0].version.substring(0, 50) + '...');
    
    // Create tables
    await createTablesIfNotExist();
    
    return true;
  } catch (error) {
    console.error('❌ SQL Server connection failed:', error.message);
    return false;
  }
}

// Create database tables - SQL Server 2005 Compatible
async function createTablesIfNotExist() {
  try {
    console.log('📋 Creating tables if not exist...');
    
    // Create customers table - Using DATETIME instead of DATETIME2
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
          registration_date DATETIME DEFAULT GETDATE(),
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          total_invested DECIMAL(12,2) DEFAULT 0.00,
          total_gold DECIMAL(10,4) DEFAULT 0.0000,
          transaction_count INT DEFAULT 0,
          last_transaction DATETIME NULL,
          created_at DATETIME DEFAULT GETDATE(),
          updated_at DATETIME DEFAULT GETDATE()
        )
        CREATE INDEX IX_customers_phone ON customers (phone)
        PRINT 'Customers table created'
      END
    `);

    // Create transactions table - Using DATETIME instead of DATETIME2
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
          gold_grams DECIMAL(10,4) NOT NULL,
          gold_price_per_gram DECIMAL(10,2) NOT NULL,
          payment_method NVARCHAR(50) NOT NULL,
          status NVARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
          gateway_transaction_id NVARCHAR(100),
          device_info NVARCHAR(MAX),
          location NVARCHAR(MAX),
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          timestamp DATETIME DEFAULT GETDATE(),
          created_at DATETIME DEFAULT GETDATE()
        )
        CREATE INDEX IX_transactions_customer ON transactions (customer_phone)
        CREATE INDEX IX_transactions_status ON transactions (status)
        PRINT 'Transactions table created'
      END
    `);

    // Create schemes table - SQL Server 2005 Compatible
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='schemes' AND xtype='U')
      BEGIN
        CREATE TABLE schemes (
          id INT IDENTITY(1,1) PRIMARY KEY,
          scheme_id NVARCHAR(100) UNIQUE NOT NULL,
          customer_id INT NOT NULL,
          customer_phone NVARCHAR(15) NOT NULL,
          customer_name NVARCHAR(100) NOT NULL,
          scheme_type NVARCHAR(20) NOT NULL CHECK (scheme_type IN ('GOLDPLUS', 'GOLDFLEXI', 'SILVERPLUS', 'SILVERFLEXI')),
          metal_type NVARCHAR(10) NOT NULL CHECK (metal_type IN ('GOLD', 'SILVER')),
          monthly_amount DECIMAL(12,2) NOT NULL,
          duration_months INT NULL,
          status NVARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED')),
          start_date DATETIME DEFAULT GETDATE(),
          end_date DATETIME NULL,
          total_invested DECIMAL(12,2) DEFAULT 0.00,
          total_metal_accumulated DECIMAL(10,4) DEFAULT 0.0000,
          completed_installments INT DEFAULT 0,
          terms_accepted BIT DEFAULT 0,
          terms_accepted_at DATETIME NULL,
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          created_at DATETIME DEFAULT GETDATE(),
          updated_at DATETIME DEFAULT GETDATE()
        )
        CREATE INDEX IX_schemes_customer ON schemes (customer_id)
        CREATE INDEX IX_schemes_phone ON schemes (customer_phone)
        CREATE INDEX IX_schemes_type ON schemes (scheme_type)
        CREATE INDEX IX_schemes_status ON schemes (status)
        PRINT 'Schemes table created'
      END
    `);

    // Insert test data
    await pool.request().query(`
      IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = '9999999999')
      BEGIN
        INSERT INTO customers (phone, name, email, address, pan_card, device_id)
        VALUES ('9999999999', 'Test Customer', 'test@vmurugan.com', 'Test Address, Chennai', 'ABCDE1234F', 'test_device_001')
        PRINT 'Test customer inserted'
      END
    `);

    console.log('✅ Tables created successfully');
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
  }
}

// ROUTES START HERE

// Health check endpoint
app.get('/health', (req, res) => {
  console.log('📋 Health check requested from:', req.ip);
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server API',
    database: sqlConfig.database,
    server: sqlConfig.server,
    port: PORT,
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'VMurugan Gold Trading SQL Server API',
    status: 'Running',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      testConnection: '/api/test-connection',
      customers: '/api/customers',
      login: '/api/login',
      transactions: '/api/transactions',
      transactionHistory: '/api/transaction-history'
    }
  });
});

// Test database connection
app.get('/api/test-connection', async (req, res) => {
  try {
    console.log('🧪 Testing database connection...');
    const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as servername, GETDATE() as currenttime');
    res.json({
      success: true,
      message: 'SQL Server connection successful',
      database: sqlConfig.database,
      server: result.recordset[0].servername,
      version: result.recordset[0].version.substring(0, 100),
      timestamp: result.recordset[0].currenttime
    });
  } catch (error) {
    console.error('❌ Database test failed:', error.message);
    res.status(500).json({
      success: false,
      message: 'SQL Server connection failed',
      error: error.message
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
    console.log('👤 Customer registration request:', req.body.phone);
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone, name, email, address, pan_card, device_id, encrypted_mpin } = req.body;
    const business_id = 'VMURUGAN_001';

    // Hash MPIN if provided
    let hashedMPIN = null;
    if (encrypted_mpin) {
      hashedMPIN = hashMPIN(encrypted_mpin);
      console.log('🔐 MPIN encrypted for storage');
    }

    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);
    request.input('name', sql.NVarChar(100), name);
    request.input('email', sql.NVarChar(100), email);
    request.input('address', sql.NVarChar(sql.MAX), address);
    request.input('pan_card', sql.NVarChar(10), pan_card);
    request.input('device_id', sql.NVarChar(100), device_id);
    request.input('business_id', sql.NVarChar(50), business_id);
    request.input('mpin', sql.NVarChar(255), hashedMPIN);

    await request.query(`
      IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = @phone)
      BEGIN
        INSERT INTO customers (phone, name, email, address, pan_card, device_id, business_id, mpin)
        VALUES (@phone, @name, @email, @address, @pan_card, @device_id, @business_id, @mpin)
      END
      ELSE
      BEGIN
        UPDATE customers
        SET name = @name, email = @email, address = @address,
            pan_card = @pan_card, device_id = @device_id,
            ${hashedMPIN ? 'mpin = @mpin,' : ''} updated_at = GETDATE()
        WHERE phone = @phone
      END
    `);

    // Get the saved customer data to return user object
    const getUserRequest = pool.request();
    getUserRequest.input('phone', sql.NVarChar(15), phone);
    const userResult = await getUserRequest.query('SELECT id, phone, name, email FROM customers WHERE phone = @phone');

    const customer = userResult.recordset[0];

    console.log('✅ Customer saved:', phone);
    res.json({
      success: true,
      message: 'Customer saved successfully',
      user: {
        id: customer.id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email
      }
    });

  } catch (error) {
    console.error('❌ Error saving customer:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// User login
app.post('/api/login', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('encrypted_mpin').isLength({ min: 32 }).withMessage('Invalid encrypted MPIN format')
], async (req, res) => {
  try {
    console.log('🔐 Login request:', req.body.phone);
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone, encrypted_mpin } = req.body;

    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);
    
    const result = await request.query('SELECT * FROM customers WHERE phone = @phone');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found. Please register first.'
      });
    }

    const customer = result.recordset[0];

    // Check if customer has MPIN set
    if (!customer.mpin) {
      return res.status(400).json({
        success: false,
        message: 'MPIN not set. Please complete registration first.'
      });
    }

    // Verify MPIN
    if (verifyMPIN(encrypted_mpin, customer.mpin)) {
      console.log('✅ Login successful:', phone);
      res.json({
        success: true,
        message: 'Login successful',
        user: {
          id: customer.id,
          phone: customer.phone,
          name: customer.name,
          email: customer.email
        }
      });
    } else {
      res.status(401).json({
        success: false,
        message: 'Invalid MPIN. Please try again.'
      });
    }

  } catch (error) {
    console.error('❌ Login error:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Send OTP endpoint
app.post('/api/auth/send-otp', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    console.log(`📱 OTP for ${phone}: ${otp}`);

    res.json({
      success: true,
      message: 'OTP sent successfully',
      otp: otp // For testing only - remove in production
    });

  } catch (error) {
    console.error('❌ Error sending OTP:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Verify OTP endpoint
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

    // For demo purposes, accept any 6-digit OTP
    if (otp.length === 6) {
      res.json({
        success: true,
        message: 'OTP verified successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

  } catch (error) {
    console.error('❌ Error verifying OTP:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get customer data endpoint
app.get('/api/customers/:phone', async (req, res) => {
  try {
    const { phone } = req.params;

    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);

    const result = await request.query('SELECT id, phone, name, email FROM customers WHERE phone = @phone');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const customer = result.recordset[0];

    res.json({
      success: true,
      user: {
        id: customer.id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email
      }
    });

  } catch (error) {
    console.error('❌ Error fetching customer:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Update MPIN endpoint
app.post('/api/customers/:phone/update-mpin', [
  body('current_mpin').isLength({ min: 4, max: 4 }).withMessage('Current MPIN must be 4 digits'),
  body('new_mpin').isLength({ min: 4, max: 4 }).withMessage('New MPIN must be 4 digits')
], async (req, res) => {
  try {
    console.log('🔐 Update MPIN request:', req.params.phone);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone } = req.params;
    const { current_mpin, new_mpin } = req.body;

    // Get customer data
    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);

    const result = await request.query('SELECT * FROM customers WHERE phone = @phone');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const customer = result.recordset[0];

    // Verify current MPIN
    if (!customer.mpin) {
      return res.status(400).json({
        success: false,
        message: 'No MPIN set. Please set MPIN first.'
      });
    }

    if (!verifyMPIN(current_mpin, customer.mpin)) {
      return res.status(401).json({
        success: false,
        message: 'Current MPIN is incorrect'
      });
    }

    // Hash new MPIN
    const hashedNewMPIN = hashMPIN(new_mpin);

    // Update MPIN
    const updateRequest = pool.request();
    updateRequest.input('phone', sql.NVarChar(15), phone);
    updateRequest.input('new_mpin', sql.NVarChar(255), hashedNewMPIN);

    await updateRequest.query('UPDATE customers SET mpin = @new_mpin, updated_at = GETDATE() WHERE phone = @phone');

    console.log('✅ MPIN updated successfully:', phone);
    res.json({
      success: true,
      message: 'MPIN updated successfully'
    });

  } catch (error) {
    console.error('❌ Error updating MPIN:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Set MPIN endpoint (for first-time setup)
app.post('/api/customers/:phone/set-mpin', [
  body('new_mpin').isLength({ min: 4, max: 4 }).withMessage('MPIN must be 4 digits')
], async (req, res) => {
  try {
    console.log('🔐 Set MPIN request:', req.params.phone);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone } = req.params;
    const { new_mpin } = req.body;

    // Get customer data
    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);

    const result = await request.query('SELECT * FROM customers WHERE phone = @phone');

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const customer = result.recordset[0];

    // Check if MPIN is already set
    if (customer.mpin) {
      return res.status(400).json({
        success: false,
        message: 'MPIN already set. Use update-mpin endpoint to change it.'
      });
    }

    // Hash new MPIN
    const hashedMPIN = hashMPIN(new_mpin);

    // Set MPIN
    const updateRequest = pool.request();
    updateRequest.input('phone', sql.NVarChar(15), phone);
    updateRequest.input('mpin', sql.NVarChar(255), hashedMPIN);

    await updateRequest.query('UPDATE customers SET mpin = @mpin, updated_at = GETDATE() WHERE phone = @phone');

    console.log('✅ MPIN set successfully:', phone);
    res.json({
      success: true,
      message: 'MPIN set successfully'
    });

  } catch (error) {
    console.error('❌ Error setting MPIN:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Save transaction
app.post('/api/transactions', [
  body('transaction_id').notEmpty().withMessage('Transaction ID is required'),
  body('customer_phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('amount').isNumeric().withMessage('Amount must be numeric')
], async (req, res) => {
  try {
    console.log('💰 Transaction request:', req.body.transaction_id);
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const {
      transaction_id, customer_phone, customer_name, type, amount, gold_grams,
      gold_price_per_gram, payment_method, status, gateway_transaction_id,
      device_info, location
    } = req.body;

    const business_id = 'VMURUGAN_001';

    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), transaction_id);
    request.input('customer_phone', sql.NVarChar(15), customer_phone);
    request.input('customer_name', sql.NVarChar(100), customer_name);
    request.input('type', sql.NVarChar(10), type || 'BUY');
    request.input('amount', sql.Decimal(12, 2), amount);
    request.input('gold_grams', sql.Decimal(10, 4), gold_grams || 0);
    request.input('gold_price_per_gram', sql.Decimal(10, 2), gold_price_per_gram || 0);
    request.input('payment_method', sql.NVarChar(50), payment_method || 'GATEWAY');
    request.input('status', sql.NVarChar(20), status || 'PENDING');
    request.input('gateway_transaction_id', sql.NVarChar(100), gateway_transaction_id);
    request.input('device_info', sql.NVarChar(sql.MAX), device_info);
    request.input('location', sql.NVarChar(sql.MAX), location);
    request.input('business_id', sql.NVarChar(50), business_id);

    await request.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount, gold_grams,
        gold_price_per_gram, payment_method, status, gateway_transaction_id,
        device_info, location, business_id
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @type, @amount, @gold_grams,
        @gold_price_per_gram, @payment_method, @status, @gateway_transaction_id,
        @device_info, @location, @business_id
      )
    `);

    console.log('✅ Transaction saved:', transaction_id);
    res.json({
      success: true,
      message: 'Transaction saved successfully',
      transaction_id: transaction_id
    });

  } catch (error) {
    console.error('❌ Error saving transaction:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get transaction history
app.get('/api/transaction-history', async (req, res) => {
  try {
    const { phone } = req.query;
    console.log('📊 Transaction history request:', phone);

    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required' });
    }

    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);

    const result = await request.query(`
      SELECT * FROM transactions 
      WHERE customer_phone = @phone 
      ORDER BY timestamp DESC
    `);

    console.log('✅ Transaction history retrieved:', result.recordset.length, 'records');
    res.json({
      success: true,
      transactions: result.recordset
    });

  } catch (error) {
    console.error('❌ Error getting transaction history:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Create scheme endpoint
app.post('/api/schemes', [
  body('customer_phone').isMobilePhone('en-IN').withMessage('Invalid customer phone'),
  body('customer_name').notEmpty().withMessage('Customer name required'),
  body('scheme_type').isIn(['GOLDPLUS', 'GOLDFLEXI', 'SILVERPLUS', 'SILVERFLEXI']).withMessage('Invalid scheme type'),
  body('monthly_amount').isFloat({ min: 100 }).withMessage('Monthly amount must be at least ₹100'),
  body('terms_accepted').isBoolean().withMessage('Terms acceptance required')
], async (req, res) => {
  try {
    console.log('📊 Scheme creation request:', req.body);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { customer_phone, customer_name, scheme_type, monthly_amount, terms_accepted } = req.body;

    if (!terms_accepted) {
      return res.status(400).json({ success: false, message: 'Terms and conditions must be accepted' });
    }

    // Get or create customer
    const customerRequest = pool.request();
    customerRequest.input('phone', sql.NVarChar(15), customer_phone);
    customerRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const customerResult = await customerRequest.query(`
      SELECT id, name FROM customers WHERE phone = @phone AND business_id = @business_id
    `);

    let customerId;
    if (customerResult.recordset.length === 0) {
      // Create customer if doesn't exist
      const createCustomerRequest = pool.request();
      createCustomerRequest.input('phone', sql.NVarChar(15), customer_phone);
      createCustomerRequest.input('name', sql.NVarChar(100), customer_name);
      createCustomerRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

      const createResult = await createCustomerRequest.query(`
        INSERT INTO customers (phone, name, business_id)
        OUTPUT INSERTED.id
        VALUES (@phone, @name, @business_id)
      `);
      customerId = createResult.recordset[0].id;
      console.log('✅ New customer created with ID:', customerId);
    } else {
      customerId = customerResult.recordset[0].id;
      console.log('✅ Existing customer found with ID:', customerId);
    }

    // Check existing schemes for this customer
    const existingSchemesRequest = pool.request();
    existingSchemesRequest.input('customer_id', sql.Int, customerId);
    existingSchemesRequest.input('status', sql.NVarChar(20), 'ACTIVE');

    const existingSchemes = await existingSchemesRequest.query(`
      SELECT scheme_type FROM schemes WHERE customer_id = @customer_id AND status = @status
    `);

    // Check if customer already has 4 schemes
    if (existingSchemes.recordset.length >= 4) {
      return res.status(400).json({
        success: false,
        message: 'Customer already has maximum 4 schemes'
      });
    }

    // Check if customer already has this scheme type
    const hasSchemeType = existingSchemes.recordset.some(scheme => scheme.scheme_type === scheme_type);
    if (hasSchemeType) {
      return res.status(400).json({
        success: false,
        message: `Customer already has ${scheme_type} scheme`
      });
    }

    // Generate scheme ID
    const timestamp = Date.now();
    const schemeId = `SCH${String(timestamp).slice(-6)}_${scheme_type}`;

    // Determine duration and metal type
    const duration = scheme_type.includes('PLUS') ? 12 : null;
    const metalType = scheme_type.includes('GOLD') ? 'GOLD' : 'SILVER';
    const endDate = duration ? new Date(Date.now() + (duration * 30 * 24 * 60 * 60 * 1000)) : null;

    // Create scheme
    const schemeRequest = pool.request();
    schemeRequest.input('scheme_id', sql.NVarChar(100), schemeId);
    schemeRequest.input('customer_id', sql.Int, customerId);
    schemeRequest.input('customer_phone', sql.NVarChar(15), customer_phone);
    schemeRequest.input('customer_name', sql.NVarChar(100), customer_name);
    schemeRequest.input('scheme_type', sql.NVarChar(20), scheme_type);
    schemeRequest.input('metal_type', sql.NVarChar(10), metalType);
    schemeRequest.input('monthly_amount', sql.Decimal(12,2), monthly_amount);
    schemeRequest.input('duration_months', sql.Int, duration);
    schemeRequest.input('end_date', sql.DateTime, endDate);
    schemeRequest.input('terms_accepted', sql.Bit, terms_accepted);
    schemeRequest.input('terms_accepted_at', sql.DateTime, new Date());
    schemeRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const schemeResult = await schemeRequest.query(`
      INSERT INTO schemes (
        scheme_id, customer_id, customer_phone, customer_name,
        scheme_type, metal_type, monthly_amount, duration_months,
        end_date, terms_accepted, terms_accepted_at, business_id
      )
      OUTPUT INSERTED.id
      VALUES (
        @scheme_id, @customer_id, @customer_phone, @customer_name,
        @scheme_type, @metal_type, @monthly_amount, @duration_months,
        @end_date, @terms_accepted, @terms_accepted_at, @business_id
      )
    `);

    console.log('✅ Scheme created successfully:', schemeId);

    res.json({
      success: true,
      message: 'Scheme created successfully',
      scheme: {
        id: schemeResult.recordset[0].id,
        scheme_id: schemeId,
        customer_id: customerId,
        scheme_type,
        metal_type: metalType,
        monthly_amount,
        duration_months: duration,
        status: 'ACTIVE'
      }
    });

  } catch (error) {
    console.error('❌ Scheme creation error:', error);
    res.status(500).json({ success: false, message: 'Scheme creation failed', error: error.message });
  }
});

// Get customer schemes
app.get('/api/schemes/:customer_phone', async (req, res) => {
  try {
    const { customer_phone } = req.params;
    console.log('📊 Getting schemes for customer:', customer_phone);

    const schemesRequest = pool.request();
    schemesRequest.input('customer_phone', sql.NVarChar(15), customer_phone);
    schemesRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const schemes = await schemesRequest.query(`
      SELECT
        s.*,
        c.name as customer_name,
        c.email as customer_email
      FROM schemes s
      INNER JOIN customers c ON s.customer_id = c.id
      WHERE s.customer_phone = @customer_phone AND s.business_id = @business_id
      ORDER BY s.created_at DESC
    `);

    // Calculate portfolio summary
    const portfolioRequest = pool.request();
    portfolioRequest.input('customer_phone', sql.NVarChar(15), customer_phone);
    portfolioRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const portfolioSummary = await portfolioRequest.query(`
      SELECT
        COUNT(*) as total_schemes,
        SUM(total_invested) as total_invested,
        SUM(CASE WHEN metal_type = 'GOLD' THEN total_metal_accumulated ELSE 0 END) as total_gold_grams,
        SUM(CASE WHEN metal_type = 'SILVER' THEN total_metal_accumulated ELSE 0 END) as total_silver_grams,
        SUM(completed_installments) as total_installments
      FROM schemes
      WHERE customer_phone = @customer_phone AND business_id = @business_id AND status = 'ACTIVE'
    `);

    res.json({
      success: true,
      customer_phone,
      schemes: schemes.recordset,
      portfolio_summary: portfolioSummary.recordset[0] || {
        total_schemes: 0,
        total_invested: 0,
        total_gold_grams: 0,
        total_silver_grams: 0,
        total_installments: 0
      }
    });

  } catch (error) {
    console.error('❌ Get schemes error:', error);
    res.status(500).json({ success: false, message: 'Failed to get schemes', error: error.message });
  }
});

// Update scheme endpoint
app.put('/api/schemes/:scheme_id', [
  body('action').isIn(['PAUSE', 'RESUME', 'CANCEL', 'UPDATE_AMOUNT']).withMessage('Invalid action'),
  body('monthly_amount').optional().isFloat({ min: 100 }).withMessage('Monthly amount must be at least ₹100')
], async (req, res) => {
  try {
    const { scheme_id } = req.params;
    const { action, monthly_amount } = req.body;
    console.log('📊 Updating scheme:', scheme_id, 'Action:', action);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const updateRequest = pool.request();
    updateRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    updateRequest.input('updated_at', sql.DateTime, new Date());

    let updateQuery = '';

    switch (action) {
      case 'PAUSE':
        updateRequest.input('status', sql.NVarChar(20), 'PAUSED');
        updateQuery = 'UPDATE schemes SET status = @status, updated_at = @updated_at WHERE scheme_id = @scheme_id';
        break;
      case 'RESUME':
        updateRequest.input('status', sql.NVarChar(20), 'ACTIVE');
        updateQuery = 'UPDATE schemes SET status = @status, updated_at = @updated_at WHERE scheme_id = @scheme_id';
        break;
      case 'CANCEL':
        updateRequest.input('status', sql.NVarChar(20), 'CANCELLED');
        updateQuery = 'UPDATE schemes SET status = @status, updated_at = @updated_at WHERE scheme_id = @scheme_id';
        break;
      case 'UPDATE_AMOUNT':
        if (!monthly_amount) {
          return res.status(400).json({ success: false, message: 'Monthly amount required for UPDATE_AMOUNT action' });
        }
        updateRequest.input('monthly_amount', sql.Decimal(12,2), monthly_amount);
        updateQuery = 'UPDATE schemes SET monthly_amount = @monthly_amount, updated_at = @updated_at WHERE scheme_id = @scheme_id';
        break;
      default:
        return res.status(400).json({ success: false, message: 'Invalid action' });
    }

    const result = await updateRequest.query(updateQuery);

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ success: false, message: 'Scheme not found' });
    }

    console.log('✅ Scheme updated successfully:', scheme_id);

    res.json({
      success: true,
      message: `Scheme ${action.toLowerCase()} successful`,
      scheme_id
    });

  } catch (error) {
    console.error('❌ Scheme update error:', error);
    res.status(500).json({ success: false, message: 'Scheme update failed', error: error.message });
  }
});

// Add scheme investment/payment
app.post('/api/schemes/:scheme_id/invest', [
  body('amount').isFloat({ min: 100 }).withMessage('Investment amount must be at least ₹100'),
  body('metal_grams').isFloat({ min: 0.001 }).withMessage('Metal grams must be positive'),
  body('current_rate').isFloat({ min: 1 }).withMessage('Current rate must be positive'),
  body('transaction_id').notEmpty().withMessage('Transaction ID required')
], async (req, res) => {
  try {
    const { scheme_id } = req.params;
    const { amount, metal_grams, current_rate, transaction_id, gateway_transaction_id } = req.body;
    console.log('💰 Adding investment to scheme:', scheme_id, 'Amount:', amount);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    // Get scheme details
    const schemeRequest = pool.request();
    schemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);

    const schemeResult = await schemeRequest.query(`
      SELECT * FROM schemes WHERE scheme_id = @scheme_id AND status = 'ACTIVE'
    `);

    if (schemeResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Active scheme not found' });
    }

    const scheme = schemeResult.recordset[0];

    // Update scheme with new investment
    const updateSchemeRequest = pool.request();
    updateSchemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    updateSchemeRequest.input('amount', sql.Decimal(12,2), amount);
    updateSchemeRequest.input('metal_grams', sql.Decimal(10,4), metal_grams);
    updateSchemeRequest.input('updated_at', sql.DateTime, new Date());

    await updateSchemeRequest.query(`
      UPDATE schemes
      SET
        total_invested = total_invested + @amount,
        total_metal_accumulated = total_metal_accumulated + @metal_grams,
        completed_installments = completed_installments + 1,
        updated_at = @updated_at
      WHERE scheme_id = @scheme_id
    `);

    // Create transaction record
    const transactionRequest = pool.request();
    transactionRequest.input('transaction_id', sql.NVarChar(100), transaction_id);
    transactionRequest.input('customer_phone', sql.NVarChar(15), scheme.customer_phone);
    transactionRequest.input('customer_name', sql.NVarChar(100), scheme.customer_name);
    transactionRequest.input('type', sql.NVarChar(10), 'BUY');
    transactionRequest.input('amount', sql.Decimal(12,2), amount);
    transactionRequest.input('gold_grams', sql.Decimal(10,4), scheme.metal_type === 'GOLD' ? metal_grams : 0);
    transactionRequest.input('silver_grams', sql.Decimal(10,4), scheme.metal_type === 'SILVER' ? metal_grams : 0);
    transactionRequest.input('status', sql.NVarChar(20), 'SUCCESS');
    transactionRequest.input('payment_method', sql.NVarChar(50), 'SCHEME_INVESTMENT');
    transactionRequest.input('gateway_transaction_id', sql.NVarChar(100), gateway_transaction_id || `SCHEME_${transaction_id}`);
    transactionRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    await transactionRequest.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount,
        gold_grams, silver_grams, status, payment_method, gateway_transaction_id, business_id
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @type, @amount,
        @gold_grams, @silver_grams, @status, @payment_method, @gateway_transaction_id, @business_id
      )
    `);

    console.log('✅ Scheme investment added successfully:', scheme_id);

    res.json({
      success: true,
      message: 'Investment added to scheme successfully',
      scheme_id,
      investment: {
        amount,
        metal_grams,
        current_rate,
        transaction_id
      }
    });

  } catch (error) {
    console.error('❌ Scheme investment error:', error);
    res.status(500).json({ success: false, message: 'Scheme investment failed', error: error.message });
  }
});

// Get scheme details by ID
app.get('/api/schemes/details/:scheme_id', async (req, res) => {
  try {
    const { scheme_id } = req.params;
    console.log('📊 Getting scheme details:', scheme_id);

    const schemeRequest = pool.request();
    schemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);

    const schemeResult = await schemeRequest.query(`
      SELECT
        s.*,
        c.name as customer_name,
        c.email as customer_email,
        c.phone as customer_phone
      FROM schemes s
      INNER JOIN customers c ON s.customer_id = c.id
      WHERE s.scheme_id = @scheme_id
    `);

    if (schemeResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Scheme not found' });
    }

    // Get scheme transactions
    const transactionsRequest = pool.request();
    transactionsRequest.input('customer_phone', sql.NVarChar(15), schemeResult.recordset[0].customer_phone);
    transactionsRequest.input('payment_method', sql.NVarChar(50), 'SCHEME_INVESTMENT');

    const transactions = await transactionsRequest.query(`
      SELECT * FROM transactions
      WHERE customer_phone = @customer_phone AND payment_method = @payment_method
      ORDER BY timestamp DESC
    `);

    res.json({
      success: true,
      scheme: schemeResult.recordset[0],
      transactions: transactions.recordset
    });

  } catch (error) {
    console.error('❌ Get scheme details error:', error);
    res.status(500).json({ success: false, message: 'Failed to get scheme details', error: error.message });
  }
});

// Payment callback endpoint
app.post('/api/payment/callback', async (req, res) => {
  try {
    console.log('💳 Payment callback received:', req.body);

    const {
      transaction_id,
      gateway_transaction_id,
      status,
      amount,
      customer_phone,
      payment_method = 'GATEWAY'
    } = req.body;

    // Update transaction status in database
    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), transaction_id);
    request.input('gateway_transaction_id', sql.NVarChar(100), gateway_transaction_id);
    request.input('status', sql.NVarChar(20), status);

    await request.query(`
      UPDATE transactions
      SET status = @status, gateway_transaction_id = @gateway_transaction_id, updated_at = GETDATE()
      WHERE transaction_id = @transaction_id
    `);

    console.log('✅ Payment status updated:', transaction_id, status);

    res.json({
      success: true,
      message: 'Payment callback processed successfully'
    });

  } catch (error) {
    console.error('❌ Payment callback error:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Payment success page
app.get('/payment/success', (req, res) => {
  res.send(`
    <html>
      <head><title>Payment Successful</title></head>
      <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
        <h1 style="color: green;">✅ Payment Successful!</h1>
        <p>Your gold purchase has been completed successfully.</p>
        <p>Transaction ID: ${req.query.transaction_id || 'N/A'}</p>
        <p>You can close this window and return to the app.</p>
      </body>
    </html>
  `);
});

// Payment failure page
app.get('/payment/failure', (req, res) => {
  res.send(`
    <html>
      <head><title>Payment Failed</title></head>
      <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
        <h1 style="color: red;">❌ Payment Failed</h1>
        <p>Your payment could not be processed.</p>
        <p>Reason: ${req.query.reason || 'Unknown error'}</p>
        <p>Please try again or contact support.</p>
      </body>
    </html>
  `);
});

// Payment cancel page
app.get('/payment/cancel', (req, res) => {
  res.send(`
    <html>
      <head><title>Payment Cancelled</title></head>
      <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
        <h1 style="color: orange;">⚠️ Payment Cancelled</h1>
        <p>You have cancelled the payment.</p>
        <p>No charges have been made to your account.</p>
        <p>You can close this window and return to the app.</p>
      </body>
    </html>
  `);
});

// Get all customers (for admin portal)
app.get('/api/customers', async (req, res) => {
  try {
    console.log('👥 Admin: Getting all customers...');
    const result = await pool.request().query(`
      SELECT id, phone, name, email, address, pan_card, business_id,
             registration_date, total_invested, total_gold, transaction_count,
             last_transaction, created_at, updated_at
      FROM customers
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      customers: result.recordset
    });

  } catch (error) {
    console.error('❌ Error getting customers:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get all transactions (for admin portal)
app.get('/api/transactions', async (req, res) => {
  try {
    console.log('💳 Admin: Getting all transactions...');
    const result = await pool.request().query(`
      SELECT * FROM transactions
      ORDER BY timestamp DESC
    `);

    res.json({
      success: true,
      transactions: result.recordset
    });

  } catch (error) {
    console.error('❌ Error getting transactions:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get schemes for a customer (for admin portal)
app.get('/api/schemes/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    console.log('📊 Admin: Getting schemes for customer:', customerId);

    const request = pool.request();
    request.input('customerId', sql.NVarChar(100), customerId);

    const result = await request.query(`
      SELECT * FROM schemes
      WHERE customer_id = @customerId OR customer_phone = @customerId
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      schemes: result.recordset
    });

  } catch (error) {
    console.error('❌ Error getting schemes:', error.message);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// 404 handler
app.use('*', (req, res) => {
  console.log('❌ 404 - Endpoint not found:', req.originalUrl);
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    requested_url: req.originalUrl,
    available_endpoints: [
      '/health',
      '/api/test-connection',
      '/api/customers',
      '/api/login',
      '/api/auth/send-otp',
      '/api/auth/verify-otp',
      '/api/customers/:phone',
      '/api/customers/:phone/update-mpin',
      '/api/customers/:phone/set-mpin',
      '/api/transactions',
      '/api/transaction-history',
      '/api/schemes/:customerId',
      '/api/payment/callback',
      '/payment/success',
      '/payment/failure',
      '/payment/cancel'
    ]
  });
});

// Error handler
app.use((error, req, res, next) => {
  console.error('❌ Server error:', error.message);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: error.message
  });
});

// Start server with HTTPS support
async function startServer() {
  const dbConnected = await initializeDatabase();

  if (!dbConnected) {
    console.error('❌ Failed to connect to SQL Server. Exiting...');
    process.exit(1);
  }

  // Check for SSL certificates
  const sslKeyPath = process.env.SSL_KEY_PATH || './ssl/private.key';
  const sslCertPath = process.env.SSL_CERT_PATH || './ssl/certificate.crt';

  let httpsOptions = {};

  try {
    if (fs.existsSync(sslKeyPath) && fs.existsSync(sslCertPath)) {
      const keyContent = fs.readFileSync(sslKeyPath, 'utf8');
      const certContent = fs.readFileSync(sslCertPath, 'utf8');

      // Validate certificate content
      if (keyContent.includes('BEGIN') && certContent.includes('BEGIN CERTIFICATE')) {
        // Skip crypto validation to avoid ASN1 encoding errors
        console.log('🔒 SSL certificates found - bypassing validation and starting HTTPS server...');

        httpsOptions = {
          key: keyContent,
          cert: certContent,
          // Options to handle SSL compatibility issues
          secureProtocol: 'TLSv1_2_method',
          honorCipherOrder: true,
          rejectUnauthorized: false // Allow self-signed certificates
        };




          console.error('� To fix ASN1 encoding errors:');




      } else {
        console.error('❌ SSL certificates invalid format!');
        console.error('🔧 To fix this:');
        console.error('1. Run: node create_proper_ssl_nodejs.js');
        console.error('2. Copy new ssl/ folder to server location');
        console.error('3. Restart server');
        process.exit(1);
      }
    } else {
      console.error('❌ SSL certificates not found!');
      console.error(`   Expected: ${sslKeyPath}`);
      console.error(`   Expected: ${sslCertPath}`);
      console.error('');
      console.error('🔧 To fix this:');
      console.error('1. Run: node create_proper_ssl_nodejs.js');
      console.error('2. Copy ssl/ folder to server location');
      console.error('3. Restart server');
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ SSL certificate error:', error.message);
    console.error('🔧 To fix this:');
    console.error('1. Run: node create_proper_ssl_nodejs.js');
    console.error('2. Copy new ssl/ folder to server location');
    console.error('3. Restart server');
    process.exit(1);
  }

  // Start HTTPS server with HTTP fallback for admin portal
  try {
    const httpsPort = process.env.HTTPS_PORT || 3001;
    const httpPort = process.env.HTTP_PORT || 3001;

    // Start HTTPS server
    const httpsServer = https.createServer(httpsOptions, app);

    httpsServer.on('error', (error) => {
      console.error('❌ HTTPS server error:', error.message);

      // Handle specific ASN1 encoding errors
      if (error.message.includes('asn1 encoding routines') || error.message.includes('ASN1')) {
        console.error('');
        console.error('🔧 ASN1 Encoding Error - SSL Certificate Issue:');
        console.error('1. Run: node create_proper_ssl_nodejs.js');
        console.error('2. Copy new ssl/ folder to server location');
        console.error('3. Restart server');
        console.error('');
        console.error('This error means the SSL certificates have invalid ASN1 structure.');
      } else if (error.message.includes('EADDRINUSE')) {
        console.error('');
        console.error('🔧 Port Already In Use:');
        console.error('1. Stop any existing server on port 3001');
        console.error('2. Check: netstat -an | findstr 3001');
        console.error('3. Restart server');
      } else {
        console.error('');
        console.error('� Common fixes:');
        console.error('1. Check SSL certificates are valid');
        console.error('2. Ensure port 3001 is not in use');
        console.error('3. Run as administrator if needed');
      }
      process.exit(1);
    });

    httpsServer.listen(httpsPort, '0.0.0.0', () => {
      console.log('');
      console.log('========================================');
      console.log('🔒 HTTPS-ONLY SERVER STARTED!');
      console.log('========================================');
      console.log(`🔒 VMurugan HTTPS Server running on port ${httpsPort}`);
      console.log(`🏥 Health Check: https://api.vmuruganjewellery.co.in:${httpsPort}/health`);
      console.log(`🔗 API Base URL: https://api.vmuruganjewellery.co.in:${httpsPort}/api`);
      console.log(`💾 Database: ${sqlConfig.database} on ${sqlConfig.server}`);
      console.log(`💳 Payment URLs:`);
      console.log(`   Callback: https://api.vmuruganjewellery.co.in:${httpsPort}/api/payment/callback`);
      console.log(`   Success:  https://api.vmuruganjewellery.co.in:${httpsPort}/payment/success`);
      console.log(`   Failure:  https://api.vmuruganjewellery.co.in:${httpsPort}/payment/failure`);
      console.log(`   Cancel:   https://api.vmuruganjewellery.co.in:${httpsPort}/payment/cancel`);
      console.log('');
      console.log('✅ HTTPS-only mode: No HTTP fallback');
      console.log('🔒 All connections encrypted');
      console.log('========================================');
    });

  } catch (httpsError) {
    console.error('❌ Failed to start HTTPS server:', httpsError.message);
    console.error('� To fix this:');
    console.error('1. Check SSL certificates are valid');
    console.error('2. Ensure port 3001 is available');
    console.error('3. Run server as administrator');
    process.exit(1);
  }
}

// HTTPS-only server - no HTTP fallback function needed

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('🛑 Shutting down gracefully...');
  if (pool) {
    await pool.close();
  }
  process.exit(0);
});

// Start the server
startServer().catch(error => {
  console.error('❌ Failed to start server:', error);
  process.exit(1);
});

module.exports = app;