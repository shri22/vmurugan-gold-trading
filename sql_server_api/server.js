// VMurugan Gold Trading - SQL Server API
// Node.js server with SQL Server (mssql) integration

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

console.log('🚀 VMurugan SQL Server API Starting...');
console.log('📊 Port:', PORT);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['*'],
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
  server: process.env.SQL_SERVER || 'localhost',
  port: parseInt(process.env.SQL_PORT) || 1433,
  database: process.env.SQL_DATABASE || 'VMuruganGoldTrading',
  user: process.env.SQL_USERNAME || 'sa',
  password: process.env.SQL_PASSWORD || '',
  options: {
    encrypt: process.env.SQL_ENCRYPT === 'true',
    trustServerCertificate: process.env.SQL_TRUST_SERVER_CERTIFICATE === 'true' || true,
    enableArithAbort: true,
  },
  connectionTimeout: parseInt(process.env.SQL_CONNECTION_TIMEOUT) || 30000,
  requestTimeout: parseInt(process.env.SQL_REQUEST_TIMEOUT) || 30000,
};

console.log('🔗 SQL Server Config:', {
  server: sqlConfig.server,
  port: sqlConfig.port,
  database: sqlConfig.database,
  user: sqlConfig.user
});

// Global connection pool
let pool;

// Initialize SQL Server connection
async function initializeDatabase() {
  try {
    console.log('📡 Connecting to SQL Server...');
    pool = await sql.connect(sqlConfig);
    console.log('✅ SQL Server connected successfully');
    
    // Create tables if they don't exist
    await createTablesIfNotExist();
    
    return true;
  } catch (error) {
    console.error('❌ SQL Server connection failed:', error.message);
    return false;
  }
}

// Create database tables
async function createTablesIfNotExist() {
  try {
    console.log('📋 Creating tables if not exist...');
    
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
          gold_grams DECIMAL(10,4) NOT NULL,
          gold_price_per_gram DECIMAL(10,2) NOT NULL,
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

    console.log('✅ Tables created successfully');
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
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

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server API',
    database: sqlConfig.database,
    server: sqlConfig.server
  });
});

// Test database connection
app.get('/api/test-connection', async (req, res) => {
  try {
    const result = await pool.request().query('SELECT 1 as test');
    res.json({
      success: true,
      message: 'SQL Server connection successful',
      database: sqlConfig.database,
      server: sqlConfig.server,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
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
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone, name, email, address, pan_card, device_id } = req.body;
    const business_id = 'VMURUGAN_001';

    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);
    request.input('name', sql.NVarChar(100), name);
    request.input('email', sql.NVarChar(100), email);
    request.input('address', sql.NVarChar(sql.MAX), address);
    request.input('pan_card', sql.NVarChar(10), pan_card);
    request.input('device_id', sql.NVarChar(100), device_id);
    request.input('business_id', sql.NVarChar(50), business_id);

    await request.query(`
      IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = @phone)
      BEGIN
        INSERT INTO customers (phone, name, email, address, pan_card, device_id, business_id)
        VALUES (@phone, @name, @email, @address, @pan_card, @device_id, @business_id)
      END
      ELSE
      BEGIN
        UPDATE customers 
        SET name = @name, email = @email, address = @address, 
            pan_card = @pan_card, device_id = @device_id, updated_at = GETDATE()
        WHERE phone = @phone
      END
    `);

    res.json({
      success: true,
      message: 'Customer saved successfully',
      customer_id: phone
    });

  } catch (error) {
    console.error('Error saving customer:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// User login
app.post('/api/login', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('encrypted_mpin').isLength({ min: 32 }).withMessage('Invalid encrypted MPIN format')
], async (req, res) => {
  try {
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

    // For demo purposes, accept any 4-digit MPIN
    // In production, implement proper MPIN verification
    if (encrypted_mpin.length === 4) {
      res.json({
        success: true,
        message: 'Login successful',
        customer: {
          id: customer.id,
          phone: customer.phone,
          name: customer.name,
          email: customer.email
        }
      });
    } else {
      res.status(401).json({
        success: false,
        message: 'Invalid MPIN'
      });
    }

  } catch (error) {
    console.error('Login error:', error);
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

    res.json({
      success: true,
      message: 'Transaction saved successfully',
      transaction_id: transaction_id
    });

  } catch (error) {
    console.error('Error saving transaction:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get transaction history
app.get('/api/transaction-history', async (req, res) => {
  try {
    const { phone } = req.query;

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

    res.json({
      success: true,
      transactions: result.recordset
    });

  } catch (error) {
    console.error('Error getting transaction history:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get all customers (for admin portal)
app.get('/api/customers', async (req, res) => {
  try {
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
    console.error('Error getting customers:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get all transactions (for admin portal)
app.get('/api/transactions', async (req, res) => {
  try {
    const result = await pool.request().query(`
      SELECT * FROM transactions
      ORDER BY timestamp DESC
    `);

    res.json({
      success: true,
      transactions: result.recordset
    });

  } catch (error) {
    console.error('Error getting transactions:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get schemes for a customer (for admin portal)
app.get('/api/schemes/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;

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
    console.error('Error getting schemes:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Start server
async function startServer() {
  const dbConnected = await initializeDatabase();
  
  if (!dbConnected) {
    console.error('❌ Failed to connect to SQL Server. Exiting...');
    process.exit(1);
  }

  app.listen(PORT, () => {
    console.log(`🚀 VMurugan SQL Server API running on port ${PORT}`);
    console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
    console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
    console.log(`💾 Database: ${sqlConfig.database} on ${sqlConfig.server}`);
  });
}

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
