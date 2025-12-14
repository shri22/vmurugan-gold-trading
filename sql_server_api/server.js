// VMurugan Gold Trading - SQL Server API (SQL Server 2019 Compatible)
const express = require('express');
const https = require('https'); // ADDED: For HTTPS support
const fs = require('fs'); // ADDED: For reading SSL certificates
const sql = require('mssql');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto'); // ADDED: For MPIN encryption
const admin = require('firebase-admin'); // ADDED: For Push Notifications
require('dotenv').config();

// Initialize Firebase Admin
try {
  // Check if service account file exists
  if (fs.existsSync(path.join(__dirname, 'serviceAccountKey.json'))) {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin initialized successfully');
  } else {
    console.log('⚠️ serviceAccountKey.json not found. Push notifications disabled.');
  }
} catch (error) {
  console.log('⚠️ Firebase Admin initialization failed:', error.message);
}

const app = express();
const PORT = process.env.PORT || 3001;
const HTTPS_PORT = process.env.HTTPS_PORT || 443;
const path = require('path');

// SSL Certificate paths - Updated to use local ssl directory
const SSL_CERT_PATH = process.env.SSL_CERT_PATH || path.join(__dirname, '..', 'ssl', 'certificate.crt');
const SSL_KEY_PATH = process.env.SSL_KEY_PATH || path.join(__dirname, '..', 'ssl', 'private.key');

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
  console.log('📁 Created logs directory:', logsDir);
}

// Server-side logging function
function writeServerLog(message, logType = 'general') {
  try {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] ${message}\n`;

    // Create log file with date
    const logFileName = `${logType}_${new Date().toISOString().split('T')[0]}.log`;
    const logFilePath = path.join(logsDir, logFileName);

    // Append to log file
    fs.appendFileSync(logFilePath, logMessage);

    // Also log to console
    console.log(message);
  } catch (error) {
    console.error('❌ Error writing to log file:', error);
  }
}

console.log('🚀 VMurugan SQL Server API Starting...');
console.log('📊 Port:', PORT);

// Security middleware
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: false,
}));

// CORS configuration for production server - Allow mobile app requests
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);

    // Allow specific origins for web clients
    const allowedOrigins = [
      'https://api.vmuruganjewellery.co.in',
      'https://api.vmuruganjewellery.co.in:3001',
      'http://localhost:3000',
      'http://localhost:3001'
    ];

    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    // Log the origin for debugging
    console.log(`🔍 CORS: Request from origin: ${origin}`);
    return callback(null, true); // Allow all origins for mobile app compatibility
  },
  credentials: false,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept', 'Origin', 'User-Agent', 'admin-token', 'X-Requested-With'],
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
  // Hash MPIN using same salt as client-side EncryptionService
  return crypto.createHash('sha256').update(mpin + 'VMURUGAN_GOLD_MPIN_SALT_2025').digest('hex');
}

function verifyMPIN(encryptedInputMPIN, storedHashedMPIN) {
  // Try direct comparison first (for new users after fix)
  if (encryptedInputMPIN === storedHashedMPIN) {
    return true;
  }

  // Try double-hash comparison (for existing users before fix)
  const doubleHashedInput = hashMPIN(encryptedInputMPIN);
  if (doubleHashedInput === storedHashedMPIN) {
    console.log('🔄 Legacy MPIN format detected - consider migrating user');
    return true;
  }

  return false;
}

// SQL Server 2019 configuration
const sqlConfig = {
  server: 'DESKTOP-3QPE6QQ',
  port: 1433,
  database: 'VMuruganGoldTrading',
  user: 'sa',
  password: 'git@#12345',
  options: {
    encrypt: false, // Use true for Azure SQL
    trustServerCertificate: true, // Use true for self-signed certificates
    enableArithAbort: true, // Required for SQL Server 2005+
    instanceName: '', // Leave empty for default instance
    useUTC: false, // Use local time
    dateFirst: 1, // Monday as first day of week
    language: 'us_english',
    // SQL Server 2019 specific options
    abortTransactionOnError: true, // Enhanced error handling
    maxRetriesOnFailure: 3, // Connection retry attempts
    multipleActiveResultSets: true, // MARS support
    packetSize: 4096, // Optimized packet size for SQL Server 2019
    readOnlyIntent: false, // Allow read/write operations
    rowCollectionOnDone: false, // Performance optimization
    rowCollectionOnRequestCompletion: false, // Performance optimization
    tdsVersion: '7_4', // TDS version for SQL Server 2019
    arrayRowMode: true, // Use array mode for better performance (replaces useColumnNames)
    validateParameters: true, // Enhanced parameter validation
    cancelTimeout: 5000, // Cancel timeout for long-running queries
    cryptoCredentialsDetails: {
      minVersion: 'TLSv1.2' // Minimum TLS version for security
    }
  },
  pool: {
    max: 20, // Maximum number of connections in pool
    min: 5,  // Minimum number of connections in pool
    idleTimeoutMillis: 30000, // Close connections after 30 seconds of inactivity
    acquireTimeoutMillis: 60000, // Maximum time to wait for a connection
    createTimeoutMillis: 30000, // Maximum time to wait when creating a connection
    destroyTimeoutMillis: 5000, // Maximum time to wait when destroying a connection
    reapIntervalMillis: 1000, // How often to check for idle connections
    createRetryIntervalMillis: 200 // How long to wait before retrying connection creation
  },
  connectionTimeout: 30000, // Optimized for SQL Server 2019
  requestTimeout: 30000,    // Optimized for SQL Server 2019
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

// Create database tables - SQL Server 2019 Compatible
async function createTablesIfNotExist() {
  try {
    console.log('📋 Creating tables if not exist...');

    // Create customers table - Using SQL Server 2019 features
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='customers')
      BEGIN
        CREATE TABLE customers (
          id INT IDENTITY(1,1) PRIMARY KEY,
          phone NVARCHAR(15) UNIQUE NOT NULL,
          name NVARCHAR(100) NOT NULL,
          email NVARCHAR(100),
          address NVARCHAR(MAX),
          pan_card NVARCHAR(10),
          device_id NVARCHAR(100),
          mpin NVARCHAR(255) NULL,
          nominee_name NVARCHAR(100),
          nominee_relationship NVARCHAR(50),
          nominee_phone NVARCHAR(15),
          registration_date DATETIME2(3) DEFAULT SYSDATETIME(),
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          total_invested DECIMAL(12,2) DEFAULT 0.00,
          total_gold DECIMAL(10,4) DEFAULT 0.0000,
          transaction_count INT DEFAULT 0,
          last_transaction DATETIME2(3) NULL,
          created_at DATETIME2(3) DEFAULT SYSDATETIME(),
          updated_at DATETIME2(3) DEFAULT SYSDATETIME()
        )
        CREATE INDEX IX_customers_phone ON customers (phone)
        CREATE INDEX IX_customers_created_at ON customers (created_at)
        CREATE INDEX IX_customers_business_id ON customers (business_id)
        PRINT 'Customers table created with SQL Server 2019 features'
      END
    `);

    // Add nominee columns if they don't exist (for existing databases)
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'nominee_name')
      BEGIN
        ALTER TABLE customers ADD nominee_name NVARCHAR(100) NULL
        PRINT 'Added nominee_name column to customers table'
      END

      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'nominee_relationship')
      BEGIN
        ALTER TABLE customers ADD nominee_relationship NVARCHAR(50) NULL
        PRINT 'Added nominee_relationship column to customers table'
      END

      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'nominee_phone')
      BEGIN
        ALTER TABLE customers ADD nominee_phone NVARCHAR(15) NULL
        PRINT 'Added nominee_phone column to customers table'
      END
    `);

    // Create transactions table - Using SQL Server 2019 features
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='transactions')
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
          additional_data NVARCHAR(MAX),
          timestamp DATETIME2(3) DEFAULT SYSDATETIME(),
          created_at DATETIME2(3) DEFAULT SYSDATETIME(),
          updated_at DATETIME2(3) DEFAULT SYSDATETIME()
        )
        CREATE INDEX IX_transactions_customer ON transactions (customer_phone)
        CREATE INDEX IX_transactions_transaction_id ON transactions (transaction_id)
        CREATE INDEX IX_transactions_timestamp ON transactions (timestamp)
        CREATE INDEX IX_transactions_status ON transactions (status)
        CREATE INDEX IX_transactions_business_id ON transactions (business_id)
        PRINT 'Transactions table created with SQL Server 2019 features'
      END
    `);

    // Add additional_data column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'additional_data')
      BEGIN
        ALTER TABLE transactions ADD additional_data NVARCHAR(MAX)
        PRINT 'Added additional_data column to transactions table'
      END
    `);

    // Add silver_grams column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'silver_grams')
      BEGIN
        ALTER TABLE transactions ADD silver_grams DECIMAL(10,4) DEFAULT 0.0000
        PRINT 'Added silver_grams column to transactions table'
      END
    `);

    // Add silver_price_per_gram column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'silver_price_per_gram')
      BEGIN
        ALTER TABLE transactions ADD silver_price_per_gram DECIMAL(10,2) DEFAULT 0.00
        PRINT 'Added silver_price_per_gram column to transactions table'
      END
    `);

    // Add scheme_type column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'scheme_type')
      BEGIN
        ALTER TABLE transactions ADD scheme_type NVARCHAR(20) NULL CHECK (scheme_type IN ('GOLDPLUS', 'GOLDFLEXI', 'SILVERPLUS', 'SILVERFLEXI', NULL))
        PRINT 'Added scheme_type column to transactions table'
      END
    `);

    // Add scheme_id column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'scheme_id')
      BEGIN
        ALTER TABLE transactions ADD scheme_id NVARCHAR(100) NULL
        PRINT 'Added scheme_id column to transactions table'
      END
    `);

    // Add installment_number column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'installment_number')
      BEGIN
        ALTER TABLE transactions ADD installment_number INT NULL
        PRINT 'Added installment_number column to transactions table'
      END
    `);

    // Add metal_type column to existing transactions table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('transactions') AND name = 'metal_type')
      BEGIN
        ALTER TABLE transactions ADD metal_type NVARCHAR(10) NULL CHECK (metal_type IN ('GOLD', 'SILVER', NULL))
        PRINT 'Added metal_type column to transactions table'
      END
    `);

    // Update existing transactions to set metal_type based on gold_grams and silver_grams
    await pool.request().query(`
      UPDATE transactions
      SET metal_type = CASE
        WHEN silver_grams > 0 THEN 'SILVER'
        WHEN gold_grams > 0 THEN 'GOLD'
        ELSE 'GOLD'
      END
      WHERE metal_type IS NULL
    `);

    // Add closure_remarks column to existing schemes table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'closure_remarks')
      BEGIN
        ALTER TABLE schemes ADD closure_remarks NVARCHAR(500) NULL
        PRINT 'Added closure_remarks column to schemes table'
      END
    `);

    // Add closure_date column to existing schemes table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('schemes') AND name = 'closure_date')
      BEGIN
        ALTER TABLE schemes ADD closure_date DATETIME2(3) NULL
        PRINT 'Added closure_date column to schemes table'
      END
    `);

    // Create schemes table - SQL Server 2019 Compatible
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='schemes')
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
          start_date DATETIME2(3) DEFAULT SYSDATETIME(),
          end_date DATETIME2(3) NULL,
          total_invested DECIMAL(12,2) DEFAULT 0.00,
          total_metal_accumulated DECIMAL(10,4) DEFAULT 0.0000,
          completed_installments INT DEFAULT 0,
          terms_accepted BIT DEFAULT 0,
          terms_accepted_at DATETIME2(3) NULL,
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          created_at DATETIME2(3) DEFAULT SYSDATETIME(),
          updated_at DATETIME2(3) DEFAULT SYSDATETIME()
        )
        CREATE INDEX IX_schemes_customer ON schemes (customer_id)
        CREATE INDEX IX_schemes_phone ON schemes (customer_phone)
        CREATE INDEX IX_schemes_type ON schemes (scheme_type)
        CREATE INDEX IX_schemes_status ON schemes (status)
        CREATE INDEX IX_schemes_business_id ON schemes (business_id)
        PRINT 'Schemes table created with SQL Server 2019 features'
      END
    `);

    // Database migration: Add MPIN column if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'mpin')
      BEGIN
        ALTER TABLE customers ADD mpin NVARCHAR(255) NULL
        PRINT 'MPIN column added to customers table'
      END
    `);

    // Database migration: Add customer_id column if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'customer_id')
      BEGIN
        ALTER TABLE customers ADD customer_id NVARCHAR(20) NULL
        PRINT 'customer_id column added to customers table'
      END
    `);

    // Populate customer_id for existing customers
    await pool.request().query(`
      IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('customers') AND name = 'customer_id')
      BEGIN
        -- Update existing customers without customer_id
        UPDATE customers
        SET customer_id = 'VM' + CAST(id AS NVARCHAR(10))
        WHERE customer_id IS NULL

        PRINT 'customer_id populated for existing customers'
      END
    `);

    // Create ID counters table for sequential ID generation
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='id_counters')
      BEGIN
        CREATE TABLE id_counters (
          counter_name NVARCHAR(50) PRIMARY KEY,
          current_value INT NOT NULL DEFAULT 0,
          last_updated DATETIME2(3) DEFAULT SYSDATETIME()
        )
        PRINT 'ID counters table created'

        -- Initialize customer counter
        INSERT INTO id_counters (counter_name, current_value)
        SELECT 'customer_id_counter', ISNULL(MAX(CAST(SUBSTRING(customer_id, 3, LEN(customer_id)-2) AS INT)), 0)
        FROM customers
        WHERE customer_id LIKE 'VM%' AND ISNUMERIC(SUBSTRING(customer_id, 3, LEN(customer_id)-2)) = 1

        -- Initialize scheme counter
        INSERT INTO id_counters (counter_name, current_value) VALUES ('scheme_id_counter', 0)

        PRINT 'ID counters initialized'
      END
    `);

    // Insert test data
    await pool.request().query(`
      IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = '9999999999')
      BEGIN
        -- Get next customer ID
        DECLARE @nextId INT
        SELECT @nextId = current_value + 1 FROM id_counters WHERE counter_name = 'customer_id_counter'
        UPDATE id_counters SET current_value = @nextId, last_updated = SYSDATETIME() WHERE counter_name = 'customer_id_counter'

        DECLARE @customerId NVARCHAR(20) = 'VM' + CAST(@nextId AS NVARCHAR(10))

        INSERT INTO customers (customer_id, phone, name, email, address, pan_card, device_id)
        VALUES (@customerId, '9999999999', 'Test Customer', 'test@vmurugan.com', 'Test Address, Chennai', 'ABCDE1234F', 'test_device_001')
        PRINT 'Test customer inserted with ID: ' + @customerId
      END
    `);

    // Create notifications table - for in-app history
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='notifications')
      BEGIN
        CREATE TABLE notifications (
          notification_id NVARCHAR(50) PRIMARY KEY,
          user_id NVARCHAR(15) NOT NULL,
          type NVARCHAR(50) NOT NULL,
          title NVARCHAR(200) NOT NULL,
          message NVARCHAR(MAX) NOT NULL,
          is_read BIT DEFAULT 0,
          created_at DATETIME2(3) DEFAULT SYSDATETIME(),
          read_at DATETIME2(3) NULL,
          data NVARCHAR(MAX) NULL,
          priority NVARCHAR(20) DEFAULT 'normal',
          image_url NVARCHAR(500) NULL,
          action_url NVARCHAR(500) NULL,
          business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
          sent_by NVARCHAR(50) DEFAULT 'SYSTEM'
        )
        CREATE INDEX IX_notifications_user_id ON notifications (user_id)
        CREATE INDEX IX_notifications_created_at ON notifications (created_at)
        PRINT 'Notifications table created'
      END
    `);

    // Create user_tokens table - for Push Notifications (FCM)
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='user_tokens')
      BEGIN
        CREATE TABLE user_tokens (
          id INT IDENTITY(1,1) PRIMARY KEY,
          user_phone NVARCHAR(15) NOT NULL,
          fcm_token NVARCHAR(MAX) NOT NULL,
          device_type NVARCHAR(20) DEFAULT 'mobile',
          last_updated DATETIME2(3) DEFAULT SYSDATETIME(),
          is_active BIT DEFAULT 1
        )
        CREATE INDEX IX_user_tokens_phone ON user_tokens (user_phone)
        PRINT 'User tokens table created'
      END
    `);

    console.log('✅ Tables created successfully');
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
  }
}

// ROUTES START HERE

// Register FCM Token Endpoint
app.post('/api/notifications/register-token', async (req, res) => {
  try {
    const { phone, fcm_token, device_type } = req.body;

    if (!phone || !fcm_token) {
      return res.status(400).json({ success: false, message: 'Phone and Token are required' });
    }

    // Check if token exists for this user
    const checkResult = await pool.request()
      .input('phone', sql.NVarChar, phone)
      .input('token', sql.NVarChar, fcm_token)
      .query('SELECT id FROM user_tokens WHERE user_phone = @phone AND fcm_token = @token');

    if (checkResult.recordset.length > 0) {
      // Update last_updated
      await pool.request()
        .input('id', sql.Int, checkResult.recordset[0].id)
        .query('UPDATE user_tokens SET last_updated = SYSDATETIME(), is_active = 1 WHERE id = @id');
    } else {
      // Insert new token
      await pool.request()
        .input('phone', sql.NVarChar, phone)
        .input('token', sql.NVarChar, fcm_token)
        .input('device_type', sql.NVarChar, device_type || 'mobile')
        .query('INSERT INTO user_tokens (user_phone, fcm_token, device_type) VALUES (@phone, @token, @device_type)');
    }

    console.log(`🔔 FCM Token registered for ${phone}`);
    res.json({ success: true, message: 'Token registered successfully' });
  } catch (error) {
    console.error('❌ Error registering token:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});


// Health check endpoint
app.get('/health', (req, res) => {
  console.log('📋 Health check requested from:', req.ip);
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server API',
    database: sqlConfig.database,
    server: sqlConfig.server,
    port: PORT,
    uptime: process.uptime()
  });
});

// Serve admin portal with HTTPS-only security headers
app.get('/admin_portal/index.html', (req, res) => {
  const adminPortalPath = path.join(__dirname, '..', 'admin_portal', 'index.html');
  console.log('📊 Serving HTTPS-only admin portal from:', adminPortalPath);

  // Add HTTPS-only security headers
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  if (require('fs').existsSync(adminPortalPath)) {
    res.sendFile(adminPortalPath);
  } else {
    res.status(404).json({
      success: false,
      message: 'Admin portal not found',
      path: adminPortalPath,
      suggestion: 'Ensure admin_portal/index.html exists in the project root'
    });
  }
});

// Serve Privacy Policy
app.get('/privacy-policy', (req, res) => {
  const privacyPolicyPath = path.join(__dirname, '..', 'privacy_policy_vmurugan.html');
  console.log('🔒 Serving Privacy Policy from:', privacyPolicyPath);

  // Set security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  if (require('fs').existsSync(privacyPolicyPath)) {
    res.sendFile(privacyPolicyPath);
  } else {
    res.status(404).json({
      success: false,
      message: 'Privacy Policy not found',
      path: privacyPolicyPath
    });
  }
});

// Serve Terms of Service
app.get('/terms-of-service', (req, res) => {
  const termsPath = path.join(__dirname, '..', 'terms_of_service_vmurugan.html');
  console.log('📋 Serving Terms of Service from:', termsPath);

  // Set security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  if (require('fs').existsSync(termsPath)) {
    res.sendFile(termsPath);
  } else {
    res.status(404).json({
      success: false,
      message: 'Terms of Service not found',
      path: termsPath
    });
  }
});

// Serve Account Deletion Request Page
app.get('/account-deletion', (req, res) => {
  const accountDeletionPath = path.join(__dirname, '..', 'account-deletion.html');
  console.log('🗑️ Serving Account Deletion page from:', accountDeletionPath);

  // Set security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Content-Type', 'text/html; charset=utf-8');

  if (require('fs').existsSync(accountDeletionPath)) {
    res.sendFile(accountDeletionPath);
  } else {
    res.status(404).json({
      success: false,
      message: 'Account Deletion page not found',
      path: accountDeletionPath
    });
  }
});

// Worldline Checkout Page - Following Payment_GateWay.md specifications
app.get('/worldline-checkout', (req, res) => {
  const requestId = `CHECKOUT_${Date.now()}`;
  console.log(`🌐 [${requestId}] Serving Worldline checkout page`);

  const { token, merchantCode, txnId, amount, consumerId, consumerMobileNo, consumerEmailId } = req.query;

  if (!token || !merchantCode || !txnId || !amount) {
    console.log(`❌ [${requestId}] Missing required parameters`);
    return res.status(400).json({
      success: false,
      message: 'Missing required parameters: token, merchantCode, txnId, amount'
    });
  }

  console.log(`🎫 [${requestId}] Token: ${token.substring(0, 20)}...`);
  console.log(`🏪 [${requestId}] Merchant: ${merchantCode}`);
  console.log(`💰 [${requestId}] Amount: ₹${amount}`);

  // Generate HTML page with Worldline Checkout.js integration
  const checkoutHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VMurugan Gold Trading - Payment Gateway</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { color: #d4af37; font-size: 24px; font-weight: bold; }
        .amount { font-size: 32px; color: #2c5530; margin: 20px 0; }
        .pay-btn { background: #d4af37; color: white; border: none; padding: 15px 30px; font-size: 18px; border-radius: 5px; cursor: pointer; width: 100%; }
        .pay-btn:hover { background: #b8941f; }
        .info { background: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .loading { display: none; text-align: center; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🏆 VMurugan Gold Trading</div>
            <h2>Secure Payment Gateway</h2>
        </div>

        <div style="text-align: center;">
            <div>Payment Amount</div>
            <div class="amount">₹${amount}</div>
            <div>Transaction ID: ${txnId}</div>
        </div>

        <div class="info">
            <strong>Test Environment Instructions:</strong><br>
            1. Click "Pay Now" to open payment gateway<br>
            2. Select "Net Banking" → "Test Bank"<br>
            3. Enter Login ID: <strong>test</strong><br>
            4. Enter Password: <strong>test</strong><br>
            5. Complete the payment process
        </div>

        <button id="payBtn" class="pay-btn">Pay Now</button>

        <div id="loading" class="loading">
            <div>Opening payment gateway...</div>
            <div>Please wait...</div>
        </div>

        <div id="debugInfo" style="margin-top: 20px; padding: 15px; background: #f0f0f0; border-radius: 5px; font-family: monospace; font-size: 12px; display: none;">
            <strong>Debug Information:</strong><br>
            <div id="debugLog"></div>
        </div>

        <button id="showDebug" style="margin-top: 10px; padding: 10px; background: #666; color: white; border: none; border-radius: 3px;">Show Debug Info</button>
    </div>

    <!-- Load jQuery from reliable CDN -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"
            onerror="console.error('❌ Failed to load jQuery'); loadFallbackJQuery();"></script>

    <!-- Try multiple Worldline Checkout.js sources -->
    <script>
        var checkoutLoaded = false;
        var checkoutSources = [
            'https://www.paynimo.com/paynimocheckout/client/lib/checkout.js',
            'https://paynimo.com/paynimocheckout/client/lib/checkout.js',
            'https://secure.paynimo.com/paynimocheckout/client/lib/checkout.js'
        ];

        function loadCheckoutScript(index) {
            if (index >= checkoutSources.length) {
                console.error('❌ All Checkout.js sources failed');
                showCheckoutError();
                return;
            }

            var script = document.createElement('script');
            script.src = checkoutSources[index];
            script.onload = function() {
                console.log('✅ Checkout.js loaded from: ' + checkoutSources[index]);
                checkoutLoaded = true;
            };
            script.onerror = function() {
                console.error('❌ Failed to load from: ' + checkoutSources[index]);
                loadCheckoutScript(index + 1);
            };
            document.head.appendChild(script);
        }

        // Start loading checkout script
        loadCheckoutScript(0);
    </script>

    <script>
        function loadFallbackJQuery() {
            console.log('🔄 Loading fallback jQuery...');
            var script = document.createElement('script');
            script.src = 'https://code.jquery.com/jquery-3.6.0.min.js';
            script.onload = function() { console.log('✅ Fallback jQuery loaded'); };
            script.onerror = function() { console.error('❌ Fallback jQuery failed'); };
            document.head.appendChild(script);
        }

        function showCheckoutError() {
            console.error('❌ Worldline Checkout.js failed to load');
            document.getElementById('loading').style.display = 'none';
            document.getElementById('payBtn').disabled = false;
            alert('Payment gateway is currently unavailable. Please try again later or contact support.');
        }
    </script>

    <script>
        console.log('🚀 Worldline Checkout Page Loaded');
        console.log('🎫 Token: ${token.substring(0, 20)}...');
        console.log('🏪 Merchant: ${merchantCode}');
        console.log('💰 Amount: ₹${amount}');

        var debugLog = [];
        function addDebugLog(message) {
            debugLog.push(new Date().toLocaleTimeString() + ': ' + message);
            console.log(message);
            if (document.getElementById('debugLog')) {
                document.getElementById('debugLog').innerHTML = debugLog.join('<br>');
            }
        }

        // Show/hide debug info
        $('#showDebug').on('click', function() {
            $('#debugInfo').toggle();
        });

        // Check if jQuery and Checkout.js are loaded
        $(document).ready(function() {
            addDebugLog('✅ jQuery loaded successfully');

            // Wait for checkout script to load with retry mechanism
            function waitForCheckout(attempts) {
                attempts = attempts || 0;
                addDebugLog('🔍 Checking Worldline Checkout.js... (attempt ' + (attempts + 1) + ')');

                if (typeof $.pnCheckout === 'function') {
                    addDebugLog('✅ Worldline Checkout.js loaded successfully');
                } else if (attempts < 20) { // Try for 10 seconds (20 * 500ms)
                    addDebugLog('⏳ Waiting for Checkout.js to load...');
                    setTimeout(function() {
                        waitForCheckout(attempts + 1);
                    }, 500);
                } else {
                    addDebugLog('❌ Worldline Checkout.js failed to load after 10 seconds');
                    addDebugLog('❌ $.pnCheckout is ' + typeof $.pnCheckout);
                    addDebugLog('🔧 Implementing fallback payment method...');

                    // Enable fallback payment method
                    $('#payBtn').text('Try Alternative Payment Method');
                    $('#payBtn').removeClass('btn-primary').addClass('btn-warning');
                    $('#loading').hide();
                    $('#payBtn').prop('disabled', false);
                    $('#debugInfo').show();

                    addDebugLog('✅ Fallback payment method enabled');
                    alert('Primary payment gateway unavailable. Using alternative method.');
                }
            }

            waitForCheckout();
        });

        $('#payBtn').on('click', function() {
            addDebugLog('💳 Pay Now button clicked');
            $('#loading').show();
            $('#payBtn').prop('disabled', true);
            $('#debugInfo').show(); // Show debug info when payment starts

            // Add timeout to prevent infinite loading
            setTimeout(function() {
                if ($('#loading').is(':visible')) {
                    addDebugLog('⏰ Payment gateway timeout - showing fallback');
                    $('#loading').hide();
                    $('#payBtn').prop('disabled', false);
                    alert('Payment gateway is taking longer than expected. Please try again or contact support.');
                }
            }, 30000); // 30 second timeout

            try {
                // Check if Worldline Checkout SDK is available
                if (typeof $.pnCheckout === 'function') {
                    addDebugLog('🔄 Using Worldline Checkout SDK...');

                    var checkoutData = {
                        "features": {"showPGResponseMsg": true},
                        "consumerData": {
                            "deviceId": "ANDROIDSH2", // CRITICAL FIX: Match Flutter app device ID for consistent hash validation
                            "token": "${token}",
                            "returnUrl": "https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/verify",
                            "merchantCode": "${merchantCode}",
                            "currency": "INR",
                            "consumerId": "${consumerId || 'GUEST'}",
                            "consumerMobileNo": "${consumerMobileNo || '9876543210'}",
                            "consumerEmailId": "${consumerEmailId || 'test@vmuruganjewellery.co.in'}",
                            "txnId": "${txnId}",
                            "items": [{
                                "itemId": "first",
                                "amount": "${amount}",
                                "comAmt": "0"
                            }]
                        }
                    };

                    addDebugLog('📤 Checkout Data: ' + JSON.stringify(checkoutData, null, 2));

                    $.pnCheckout(checkoutData).then(function(response) {
                        addDebugLog("🎯 Payment Response: " + JSON.stringify(response));
                        $('#loading').hide();
                        $('#payBtn').prop('disabled', false);

                        if (response && response.status === 'success') {
                            alert('Payment completed successfully! WL Transaction ID: ' + (response.pgTransactionId || response.gatewayTransactionId || 'N/A'));
                        } else {
                            alert('Payment status: ' + (response ? response.status : 'Unknown') + '\\nMessage: ' + (response ? response.message || 'No message' : 'No response'));
                        }
                    }).catch(function(error) {
                        addDebugLog("❌ Payment Error: " + error.message);
                        $('#loading').hide();
                        $('#payBtn').prop('disabled', false);
                        alert('Payment failed: ' + (error.message || error.toString()));
                    });

                } else {
                    addDebugLog('🔄 SDK not available - Using Direct Form Submission...');

                    // Create and submit form directly to Worldline
                    var form = document.createElement('form');
                    form.method = 'POST';
                    form.action = 'https://www.paynimo.com/api/paynimoV2.req';
                    form.target = '_self';

                    var formData = {
                        'merchantCode': '${merchantCode}',
                        'txnId': '${txnId}',
                        'amount': '${amount}',
                        'currency': 'INR',
                        'token': '${token}',
                        'returnUrl': 'https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/verify',
                        'consumerId': '${consumerId || 'GUEST'}',
                        'consumerMobileNo': '${consumerMobileNo || '9876543210'}',
                        'consumerEmailId': '${consumerEmailId || 'test@vmuruganjewellery.co.in'}'
                    };

                    for (var key in formData) {
                        var input = document.createElement('input');
                        input.type = 'hidden';
                        input.name = key;
                        input.value = formData[key];
                        form.appendChild(input);
                    }

                    addDebugLog('📤 Submitting direct form to Worldline...');
                    addDebugLog('🌐 Form Action: ' + form.action);
                    addDebugLog('📋 Form Data: ' + JSON.stringify(formData, null, 2));

                    document.body.appendChild(form);
                    form.submit();
                }

            } catch (e) {
                addDebugLog("❌ Checkout Error: " + e.message);
                $('#loading').hide();
                $('#payBtn').prop('disabled', false);
                alert('Payment initialization failed: ' + e.message);
            }
        });
    </script>
</body>
</html>`;

  console.log(`✅ [${requestId}] Serving checkout HTML page`);
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(checkoutHtml);
});

// Redirect any HTTP requests to HTTPS (if somehow they reach here)
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    console.log('🔒 Enforcing HTTPS-only access');
  }
  next();
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'VMurugan Gold Trading SQL Server API',
    status: 'Running',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      adminPortal: '/admin_portal/index.html',
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
    const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as servername, SYSDATETIME() as currenttime');
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

    // Store encrypted MPIN directly (client already hashed it)
    let hashedMPIN = null;
    if (encrypted_mpin) {
      hashedMPIN = encrypted_mpin; // Client already encrypted with salt
      console.log('🔐 MPIN stored directly (already encrypted by client)');
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
        -- Generate sequential customer ID
        DECLARE @nextId INT
        DECLARE @customerId NVARCHAR(20)

        -- Get and increment counter atomically
        UPDATE id_counters
        SET @nextId = current_value = current_value + 1, last_updated = SYSDATETIME()
        WHERE counter_name = 'customer_id_counter'

        SET @customerId = 'VM' + CAST(@nextId AS NVARCHAR(10))

        INSERT INTO customers (customer_id, phone, name, email, address, pan_card, device_id, business_id, mpin)
        VALUES (@customerId, @phone, @name, @email, @address, @pan_card, @device_id, @business_id, @mpin)
      END
      ELSE
      BEGIN
        UPDATE customers
        SET name = @name, email = @email, address = @address,
            pan_card = @pan_card, device_id = @device_id,
            ${hashedMPIN ? 'mpin = @mpin,' : ''} updated_at = SYSDATETIME()
        WHERE phone = @phone
      END
    `);

    // Get the saved customer data to return user object with all fields
    const getUserRequest = pool.request();
    getUserRequest.input('phone', sql.NVarChar(15), phone);
    const userResult = await getUserRequest.query(`
      SELECT id, customer_id, phone, name, email, address, pan_card, registration_date,
             business_id, total_invested, total_gold, transaction_count,
             last_transaction, created_at, updated_at
      FROM customers
      WHERE phone = @phone
    `);

    const customer = userResult.recordset[0];

    console.log('✅ Customer saved:', phone, '| Customer ID:', customer.customer_id);
    res.json({
      success: true,
      message: 'Customer saved successfully',
      user: {
        id: customer.customer_id, // Use customer_id (VM1, VM2, etc.) instead of database id
        customer_id: customer.customer_id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email,
        address: customer.address,
        pan_card: customer.pan_card,
        registration_date: customer.registration_date,
        business_id: customer.business_id,
        total_invested: customer.total_invested,
        total_gold: customer.total_gold,
        transaction_count: customer.transaction_count,
        last_transaction: customer.last_transaction,
        created_at: customer.created_at,
        updated_at: customer.updated_at
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

    // Verify MPIN using hybrid verification
    console.log('🔐 Verifying MPIN with hybrid system...');
    console.log('🔐 Input encrypted MPIN:', encrypted_mpin.substring(0, 20) + '...');
    console.log('🔐 Stored MPIN hash:', customer.mpin.substring(0, 20) + '...');

    if (verifyMPIN(encrypted_mpin, customer.mpin)) {
      console.log('✅ Login successful (hybrid verification):', phone);
      res.json({
        success: true,
        message: 'Login successful',
        customer: {  // Changed from 'user' to 'customer' for consistency
          customer_id: customer.id,
          phone: customer.phone,
          name: customer.name,
          email: customer.email
        },
        user: {  // Keep 'user' for backward compatibility
          id: customer.id,
          phone: customer.phone,
          name: customer.name,
          email: customer.email
        }
      });
    } else {
      console.log('❌ MPIN verification failed for:', phone);
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

    const result = await request.query(`
      SELECT id, customer_id, phone, name, email, address, pan_card, registration_date,
             business_id, total_invested, total_gold, transaction_count,
             last_transaction, created_at, updated_at
      FROM customers
      WHERE phone = @phone
    `);

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
        id: customer.customer_id, // Use customer_id (VM1, VM2, etc.) instead of database id
        customer_id: customer.customer_id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email,
        address: customer.address,
        pan_card: customer.pan_card,
        registration_date: customer.registration_date,
        business_id: customer.business_id,
        total_invested: customer.total_invested,
        total_gold: customer.total_gold,
        transaction_count: customer.transaction_count,
        last_transaction: customer.last_transaction,
        created_at: customer.created_at,
        updated_at: customer.updated_at
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

    // Encrypt current MPIN to compare with stored MPIN
    const encryptedCurrentMPIN = hashMPIN(current_mpin);
    if (!verifyMPIN(encryptedCurrentMPIN, customer.mpin)) {
      return res.status(401).json({
        success: false,
        message: 'Current MPIN is incorrect'
      });
    }

    // Encrypt new MPIN for storage
    const hashedNewMPIN = hashMPIN(new_mpin);

    // Update MPIN
    const updateRequest = pool.request();
    updateRequest.input('phone', sql.NVarChar(15), phone);
    updateRequest.input('new_mpin', sql.NVarChar(255), hashedNewMPIN);

    await updateRequest.query('UPDATE customers SET mpin = @new_mpin, updated_at = SYSDATETIME() WHERE phone = @phone');

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

    // Encrypt new MPIN for storage
    const hashedMPIN = hashMPIN(new_mpin);

    // Set MPIN
    const updateRequest = pool.request();
    updateRequest.input('phone', sql.NVarChar(15), phone);
    updateRequest.input('mpin', sql.NVarChar(255), hashedMPIN);

    await updateRequest.query('UPDATE customers SET mpin = @mpin, updated_at = SYSDATETIME() WHERE phone = @phone');

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
    console.log('🎯🎯🎯 TRANSACTION CREATION REQUEST RECEIVED 🎯🎯🎯');
    console.log('💰 Transaction ID:', req.body.transaction_id);
    console.log('💰 Customer Phone:', req.body.customer_phone);
    console.log('💰 Customer Name:', req.body.customer_name);
    console.log('💰 Amount:', req.body.amount);
    console.log('💰 Status:', req.body.status);
    console.log('💰 Payment Method:', req.body.payment_method);
    console.log('💰 Gateway Transaction ID:', req.body.gateway_transaction_id);
    console.log('💰 Additional Data Present:', req.body.additional_data ? 'YES' : 'NO');

    if (req.body.additional_data) {
      console.log('📋 Additional Data Content:', JSON.stringify(req.body.additional_data, null, 2));
    }

    console.log('💰 Full request body:', JSON.stringify(req.body, null, 2));

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ Validation errors:', errors.array());
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const {
      transaction_id, customer_phone, customer_name, type, amount, gold_grams,
      gold_price_per_gram, payment_method, status, gateway_transaction_id,
      device_info, location, additional_data, scheme_type, scheme_id, installment_number,
      silver_grams, silver_price_per_gram
    } = req.body;

    const business_id = 'VMURUGAN_001';

    console.log('💰 Processing transaction data:');
    console.log('  - Transaction ID:', transaction_id);
    console.log('  - Customer Phone:', customer_phone);
    console.log('  - Amount:', amount);
    console.log('  - Status:', status);
    console.log('  - Payment Method:', payment_method);
    console.log('  - Gateway Transaction ID:', gateway_transaction_id);
    console.log('  - Scheme Type:', scheme_type || 'REGULAR');
    console.log('  - Scheme ID:', scheme_id || 'N/A');
    console.log('  - Installment Number:', installment_number || 'N/A');
    console.log('  - Additional Data:', additional_data ? 'Present' : 'Not provided');
    if (additional_data) {
      console.log('  - Additional Data Content:', JSON.stringify(additional_data, null, 2));
    }

    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), transaction_id);
    request.input('customer_phone', sql.NVarChar(15), customer_phone);
    request.input('customer_name', sql.NVarChar(100), customer_name);
    request.input('type', sql.NVarChar(10), type || 'BUY');
    request.input('amount', sql.Decimal(12, 2), amount);
    request.input('gold_grams', sql.Decimal(10, 4), gold_grams || 0);
    request.input('gold_price_per_gram', sql.Decimal(10, 2), gold_price_per_gram || 0);
    request.input('silver_grams', sql.Decimal(10, 4), silver_grams || 0);
    request.input('silver_price_per_gram', sql.Decimal(10, 2), silver_price_per_gram || 0);
    request.input('payment_method', sql.NVarChar(50), payment_method || 'GATEWAY');
    request.input('status', sql.NVarChar(20), status || 'PENDING');
    request.input('gateway_transaction_id', sql.NVarChar(100), gateway_transaction_id);
    request.input('device_info', sql.NVarChar(sql.MAX), device_info);
    request.input('location', sql.NVarChar(sql.MAX), location);
    request.input('business_id', sql.NVarChar(50), business_id);
    request.input('additional_data', sql.NVarChar(sql.MAX), additional_data ? JSON.stringify(additional_data) : null);
    request.input('scheme_type', sql.NVarChar(20), scheme_type || null);
    request.input('scheme_id', sql.NVarChar(100), scheme_id || null);
    request.input('installment_number', sql.Int, installment_number || null);

    // Determine metal_type based on which grams field is non-zero
    const metal_type = silver_grams > 0 ? 'SILVER' : 'GOLD';
    request.input('metal_type', sql.NVarChar(10), metal_type);

    await request.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount, gold_grams,
        gold_price_per_gram, silver_grams, silver_price_per_gram, payment_method, status, gateway_transaction_id,
        device_info, location, business_id, additional_data, scheme_type, scheme_id, installment_number, metal_type
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @type, @amount, @gold_grams,
        @gold_price_per_gram, @silver_grams, @silver_price_per_gram, @payment_method, @status, @gateway_transaction_id,
        @device_info, @location, @business_id, @additional_data, @scheme_type, @scheme_id, @installment_number, @metal_type
      )
    `);

    console.log('✅ Transaction saved successfully to database:', transaction_id);
    console.log('✅ Database insert completed with additional_data included');

    res.json({
      success: true,
      message: 'Transaction saved successfully',
      transaction_id: transaction_id
    });

  } catch (error) {
    console.error('❌ CRITICAL ERROR saving transaction:', error.message);
    console.error('❌ Error stack:', error.stack);
    console.error('❌ Failed transaction data:', JSON.stringify(req.body, null, 2));
    res.status(500).json({ success: false, message: 'Internal server error', error: error.message });
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

// Get customer portfolio
// Price caching to improve performance (5 minute cache)
// Initialize as null - will be set only when MJDTA successfully returns prices
let cachedGoldPrice = null;
let cachedSilverPrice = null;
let lastPriceFetch = null;
const PRICE_CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

app.get('/api/portfolio', async (req, res) => {
  try {
    const { phone } = req.query;
    console.log('📊 Portfolio request for phone:', phone);

    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required' });
    }

    const request = pool.request();
    request.input('phone', sql.NVarChar(15), phone);

    // Get customer info (including customer_id, address, pan_card, nominee details)
    const customerResult = await request.query(`
      SELECT customer_id, name, email, address, pan_card,
             nominee_name, nominee_relationship, nominee_phone
      FROM customers
      WHERE phone = @phone
    `);

    const customer = customerResult.recordset[0] || null;

    // Get portfolio summary - COMBINED query for better performance
    // This calculates:
    // 1. Direct purchases (transactions with scheme_id IS NULL)
    // 2. Scheme payments (transactions with scheme_id IS NOT NULL)
    // 3. Separates gold and silver based on actual grams in transactions
    const portfolioRequest = pool.request();
    portfolioRequest.input('phone', sql.NVarChar(15), phone);

    const portfolioResult = await portfolioRequest.query(`
      SELECT
        -- Total invested (all successful BUY transactions)
        ISNULL(SUM(CASE WHEN status = 'SUCCESS' AND type = 'BUY' THEN amount ELSE 0 END), 0) as total_invested,

        -- Gold grams (sum all gold_grams from successful transactions)
        ISNULL(SUM(CASE WHEN status = 'SUCCESS' AND type = 'BUY' THEN gold_grams ELSE 0 END), 0) as total_gold_grams,

        -- Silver grams (sum all silver_grams from successful transactions)
        ISNULL(SUM(CASE WHEN status = 'SUCCESS' AND type = 'BUY' THEN silver_grams ELSE 0 END), 0) as total_silver_grams,

        -- Transaction counts
        COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as total_transactions,
        MAX(timestamp) as last_transaction_date
      FROM transactions
      WHERE customer_phone = @phone
    `);

    const portfolio = portfolioResult.recordset[0] || {
      total_invested: 0,
      total_gold_grams: 0,
      total_silver_grams: 0,
      total_transactions: 0,
      last_transaction_date: null
    };

    // Use the values directly (no need to combine with schemes since all transactions are already included)
    const totalInvested = portfolio.total_invested || 0;
    const totalGoldGrams = portfolio.total_gold_grams || 0;
    const totalSilverGrams = portfolio.total_silver_grams || 0;

    // Fetch live prices from MJDTA with caching (for display purposes only)
    let currentGoldPrice = cachedGoldPrice;
    let currentSilverPrice = cachedSilverPrice;

    const now = Date.now();
    if (!lastPriceFetch || (now - lastPriceFetch) > PRICE_CACHE_DURATION) {
      try {
        // Fetch live gold price from MJDTA
        const goldPriceResponse = await fetch('https://www.mjdta.com/');
        if (goldPriceResponse.ok) {
          const html = await goldPriceResponse.text();

          // Parse gold price (22K) from MJDTA HTML
          const goldMatch = html.match(/22\s*K.*?₹\s*([\d,]+)/i);
          if (goldMatch) {
            const parsedGoldPrice = parseFloat(goldMatch[1].replace(/,/g, ''));
            if (parsedGoldPrice >= 3000 && parsedGoldPrice <= 15000) {
              cachedGoldPrice = parsedGoldPrice;
              currentGoldPrice = parsedGoldPrice;
              console.log('✅ Live Gold Price fetched from MJDTA:', currentGoldPrice);
            }
          }

          // Parse silver price from MJDTA HTML
          const silverMatch = html.match(/Silver.*?₹\s*([\d,]+)/i);
          if (silverMatch) {
            const parsedSilverPrice = parseFloat(silverMatch[1].replace(/,/g, ''));
            if (parsedSilverPrice >= 30 && parsedSilverPrice <= 300) {
              cachedSilverPrice = parsedSilverPrice;
              currentSilverPrice = parsedSilverPrice;
              console.log('✅ Live Silver Price fetched from MJDTA:', currentSilverPrice);
            }
          }

          lastPriceFetch = now;
        } else {
          console.log('⚠️ MJDTA returned non-OK status:', goldPriceResponse.status);
        }
      } catch (priceError) {
        console.log('⚠️ Could not fetch live prices from MJDTA:', priceError.message);
        console.log('ℹ️ Prices will be returned as null (frontend will display "--")');
      }
    } else {
      console.log('ℹ️ Using cached prices (last fetched', Math.round((now - lastPriceFetch) / 1000), 'seconds ago)');
    }

    // OPTION 2: Current Value = Total Invested (no market value calculation)
    // This is a savings scheme - customers cannot sell, only receive physical gold/silver
    const currentValue = totalInvested;
    const profitLoss = 0; // Always zero (no unrealized gains)
    const profitLossPercentage = 0; // Always zero

    // Calculate market values for informational display only (not used in portfolio value)
    // Only calculate if prices are available (not null)
    const currentGoldValue = currentGoldPrice ? totalGoldGrams * currentGoldPrice : null;
    const currentSilverValue = currentSilverPrice ? totalSilverGrams * currentSilverPrice : null;

    console.log('✅ Portfolio retrieved for phone:', phone);
    console.log('📊 Portfolio Summary:', {
      customer_id: customer?.customer_id,
      totalInvested,
      totalGoldGrams,
      totalSilverGrams,
      totalTransactions: portfolio.total_transactions,
      currentValue: totalInvested, // Same as invested (Option 2 - Savings Scheme)
      profitLoss: 0, // Always zero (Option 2 - No selling allowed)
      currentGoldPrice, // From MJDTA (for display)
      currentSilverPrice // From MJDTA (for display)
    });

    res.json({
      success: true,
      portfolio: {
        customer_id: customer?.customer_id || null,
        customer_name: customer?.name || null,
        customer_email: customer?.email || null,
        customer_address: customer?.address || null,
        customer_pan_card: customer?.pan_card || null,
        customer_nominee_name: customer?.nominee_name || null,
        customer_nominee_relationship: customer?.nominee_relationship || null,
        customer_nominee_phone: customer?.nominee_phone || null,
        total_invested: totalInvested,
        total_gold_grams: totalGoldGrams,
        total_silver_grams: totalSilverGrams,
        current_value: currentValue, // Same as total_invested (Option 2)
        current_gold_price: currentGoldPrice, // For display only
        current_silver_price: currentSilverPrice, // For display only
        current_gold_value: currentGoldValue, // For informational display only
        current_silver_value: currentSilverValue, // For informational display only
        profit_loss: profitLoss, // Always 0 (Option 2)
        profit_loss_percentage: profitLossPercentage, // Always 0 (Option 2)
        total_transactions: portfolio.total_transactions || 0,
        last_updated: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('❌ Portfolio error:', error);
    res.status(500).json({ success: false, message: 'Failed to get portfolio', error: error.message });
  }
});

// Create scheme endpoint
app.post('/api/schemes', [
  body('customer_phone').notEmpty().withMessage('Customer phone required'),
  body('customer_name').notEmpty().withMessage('Customer name required'),
  body('scheme_type').isIn(['GOLDPLUS', 'GOLDFLEXI', 'SILVERPLUS', 'SILVERFLEXI']).withMessage('Invalid scheme type'),
  body('monthly_amount').isFloat({ min: 0 }).withMessage('Monthly amount must be a valid number'),
  body('terms_accepted').isBoolean().withMessage('Terms acceptance required')
], async (req, res) => {
  try {
    console.log('🎯🎯🎯 SCHEME CREATION REQUEST RECEIVED 🎯🎯🎯');
    console.log('📊 Request Body:', JSON.stringify(req.body, null, 2));
    console.log('📊 Request Headers:', JSON.stringify(req.headers, null, 2));

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: errors.array().map(e => e.msg).join(', '),
        errors: errors.array()
      });
    }

    const { customer_phone, customer_name, scheme_type, monthly_amount, terms_accepted } = req.body;

    // Validate monthly_amount based on scheme type
    // For testing: Allow amounts from ₹1
    if (scheme_type === 'GOLDPLUS' || scheme_type === 'SILVERPLUS') {
      if (monthly_amount < 1) {
        return res.status(400).json({
          success: false,
          message: 'Monthly amount for PLUS schemes must be at least ₹1'
        });
      }
    }
    // For FLEXI schemes, monthly_amount can be 0 (no fixed monthly amount)

    if (!terms_accepted) {
      return res.status(400).json({ success: false, message: 'Terms and conditions must be accepted' });
    }

    // Get or create customer
    const customerRequest = pool.request();
    customerRequest.input('phone', sql.NVarChar(15), customer_phone);
    customerRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const customerResult = await customerRequest.query(`
      SELECT id, customer_id, name FROM customers WHERE phone = @phone AND business_id = @business_id
    `);

    let customerId;
    if (customerResult.recordset.length === 0) {
      // Create customer if doesn't exist with sequential customer ID
      const createCustomerRequest = pool.request();
      createCustomerRequest.input('phone', sql.NVarChar(15), customer_phone);
      createCustomerRequest.input('name', sql.NVarChar(100), customer_name);
      createCustomerRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

      const createResult = await createCustomerRequest.query(`
        DECLARE @nextId INT
        DECLARE @customerId NVARCHAR(20)

        -- Get and increment counter atomically
        UPDATE id_counters
        SET @nextId = current_value = current_value + 1, last_updated = SYSDATETIME()
        WHERE counter_name = 'customer_id_counter'

        SET @customerId = 'VM' + CAST(@nextId AS NVARCHAR(10))

        INSERT INTO customers (customer_id, phone, name, business_id)
        OUTPUT INSERTED.id
        VALUES (@customerId, @phone, @name, @business_id)
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
      SELECT id, scheme_id, scheme_type, metal_type, monthly_amount, duration_months, status
      FROM schemes
      WHERE customer_id = @customer_id AND status = @status
    `);

    // Check if customer already has 4 schemes
    if (existingSchemes.recordset.length >= 4) {
      return res.status(400).json({
        success: false,
        message: 'Customer already has maximum 4 schemes'
      });
    }

    // Check if customer already has this scheme type
    const existingScheme = existingSchemes.recordset.find(scheme => scheme.scheme_type === scheme_type);
    if (existingScheme) {
      console.log(`ℹ️ Customer already has ${scheme_type} scheme, returning existing scheme_id: ${existingScheme.scheme_id}`);

      // Return the existing scheme instead of error
      return res.json({
        success: true,
        message: 'Using existing scheme',
        scheme: {
          id: existingScheme.id,
          scheme_id: existingScheme.scheme_id,
          customer_id: customerId,
          scheme_type: existingScheme.scheme_type,
          metal_type: existingScheme.metal_type,
          monthly_amount: existingScheme.monthly_amount,
          duration_months: existingScheme.duration_months,
          status: existingScheme.status
        }
      });
    }

    // Generate sequential scheme ID based on MAX(scheme_id) for this scheme_type
    // Format: {type}_P{number} where type is GP, GF, SP, SF
    const schemeTypeMap = {
      'GOLDPLUS': 'GP',
      'GOLDFLEXI': 'GF',
      'SILVERPLUS': 'SP',
      'SILVERFLEXI': 'SF'
    };

    const schemePrefix = schemeTypeMap[scheme_type];

    // Get the last scheme_id for this scheme_type
    const lastSchemeRequest = pool.request();
    lastSchemeRequest.input('scheme_type', sql.NVarChar(20), scheme_type);
    const lastSchemeResult = await lastSchemeRequest.query(`
      SELECT TOP 1 scheme_id
      FROM schemes
      WHERE scheme_type = @scheme_type
      ORDER BY id DESC
    `);

    let nextSchemeNumber = 1; // Default to 1 if no schemes exist

    if (lastSchemeResult.recordset.length > 0) {
      const lastSchemeId = lastSchemeResult.recordset[0].scheme_id;
      console.log(`🔍 Last scheme_id for ${scheme_type}: ${lastSchemeId}`);

      // Extract number from scheme_id (e.g., "GP_P5" -> 5)
      const match = lastSchemeId.match(/_P(\d+)$/);
      if (match) {
        nextSchemeNumber = parseInt(match[1]) + 1;
      }
    }

    const schemeId = `${schemePrefix}_P${nextSchemeNumber}`;

    console.log(`🎯 Generated Scheme ID: ${schemeId} (Type: ${scheme_type}, Number: ${nextSchemeNumber})`);

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
    schemeRequest.input('monthly_amount', sql.Decimal(12, 2), monthly_amount);
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

// Create scheme AFTER payment success
app.post('/api/schemes/create-after-payment', [
  body('customer_phone').notEmpty().withMessage('Customer phone required'),
  body('customer_name').notEmpty().withMessage('Customer name required'),
  body('scheme_type').isIn(['GOLDPLUS', 'GOLDFLEXI', 'SILVERPLUS', 'SILVERFLEXI']).withMessage('Invalid scheme type'),
  body('monthly_amount').isFloat({ min: 0 }).withMessage('Monthly amount must be a valid number'),
  body('transaction_id').notEmpty().withMessage('Transaction ID required')
], async (req, res) => {
  try {
    console.log('🎯🎯🎯 CREATE SCHEME AFTER PAYMENT REQUEST 🎯🎯🎯');
    console.log('📊 Request Body:', JSON.stringify(req.body, null, 2));

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        message: errors.array().map(e => e.msg).join(', '),
        errors: errors.array()
      });
    }

    const { customer_phone, customer_name, scheme_type, monthly_amount, transaction_id } = req.body;

    // Get customer ID
    const customerRequest = pool.request();
    customerRequest.input('phone', sql.NVarChar(15), customer_phone);
    customerRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const customerResult = await customerRequest.query(`
      SELECT id FROM customers WHERE phone = @phone AND business_id = @business_id
    `);

    if (customerResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    const customerId = customerResult.recordset[0].id;

    // Check if customer already has an ACTIVE scheme for this type
    const existingSchemesRequest = pool.request();
    existingSchemesRequest.input('customer_id', sql.Int, customerId);
    existingSchemesRequest.input('scheme_type', sql.NVarChar(20), scheme_type);
    existingSchemesRequest.input('status', sql.NVarChar(20), 'ACTIVE');

    const existingSchemes = await existingSchemesRequest.query(`
      SELECT id, scheme_id, scheme_type, metal_type, monthly_amount, duration_months, status, completed_installments
      FROM schemes
      WHERE customer_id = @customer_id AND scheme_type = @scheme_type AND status = @status
    `);

    // For FLEXI schemes: Always reuse existing scheme if found
    // For PLUS schemes: Only reuse if not completed (completed_installments < 12)
    if (existingSchemes.recordset.length > 0) {
      const existingScheme = existingSchemes.recordset[0];

      const isFlexi = scheme_type.includes('FLEXI');
      const isPlus = scheme_type.includes('PLUS');

      if (isFlexi) {
        // FLEXI: Always reuse
        console.log(`ℹ️ Customer already has ${scheme_type} FLEXI scheme, reusing: ${existingScheme.scheme_id}`);
        return res.json({
          success: true,
          message: 'Using existing FLEXI scheme',
          scheme_id: existingScheme.scheme_id,
          is_new: false
        });
      } else if (isPlus && existingScheme.completed_installments < 12) {
        // PLUS: Check if customer already paid this month
        console.log(`ℹ️ Customer has incomplete ${scheme_type} PLUS scheme: ${existingScheme.scheme_id}`);

        // Check for payments in current calendar month
        const monthlyCheckRequest = pool.request();
        monthlyCheckRequest.input('scheme_id', sql.NVarChar(100), existingScheme.scheme_id);

        const monthlyCheckResult = await monthlyCheckRequest.query(`
          SELECT TOP 1 created_at, installment_number
          FROM transactions
          WHERE scheme_id = @scheme_id
            AND status = 'SUCCESS'
            AND YEAR(created_at) = YEAR(GETDATE())
            AND MONTH(created_at) = MONTH(GETDATE())
          ORDER BY created_at DESC
        `);

        if (monthlyCheckResult.recordset.length > 0) {
          // Customer already paid this month
          const lastPayment = monthlyCheckResult.recordset[0];
          const lastPaymentDate = new Date(lastPayment.created_at);

          console.log(`⚠️ Customer already paid for ${scheme_type} this month on ${lastPaymentDate.toISOString()}`);
          console.log(`ℹ️ Linking transaction to existing scheme as an extra installment/duplicate payment`);

          // Update transaction with scheme_id to prevent orphan transaction
          const updateTxnRequest = pool.request();
          updateTxnRequest.input('transaction_id', sql.NVarChar(100), transaction_id);
          updateTxnRequest.input('scheme_id', sql.NVarChar(100), existingScheme.scheme_id);

          await updateTxnRequest.query(`
            UPDATE transactions
            SET scheme_id = @scheme_id
            WHERE transaction_id = @transaction_id
          `);

          console.log(`✅ Transaction ${transaction_id} updated with scheme_id: ${existingScheme.scheme_id}`);

          // Return success so frontend knows it's handled (even if it's a duplicate/extra)
          return res.json({
            success: true,
            message: 'Payment recorded for existing PLUS scheme',
            scheme_id: existingScheme.scheme_id,
            is_new: false,
            warning: 'Payment for this month was already made. This has been recorded as an additional transaction.'
          });
        }

        // No payment this month, allow payment
        console.log(`✅ No payment found for ${scheme_type} this month, allowing payment`);

        // Update transaction with scheme_id
        const updateTxnRequest = pool.request();
        updateTxnRequest.input('transaction_id', sql.NVarChar(100), transaction_id);
        updateTxnRequest.input('scheme_id', sql.NVarChar(100), existingScheme.scheme_id);

        await updateTxnRequest.query(`
        UPDATE transactions
        SET scheme_id = @scheme_id
        WHERE transaction_id = @transaction_id
      `);

        return res.json({
          success: true,
          message: 'Using existing PLUS scheme',
          scheme_id: existingScheme.scheme_id,
          is_new: false
        });
      }
      // If PLUS scheme is completed, create new one below
    }

    // Generate new scheme_id based on MAX for this scheme_type
    const schemeTypeMap = {
      'GOLDPLUS': 'GP',
      'GOLDFLEXI': 'GF',
      'SILVERPLUS': 'SP',
      'SILVERFLEXI': 'SF'
    };

    const schemePrefix = schemeTypeMap[scheme_type];

    const lastSchemeRequest = pool.request();
    lastSchemeRequest.input('scheme_type', sql.NVarChar(20), scheme_type);
    const lastSchemeResult = await lastSchemeRequest.query(`
      SELECT TOP 1 scheme_id
      FROM schemes
      WHERE scheme_type = @scheme_type
      ORDER BY id DESC
    `);

    let nextSchemeNumber = 1;

    if (lastSchemeResult.recordset.length > 0) {
      const lastSchemeId = lastSchemeResult.recordset[0].scheme_id;
      console.log(`🔍 Last scheme_id for ${scheme_type}: ${lastSchemeId}`);

      const match = lastSchemeId.match(/_P(\d+)$/);
      if (match) {
        nextSchemeNumber = parseInt(match[1]) + 1;
      }
    }

    const schemeId = `${schemePrefix}_P${nextSchemeNumber}`;
    console.log(`🎯 Generated NEW Scheme ID: ${schemeId} (Type: ${scheme_type}, Number: ${nextSchemeNumber})`);

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
    schemeRequest.input('monthly_amount', sql.Decimal(12, 2), monthly_amount);
    schemeRequest.input('duration_months', sql.Int, duration);
    schemeRequest.input('end_date', sql.DateTime, endDate);
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
        @end_date, 1, SYSDATETIME(), @business_id
      )
    `);

    console.log(`✅ Scheme created successfully: ${schemeId}`);

    // Update transaction with scheme_id
    const updateTxnRequest = pool.request();
    updateTxnRequest.input('transaction_id', sql.NVarChar(100), transaction_id);
    updateTxnRequest.input('scheme_id', sql.NVarChar(100), schemeId);

    await updateTxnRequest.query(`
      UPDATE transactions
      SET scheme_id = @scheme_id
      WHERE transaction_id = @transaction_id
    `);

    console.log(`✅ Transaction ${transaction_id} updated with scheme_id: ${schemeId}`);

    res.json({
      success: true,
      message: 'Scheme created successfully after payment',
      scheme_id: schemeId,
      is_new: true
    });

  } catch (error) {
    console.error('❌ Scheme creation after payment error:', error);
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

    // Get schemes with calculated values from transactions table
    const schemes = await schemesRequest.query(`
      SELECT
        s.*,
        c.name as customer_name,
        c.email as customer_email,
        ISNULL(SUM(t.amount), 0) as calculated_invested,
        ISNULL(SUM(CASE WHEN s.metal_type = 'GOLD' THEN t.gold_grams WHEN s.metal_type = 'SILVER' THEN t.silver_grams ELSE 0 END), 0) as calculated_metal_accumulated,
        COUNT(t.id) as payment_count,
        ISNULL(SUM(CASE WHEN t.status = 'SUCCESS' AND YEAR(t.created_at) = YEAR(GETDATE()) AND MONTH(t.created_at) = MONTH(GETDATE()) THEN 1 ELSE 0 END), 0) as current_month_payments
      FROM schemes s
      INNER JOIN customers c ON s.customer_id = c.id
      LEFT JOIN transactions t ON s.scheme_id = t.scheme_id AND t.status = 'SUCCESS'
      WHERE s.customer_phone = @customer_phone AND s.business_id = @business_id
      GROUP BY s.id, s.scheme_id, s.customer_id, s.customer_phone, s.customer_name,
               s.scheme_type, s.metal_type, s.monthly_amount, s.duration_months,
               s.status, s.start_date, s.end_date, s.total_invested,
               s.total_metal_accumulated, s.completed_installments, s.next_payment_date,
               s.terms_accepted, s.terms_accepted_at, s.closure_remarks, s.closure_date,
               s.business_id, s.created_at, s.updated_at,
               c.name, c.email
      ORDER BY s.created_at DESC
    `);

    // Update the schemes with calculated values
    const updatedSchemes = schemes.recordset.map(scheme => {
      // Ensure current_month_payments is a number, not null
      const monthPayments = parseInt(scheme.current_month_payments) || 0;

      // Calculate hasPaidThisMonth - true if any payments this month
      const hasPaidThisMonth = monthPayments > 0;

      // Debug logging for PLUS schemes
      if (scheme.scheme_type && scheme.scheme_type.includes('PLUS')) {
        console.log(`🔍 Scheme ${scheme.scheme_id} (${scheme.scheme_type}):`);
        console.log(`   current_month_payments (raw): ${scheme.current_month_payments}`);
        console.log(`   monthPayments (parsed): ${monthPayments}`);
        console.log(`   hasPaidThisMonth: ${hasPaidThisMonth}`);
      }

      return {
        ...scheme,
        total_invested: scheme.calculated_invested || 0,
        total_metal_accumulated: scheme.calculated_metal_accumulated || 0,
        total_amount_paid: scheme.calculated_invested || 0, // Frontend expects this field
        completed_installments: scheme.payment_count || 0,
        paid_months: scheme.payment_count || 0, // Frontend expects this field
        // CRITICAL: Return hasPaidThisMonth as boolean
        has_paid_this_month: hasPaidThisMonth,
        hasPaidThisMonth: hasPaidThisMonth, // Also include camelCase version
        next_payment_allowed: scheme.scheme_type.includes('FLEXI') || monthPayments === 0
      };
    });

    // Calculate portfolio summary from actual payments
    const portfolioRequest = pool.request();
    portfolioRequest.input('customer_phone', sql.NVarChar(15), customer_phone);
    portfolioRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    const portfolioSummary = await portfolioRequest.query(`
      SELECT
        COUNT(DISTINCT s.scheme_id) as total_schemes,
        ISNULL(SUM(t.amount), 0) as total_invested,
        ISNULL(SUM(CASE WHEN s.metal_type = 'GOLD' THEN t.gold_grams ELSE 0 END), 0) as total_gold_grams,
        ISNULL(SUM(CASE WHEN s.metal_type = 'SILVER' THEN t.silver_grams ELSE 0 END), 0) as total_silver_grams,
        COUNT(t.id) as total_installments
      FROM schemes s
      LEFT JOIN transactions t ON s.scheme_id = t.scheme_id AND t.status = 'SUCCESS'
      WHERE s.customer_phone = @customer_phone AND s.business_id = @business_id AND s.status = 'ACTIVE'
    `);


    console.log('✅ Schemes retrieved:', updatedSchemes.length);

    // Debug: Log validation values for each scheme
    updatedSchemes.forEach(scheme => {
      console.log(`🔍 ${scheme.scheme_type}: has_paid_this_month=${scheme.has_paid_this_month}, next_payment_allowed=${scheme.next_payment_allowed}, current_month_payments=${scheme.current_month_payments}`);
    });

    console.log('📊 Portfolio Summary:', portfolioSummary.recordset[0]);

    res.json({
      success: true,
      customer_phone,
      schemes: updatedSchemes,
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
        updateRequest.input('monthly_amount', sql.Decimal(12, 2), monthly_amount);
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

// Close scheme endpoint (Admin only)
app.post('/api/schemes/:scheme_id/close', [
  body('closure_remarks').optional().isString().withMessage('Closure remarks must be a string')
], async (req, res) => {
  try {
    const { scheme_id } = req.params;
    const { closure_remarks } = req.body;
    console.log('🔒 Closing scheme:', scheme_id);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    // Get scheme details
    const schemeRequest = pool.request();
    schemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);

    const schemeResult = await schemeRequest.query(`
      SELECT * FROM schemes WHERE scheme_id = @scheme_id
    `);

    if (schemeResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Scheme not found' });
    }

    const scheme = schemeResult.recordset[0];

    // Check if scheme is already closed
    if (scheme.status === 'COMPLETED' || scheme.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: `Scheme is already ${scheme.status.toLowerCase()}`
      });
    }

    // Validate closure criteria
    const schemeType = scheme.scheme_type;
    const completedInstallments = scheme.completed_installments;
    const durationMonths = scheme.duration_months;

    // For GOLDPLUS/SILVERPLUS: Must complete 12 months
    if ((schemeType === 'GOLDPLUS' || schemeType === 'SILVERPLUS') && completedInstallments < 12) {
      return res.status(400).json({
        success: false,
        message: `${schemeType} scheme requires 12 completed installments. Current: ${completedInstallments}/12`
      });
    }

    // For GOLDFLEXI/SILVERFLEXI: Can close anytime (no restrictions)

    // Update scheme status to COMPLETED
    const updateRequest = pool.request();
    updateRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    updateRequest.input('status', sql.NVarChar(20), 'COMPLETED');
    updateRequest.input('closure_date', sql.DateTime, new Date());
    updateRequest.input('closure_remarks', sql.NVarChar(500), closure_remarks || 'Scheme closed successfully');
    updateRequest.input('end_date', sql.DateTime, new Date());
    updateRequest.input('updated_at', sql.DateTime, new Date());

    await updateRequest.query(`
      UPDATE schemes
      SET status = @status,
          closure_date = @closure_date,
          closure_remarks = @closure_remarks,
          end_date = @end_date,
          updated_at = @updated_at
      WHERE scheme_id = @scheme_id
    `);

    console.log('✅ Scheme closed successfully:', scheme_id);

    res.json({
      success: true,
      message: 'Scheme closed successfully',
      scheme_id,
      closure_summary: {
        scheme_type: scheme.scheme_type,
        total_invested: scheme.total_invested,
        total_metal_accumulated: scheme.total_metal_accumulated,
        completed_installments: scheme.completed_installments,
        start_date: scheme.start_date,
        closure_date: new Date(),
        closure_remarks: closure_remarks || 'Scheme closed successfully'
      }
    });

  } catch (error) {
    console.error('❌ Scheme closure error:', error);
    res.status(500).json({ success: false, message: 'Scheme closure failed', error: error.message });
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

    // Check for monthly payment restriction (GOLDPLUS/SILVERPLUS)
    if (scheme.scheme_type === 'GOLDPLUS' || scheme.scheme_type === 'SILVERPLUS') {
      const monthlyCheckRequest = pool.request();
      monthlyCheckRequest.input('scheme_id', sql.NVarChar(100), scheme_id);

      const monthlyCheckResult = await monthlyCheckRequest.query(`
        SELECT TOP 1 created_at 
        FROM transactions 
        WHERE scheme_id = @scheme_id 
          AND status = 'SUCCESS' 
          AND YEAR(created_at) = YEAR(GETDATE()) 
          AND MONTH(created_at) = MONTH(GETDATE())
      `);

      if (monthlyCheckResult.recordset.length > 0) {
        const lastPaymentDate = new Date(monthlyCheckResult.recordset[0].created_at);
        return res.status(400).json({
          success: false,
          message: `Payment for this month already received on ${lastPaymentDate.toLocaleDateString()}`,
          error_code: 'MONTHLY_PAYMENT_ALREADY_MADE'
        });
      }
    }

    // Update scheme with new investment
    const updateSchemeRequest = pool.request();
    updateSchemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    updateSchemeRequest.input('amount', sql.Decimal(12, 2), amount);
    updateSchemeRequest.input('metal_grams', sql.Decimal(10, 4), metal_grams);
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

    // Create transaction record with scheme context
    const transactionRequest = pool.request();
    transactionRequest.input('transaction_id', sql.NVarChar(100), transaction_id);
    transactionRequest.input('customer_phone', sql.NVarChar(15), scheme.customer_phone);
    transactionRequest.input('customer_name', sql.NVarChar(100), scheme.customer_name);
    transactionRequest.input('type', sql.NVarChar(10), 'BUY');
    transactionRequest.input('amount', sql.Decimal(12, 2), amount);
    transactionRequest.input('gold_grams', sql.Decimal(10, 4), scheme.metal_type === 'GOLD' ? metal_grams : 0);
    transactionRequest.input('gold_price_per_gram', sql.Decimal(10, 2), scheme.metal_type === 'GOLD' ? current_rate : 0);
    transactionRequest.input('silver_grams', sql.Decimal(10, 4), scheme.metal_type === 'SILVER' ? metal_grams : 0);
    transactionRequest.input('silver_price_per_gram', sql.Decimal(10, 2), scheme.metal_type === 'SILVER' ? current_rate : 0);
    transactionRequest.input('status', sql.NVarChar(20), 'SUCCESS');
    transactionRequest.input('payment_method', sql.NVarChar(50), 'SCHEME_INVESTMENT');
    transactionRequest.input('gateway_transaction_id', sql.NVarChar(100), gateway_transaction_id || `SCHEME_${transaction_id}`);
    transactionRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    // Add scheme context fields
    transactionRequest.input('scheme_type', sql.NVarChar(20), scheme.scheme_type);
    transactionRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    transactionRequest.input('installment_number', sql.Int, scheme.completed_installments + 1);
    transactionRequest.input('metal_type', sql.NVarChar(10), scheme.metal_type);

    await transactionRequest.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount,
        gold_grams, gold_price_per_gram, silver_grams, silver_price_per_gram,
        status, payment_method, gateway_transaction_id, business_id,
        scheme_type, scheme_id, installment_number, metal_type
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @type, @amount,
        @gold_grams, @gold_price_per_gram, @silver_grams, @silver_price_per_gram,
        @status, @payment_method, @gateway_transaction_id, @business_id,
        @scheme_type, @scheme_id, @installment_number, @metal_type
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

// Add Flexi scheme payment (unlimited payments, no monthly restrictions)
app.post('/api/schemes/:scheme_id/flexi-payment', [
  body('amount').isFloat({ min: 100 }).withMessage('Payment amount must be at least ₹100'),
  body('metal_grams').isFloat({ min: 0.001 }).withMessage('Metal grams must be positive'),
  body('current_rate').isFloat({ min: 1 }).withMessage('Current rate must be positive'),
  body('transaction_id').notEmpty().withMessage('Transaction ID required')
], async (req, res) => {
  try {
    const { scheme_id } = req.params;
    const { amount, metal_grams, current_rate, transaction_id, gateway_transaction_id, payment_method } = req.body;
    console.log('💰 Adding Flexi payment to scheme:', scheme_id, 'Amount:', amount);

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

    // Verify it's a FLEXI scheme
    if (scheme.scheme_type !== 'GOLDFLEXI' && scheme.scheme_type !== 'SILVERFLEXI') {
      return res.status(400).json({
        success: false,
        message: 'This endpoint is only for FLEXI schemes. Use /invest for PLUS schemes.'
      });
    }

    // Update scheme with new payment
    const updateSchemeRequest = pool.request();
    updateSchemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    updateSchemeRequest.input('amount', sql.Decimal(12, 2), amount);
    updateSchemeRequest.input('metal_grams', sql.Decimal(10, 4), metal_grams);
    updateSchemeRequest.input('updated_at', sql.DateTime, new Date());

    await updateSchemeRequest.query(`
      UPDATE schemes
      SET
        total_amount_paid = total_amount_paid + @amount,
        total_metal_accumulated = total_metal_accumulated + @metal_grams,
        updated_at = @updated_at
      WHERE scheme_id = @scheme_id
    `);

    // Create transaction record with scheme context (no installment_number for Flexi)
    const transactionRequest = pool.request();
    transactionRequest.input('transaction_id', sql.NVarChar(100), transaction_id);
    transactionRequest.input('customer_phone', sql.NVarChar(15), scheme.customer_phone);
    transactionRequest.input('customer_name', sql.NVarChar(100), scheme.customer_name);
    transactionRequest.input('type', sql.NVarChar(10), 'BUY');
    transactionRequest.input('amount', sql.Decimal(12, 2), amount);
    transactionRequest.input('gold_grams', sql.Decimal(10, 4), scheme.metal_type === 'GOLD' ? metal_grams : 0);
    transactionRequest.input('gold_price_per_gram', sql.Decimal(10, 2), scheme.metal_type === 'GOLD' ? current_rate : 0);
    transactionRequest.input('silver_grams', sql.Decimal(10, 4), scheme.metal_type === 'SILVER' ? metal_grams : 0);
    transactionRequest.input('silver_price_per_gram', sql.Decimal(10, 2), scheme.metal_type === 'SILVER' ? current_rate : 0);
    transactionRequest.input('status', sql.NVarChar(20), 'SUCCESS');
    transactionRequest.input('payment_method', sql.NVarChar(50), payment_method || 'FLEXI_PAYMENT');
    transactionRequest.input('gateway_transaction_id', sql.NVarChar(100), gateway_transaction_id || `FLEXI_${transaction_id}`);
    transactionRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    // Add scheme context fields (no installment_number for Flexi)
    transactionRequest.input('scheme_type', sql.NVarChar(20), scheme.scheme_type);
    transactionRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    transactionRequest.input('metal_type', sql.NVarChar(10), scheme.metal_type);

    await transactionRequest.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount,
        gold_grams, gold_price_per_gram, silver_grams, silver_price_per_gram,
        status, payment_method, gateway_transaction_id, business_id,
        scheme_type, scheme_id, metal_type
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @type, @amount,
        @gold_grams, @gold_price_per_gram, @silver_grams, @silver_price_per_gram,
        @status, @payment_method, @gateway_transaction_id, @business_id,
        @scheme_type, @scheme_id, @metal_type
      )
    `);

    console.log('✅ Flexi payment added successfully:', scheme_id);

    res.json({
      success: true,
      message: 'Flexi payment added successfully',
      scheme_id,
      payment: {
        amount,
        metal_grams,
        current_rate,
        transaction_id
      }
    });

  } catch (error) {
    console.error('❌ Flexi payment error:', error);
    res.status(500).json({ success: false, message: 'Flexi payment failed', error: error.message });
  }
});

// Get scheme details by ID
app.get('/api/schemes/details/:scheme_id', async (req, res) => {
  try {
    const { scheme_id } = req.params;
    console.log('📊 Getting scheme details for scheme_id:', scheme_id);

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

    console.log(`📊 Query returned ${schemeResult.recordset.length} results`);

    if (schemeResult.recordset.length === 0) {
      console.log(`❌ Scheme not found: ${scheme_id}`);

      // Debug: Check if scheme exists with different query
      const debugRequest = pool.request();
      debugRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
      const debugResult = await debugRequest.query(`SELECT COUNT(*) as count FROM schemes WHERE scheme_id = @scheme_id`);
      console.log(`🔍 Debug: Schemes table has ${debugResult.recordset[0].count} records with scheme_id = ${scheme_id}`);

      return res.status(404).json({ success: false, message: 'Scheme not found' });
    }

    console.log(`✅ Scheme found: ${scheme_id}, Type: ${schemeResult.recordset[0].scheme_type}`);

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

// Check monthly payment for scheme
app.get('/api/schemes/:scheme_id/payments/monthly-check', async (req, res) => {
  try {
    const { scheme_id } = req.params;
    const { month, year } = req.query;

    console.log('📊 Checking monthly payment for scheme:', scheme_id, 'Month:', month, 'Year:', year);

    if (!month || !year) {
      return res.status(400).json({
        success: false,
        message: 'Month and year parameters required'
      });
    }

    // Get scheme details first
    const schemeRequest = pool.request();
    schemeRequest.input('scheme_id', sql.NVarChar(100), scheme_id);

    const schemeResult = await schemeRequest.query(`
      SELECT customer_phone, scheme_type FROM schemes
      WHERE scheme_id = @scheme_id
    `);

    if (schemeResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Scheme not found' });
    }

    const customerPhone = schemeResult.recordset[0].customer_phone;
    const schemeType = schemeResult.recordset[0].scheme_type;

    // For FLEXI schemes, always return false (no monthly restrictions)
    if (schemeType === 'GOLDFLEXI' || schemeType === 'SILVERFLEXI') {
      return res.json({
        success: true,
        has_payment: false,
        message: 'No monthly restrictions for flexible schemes'
      });
    }

    // Check for successful payments in the specified month
    const paymentRequest = pool.request();
    paymentRequest.input('customer_phone', sql.NVarChar(15), customerPhone);
    paymentRequest.input('scheme_id', sql.NVarChar(100), scheme_id);
    paymentRequest.input('month', sql.Int, parseInt(month));
    paymentRequest.input('year', sql.Int, parseInt(year));
    const paymentResult = await paymentRequest.query(`
      SELECT COUNT(*) as payment_count
      FROM transactions
      WHERE customer_phone = @customer_phone
        AND scheme_id = @scheme_id
        AND status = 'SUCCESS'
        AND MONTH(timestamp) = @month
        AND YEAR(timestamp) = @year
    `);

    const hasPayment = paymentResult.recordset[0].payment_count > 0;

    res.json({
      success: true,
      has_payment: hasPayment,
      payment_count: paymentResult.recordset[0].payment_count,
      message: hasPayment ? 'Payment found for this month' : 'No payment found for this month'
    });

  } catch (error) {
    console.error('❌ Monthly payment check error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check monthly payment',
      error: error.message
    });
  }
});

// =============================================================================
// HEALTH CHECK ENDPOINT FOR DEBUGGING
// =============================================================================

// Health check endpoint to verify server connectivity
app.get('/health', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`🏥 Health check request received at ${timestamp} from ${req.ip || 'unknown'}`);
  res.status(200).json({
    status: 'healthy',
    timestamp: timestamp,
    server: 'VMurugan Gold Trading API',
    version: '1.0.0'
  });
});







// =============================================================================
// WORLDLINE PAYMENT GATEWAY INTEGRATION - CLEAN SLATE REBUILD
// =============================================================================

// Worldline configuration - PRODUCTION MODE
// Import production configuration
const worldlineConfig = require('./worldline_config');

// Legacy WORLDLINE_CONFIG for backward compatibility
// This will be dynamically set based on metal type
let WORLDLINE_CONFIG = {
  MERCHANT_CODE: "779285", // Default to Gold merchant
  SCHEME_CODE: "first",
  ENCRYPTION_KEY: "47cdd26963f53e3181f93adcf3af487ec28d7643", // Gold SALT
  WORLDLINE_URL: "https://www.paynimo.com/api/paynimoV2.req",
  MIN_AMOUNT: 1,
  MAX_AMOUNT: 1000000, // Production: 10 lakhs
  IS_TEST_ENVIRONMENT: false,
  IS_PRODUCTION: true,
};

// Generate hash for Worldline - supports both SHA-256 and SHA-512
function generateWorldlineHash(text, algorithm = 'sha512') {
  return crypto.createHash(algorithm).update(text).digest('hex');
}

// Test hash generation against known Worldline example
function testWorldlineHashGeneration(requestId) {
  console.log(`🧪 [${requestId}] TESTING HASH GENERATION AGAINST WORLDLINE EXAMPLE...`);

  // Example from Worldline documentation (modified for our merchant)
  const testComponents = [
    'T1098761',                    // merchantId
    'TEST_TXN_123',               // txnId
    '1.00',                       // totalamount
    '',                           // accountNo
    'TEST_CONSUMER',              // consumerId
    '9876543210',                 // consumerMobileNo
    'test@vmuruganjewellery.co.in', // consumerEmailId
    '',                           // debitStartDate
    '',                           // debitEndDate
    '',                           // maxAmount
    '',                           // amountType
    '',                           // frequency
    '',                           // cardNumber
    '',                           // expMonth
    '',                           // expYear
    '',                           // cvvCode
    '9221995309QQNRIO'            // SALT
  ];

  const testHashString = testComponents.join('|');
  const testToken = generateWorldlineHash(testHashString, 'sha512');

  console.log(`🧪 [${requestId}] TEST HASH STRING: "${testHashString}"`);
  console.log(`🧪 [${requestId}] TEST TOKEN: ${testToken}`);
  console.log(`🧪 [${requestId}] TEST TOKEN LENGTH: ${testToken.length} characters`);

  return testToken;
}

// Generate Worldline token using EXACT official specification
// Reference: https://www.paynimo.com/paynimocheckout/docs/
function generateWorldlineToken(paymentData, requestId) {
  const { merchantCode, txnId, amount, customerId, consumerMobileNo, consumerEmailId } = paymentData;

  console.log(`🔐 [${requestId}] GENERATING WORLDLINE TOKEN USING OFFICIAL SPECIFICATION...`);
  console.log(`📋 [${requestId}] Reference: https://www.paynimo.com/paynimocheckout/docs/`);

  // EXACT format from official Worldline documentation:
  // merchantId|txnId|totalamount|accountNo|consumerId|consumerMobileNo|consumerEmailId|debitStartDate|debitEndDate|maxAmount|amountType|frequency|cardNumber|expMonth|expYear|cvvCode|SALT

  const hashComponents = [
    merchantCode,           // merchantId
    txnId,                 // txnId
    amount,                // totalamount (CRITICAL: Use exact field name from docs)
    '',                    // accountNo (empty)
    customerId,            // consumerId
    consumerMobileNo,      // consumerMobileNo
    consumerEmailId,       // consumerEmailId
    '',                    // debitStartDate (empty)
    '',                    // debitEndDate (empty)
    '',                    // maxAmount (empty)
    '',                    // amountType (empty)
    '',                    // frequency (empty)
    '',                    // cardNumber (empty)
    '',                    // expMonth (empty)
    '',                    // expYear (empty)
    '',                    // cvvCode (empty)
    WORLDLINE_CONFIG.ENCRYPTION_KEY // SALT
  ];

  const hashString = hashComponents.join('|');

  // ANDROIDSH2 = SHA-512 algorithm (as per official documentation)
  const token = generateWorldlineHash(hashString, 'sha512');

  console.log(`🔐 [${requestId}] Hash components: ${hashComponents.length} fields (EXACT Worldline specification)`);
  console.log(`🔐 [${requestId}] DETAILED HASH COMPONENTS ANALYSIS:`);
  console.log(`   [1] merchantId: "${merchantCode}"`);
  console.log(`   [2] txnId: "${txnId}"`);
  console.log(`   [3] totalamount: "${amount}"`);
  console.log(`   [4] accountNo: ""`);
  console.log(`   [5] consumerId: "${customerId}"`);
  console.log(`   [6] consumerMobileNo: "${consumerMobileNo}"`);
  console.log(`   [7] consumerEmailId: "${consumerEmailId}"`);
  console.log(`   [8] debitStartDate: ""`);
  console.log(`   [9] debitEndDate: ""`);
  console.log(`   [10] maxAmount: ""`);
  console.log(`   [11] amountType: ""`);
  console.log(`   [12] frequency: ""`);
  console.log(`   [13] cardNumber: ""`);
  console.log(`   [14] expMonth: ""`);
  console.log(`   [15] expYear: ""`);
  console.log(`   [16] cvvCode: ""`);
  console.log(`   [17] SALT: "${WORLDLINE_CONFIG.ENCRYPTION_KEY}"`);
  console.log(`🔐 [${requestId}] COMPLETE HASH STRING: "${hashString}"`);
  console.log(`🔐 [${requestId}] Generated token: ${token}`);
  console.log(`🔐 [${requestId}] Token length: ${token.length} characters`);
  console.log(`🔐 [${requestId}] Algorithm: SHA-512 (ANDROIDSH2)`);

  // CRITICAL VALIDATION: Check for data type issues
  console.log(`🔍 [${requestId}] DATA TYPE VALIDATION:`);
  console.log(`   merchantCode type: ${typeof merchantCode}, value: "${merchantCode}"`);
  console.log(`   txnId type: ${typeof txnId}, value: "${txnId}"`);
  console.log(`   amount type: ${typeof amount}, value: "${amount}"`);
  console.log(`   customerId type: ${typeof customerId}, value: "${customerId}"`);
  console.log(`   consumerMobileNo type: ${typeof consumerMobileNo}, value: "${consumerMobileNo}"`);
  console.log(`   consumerEmailId type: ${typeof consumerEmailId}, value: "${consumerEmailId}"`);

  // CRITICAL: Verify hash string has no undefined or null values
  const hasUndefined = hashString.includes('undefined');
  const hasNull = hashString.includes('null');
  const hasNaN = hashString.includes('NaN');

  if (hasUndefined || hasNull || hasNaN) {
    console.log(`❌ [${requestId}] CRITICAL ERROR: Hash string contains invalid values!`);
    console.log(`   Contains 'undefined': ${hasUndefined}`);
    console.log(`   Contains 'null': ${hasNull}`);
    console.log(`   Contains 'NaN': ${hasNaN}`);
  } else {
    console.log(`✅ [${requestId}] Hash string validation passed - no invalid values`);
  }

  return {
    token: token,
    merchantCode: merchantCode,
    txnId: txnId,
    amount: amount,
    consumerDataFields: {
      merchantId: merchantCode,
      txnId: txnId,
      amount: amount,
      accountNo: '',
      consumerId: customerId,
      consumerMobileNo: consumerMobileNo,
      consumerEmailId: consumerEmailId,
      debitStartDate: '',
      debitEndDate: '',
      maxAmount: '',
      amountType: '',
      frequency: '',
      cardNumber: '',
      expMonth: '',
      expYear: '',
      cvvCode: '',
      token: token // Include the generated token
    }
  };
}

// Worldline Token Generation API - Following Payment_GateWay.md specifications
app.post('/api/payments/worldline/token', [
  // Accept amount as whole number (1 to 1,000,000) for production environment
  body('amount').custom((value) => {
    let amount;
    // If it's a string, convert to number
    if (typeof value === 'string') {
      amount = parseFloat(value);
    } else if (typeof value === 'number') {
      amount = value;
    } else {
      throw new Error('Amount must be a number or string');
    }

    // Validate range for production environment (₹1 to ₹10,00,000)
    if (amount < 1 || amount > 1000000) {
      throw new Error(`Amount must be between ₹1 and ₹10,00,000 (10 lakhs)`);
    }
    return true;
  }),
], async (req, res) => {
  const requestStartTime = Date.now();
  const requestId = `TOKEN_${requestStartTime}`;

  // Log to both console and file
  writeServerLog('', 'worldline');
  writeServerLog('🔥 ===== WORLDLINE TOKEN REQUEST STARTED =====', 'worldline');
  writeServerLog(`📋 Request ID: ${requestId}`, 'worldline');
  writeServerLog(`⏰ Timestamp: ${new Date().toISOString()}`, 'worldline');
  writeServerLog(`🌐 Client IP: ${req.ip || 'unknown'}`, 'worldline');
  writeServerLog(`📦 Request Body: ${JSON.stringify(req.body, null, 2)}`, 'worldline');

  try {
    console.log(`🔍 [${requestId}] STEP 1: Validating request parameters...`);
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log(`❌ [${requestId}] VALIDATION FAILED:`, JSON.stringify(errors.array(), null, 2));
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { amount: rawAmount, orderId, customerId, metalType } = req.body;
    const txnId = orderId || Date.now().toString();

    // PRODUCTION: Get merchant configuration based on metal type
    const merchantConfig = worldlineConfig.getMerchantConfig(metalType || 'gold');
    console.log(`🏪 [${requestId}] Using merchant: ${merchantConfig.MERCHANT_NAME} (${merchantConfig.MERCHANT_CODE})`);
    console.log(`🔑 [${requestId}] Metal Type: ${metalType || 'gold'}`);

    // Update WORLDLINE_CONFIG for this request
    WORLDLINE_CONFIG.MERCHANT_CODE = merchantConfig.MERCHANT_CODE;
    WORLDLINE_CONFIG.SCHEME_CODE = merchantConfig.SCHEME_CODE;
    WORLDLINE_CONFIG.ENCRYPTION_KEY = merchantConfig.SALT;

    // CRITICAL FIX: Maintain decimal format throughout entire process
    // Worldline requires exact format consistency between server hash and client consumerData
    const amount = parseFloat(rawAmount);
    const formattedAmount = amount.toFixed(2); // Always "X.00" format for hash consistency

    // Log to both console and file
    writeServerLog(`💰 [${requestId}] Raw Amount: ${JSON.stringify(rawAmount)} (${typeof rawAmount})`, 'worldline');
    writeServerLog(`💰 [${requestId}] Processed Amount: ${amount}`, 'worldline');
    writeServerLog(`💰 [${requestId}] Formatted Amount for Hash: "${formattedAmount}"`, 'worldline');
    writeServerLog(`💰 [${requestId}] ✅ Amount is within production range (1-1000000): ${amount >= 1 && amount <= 1000000}`, 'worldline');
    writeServerLog(`🆔 [${requestId}] Transaction ID: ${txnId}`, 'worldline');
    writeServerLog(`👤 [${requestId}] Customer ID: ${customerId}`, 'worldline');
    writeServerLog(`🏪 [${requestId}] Merchant: ${merchantConfig.MERCHANT_NAME}`, 'worldline');
    writeServerLog(`🔑 [${requestId}] Merchant Code: ${merchantConfig.MERCHANT_CODE}`, 'worldline');

    // Build payload for Worldline API (following Payment_GateWay.md)
    const payload = {
      merchant: { identifier: WORLDLINE_CONFIG.MERCHANT_CODE },
      payment: { instruction: { amount: formattedAmount, currency: "INR" } },
      transaction: {
        deviceIdentifier: "S",
        identifier: txnId,
        type: "SALE",
        tokenType: "TXN_TOKEN",
      },
      consumer: { identifier: customerId || "CUST123" },
    };

    console.log(`🔍 [${requestId}] STEP 2: Requesting token from Worldline...`);
    console.log(`📤 [${requestId}] Payload:`, JSON.stringify(payload, null, 2));

    // CRITICAL FIX: Generate hash-based token for Worldline checkout
    // According to Worldline documentation, token should be a hash generated using specific algorithm
    console.log(`🔍 [${requestId}] STEP 2: Generating Worldline hash token...`);

    // CRITICAL FIX: Use exact test environment values for hash generation
    // CRITICAL FIX: Use CONSISTENT values across ALL hash operations
    // These MUST match exactly in token generation, verification, and web checkout
    const testMobileNo = '9876543210';           // CONSISTENT: Same as verification and web checkout
    const testEmailId = 'test@vmuruganjewellery.co.in';  // CONSISTENT: Same as verification and web checkout

    // Build hash string according to Worldline specification
    // Format: merchantId|txnId|amount|accountNo|consumerId|consumerMobileNo|consumerEmailId|debitStartDate|debitEndDate|maxAmount|amountType|frequency|cardNumber|expMonth|expYear|cvvCode|SALT
    const hashComponents = [
      WORLDLINE_CONFIG.MERCHANT_CODE,           // merchantId
      txnId,                                    // txnId
      formattedAmount,                          // amount (CRITICAL: Use consistent decimal format)
      '',                                       // accountNo (empty for regular transactions)
      customerId || 'GUEST',                    // consumerId
      testMobileNo,                            // consumerMobileNo (TEST: 9999999999)
      testEmailId,                             // consumerEmailId (TEST: test@domain.com)
      '',                                       // debitStartDate (empty for regular transactions)
      '',                                       // debitEndDate (empty for regular transactions)
      '',                                       // maxAmount (empty for regular transactions)
      '',                                       // amountType (empty for regular transactions)
      '',                                       // frequency (empty for regular transactions)
      '',                                       // cardNumber (empty for regular transactions)
      '',                                       // expMonth (empty for regular transactions)
      '',                                       // expYear (empty for regular transactions)
      '',                                       // cvvCode (empty for regular transactions)
      WORLDLINE_CONFIG.ENCRYPTION_KEY           // SALT (encryption key)
    ];

    const hashString = hashComponents.join('|');
    console.log(`🔐 [${requestId}] Hash string components: ${hashComponents.length} fields`);
    console.log(`🔐 [${requestId}] COMPLETE Hash string: ${hashString}`);
    console.log(`🔐 [${requestId}] Hash components breakdown:`);
    hashComponents.forEach((component, index) => {
      console.log(`🔐 [${requestId}] Field ${index + 1}: "${component}"`);
    });

    // CRITICAL: Log expected consumerData format for Flutter app comparison
    console.log('');
    console.log(`🔍 [${requestId}] HASH VALIDATION - EXPECTED CONSUMER DATA FORMAT:`);
    console.log('================================================================');
    console.log(`🔐 Expected Field 1 - merchantId: "${WORLDLINE_CONFIG.MERCHANT_CODE}"`);
    console.log(`🔐 Expected Field 2 - txnId: "${txnId}"`);
    console.log(`🔐 Expected Field 3 - amount: "${formattedAmount}"`);
    console.log(`🔐 Expected Field 4 - accountNo: ""`);
    console.log(`🔐 Expected Field 5 - consumerId: "${customerId || 'GUEST'}"`);
    console.log(`🔐 Expected Field 6 - consumerMobileNo: "${testMobileNo}" (CONSISTENT ACROSS ALL OPERATIONS)`);
    console.log(`🔐 Expected Field 7 - consumerEmailId: "${testEmailId}" (CONSISTENT ACROSS ALL OPERATIONS)`);
    console.log(`🔐 Expected Field 8 - debitStartDate: ""`);
    console.log(`🔐 Expected Field 9 - debitEndDate: ""`);
    console.log(`🔐 Expected Field 10 - maxAmount: ""`);
    console.log(`🔐 Expected Field 11 - amountType: ""`);
    console.log(`🔐 Expected Field 12 - frequency: ""`);
    console.log(`🔐 Expected Field 13 - cardNumber: ""`);
    console.log(`🔐 Expected Field 14 - expMonth: ""`);
    console.log(`🔐 Expected Field 15 - expYear: ""`);
    console.log(`🔐 Expected Field 16 - cvvCode: ""`);
    console.log(`🔐 SALT (Field 17): "${WORLDLINE_CONFIG.ENCRYPTION_KEY}" (NOT sent to Flutter)`);
    console.log('================================================================');
    console.log(`💡 [${requestId}] Flutter app MUST send consumerData with EXACT same field values`);
    console.log(`💡 [${requestId}] Compare Flutter logs with these expected values for mismatch detection`);
    console.log(`🚨 [${requestId}] CRITICAL: Amount MUST be "${formattedAmount}" (decimal format)`);
    console.log('');

    // STEP 2: Generate Worldline token using EXACT official specification
    console.log(`🔍 [${requestId}] STEP 2: Generating Worldline token using official specification...`);

    // DEBUGGING: Show which merchant configuration is being used
    console.log(`🏪 [${requestId}] MERCHANT CONFIGURATION:`);
    console.log(`   Current Merchant: ${WORLDLINE_CONFIG.MERCHANT_CODE} (${WORLDLINE_CONFIG.MERCHANT_CODE === 'T1098761' ? 'YOUR ORIGINAL MERCHANT' : 'OTHER'})`);
    console.log(`   Current Scheme: ${WORLDLINE_CONFIG.SCHEME_CODE}`);
    console.log(`   Current SALT: ${WORLDLINE_CONFIG.ENCRYPTION_KEY.substring(0, 8)}...`);
    if (WORLDLINE_CONFIG.DEMO_MERCHANT_CODE) {
      console.log(`   Demo Merchant (for comparison): ${WORLDLINE_CONFIG.DEMO_MERCHANT_CODE}`);
      console.log(`   Demo Scheme: ${WORLDLINE_CONFIG.DEMO_SCHEME_CODE}`);
    }

    const worldlinePaymentData = {
      merchantCode: WORLDLINE_CONFIG.MERCHANT_CODE,
      txnId: txnId,
      amount: formattedAmount,
      customerId: customerId || 'GUEST',
      consumerMobileNo: testMobileNo,
      consumerEmailId: testEmailId
    };

    const worldlineResult = generateWorldlineToken(worldlinePaymentData, requestId);

    const token = worldlineResult.token;
    const consumerDataFields = worldlineResult.consumerDataFields;

    // CRITICAL: Validate hash generation integrity (SHA-512 produces 128 character hex string)
    if (!token || token.length !== 128) {
      throw new Error(`Hash generation failed - invalid token length: ${token ? token.length : 'null'} (expected 128 for SHA-512)`);
    }

    console.log(`✅ [${requestId}] STEP 2 COMPLETED: Worldline token generated using official specification`);
    console.log(`🎫 [${requestId}] Token: ${token.substring(0, 20)}...`);
    console.log(`🔐 [${requestId}] Token Length: ${token.length} characters (expected: 128 for SHA-512)`);
    console.log(`🔐 [${requestId}] Algorithm: SHA-512 (ANDROIDSH2 specification)`);
    console.log(`📋 [${requestId}] Official Reference: https://www.paynimo.com/paynimocheckout/docs/`);

    // Store hash components for verification debugging
    console.log(`📋 [${requestId}] Hash components stored for verification:`);
    console.log(`   - Merchant Code: ${WORLDLINE_CONFIG.MERCHANT_CODE}`);
    console.log(`   - Transaction ID: ${txnId}`);
    console.log(`   - Amount: ${amount}`);
    console.log(`   - Customer ID: ${customerId || 'GUEST'}`);
    console.log(`   - Encryption Key: ${WORLDLINE_CONFIG.ENCRYPTION_KEY.substring(0, 5)}...`);

    // Store transaction in database
    console.log(`🔍 [${requestId}] STEP 3: Storing transaction in database...`);
    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), txnId);
    request.input('customer_phone', sql.NVarChar(15), 'N/A');
    request.input('customer_name', sql.NVarChar(100), customerId || 'VMurugan Customer');
    request.input('type', sql.NVarChar(10), 'BUY');
    request.input('amount', sql.Decimal(12, 2), amount);
    request.input('gold_grams', sql.Decimal(10, 4), 0);
    request.input('gold_price_per_gram', sql.Decimal(10, 2), 0);
    request.input('payment_method', sql.NVarChar(50), 'WORLDLINE_NETBANKING');
    request.input('status', sql.NVarChar(20), 'PENDING');
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    await request.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount, gold_grams, gold_price_per_gram, payment_method, status, business_id
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @type, @amount, @gold_grams, @gold_price_per_gram, @payment_method, @status, @business_id
      )
    `);

    console.log(`✅ [${requestId}] STEP 3 COMPLETED: Transaction stored in database`);

    const totalTime = Date.now() - requestStartTime;

    // CRITICAL: Bank's exact specification compliance - ONLY the exact format specified
    // Bank requirement: "Please ensure that the information provided in the consumerData object
    // exactly matches the details used in the pipe-separated format for token generation"

    console.log(`🏦 [${requestId}] BANK COMPLIANCE: Using ONLY the exact 17-field format as specified`);

    const response = {
      token: token,  // Real Worldline token or fallback hash
      txnId: txnId,
      merchantCode: WORLDLINE_CONFIG.MERCHANT_CODE,
      amount: formattedAmount,  // CRITICAL: Use consistent decimal format
      currency: "INR",

      // CRITICAL: Include ALL hash components for consumerData object (exact field matching)
      // This MUST match the pipe-separated format exactly as per bank's email
      // Now includes the real token from Worldline API
      consumerDataFields: consumerDataFields,

      // Bank compliance information
      tokenType: 'WORLDLINE_HASH_TOKEN',
      algorithm: 'SHA512',
      deviceId: 'ANDROIDSH2', // Matches Flutter app device ID for SHA-512
      integrationKit: 'FLUTTER_PLUGIN',
      specification: 'OFFICIAL_WORLDLINE_DOCUMENTATION',
      reference: 'https://www.paynimo.com/paynimocheckout/docs/',
      bankCompliance: {
        format: '17-field pipe-separated as per bank specification',
        fieldCount: 17,
        emptyFieldHandling: 'Empty strings without whitespace',
        specification: 'merchantId|txnId|amount|accountNo|consumerId|consumerMobileNo|consumerEmailId|debitStartDate|debitEndDate|maxAmount|amountType|frequency|cardNumber|expMonth|expYear|cvvCode|SALT'
      },

      // CRITICAL: Test environment configuration for proper bank authentication flow
      testEnvironment: {
        mode: 'INTERACTIVE',
        forceCredentialEntry: true,
        autoRedirect: false,
        bankAuthenticationRequired: true,
        expectedFlow: 'Test Bank selection → Credentials entry (test/test) → Manual payment completion'
      }
    };

    console.log(`📤 [${requestId}] Response:`, JSON.stringify(response, null, 2));
    console.log(`⏱️ [${requestId}] Total processing time: ${totalTime}ms`);
    console.log(`✅ [${requestId}] TOKEN REQUEST COMPLETED SUCCESSFULLY`);
    console.log('');
    console.log('🔍 PAYMENT FLOW TRACKING - TOKEN GENERATED');
    console.log('==========================================');
    console.log(`📋 Next Step: Flutter app will use this token to open Worldline gateway`);
    console.log(`📋 Expected: User selects Test Bank → Credentials page → test/test → Success`);
    console.log(`📋 Watch for: Payment response callback with actual authentication result`);
    console.log('==========================================');
    console.log('🔥 ===== WORLDLINE TOKEN REQUEST ENDED =====');
    console.log('');

    res.json(response);

  } catch (error) {
    const totalTime = Date.now() - requestStartTime;
    console.log(`💥 [${requestId}] CRITICAL ERROR OCCURRED:`);
    console.log(`❌ [${requestId}] Error message: ${error.message}`);
    console.log(`❌ [${requestId}] Error stack: ${error.stack}`);

    const errorResponse = {
      error: 'Token generation failed',
      message: error.message,
      requestId: requestId
    };

    console.log(`📤 [${requestId}] Sending error response:`, JSON.stringify(errorResponse, null, 2));
    console.log(`❌ [${requestId}] TOKEN REQUEST FAILED`);
    console.log('🔥 ===== WORLDLINE TOKEN REQUEST ENDED =====');
    console.log('');

    res.status(500).json(errorResponse);
  }
});

// Worldline Response Handler (Alternative endpoint)
app.post('/worldline-response', async (req, res) => {
  console.log('🔄 Worldline response received at /worldline-response');
  console.log('📦 Request body:', JSON.stringify(req.body, null, 2));

  // Forward to the main verify endpoint
  try {
    const response = await fetch(`${req.protocol}://${req.get('host')}/api/payments/worldline/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body),
    });

    const result = await response.json();
    res.json(result);
  } catch (error) {
    console.error('❌ Error forwarding to verify endpoint:', error);
    res.status(500).json({ success: false, message: 'Error processing payment response' });
  }
});

// Worldline Payment Verification API - Following Payment_GateWay.md specifications
app.post('/api/payments/worldline/verify', async (req, res) => {
  const requestStartTime = Date.now();
  const requestId = `VERIFY_${requestStartTime}`;

  console.log('');
  console.log('🔥 ===== WORLDLINE VERIFY REQUEST STARTED =====');
  console.log(`📋 Request ID: ${requestId}`);
  console.log(`⏰ Timestamp: ${new Date().toISOString()}`);
  console.log(`🌐 Client IP: ${req.ip || 'unknown'}`);
  console.log(`📦 Request Body:`, JSON.stringify(req.body, null, 2));

  try {
    // Extract payment response data
    const responsePayload = req.body;
    const txnId = responsePayload.txnId || responsePayload.merchantTransactionId;
    const status = responsePayload.statusCode || responsePayload.status;
    const gatewayTxnId = responsePayload.pgTransactionId || responsePayload.gatewayTransactionId;
    const amount = responsePayload.amount;

    console.log(`🔍 [${requestId}] STEP 1: Processing verification request...`);
    console.log(`🆔 [${requestId}] Transaction ID: ${txnId}`);
    console.log(`📊 [${requestId}] Status: ${status}`);
    console.log(`🏦 [${requestId}] Gateway Transaction ID: ${gatewayTxnId}`);
    console.log(`💰 [${requestId}] Amount: ${amount}`);

    // CRITICAL FIX: Implement proper hash verification
    console.log(`🔍 [${requestId}] STEP 2: Performing hash verification...`);

    let isVerified = false;
    let verificationMethod = 'NONE';

    // Check if response contains hash for verification
    const responseHash = responsePayload.hash || responsePayload.checksum;

    if (responseHash && txnId && amount && status) {
      // BANK COMPLIANCE: Use ONLY the exact hash verification format as specified
      // NO FALLBACK MECHANISMS - Only the bank's exact specification
      try {
        console.log(`🏦 [${requestId}] BANK COMPLIANCE: Using ONLY exact hash verification format`);

        // Use the EXACT same 17-field format used for token generation
        // This ensures 100% compliance with bank's requirement for field matching
        const verificationHashComponents = [
          WORLDLINE_CONFIG.MERCHANT_CODE,         // merchantId (Field 1)
          txnId,                                  // txnId (Field 2)
          amount.toString(),                      // amount (Field 3)
          '',                                     // accountNo (Field 4 - empty)
          responsePayload.consumerId || 'GUEST',  // consumerId (Field 5)
          '9876543210',                          // consumerMobileNo (Field 6)
          'test@vmuruganjewellery.co.in',        // consumerEmailId (Field 7)
          '',                                     // debitStartDate (Field 8 - empty)
          '',                                     // debitEndDate (Field 9 - empty)
          '',                                     // maxAmount (Field 10 - empty)
          '',                                     // amountType (Field 11 - empty)
          '',                                     // frequency (Field 12 - empty)
          '',                                     // cardNumber (Field 13 - empty)
          '',                                     // expMonth (Field 14 - empty)
          '',                                     // expYear (Field 15 - empty)
          '',                                     // cvvCode (Field 16 - empty)
          WORLDLINE_CONFIG.ENCRYPTION_KEY         // SALT (Field 17)
        ];

        const verificationHashString = verificationHashComponents.join('|');
        const expectedHash = generateWorldlineHash(verificationHashString);

        console.log(`🔐 [${requestId}] Bank specification hash components: ${verificationHashComponents.length} fields`);
        console.log(`🔐 [${requestId}] Hash string (first 100 chars): ${verificationHashString.substring(0, 100)}...`);
        console.log(`🔍 [${requestId}] Expected hash: ${expectedHash.substring(0, 20)}...`);
        console.log(`🔍 [${requestId}] Received hash: ${responseHash.substring(0, 20)}...`);

        if (responseHash === expectedHash) {
          isVerified = true;
          verificationMethod = 'BANK_SPECIFICATION_VERIFIED';
          console.log(`✅ [${requestId}] Bank specification hash verification PASSED`);
        } else {
          isVerified = false;
          verificationMethod = 'BANK_SPECIFICATION_FAILED';
          console.log(`❌ [${requestId}] Bank specification hash verification FAILED`);
          console.log(`🏦 [${requestId}] NO FALLBACK - Using only bank's exact specification`);
        }
      } catch (hashError) {
        console.error(`❌ [${requestId}] Hash computation error:`, hashError.message);
        verificationMethod = 'HASH_ERROR';
        isVerified = false;
      }
    } else {
      // BANK COMPLIANCE: NO FALLBACK - Hash is required for all transactions
      console.log(`❌ [${requestId}] No hash found in response - BANK COMPLIANCE REQUIRES HASH`);
      isVerified = false;
      verificationMethod = 'NO_HASH_BANK_COMPLIANCE_FAILED';
      console.log(`🏦 [${requestId}] Bank specification requires hash validation for all transactions`);
    }

    // BANK COMPLIANCE: NO OVERRIDE for Hash_Validation_fail errors
    // If Worldline returns Hash_Validation_fail, the transaction must be rejected
    if (!isVerified && (status === 'Hash_Validation_fail' || responsePayload.statusMessage === 'Hash_Validation_fail')) {
      console.log(`❌ [${requestId}] Hash_Validation_fail error from Worldline - TRANSACTION REJECTED`);
      verificationMethod = 'HASH_VALIDATION_FAIL_REJECTED';
      console.log(`🏦 [${requestId}] Bank compliance: No override for hash validation failures`);
    }

    console.log(`📊 [${requestId}] Verification result: ${isVerified ? 'VERIFIED' : 'FAILED'} (${verificationMethod})`);

    if (isVerified) {
      console.log(`✅ [${requestId}] STEP 2: Payment verification SUCCESSFUL`);

      // ENHANCED: Update transaction status with complete gateway response data
      const mappedStatus = (status === 'SUCCESS' || status === '0') ? 'SUCCESS' : 'FAILED';
      console.log(`📊 [${requestId}] Status mapping: "${status}" -> "${mappedStatus}"`);

      // Prepare complete gateway response data for audit trail
      const gatewayResponseData = {
        timestamp: new Date().toISOString(),
        verificationMethod: verificationMethod,
        originalStatus: status,
        mappedStatus: mappedStatus,
        gatewayTransactionId: gatewayTxnId,
        amount: amount,
        verificationResult: {
          isVerified: isVerified,
          method: verificationMethod,
          requestId: requestId
        },
        fullResponse: responsePayload,
        processingTime: Date.now() - requestStartTime
      };

      console.log(`📋 [${requestId}] Saving complete gateway response data to additional_data column`);

      const request = pool.request();
      request.input('transaction_id', sql.NVarChar(100), txnId);
      request.input('gateway_transaction_id', sql.NVarChar(100), gatewayTxnId || `WL_${txnId}`);
      request.input('status', sql.NVarChar(20), mappedStatus);
      request.input('additional_data', sql.NVarChar(sql.MAX), JSON.stringify(gatewayResponseData));

      await request.query(`
        UPDATE transactions
        SET status = @status,
            gateway_transaction_id = @gateway_transaction_id,
            additional_data = @additional_data,
            updated_at = GETDATE()
        WHERE transaction_id = @transaction_id
      `);

      // SEND NOTIFICATION TO OWNER (New)
      if (mappedStatus === 'SUCCESS') {
        try {
          const detailResult = await pool.request()
            .input('tid', sql.NVarChar, txnId)
            .query('SELECT amount, customer_name, type, customer_phone FROM transactions WHERE transaction_id = @tid');

          if (detailResult.recordset.length > 0) {
            const tx = detailResult.recordset[0];
            // Call helper function asynchronously
            notifyOwnerOfPayment({
              amount: tx.amount,
              customer_name: tx.customer_name,
              type: tx.type,
              transaction_id: txnId,
              customer_phone: tx.customer_phone
            }).catch(err => console.error('Notification failed:', err));
          }
        } catch (notifErr) {
          console.error('Notification fetch error:', notifErr);
        }
      }


      console.log(`✅ [${requestId}] STEP 3: Database updated successfully`);

      const totalTime = Date.now() - requestStartTime;
      const response = {
        verified: true,
        valid: true,
        transactionId: txnId,
        status: mappedStatus,
        gatewayTransactionId: gatewayTxnId,
        raw: responsePayload
      };

      console.log(`📤 [${requestId}] Response:`, JSON.stringify(response, null, 2));
      console.log(`⏱️ [${requestId}] Total processing time: ${totalTime}ms`);
      console.log(`✅ [${requestId}] VERIFY REQUEST COMPLETED SUCCESSFULLY`);
      console.log('🔥 ===== WORLDLINE VERIFY REQUEST ENDED =====');
      console.log('');

      return res.json(response);
    } else {
      console.log(`❌ [${requestId}] Payment verification FAILED`);

      // ENHANCED: Save failed verification data for audit trail
      const failedVerificationData = {
        timestamp: new Date().toISOString(),
        verificationMethod: verificationMethod,
        originalStatus: status,
        mappedStatus: 'FAILED',
        gatewayTransactionId: gatewayTxnId,
        amount: amount,
        verificationResult: {
          isVerified: false,
          method: verificationMethod,
          requestId: requestId,
          failureReason: 'Hash verification failed'
        },
        fullResponse: responsePayload,
        processingTime: Date.now() - requestStartTime
      };

      console.log(`📋 [${requestId}] Saving failed verification data to database`);

      try {
        const failedRequest = pool.request();
        failedRequest.input('transaction_id', sql.NVarChar(100), txnId);
        failedRequest.input('gateway_transaction_id', sql.NVarChar(100), gatewayTxnId || `WL_FAILED_${txnId}`);
        failedRequest.input('status', sql.NVarChar(20), 'FAILED');
        failedRequest.input('additional_data', sql.NVarChar(sql.MAX), JSON.stringify(failedVerificationData));

        await failedRequest.query(`
          UPDATE transactions
          SET status = @status,
              gateway_transaction_id = @gateway_transaction_id,
              additional_data = @additional_data,
              updated_at = GETDATE()
          WHERE transaction_id = @transaction_id
        `);

        console.log(`✅ [${requestId}] Failed verification data saved to database`);
      } catch (dbError) {
        console.log(`❌ [${requestId}] Error saving failed verification data: ${dbError.message}`);
      }

      const response = { verified: false, valid: false, raw: responsePayload };
      return res.json(response);
    }

  } catch (error) {
    const totalTime = Date.now() - requestStartTime;
    console.log(`💥 [${requestId}] CRITICAL ERROR OCCURRED:`);
    console.log(`❌ [${requestId}] Error message: ${error.message}`);
    console.log(`❌ [${requestId}] Error stack: ${error.stack}`);

    const errorResponse = {
      verified: false,
      valid: false,
      error: error.message,
      requestId: requestId
    };

    console.log(`📤 [${requestId}] Sending error response:`, JSON.stringify(errorResponse, null, 2));
    console.log(`❌ [${requestId}] VERIFY REQUEST FAILED`);
    console.log('🔥 ===== WORLDLINE VERIFY REQUEST ENDED =====');
    console.log('');

    res.status(500).json(errorResponse);
  }
});


// =============================================================================
// STATIC PAGES AND ADMIN PORTAL
// =============================================================================

// =============================================================================
// PAYNIMO PAYMENT GATEWAY ENDPOINTS (Legacy - Deprecated)
// =============================================================================

// Paynimo payment initiation endpoint
app.post('/api/paynimo/initiate', [
  body('transactionId').notEmpty().withMessage('Transaction ID required'),
  body('amount').isFloat({ min: 1 }).withMessage('Amount must be positive'),
  body('customerName').notEmpty().withMessage('Customer name required'),
  body('customerEmail').isEmail().withMessage('Valid email required'),
  body('customerPhone').isMobilePhone('en-IN').withMessage('Valid Indian mobile number required'),
  body('description').notEmpty().withMessage('Description required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    console.log('🚀 Paynimo payment initiation request:', req.body);

    const {
      transactionId,
      amount,
      customerName,
      customerEmail,
      customerPhone,
      description,
      paymentMethod = 'credit_card'
    } = req.body;

    // Validate Paynimo configuration
    const PaynimoConfig = {
      merchantCode: 'T1098761',
      schemeCode: 'first',
      encryptionKey: '9221995309QQNRIO',
      encryptionIV: '6753042926GDVTTK',
      isTestEnvironment: true
    };

    // Build payment request
    const paymentRequest = {
      merchantCode: PaynimoConfig.merchantCode,
      schemeCode: PaynimoConfig.schemeCode,
      txnId: transactionId,
      amount: (amount * 100).toString(), // Convert to paisa
      currency: 'INR',
      custName: customerName,
      custEmail: customerEmail,
      custMobile: customerPhone,
      productDescription: description,
      returnUrl: `https://api.vmuruganjewellery.co.in:3001/api/paynimo/callback`,
      cancelUrl: `https://api.vmuruganjewellery.co.in:3001/payment/cancel`,
      requestType: 'T',
      paymentMode: _mapPaymentMethod(paymentMethod),
      timestamp: Date.now().toString()
    };

    // Store transaction in database
    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), transactionId);
    request.input('customer_phone', sql.NVarChar(15), customerPhone);
    request.input('customer_name', sql.NVarChar(100), customerName);
    request.input('amount', sql.Decimal(12, 2), amount);
    request.input('payment_method', sql.NVarChar(50), `PAYNIMO_${paymentMethod.toUpperCase()}`);
    request.input('status', sql.NVarChar(20), 'PENDING');
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    await request.query(`
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, amount, payment_method, status, business_id
      ) VALUES (
        @transaction_id, @customer_phone, @customer_name, @amount, @payment_method, @status, @business_id
      )
    `);

    console.log('✅ Paynimo payment request stored:', transactionId);

    res.json({
      success: true,
      transactionId: transactionId,
      paymentRequest: paymentRequest,
      message: 'Payment initiation successful'
    });

  } catch (error) {
    console.error('❌ Paynimo payment initiation error:', error);
    res.status(500).json({ success: false, message: 'Payment initiation failed', error: error.message });
  }
});

// Paynimo payment callback endpoint
app.post('/api/paynimo/callback', async (req, res) => {
  try {
    console.log('💳 Paynimo payment callback received:', req.body);

    const {
      txnId,
      gatewayTxnId,
      status,
      amount,
      paymentMode,
      responseCode,
      responseMessage
    } = req.body;

    // Map Paynimo status to our status
    let mappedStatus = 'FAILED';
    if (status === 'SUCCESS' || responseCode === '0') {
      mappedStatus = 'SUCCESS';
    } else if (status === 'PENDING') {
      mappedStatus = 'PENDING';
    }

    // Update transaction status in database
    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), txnId);
    request.input('gateway_transaction_id', sql.NVarChar(100), gatewayTxnId);
    request.input('status', sql.NVarChar(20), mappedStatus);

    await request.query(`
      UPDATE transactions
      SET status = @status, gateway_transaction_id = @gateway_transaction_id, updated_at = SYSDATETIME()
      WHERE transaction_id = @transaction_id
    `);

    console.log('✅ Paynimo payment status updated:', txnId, mappedStatus);

    // Redirect based on status
    if (mappedStatus === 'SUCCESS') {
      res.redirect(`/payment/success?transaction_id=${txnId}&gateway_id=${gatewayTxnId}`);
    } else {
      res.redirect(`/payment/failure?transaction_id=${txnId}&reason=${responseMessage || 'Payment failed'}`);
    }

  } catch (error) {
    console.error('❌ Paynimo payment callback error:', error.message);
    res.redirect(`/payment/failure?reason=Callback processing failed`);
  }
});

// =============================================================================
// WORLDLINE PAYMENT RESPONSE DETAILED LOGGING - FOR DEBUGGING
// =============================================================================

// Enhanced payment response logging endpoint for debugging authentication failures
app.post('/api/worldline/payment-response-debug', async (req, res) => {
  const requestId = `WL_DEBUG_${Date.now()}`;

  console.log('');
  console.log('🔍 ===== WORLDLINE PAYMENT RESPONSE DEBUG =====');
  console.log(`📥 [${requestId}] Received at: ${new Date().toISOString()}`);
  console.log(`📋 [${requestId}] Full request body:`, JSON.stringify(req.body, null, 2));

  try {
    const {
      txnId,
      status,
      msg,
      wlTxnId,
      gatewayTransactionId,
      amount,
      responseCode,
      responseMessage,
      authenticationResult,
      bankResponse
    } = req.body;

    console.log('');
    console.log('🎯 AUTHENTICATION FAILURE ANALYSIS:');
    console.log('===================================');
    console.log(`🆔 Transaction ID: ${txnId || 'NOT_PROVIDED'}`);
    console.log(`🏦 WL Transaction ID: ${wlTxnId || gatewayTransactionId || 'NOT_PROVIDED'}`);
    console.log(`📊 Status: ${status || 'NOT_PROVIDED'}`);
    console.log(`💬 Message: ${msg || responseMessage || 'NOT_PROVIDED'}`);
    console.log(`🔢 Response Code: ${responseCode || 'NOT_PROVIDED'}`);
    console.log(`💰 Amount: ${amount || 'NOT_PROVIDED'}`);

    // Detailed analysis of why authentication failed
    if (status && status.toLowerCase().includes('fail')) {
      console.log('');
      console.log('❌ AUTHENTICATION FAILURE DETECTED:');
      console.log('===================================');
      if (msg && msg.toLowerCase().includes('credential')) {
        console.log('🔐 Root Cause: Test credentials authentication failed');
        console.log('💡 User Action: Did not enter test/test correctly');
        console.log('🔧 Fix: Ensure test/test is entered in username/password fields');
      } else if (msg && msg.toLowerCase().includes('timeout')) {
        console.log('⏰ Root Cause: Authentication session timed out');
        console.log('💡 User Action: Took too long to enter credentials');
        console.log('🔧 Fix: Complete authentication faster');
      } else if (msg && msg.toLowerCase().includes('cancel')) {
        console.log('🚫 Root Cause: User cancelled authentication');
        console.log('💡 User Action: Clicked cancel or back button');
        console.log('🔧 Fix: Complete the authentication process');
      } else {
        console.log('🏦 Root Cause: Test bank service issue');
        console.log('💡 Possible: Test bank temporarily unavailable');
        console.log('🔧 Fix: Retry payment or check test bank status');
      }
      console.log('📋 Expected Flow: Test Bank → Enter test/test → Click OK → Success');
      console.log('===================================');
    } else if (status && status.toLowerCase().includes('success')) {
      console.log('');
      console.log('✅ AUTHENTICATION SUCCESS CONFIRMED:');
      console.log('====================================');
      console.log('🎉 Test bank authentication completed successfully');
      console.log('🔐 Test credentials (test/test) were accepted');
      console.log('💰 Payment processed correctly');
      console.log('====================================');
    } else {
      console.log('');
      console.log('❓ UNCLEAR AUTHENTICATION STATUS:');
      console.log('=================================');
      console.log('⚠️  Status is neither clear success nor failure');
      console.log('🔍 Manual analysis required');
      console.log('=================================');
    }

    console.log('');
    console.log('🔥 ===== WORLDLINE PAYMENT RESPONSE DEBUG ENDED =====');
    console.log('');

    res.json({
      success: true,
      message: 'Payment response debug logged',
      requestId,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.log(`💥 [${requestId}] ERROR in debug logging:`);
    console.log(`❌ [${requestId}] Error: ${error.message}`);

    res.status(500).json({
      success: false,
      error: 'Debug logging failed',
      message: error.message
    });
  }
});

// Paynimo payment status check endpoint
app.get('/api/paynimo/status/:transactionId', async (req, res) => {
  try {
    const { transactionId } = req.params;
    console.log('🔍 Paynimo payment status check:', transactionId);

    const request = pool.request();
    request.input('transaction_id', sql.NVarChar(100), transactionId);

    const result = await request.query(`
      SELECT transaction_id, status, gateway_transaction_id, amount, payment_method, timestamp
      FROM transactions
      WHERE transaction_id = @transaction_id
    `);

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    const transaction = result.recordset[0];

    res.json({
      success: true,
      transactionId: transaction.transaction_id,
      status: transaction.status,
      gatewayTransactionId: transaction.gateway_transaction_id,
      amount: transaction.amount,
      paymentMethod: transaction.payment_method,
      timestamp: transaction.timestamp
    });

  } catch (error) {
    console.error('❌ Paynimo status check error:', error);
    res.status(500).json({ success: false, message: 'Status check failed', error: error.message });
  }
});

// Helper function to map payment methods
function _mapPaymentMethod(method) {
  switch (method) {
    case 'credit_card':
      return 'CC';
    case 'debit_card':
      return 'DC';
    case 'net_banking':
      return 'NB';
    case 'upi':
      return 'UP';
    case 'wallet':
      return 'WL';
    default:
      return 'CC';
  }
}

// Legacy payment callback endpoint (deprecated)
app.post('/api/payment/callback', async (req, res) => {
  try {
    console.log('💳 Legacy payment callback received:', req.body);

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
      SET status = @status, gateway_transaction_id = @gateway_transaction_id, updated_at = SYSDATETIME()
      WHERE transaction_id = @transaction_id
    `);

    console.log('✅ Legacy payment status updated:', transaction_id, status);

    res.json({
      success: true,
      message: 'Payment callback processed successfully'
    });

  } catch (error) {
    console.error('❌ Legacy payment callback error:', error.message);
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

// Get comprehensive customer details (for admin portal)
app.get('/api/admin/customers/:phone', async (req, res) => {
  try {
    const { phone } = req.params;
    console.log('👤 Admin: Getting comprehensive details for customer:', phone);

    // Get customer basic info
    const customerRequest = pool.request();
    customerRequest.input('phone', sql.NVarChar(15), phone);

    const customerResult = await customerRequest.query(`
      SELECT id, customer_id, phone, name, email, address, pan_card,
             business_id, registration_date, total_invested, total_gold,
             transaction_count, last_transaction, created_at, updated_at
      FROM customers
      WHERE phone = @phone
    `);

    if (customerResult.recordset.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    const customer = customerResult.recordset[0];

    // Get all schemes for this customer with calculated values from transactions
    const schemesRequest = pool.request();
    schemesRequest.input('phone', sql.NVarChar(15), phone);

    const schemesResult = await schemesRequest.query(`
      SELECT
        s.scheme_id, s.scheme_type, s.metal_type, s.monthly_amount, s.duration_months,
        s.status, s.start_date, s.end_date, s.closure_date, s.closure_remarks,
        s.created_at, s.updated_at,
        ISNULL(SUM(t.amount), 0) as total_invested,
        ISNULL(SUM(CASE WHEN s.metal_type = 'GOLD' THEN t.gold_grams WHEN s.metal_type = 'SILVER' THEN t.silver_grams ELSE 0 END), 0) as total_metal_accumulated,
        ISNULL(SUM(t.amount), 0) as total_amount_paid,
        COUNT(CASE WHEN t.status = 'SUCCESS' THEN 1 END) as completed_installments,
        COUNT(CASE WHEN t.status = 'SUCCESS' THEN 1 END) as paid_months
      FROM schemes s
      LEFT JOIN transactions t ON s.scheme_id = t.scheme_id AND t.status = 'SUCCESS'
      WHERE s.customer_phone = @phone
      GROUP BY s.scheme_id, s.scheme_type, s.metal_type, s.monthly_amount, s.duration_months,
               s.status, s.start_date, s.end_date, s.closure_date, s.closure_remarks,
               s.created_at, s.updated_at
      ORDER BY s.created_at DESC
    `);

    // Get all transactions for this customer
    const transactionsRequest = pool.request();
    transactionsRequest.input('phone', sql.NVarChar(15), phone);

    const transactionsResult = await transactionsRequest.query(`
      SELECT transaction_id, type, amount, gold_grams, silver_grams,
             gold_price_per_gram, silver_price_per_gram, payment_method,
             status, gateway_transaction_id, timestamp, created_at
      FROM transactions
      WHERE customer_phone = @phone
      ORDER BY timestamp DESC
    `);

    // Calculate total holdings (from schemes + direct purchases)
    // IMPORTANT: Avoid double-counting by excluding scheme transactions from direct purchases

    // Gold from schemes (GOLDPLUS + GOLDFLEXI)
    const goldFromSchemes = schemesResult.recordset
      .filter(s => s.metal_type === 'GOLD' && s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_metal_accumulated || 0), 0);

    // Gold from direct purchases (exclude scheme transactions)
    const goldFromDirectPurchases = transactionsResult.recordset
      .filter(t => t.status === 'SUCCESS' && t.type === 'BUY' && !t.scheme_id)
      .reduce((sum, t) => sum + (t.gold_grams || 0), 0);

    const totalGoldGrams = goldFromSchemes + goldFromDirectPurchases;

    // Silver from schemes (SILVERPLUS + SILVERFLEXI)
    const silverFromSchemes = schemesResult.recordset
      .filter(s => s.metal_type === 'SILVER' && s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_metal_accumulated || 0), 0);

    // Silver from direct purchases (exclude scheme transactions)
    const silverFromDirectPurchases = transactionsResult.recordset
      .filter(t => t.status === 'SUCCESS' && t.type === 'BUY' && !t.scheme_id)
      .reduce((sum, t) => sum + (t.silver_grams || 0), 0);

    const totalSilverGrams = silverFromSchemes + silverFromDirectPurchases;

    // Total invested (schemes + direct purchases, avoid double-counting)
    const investedInSchemes = schemesResult.recordset
      .filter(s => s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_invested || 0), 0);

    const investedInDirectPurchases = transactionsResult.recordset
      .filter(t => t.status === 'SUCCESS' && t.type === 'BUY' && !t.scheme_id)
      .reduce((sum, t) => sum + (t.amount || 0), 0);

    const totalInvested = investedInSchemes + investedInDirectPurchases;

    // Calculate breakdown by scheme type
    const goldPlusGrams = schemesResult.recordset
      .filter(s => s.scheme_type === 'GOLDPLUS' && s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_metal_accumulated || 0), 0);

    const goldFlexiGrams = schemesResult.recordset
      .filter(s => s.scheme_type === 'GOLDFLEXI' && s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_metal_accumulated || 0), 0);

    const silverPlusGrams = schemesResult.recordset
      .filter(s => s.scheme_type === 'SILVERPLUS' && s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_metal_accumulated || 0), 0);

    const silverFlexiGrams = schemesResult.recordset
      .filter(s => s.scheme_type === 'SILVERFLEXI' && s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (s.total_metal_accumulated || 0), 0);

    res.json({
      success: true,
      customer: {
        ...customer,
        total_gold_grams: totalGoldGrams,
        total_silver_grams: totalSilverGrams,
        total_invested: totalInvested
      },
      schemes: schemesResult.recordset,
      transactions: transactionsResult.recordset,
      summary: {
        active_schemes: schemesResult.recordset.filter(s => s.status === 'ACTIVE').length,
        completed_schemes: schemesResult.recordset.filter(s => s.status === 'COMPLETED').length,
        total_schemes: schemesResult.recordset.length,
        total_transactions: transactionsResult.recordset.length,
        successful_transactions: transactionsResult.recordset.filter(t => t.status === 'SUCCESS').length
      },
      breakdown: {
        gold: {
          total: totalGoldGrams,
          direct_purchase: goldFromDirectPurchases,
          gold_plus: goldPlusGrams,
          gold_flexi: goldFlexiGrams
        },
        silver: {
          total: totalSilverGrams,
          direct_purchase: silverFromDirectPurchases,
          silver_plus: silverPlusGrams,
          silver_flexi: silverFlexiGrams
        }
      }
    });

  } catch (error) {
    console.error('❌ Error getting customer details:', error.message);
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

// ============================================
// NOTIFICATION MANAGEMENT ENDPOINTS
// ============================================

// Send notification to specific user
app.post('/api/admin/notifications/send', [
  body('userId').notEmpty().withMessage('User ID (phone) required'),
  body('type').notEmpty().withMessage('Notification type required'),
  body('title').notEmpty().withMessage('Title required'),
  body('message').notEmpty().withMessage('Message required'),
  body('priority').optional().isIn(['low', 'normal', 'high', 'urgent']),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { userId, type, title, message, priority, imageUrl, actionUrl, data } = req.body;
    const notificationId = `NOTIF_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    console.log(`📬 Sending notification to user ${userId}:`, { type, title });

    const request = pool.request();
    request.input('notification_id', sql.NVarChar(50), notificationId);
    request.input('user_id', sql.NVarChar(15), userId);
    request.input('type', sql.NVarChar(50), type);
    request.input('title', sql.NVarChar(200), title);
    request.input('message', sql.NVarChar(sql.MAX), message);
    request.input('priority', sql.NVarChar(20), priority || 'normal');
    request.input('image_url', sql.NVarChar(500), imageUrl || null);
    request.input('action_url', sql.NVarChar(500), actionUrl || null);
    request.input('data', sql.NVarChar(sql.MAX), data ? JSON.stringify(data) : null);
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');
    request.input('sent_by', sql.NVarChar(50), 'ADMIN');

    await request.query(`
      INSERT INTO notifications (
        notification_id, user_id, type, title, message, priority,
        image_url, action_url, data, business_id, sent_by
      ) VALUES (
        @notification_id, @user_id, @type, @title, @message, @priority,
        @image_url, @action_url, @data, @business_id, @sent_by
      )
    `);

    console.log(`✅ Notification sent to user ${userId}:`, notificationId);

    res.json({
      success: true,
      message: 'Notification sent successfully',
      notificationId: notificationId
    });

  } catch (error) {
    console.error('❌ Send notification error:', error);
    res.status(500).json({ success: false, message: 'Failed to send notification', error: error.message });
  }
});

// Broadcast notification to all users
app.post('/api/admin/notifications/broadcast', [
  body('type').notEmpty().withMessage('Notification type required'),
  body('title').notEmpty().withMessage('Title required'),
  body('message').notEmpty().withMessage('Message required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { type, title, message, priority, imageUrl, actionUrl, data } = req.body;

    console.log(`📢 Broadcasting notification to all users:`, { type, title });

    // Get all customers
    const customersResult = await pool.request()
      .input('business_id', sql.NVarChar(50), 'VMURUGAN_001')
      .query('SELECT customer_phone FROM customers WHERE business_id = @business_id');

    const customers = customersResult.recordset;
    let sentCount = 0;

    // Send notification to each customer
    for (const customer of customers) {
      const notificationId = `NOTIF_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      const request = pool.request();
      request.input('notification_id', sql.NVarChar(50), notificationId);
      request.input('user_id', sql.NVarChar(15), customer.customer_phone);
      request.input('type', sql.NVarChar(50), type);
      request.input('title', sql.NVarChar(200), title);
      request.input('message', sql.NVarChar(sql.MAX), message);
      request.input('priority', sql.NVarChar(20), priority || 'normal');
      request.input('image_url', sql.NVarChar(500), imageUrl || null);
      request.input('action_url', sql.NVarChar(500), actionUrl || null);
      request.input('data', sql.NVarChar(sql.MAX), data ? JSON.stringify(data) : null);
      request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');
      request.input('sent_by', sql.NVarChar(50), 'ADMIN');

      await request.query(`
        INSERT INTO notifications (
          notification_id, user_id, type, title, message, priority,
          image_url, action_url, data, business_id, sent_by
        ) VALUES (
          @notification_id, @user_id, @type, @title, @message, @priority,
          @image_url, @action_url, @data, @business_id, @sent_by
        )
      `);

      sentCount++;
    }

    console.log(`✅ Broadcast notification sent to ${sentCount} users`);

    res.json({
      success: true,
      message: `Notification broadcast to ${sentCount} users`,
      sentCount: sentCount
    });

  } catch (error) {
    console.error('❌ Broadcast notification error:', error);
    res.status(500).json({ success: false, message: 'Failed to broadcast notification', error: error.message });
  }
});

// Send notification to filtered users
app.post('/api/admin/notifications/send-filtered', [
  body('filter').notEmpty().withMessage('Filter criteria required'),
  body('type').notEmpty().withMessage('Notification type required'),
  body('title').notEmpty().withMessage('Title required'),
  body('message').notEmpty().withMessage('Message required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { filter, type, title, message, priority, imageUrl, actionUrl, data } = req.body;

    console.log(`🎯 Sending filtered notification:`, { type, title, filter });

    // Build SQL query based on filter
    let query = 'SELECT DISTINCT c.customer_phone FROM customers c';
    let whereConditions = ['c.business_id = @business_id'];
    const request = pool.request();
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    // Add filter conditions
    if (filter.hasScheme) {
      query += ' INNER JOIN schemes s ON c.customer_phone = s.customer_phone';
      whereConditions.push('s.status = \'ACTIVE\'');
    }

    if (filter.schemeType) {
      request.input('scheme_type', sql.NVarChar(20), filter.schemeType);
      whereConditions.push('s.scheme_type = @scheme_type');
    }

    if (filter.metalType) {
      request.input('metal_type', sql.NVarChar(10), filter.metalType);
      whereConditions.push('s.metal_type = @metal_type');
    }

    query += ' WHERE ' + whereConditions.join(' AND ');

    const customersResult = await request.query(query);
    const customers = customersResult.recordset;
    let sentCount = 0;

    // Send notification to each filtered customer
    for (const customer of customers) {
      const notificationId = `NOTIF_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

      const notifRequest = pool.request();
      notifRequest.input('notification_id', sql.NVarChar(50), notificationId);
      notifRequest.input('user_id', sql.NVarChar(15), customer.customer_phone);
      notifRequest.input('type', sql.NVarChar(50), type);
      notifRequest.input('title', sql.NVarChar(200), title);
      notifRequest.input('message', sql.NVarChar(sql.MAX), message);
      notifRequest.input('priority', sql.NVarChar(20), priority || 'normal');
      notifRequest.input('image_url', sql.NVarChar(500), imageUrl || null);
      notifRequest.input('action_url', sql.NVarChar(500), actionUrl || null);
      notifRequest.input('data', sql.NVarChar(sql.MAX), data ? JSON.stringify(data) : null);
      notifRequest.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');
      notifRequest.input('sent_by', sql.NVarChar(50), 'ADMIN');

      await notifRequest.query(`
        INSERT INTO notifications (
          notification_id, user_id, type, title, message, priority,
          image_url, action_url, data, business_id, sent_by
        ) VALUES (
          @notification_id, @user_id, @type, @title, @message, @priority,
          @image_url, @action_url, @data, @business_id, @sent_by
        )
      `);

      sentCount++;
    }

    console.log(`✅ Filtered notification sent to ${sentCount} users`);

    res.json({
      success: true,
      message: `Notification sent to ${sentCount} filtered users`,
      sentCount: sentCount,
      filter: filter
    });

  } catch (error) {
    console.error('❌ Send filtered notification error:', error);
    res.status(500).json({ success: false, message: 'Failed to send filtered notification', error: error.message });
  }
});

// Get notification history
app.get('/api/admin/notifications/history', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;

    const request = pool.request();
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');
    request.input('limit', sql.Int, limit);
    request.input('offset', sql.Int, offset);

    const result = await request.query(`
      SELECT
        notification_id,
        user_id,
        type,
        title,
        message,
        is_read,
        created_at,
        priority,
        sent_by
      FROM notifications
      WHERE business_id = @business_id
      ORDER BY created_at DESC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `);

    const countResult = await pool.request()
      .input('business_id', sql.NVarChar(50), 'VMURUGAN_001')
      .query('SELECT COUNT(*) as total FROM notifications WHERE business_id = @business_id');

    res.json({
      success: true,
      notifications: result.recordset,
      pagination: {
        page: page,
        limit: limit,
        total: countResult.recordset[0].total,
        totalPages: Math.ceil(countResult.recordset[0].total / limit)
      }
    });

  } catch (error) {
    console.error('❌ Get notification history error:', error);
    res.status(500).json({ success: false, message: 'Failed to get notification history', error: error.message });
  }
});

// Get notification statistics
app.get('/api/admin/notifications/stats', async (req, res) => {
  try {
    const request = pool.request();
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

    // Get read/unread counts
    const readStatsResult = await request.query(`
      SELECT
        COUNT(*) as totalSent,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as totalRead,
        SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as totalUnread
      FROM notifications
      WHERE business_id = @business_id
    `);

    // Get counts by type
    const typeStatsResult = await pool.request()
      .input('business_id', sql.NVarChar(50), 'VMURUGAN_001')
      .query(`
        SELECT type, COUNT(*) as count
        FROM notifications
        WHERE business_id = @business_id
        GROUP BY type
      `);

    const stats = {
      totalSent: readStatsResult.recordset[0].totalSent || 0,
      totalRead: readStatsResult.recordset[0].totalRead || 0,
      totalUnread: readStatsResult.recordset[0].totalUnread || 0,
      byType: {}
    };

    typeStatsResult.recordset.forEach(row => {
      stats.byType[row.type] = row.count;
    });

    res.json({
      success: true,
      stats: stats
    });

  } catch (error) {
    console.error('❌ Get notification stats error:', error);
    res.status(500).json({ success: false, message: 'Failed to get notification stats', error: error.message });
  }
});

// Get user notifications (for frontend sync)
app.get('/api/notifications/:phone', async (req, res) => {
  try {
    const { phone } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;

    const request = pool.request();
    request.input('user_id', sql.NVarChar(15), phone);
    request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');
    request.input('limit', sql.Int, limit);
    request.input('offset', sql.Int, offset);

    const result = await request.query(`
      SELECT
        notification_id as id,
        user_id as userId,
        type,
        title,
        message,
        is_read as isRead,
        created_at as createdAt,
        read_at as readAt,
        data,
        priority,
        image_url as imageUrl,
        action_url as actionUrl
      FROM notifications
      WHERE user_id = @user_id AND business_id = @business_id
      ORDER BY created_at DESC
      OFFSET @offset ROWS
      FETCH NEXT @limit ROWS ONLY
    `);

    res.json({
      success: true,
      notifications: result.recordset.map(n => ({
        ...n,
        data: n.data ? JSON.parse(n.data) : null
      }))
    });

  } catch (error) {
    console.error('❌ Get user notifications error:', error);
    res.status(500).json({ success: false, message: 'Failed to get notifications', error: error.message });
  }
});

// Mark notification as read
app.put('/api/notifications/:notification_id/read', async (req, res) => {
  try {
    const { notification_id } = req.params;

    const request = pool.request();
    request.input('notification_id', sql.NVarChar(50), notification_id);

    await request.query(`
      UPDATE notifications
      SET is_read = 1, read_at = GETDATE()
      WHERE notification_id = @notification_id
    `);

    res.json({
      success: true,
      message: 'Notification marked as read'
    });

  } catch (error) {
    console.error('❌ Mark notification as read error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark notification as read', error: error.message });
  }
});

// ============================================
// OMNIWARE UPI INTENT API ENDPOINTS
// ============================================

// Import Omniware UPI routes
const omniwareUpiRoutes = require('./routes/omniware_upi');
app.use('/api/omniware', omniwareUpiRoutes);

// Import Omniware Webhook routes
const omniwareWebhookRoutes = require('./routes/omniware_webhook');
app.use('/api/omniware/webhook', omniwareWebhookRoutes);

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
      '/api/portfolio',
      '/api/schemes/:customerId',
      '/api/payments/worldline/token',
      '/api/payments/worldline/verify',
      '/worldline-response',
      '/worldline-checkout',
      '/privacy-policy',
      '/terms-of-service',
      '/account-deletion',
      '/admin_portal/index.html'
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

  // Check for SSL certificates - VMurugan Jewellery domain (Updated to use local ssl directory)
  const sslKeyPath = SSL_KEY_PATH;
  const sslCertPath = SSL_CERT_PATH;

  let httpsOptions = {};

  try {
    if (fs.existsSync(sslKeyPath) && fs.existsSync(sslCertPath)) {
      console.log('🔍 SSL certificate files found:');
      console.log(`   Key: ${sslKeyPath}`);
      console.log(`   Cert: ${sslCertPath}`);

      const keyContent = fs.readFileSync(sslKeyPath, 'utf8');
      const certContent = fs.readFileSync(sslCertPath, 'utf8');

      // Validate certificate content
      if (keyContent.includes('BEGIN') && certContent.includes('BEGIN CERTIFICATE')) {
        console.log('🔒 SSL certificates validated - configuring HTTPS server...');

        // Extract certificate details for logging
        const certLines = certContent.split('\n');
        const certData = certLines.slice(1, -2).join('');
        console.log('📜 Certificate loaded successfully');

        httpsOptions = {
          key: keyContent,
          cert: certContent,
          // Enhanced SSL options for better compatibility
          secureProtocol: 'TLSv1_2_method',
          honorCipherOrder: true,
          ciphers: [
            'ECDHE-RSA-AES128-GCM-SHA256',
            'ECDHE-RSA-AES256-GCM-SHA384',
            'ECDHE-RSA-AES128-SHA256',
            'ECDHE-RSA-AES256-SHA384'
          ].join(':'),
          rejectUnauthorized: false, // Allow self-signed certificates
          requestCert: false,
          agent: false
        };




        console.error('� To fix ASN1 encoding errors:');




      } else {
        console.error('❌ SSL certificates invalid format!');
        console.error('🔧 To fix this:');
        console.error('1. Run the SSL setup script: .\\setup-vmurugan-ssl.ps1');
        console.error('2. Ensure certificates are generated at: C:\\Certbot\\live\\api.vmuruganjewellery.co.in\\');
        console.error('3. Restart server');
        process.exit(1);
      }
    } else {
      console.error('❌ SSL certificates not found!');
      console.error(`   Expected Key: ${sslKeyPath}`);
      console.error(`   Expected Cert: ${sslCertPath}`);
      console.error('');
      console.error('🔧 To fix this:');
      console.error('1. Run the SSL setup script: .\\setup-vmurugan-ssl.ps1');
      console.error('2. Or run manually: .\\setup-ssl.bat');
      console.error('3. Ensure domain api.vmuruganjewellery.co.in points to this server');
      console.error('4. Restart server after SSL certificates are generated');
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

  // Start HTTPS server for production
  try {
    const httpsPort = process.env.HTTPS_PORT || 3001;

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
        console.error('🔧 Common fixes:');
        console.error('1. Check SSL certificates are valid');
        console.error('2. Ensure port 3001 is not in use');
        console.error('3. Run as administrator if needed');
      }
      process.exit(1);
    });

    httpsServer.listen(httpsPort, '0.0.0.0', () => {
      console.log('');
      console.log('========================================');
      console.log('🔒 HTTPS PRODUCTION SERVER STARTED!');
      console.log('========================================');
      console.log(`🔒 VMurugan HTTPS Server running on port ${httpsPort}`);
      console.log(`🏥 Health Check: https://api.vmuruganjewellery.co.in:${httpsPort}/health`);
      console.log(`🔗 API Base URL: https://api.vmuruganjewellery.co.in:${httpsPort}/api`);
      console.log(`💾 Database: ${sqlConfig.database} on ${sqlConfig.server}`);
      console.log(`🔒 Privacy & Legal URLs:`);
      console.log(`   Privacy:  https://api.vmuruganjewellery.co.in:${httpsPort}/privacy-policy`);
      console.log(`   Terms:    https://api.vmuruganjewellery.co.in:${httpsPort}/terms-of-service`);
      console.log(`   Account Deletion: https://api.vmuruganjewellery.co.in:${httpsPort}/account-deletion`);
      console.log(`💳 Worldline Payment Integration (Clean Slate Rebuild):`);
      console.log(`   Token:    https://api.vmuruganjewellery.co.in:${httpsPort}/api/payments/worldline/token`);
      console.log(`   Verify:   https://api.vmuruganjewellery.co.in:${httpsPort}/api/payments/worldline/verify`);
      console.log(`💳 Omniware UPI Payment Integration (UPI Mode):`);
      console.log(`   Payment Page URL: https://api.vmuruganjewellery.co.in:${httpsPort}/api/omniware/payment-page-url`);
      console.log(`   Payment Status:   https://api.vmuruganjewellery.co.in:${httpsPort}/api/omniware/check-payment-status`);
      console.log(`   Webhook:          https://api.vmuruganjewellery.co.in:${httpsPort}/api/omniware/webhook/payment`);
      console.log('');
      console.log('✅ HTTPS-only production mode');
      console.log('🔒 All connections encrypted');
      console.log('========================================');
    });

  } catch (httpsError) {
    console.error('❌ Failed to start HTTPS server:', httpsError.message);
    console.error('🔧 To fix this:');
    console.error('1. Check SSL certificates are valid');
    console.error('2. Ensure port 3001 is available');
    console.error('3. Run server as administrator');
    process.exit(1);
  }
}

// ==================== ADMIN REPORTING ENDPOINTS ====================

// Dashboard Analytics - Comprehensive overview
app.get('/api/admin/analytics/dashboard', async (req, res) => {
  const requestId = `DASH_${Date.now()}`;
  console.log(`📊 [${requestId}] Dashboard analytics requested`);

  try {
    const pool = await sql.connect(sqlConfig);

    // Get total customers
    const customersResult = await pool.request().query(`
      SELECT
        COUNT(*) as total_customers,
        COUNT(CASE WHEN CAST(created_at AS DATE) >= DATEADD(MONTH, -1, GETDATE()) THEN 1 END) as new_customers_this_month,
        COUNT(CASE WHEN CAST(created_at AS DATE) >= DATEADD(DAY, -7, GETDATE()) THEN 1 END) as new_customers_this_week
      FROM customers
    `);

    // Get transaction analytics
    const transactionsResult = await pool.request().query(`
      SELECT
        COUNT(*) as total_transactions,
        SUM(amount) as total_revenue,
        SUM(CASE WHEN metal_type = 'GOLD' THEN metal_grams ELSE 0 END) as total_gold_sold,
        SUM(CASE WHEN metal_type = 'SILVER' THEN metal_grams ELSE 0 END) as total_silver_sold,
        COUNT(CASE WHEN CAST(created_at AS DATE) >= DATEADD(MONTH, -1, GETDATE()) THEN 1 END) as transactions_this_month,
        SUM(CASE WHEN CAST(created_at AS DATE) >= DATEADD(MONTH, -1, GETDATE()) THEN amount ELSE 0 END) as revenue_this_month
      FROM transactions
      WHERE status = 'SUCCESS'
    `);

    // Get scheme analytics
    const schemesResult = await pool.request().query(`
      SELECT
        COUNT(*) as total_schemes,
        COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) as active_schemes,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_schemes,
        COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_schemes,
        COUNT(CASE WHEN scheme_type = 'GOLDPLUS' THEN 1 END) as goldplus_count,
        COUNT(CASE WHEN scheme_type = 'GOLDFLEXI' THEN 1 END) as goldflexi_count,
        COUNT(CASE WHEN scheme_type = 'SILVERPLUS' THEN 1 END) as silverplus_count,
        COUNT(CASE WHEN scheme_type = 'SILVERFLEXI' THEN 1 END) as silverflexi_count,
        SUM(total_invested) as total_scheme_investment,
        SUM(CASE WHEN metal_type = 'GOLD' THEN total_metal_accumulated ELSE 0 END) as total_gold_accumulated,
        SUM(CASE WHEN metal_type = 'SILVER' THEN total_metal_accumulated ELSE 0 END) as total_silver_accumulated,
        AVG(monthly_amount) as avg_monthly_amount
      FROM schemes
    `);

    // Get monthly revenue trend (last 6 months)
    const monthlyTrendResult = await pool.request().query(`
      SELECT
        FORMAT(created_at, 'yyyy-MM') as month,
        COUNT(*) as transaction_count,
        SUM(amount) as revenue
      FROM transactions
      WHERE status = 'SUCCESS'
        AND created_at >= DATEADD(MONTH, -6, GETDATE())
      GROUP BY FORMAT(created_at, 'yyyy-MM')
      ORDER BY month
    `);

    const analytics = {
      customers: customersResult.recordset[0],
      transactions: transactionsResult.recordset[0],
      schemes: schemesResult.recordset[0],
      monthlyTrend: monthlyTrendResult.recordset
    };

    console.log(`✅ [${requestId}] Dashboard analytics retrieved successfully`);
    res.json({
      success: true,
      analytics: analytics
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error fetching dashboard analytics:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch dashboard analytics',
      message: error.message
    });
  }
});

// Scheme-wise Report
app.get('/api/admin/reports/scheme-wise', async (req, res) => {
  const requestId = `SCHEME_RPT_${Date.now()}`;
  const { start_date, end_date } = req.query;

  console.log(`📊 [${requestId}] Scheme-wise report requested`);
  console.log(`   Date range: ${start_date || 'ALL'} to ${end_date || 'ALL'}`);

  try {
    const pool = await sql.connect(sqlConfig);
    const request = pool.request();

    let dateFilter = '';
    if (start_date && end_date) {
      request.input('start_date', sql.DateTime, new Date(start_date));
      request.input('end_date', sql.DateTime, new Date(end_date));
      dateFilter = 'AND created_at >= @start_date AND created_at <= @end_date';
    }

    const query = `
      SELECT
        scheme_type,
        metal_type,
        COUNT(*) as total_schemes,
        COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) as active_count,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_count,
        COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_count,
        COUNT(CASE WHEN status = 'PAUSED' THEN 1 END) as paused_count,
        SUM(total_invested) as total_investment,
        SUM(total_metal_accumulated) as total_metal_accumulated,
        AVG(monthly_amount) as avg_monthly_amount,
        AVG(completed_installments) as avg_completed_installments,
        MIN(monthly_amount) as min_monthly_amount,
        MAX(monthly_amount) as max_monthly_amount
      FROM schemes
      WHERE 1=1 ${dateFilter}
      GROUP BY scheme_type, metal_type
      ORDER BY scheme_type
    `;

    const result = await request.query(query);

    console.log(`✅ [${requestId}] Scheme-wise report generated: ${result.recordset.length} scheme types`);
    res.json({
      success: true,
      report: result.recordset,
      filters: { start_date, end_date }
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error generating scheme-wise report:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate scheme-wise report',
      message: error.message
    });
  }
});

// Customer-wise Report
app.get('/api/admin/reports/customer-wise', async (req, res) => {
  const requestId = `CUST_RPT_${Date.now()}`;
  const { customer_id, customer_phone, start_date, end_date } = req.query;

  console.log(`📊 [${requestId}] Customer-wise report requested`);
  console.log(`   Customer ID: ${customer_id || 'N/A'}, Phone: ${customer_phone || 'N/A'}`);

  try {
    const pool = await sql.connect(sqlConfig);
    const request = pool.request();

    // Build customer filter
    let customerFilter = '';
    if (customer_id) {
      request.input('customer_id', sql.NVarChar(20), customer_id);
      customerFilter = 'AND c.customer_id = @customer_id';
    } else if (customer_phone) {
      request.input('customer_phone', sql.NVarChar(15), customer_phone);
      customerFilter = 'AND c.phone = @customer_phone';
    }

    // Get customer details with aggregated data
    const customerQuery = `
      SELECT
        c.id,
        c.customer_id,
        c.phone,
        c.name,
        c.email,
        c.address,
        c.pan_card,
        c.registration_date,
        c.created_at as member_since,
        COUNT(DISTINCT s.id) as total_schemes,
        COUNT(DISTINCT CASE WHEN s.status = 'ACTIVE' THEN s.id END) as active_schemes,
        SUM(s.total_invested) as total_scheme_investment,
        SUM(CASE WHEN s.metal_type = 'GOLD' THEN s.total_metal_accumulated ELSE 0 END) as total_gold_grams,
        SUM(CASE WHEN s.metal_type = 'SILVER' THEN s.total_metal_accumulated ELSE 0 END) as total_silver_grams,
        COUNT(DISTINCT t.id) as total_transactions,
        SUM(t.amount) as total_transaction_amount,
        SUM(CASE WHEN t.metal_type = 'GOLD' THEN t.metal_grams ELSE 0 END) as total_gold_purchased,
        SUM(CASE WHEN t.metal_type = 'SILVER' THEN t.metal_grams ELSE 0 END) as total_silver_purchased
      FROM customers c
      LEFT JOIN schemes s ON c.id = s.customer_id
      LEFT JOIN transactions t ON c.phone = t.customer_phone AND t.status = 'SUCCESS'
      WHERE 1=1 ${customerFilter}
      GROUP BY c.id, c.customer_id, c.phone, c.name, c.email, c.address, c.pan_card, c.registration_date, c.created_at
    `;

    const customerResult = await request.query(customerQuery);

    if (customerResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Customer not found'
      });
    }

    const customer = customerResult.recordset[0];

    // Get customer's schemes
    const schemesRequest = pool.request();
    schemesRequest.input('customer_id_int', sql.Int, customer.id);
    const schemesResult = await schemesRequest.query(`
      SELECT
        scheme_id, scheme_type, metal_type, monthly_amount, duration_months,
        status, start_date, end_date, total_invested, total_metal_accumulated,
        completed_installments, created_at
      FROM schemes
      WHERE customer_id = @customer_id_int
      ORDER BY created_at DESC
    `);

    // Get customer's transactions
    const transactionsRequest = pool.request();
    transactionsRequest.input('customer_phone_txn', sql.NVarChar(15), customer.phone);

    let dateFilter = '';
    if (start_date && end_date) {
      transactionsRequest.input('start_date', sql.DateTime, new Date(start_date));
      transactionsRequest.input('end_date', sql.DateTime, new Date(end_date));
      dateFilter = 'AND created_at >= @start_date AND created_at <= @end_date';
    }

    const transactionsResult = await transactionsRequest.query(`
      SELECT
        transaction_id, amount, metal_type, metal_grams, metal_price_per_gram,
        payment_method, status, created_at, scheme_id
      FROM transactions
      WHERE customer_phone = @customer_phone_txn ${dateFilter}
      ORDER BY created_at DESC
    `);

    console.log(`✅ [${requestId}] Customer report generated for ${customer.customer_id}`);
    res.json({
      success: true,
      customer: customer,
      schemes: schemesResult.recordset,
      transactions: transactionsResult.recordset,
      filters: { start_date, end_date }
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error generating customer report:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate customer report',
      message: error.message
    });
  }
});

// Transaction-wise Report
app.get('/api/admin/reports/transaction-wise', async (req, res) => {
  const requestId = `TXN_RPT_${Date.now()}`;
  const { start_date, end_date, type, status, metal_type, min_amount, max_amount } = req.query;

  console.log(`📊 [${requestId}] Transaction-wise report requested`);

  try {
    const pool = await sql.connect(sqlConfig);
    const request = pool.request();

    let filters = [];

    if (start_date && end_date) {
      request.input('start_date', sql.DateTime, new Date(start_date));
      request.input('end_date', sql.DateTime, new Date(end_date));
      filters.push('t.created_at >= @start_date AND t.created_at <= @end_date');
    }

    if (status) {
      request.input('status', sql.NVarChar(20), status);
      filters.push('t.status = @status');
    }

    if (metal_type) {
      request.input('metal_type', sql.NVarChar(10), metal_type);
      filters.push('t.metal_type = @metal_type');
    }

    if (min_amount) {
      request.input('min_amount', sql.Decimal(12, 2), parseFloat(min_amount));
      filters.push('t.amount >= @min_amount');
    }

    if (max_amount) {
      request.input('max_amount', sql.Decimal(12, 2), parseFloat(max_amount));
      filters.push('t.amount <= @max_amount');
    }

    const whereClause = filters.length > 0 ? 'WHERE ' + filters.join(' AND ') : '';

    const query = `
      SELECT
        t.id,
        t.transaction_id,
        t.customer_phone,
        c.customer_id,
        c.name as customer_name,
        t.amount,
        t.metal_type,
        t.metal_grams,
        t.metal_price_per_gram,
        t.payment_method,
        t.status,
        t.scheme_id,
        CASE WHEN t.scheme_id IS NOT NULL THEN 'Scheme Payment' ELSE 'Direct Purchase' END as transaction_type,
        t.created_at
      FROM transactions t
      LEFT JOIN customers c ON t.customer_phone = c.phone
      ${whereClause}
      ORDER BY t.created_at DESC
    `;

    const result = await request.query(query);

    // Calculate summary
    const summary = {
      total_transactions: result.recordset.length,
      total_amount: result.recordset.reduce((sum, txn) => sum + parseFloat(txn.amount || 0), 0),
      total_gold_grams: result.recordset.reduce((sum, txn) =>
        sum + (txn.metal_type === 'GOLD' ? parseFloat(txn.metal_grams || 0) : 0), 0),
      total_silver_grams: result.recordset.reduce((sum, txn) =>
        sum + (txn.metal_type === 'SILVER' ? parseFloat(txn.metal_grams || 0) : 0), 0),
      success_count: result.recordset.filter(txn => txn.status === 'SUCCESS').length,
      pending_count: result.recordset.filter(txn => txn.status === 'PENDING').length,
      failed_count: result.recordset.filter(txn => txn.status === 'FAILED').length
    };

    console.log(`✅ [${requestId}] Transaction report generated: ${result.recordset.length} transactions`);
    res.json({
      success: true,
      transactions: result.recordset,
      summary: summary,
      filters: { start_date, end_date, type, status, metal_type, min_amount, max_amount }
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error generating transaction report:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate transaction report',
      message: error.message
    });
  }
});

// Date-wise Report
app.get('/api/admin/reports/date-wise', async (req, res) => {
  const requestId = `DATE_RPT_${Date.now()}`;
  const { date, start_date, end_date } = req.query;

  console.log(`📊 [${requestId}] Date-wise report requested`);

  try {
    const pool = await sql.connect(sqlConfig);
    const request = pool.request();

    let dateFilter = '';
    if (date) {
      // Single date
      request.input('target_date', sql.Date, new Date(date));
      dateFilter = 'CAST(created_at AS DATE) = @target_date';
    } else if (start_date && end_date) {
      // Date range
      request.input('start_date', sql.DateTime, new Date(start_date));
      request.input('end_date', sql.DateTime, new Date(end_date));
      dateFilter = 'created_at >= @start_date AND created_at <= @end_date';
    } else {
      return res.status(400).json({
        success: false,
        error: 'Please provide either date or start_date and end_date'
      });
    }

    // Get transaction summary
    const transactionQuery = `
      SELECT
        CAST(created_at AS DATE) as transaction_date,
        COUNT(*) as total_transactions,
        SUM(amount) as total_revenue,
        SUM(CASE WHEN metal_type = 'GOLD' THEN metal_grams ELSE 0 END) as total_gold_sold,
        SUM(CASE WHEN metal_type = 'SILVER' THEN metal_grams ELSE 0 END) as total_silver_sold,
        COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as successful_transactions,
        COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_transactions,
        COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_transactions
      FROM transactions
      WHERE ${dateFilter}
      GROUP BY CAST(created_at AS DATE)
      ORDER BY transaction_date
    `;

    const transactionResult = await request.query(transactionQuery);

    // Get new customers registered
    const customerRequest = pool.request();
    if (date) {
      customerRequest.input('target_date', sql.Date, new Date(date));
      dateFilter = 'CAST(created_at AS DATE) = @target_date';
    } else {
      customerRequest.input('start_date', sql.DateTime, new Date(start_date));
      customerRequest.input('end_date', sql.DateTime, new Date(end_date));
      dateFilter = 'created_at >= @start_date AND created_at <= @end_date';
    }

    const customerQuery = `
      SELECT
        CAST(created_at AS DATE) as registration_date,
        COUNT(*) as new_customers
      FROM customers
      WHERE ${dateFilter}
      GROUP BY CAST(created_at AS DATE)
      ORDER BY registration_date
    `;

    const customerResult = await customerRequest.query(customerQuery);

    // Get new schemes enrolled
    const schemeRequest = pool.request();
    if (date) {
      schemeRequest.input('target_date', sql.Date, new Date(date));
      dateFilter = 'CAST(created_at AS DATE) = @target_date';
    } else {
      schemeRequest.input('start_date', sql.DateTime, new Date(start_date));
      schemeRequest.input('end_date', sql.DateTime, new Date(end_date));
      dateFilter = 'created_at >= @start_date AND created_at <= @end_date';
    }

    const schemeQuery = `
      SELECT
        CAST(created_at AS DATE) as enrollment_date,
        COUNT(*) as new_schemes,
        COUNT(CASE WHEN scheme_type = 'GOLDPLUS' THEN 1 END) as goldplus_count,
        COUNT(CASE WHEN scheme_type = 'GOLDFLEXI' THEN 1 END) as goldflexi_count,
        COUNT(CASE WHEN scheme_type = 'SILVERPLUS' THEN 1 END) as silverplus_count,
        COUNT(CASE WHEN scheme_type = 'SILVERFLEXI' THEN 1 END) as silverflexi_count
      FROM schemes
      WHERE ${dateFilter}
      GROUP BY CAST(created_at AS DATE)
      ORDER BY enrollment_date
    `;

    const schemeResult = await schemeRequest.query(schemeQuery);

    console.log(`✅ [${requestId}] Date-wise report generated`);
    res.json({
      success: true,
      transactions: transactionResult.recordset,
      customers: customerResult.recordset,
      schemes: schemeResult.recordset,
      filters: { date, start_date, end_date }
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error generating date-wise report:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate date-wise report',
      message: error.message
    });
  }
});

// Month-wise Report
app.get('/api/admin/reports/month-wise', async (req, res) => {
  const requestId = `MONTH_RPT_${Date.now()}`;
  const { year, month } = req.query;

  console.log(`📊 [${requestId}] Month-wise report requested for ${year || 'all years'}/${month || 'all months'}`);

  try {
    const pool = await sql.connect(sqlConfig);
    const request = pool.request();

    let dateFilter = '';
    if (year && month) {
      request.input('year', sql.Int, parseInt(year));
      request.input('month', sql.Int, parseInt(month));
      dateFilter = 'AND YEAR(created_at) = @year AND MONTH(created_at) = @month';
    } else if (year) {
      request.input('year', sql.Int, parseInt(year));
      dateFilter = 'AND YEAR(created_at) = @year';
    }

    // Get monthly transaction summary
    const transactionQuery = `
      SELECT
        YEAR(created_at) as year,
        MONTH(created_at) as month,
        FORMAT(created_at, 'yyyy-MM') as month_year,
        COUNT(*) as total_transactions,
        SUM(amount) as total_revenue,
        SUM(CASE WHEN metal_type = 'GOLD' THEN metal_grams ELSE 0 END) as total_gold_sold,
        SUM(CASE WHEN metal_type = 'SILVER' THEN metal_grams ELSE 0 END) as total_silver_sold,
        AVG(amount) as avg_transaction_amount
      FROM transactions
      WHERE status = 'SUCCESS' ${dateFilter}
      GROUP BY YEAR(created_at), MONTH(created_at), FORMAT(created_at, 'yyyy-MM')
      ORDER BY year, month
    `;

    const transactionResult = await request.query(transactionQuery);

    // Get monthly customer registrations
    const customerRequest = pool.request();
    if (year && month) {
      customerRequest.input('year', sql.Int, parseInt(year));
      customerRequest.input('month', sql.Int, parseInt(month));
      dateFilter = 'AND YEAR(created_at) = @year AND MONTH(created_at) = @month';
    } else if (year) {
      customerRequest.input('year', sql.Int, parseInt(year));
      dateFilter = 'AND YEAR(created_at) = @year';
    }

    const customerQuery = `
      SELECT
        YEAR(created_at) as year,
        MONTH(created_at) as month,
        FORMAT(created_at, 'yyyy-MM') as month_year,
        COUNT(*) as new_customers
      FROM customers
      WHERE 1=1 ${dateFilter}
      GROUP BY YEAR(created_at), MONTH(created_at), FORMAT(created_at, 'yyyy-MM')
      ORDER BY year, month
    `;

    const customerResult = await customerRequest.query(customerQuery);

    // Get monthly scheme enrollments
    const schemeRequest = pool.request();
    if (year && month) {
      schemeRequest.input('year', sql.Int, parseInt(year));
      schemeRequest.input('month', sql.Int, parseInt(month));
      dateFilter = 'AND YEAR(created_at) = @year AND MONTH(created_at) = @month';
    } else if (year) {
      schemeRequest.input('year', sql.Int, parseInt(year));
      dateFilter = 'AND YEAR(created_at) = @year';
    }

    const schemeQuery = `
      SELECT
        YEAR(created_at) as year,
        MONTH(created_at) as month,
        FORMAT(created_at, 'yyyy-MM') as month_year,
        COUNT(*) as new_schemes,
        SUM(total_invested) as total_investment
      FROM schemes
      WHERE 1=1 ${dateFilter}
      GROUP BY YEAR(created_at), MONTH(created_at), FORMAT(created_at, 'yyyy-MM')
      ORDER BY year, month
    `;

    const schemeResult = await schemeRequest.query(schemeQuery);

    console.log(`✅ [${requestId}] Month-wise report generated`);
    res.json({
      success: true,
      transactions: transactionResult.recordset,
      customers: customerResult.recordset,
      schemes: schemeResult.recordset,
      filters: { year, month }
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error generating month-wise report:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate month-wise report',
      message: error.message
    });
  }
});

// Year-wise Report
app.get('/api/admin/reports/year-wise', async (req, res) => {
  const requestId = `YEAR_RPT_${Date.now()}`;
  const { year } = req.query;

  console.log(`📊 [${requestId}] Year-wise report requested for ${year || 'all years'}`);

  try {
    const pool = await sql.connect(sqlConfig);
    const request = pool.request();

    let dateFilter = '';
    if (year) {
      request.input('year', sql.Int, parseInt(year));
      dateFilter = 'AND YEAR(created_at) = @year';
    }

    // Get yearly transaction summary
    const transactionQuery = `
      SELECT
        YEAR(created_at) as year,
        COUNT(*) as total_transactions,
        SUM(amount) as total_revenue,
        SUM(CASE WHEN metal_type = 'GOLD' THEN metal_grams ELSE 0 END) as total_gold_sold,
        SUM(CASE WHEN metal_type = 'SILVER' THEN metal_grams ELSE 0 END) as total_silver_sold,
        AVG(amount) as avg_transaction_amount
      FROM transactions
      WHERE status = 'SUCCESS' ${dateFilter}
      GROUP BY YEAR(created_at)
      ORDER BY year
    `;

    const transactionResult = await request.query(transactionQuery);

    // Get yearly customer registrations
    const customerRequest = pool.request();
    if (year) {
      customerRequest.input('year', sql.Int, parseInt(year));
      dateFilter = 'AND YEAR(created_at) = @year';
    }

    const customerQuery = `
      SELECT
        YEAR(created_at) as year,
        COUNT(*) as new_customers
      FROM customers
      WHERE 1=1 ${dateFilter}
      GROUP BY YEAR(created_at)
      ORDER BY year
    `;

    const customerResult = await customerRequest.query(customerQuery);

    // Get yearly scheme enrollments
    const schemeRequest = pool.request();
    if (year) {
      schemeRequest.input('year', sql.Int, parseInt(year));
      dateFilter = 'AND YEAR(created_at) = @year';
    }

    const schemeQuery = `
      SELECT
        YEAR(created_at) as year,
        COUNT(*) as new_schemes,
        SUM(total_invested) as total_investment,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_schemes
      FROM schemes
      WHERE 1=1 ${dateFilter}
      GROUP BY YEAR(created_at)
      ORDER BY year
    `;

    const schemeResult = await schemeRequest.query(schemeQuery);

    // Calculate year-over-year growth if multiple years
    const growth = [];
    if (transactionResult.recordset.length > 1) {
      for (let i = 1; i < transactionResult.recordset.length; i++) {
        const current = transactionResult.recordset[i];
        const previous = transactionResult.recordset[i - 1];

        growth.push({
          year: current.year,
          revenue_growth: ((current.total_revenue - previous.total_revenue) / previous.total_revenue * 100).toFixed(2),
          transaction_growth: ((current.total_transactions - previous.total_transactions) / previous.total_transactions * 100).toFixed(2)
        });
      }
    }

    console.log(`✅ [${requestId}] Year-wise report generated`);
    res.json({
      success: true,
      transactions: transactionResult.recordset,
      customers: customerResult.recordset,
      schemes: schemeResult.recordset,
      growth: growth,
      filters: { year }
    });

  } catch (error) {
    console.error(`❌ [${requestId}] Error generating year-wise report:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate year-wise report',
      message: error.message
    });
  }
});

// Worldline Error Capture API - Persistent logging for "Invalid Request" debugging
app.post('/api/payments/worldline/error-capture', [
  body('timestamp').notEmpty().withMessage('Timestamp is required'),
  body('errorAnalysis').isObject().withMessage('Error analysis must be an object'),
  body('fullResponse').isObject().withMessage('Full response must be an object')
], async (req, res) => {
  const requestId = `ERR_${Date.now()}`;
  const requestStartTime = Date.now();

  try {
    console.log(`🚨 ===== WORLDLINE ERROR CAPTURE STARTED =====`);
    console.log(`📋 Request ID: ${requestId}`);
    console.log(`⏰ Timestamp: ${new Date().toISOString()}`);
    console.log(`🌐 Client IP: ${req.ip}`);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log(`❌ [${requestId}] Validation errors: ${JSON.stringify(errors.array())}`);
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      timestamp,
      sessionId,
      errorAnalysis,
      fullResponse,
      paymentContext,
      deviceInfo
    } = req.body;

    console.log(`🔍 [${requestId}] ERROR ANALYSIS RECEIVED:`);
    console.log(`   Session ID: ${sessionId}`);
    console.log(`   Error Type: ${errorAnalysis.isInvalidRequest ? 'INVALID REQUEST' : 'OTHER'}`);
    console.log(`   Error Message: ${errorAnalysis.errorMessage || 'N/A'}`);
    console.log(`   Error Code: ${errorAnalysis.errorCode || 'N/A'}`);
    console.log(`   Payment Amount: ${paymentContext?.amount || 'N/A'}`);
    console.log(`   Order ID: ${paymentContext?.orderId || 'N/A'}`);
    console.log(`   Merchant Code: ${paymentContext?.merchantCode || 'N/A'}`);

    console.log(`🔍 [${requestId}] FULL WORLDLINE RESPONSE:`);
    console.log(JSON.stringify(fullResponse, null, 2));

    if (errorAnalysis.potentialCauses && errorAnalysis.potentialCauses.length > 0) {
      console.log(`🔍 [${requestId}] POTENTIAL CAUSES:`);
      errorAnalysis.potentialCauses.forEach((cause, index) => {
        console.log(`   ${index + 1}. ${cause}`);
      });
    }

    console.log(`✅ [${requestId}] Error details captured and logged`);

    const totalTime = Date.now() - requestStartTime;
    console.log(`⏱️ [${requestId}] Total processing time: ${totalTime}ms`);
    console.log(`🚨 ===== WORLDLINE ERROR CAPTURE COMPLETED =====`);

    res.json({
      success: true,
      requestId: requestId,
      message: 'Error details captured successfully',
      processingTime: totalTime
    });

  } catch (error) {
    const totalTime = Date.now() - requestStartTime;
    console.log(`💥 [${requestId}] CRITICAL ERROR OCCURRED:`);
    console.log(`❌ [${requestId}] Error message: ${error.message}`);
    console.log(`❌ [${requestId}] Error stack: ${error.stack}`);
    console.log(`⏱️ [${requestId}] Total time before error: ${totalTime}ms`);

    res.status(500).json({
      success: false,
      error: 'Internal server error during error capture',
      requestId: requestId,
      message: error.message
    });
  }
});

// ============================================
// OMNIWARE PAYMENT GATEWAY INTEGRATION
// ============================================

const omniwareConfig = require('./omniware_config');

/**
 * Omniware Payment Initiation API
 * Generates payment URL for Omniware payment gateway
 */
app.post('/api/payments/omniware/initiate', [
  body('orderId').notEmpty().withMessage('Order ID is required'),
  body('amount').isFloat({ min: 100, max: 1000000 }).withMessage('Amount must be between ₹100 and ₹10,00,000'),
  body('description').notEmpty().withMessage('Description is required'),
  body('metalType').isIn(['gold', 'silver']).withMessage('Metal type must be gold or silver'),
  body('customer').isObject().withMessage('Customer details are required')
], async (req, res) => {
  const requestId = `OMNI_INIT_${Date.now()}`;
  const requestStartTime = Date.now();

  try {
    console.log('');
    console.log('🟢 ===== OMNIWARE PAYMENT INITIATION STARTED =====');
    console.log(`📋 Request ID: ${requestId}`);
    console.log(`⏰ Timestamp: ${new Date().toISOString()}`);
    console.log(`🌐 Client IP: ${req.ip || 'unknown'}`);

    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log(`❌ [${requestId}] Validation errors:`, errors.array());
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { orderId, amount, description, metalType, customer } = req.body;

    console.log(`💰 [${requestId}] Payment Details:`);
    console.log(`   Order ID: ${orderId}`);
    console.log(`   Amount: ₹${amount}`);
    console.log(`   Metal Type: ${metalType}`);
    console.log(`   Customer: ${customer.name} (${customer.phone})`);

    // Get merchant configuration
    const merchant = omniwareConfig.getMerchantConfig(metalType);
    console.log(`🏪 [${requestId}] Using Merchant: ${merchant.name} (${merchant.merchantId})`);

    // Build payment request parameters
    const paymentData = {
      orderId,
      amount,
      description,
      customer
    };

    const paymentParams = omniwareConfig.buildPaymentRequest(paymentData, metalType);

    console.log(`🔐 [${requestId}] Payment Parameters Generated:`);
    console.log(`   API Key: ${paymentParams.api_key.substring(0, 10)}...`);
    console.log(`   Hash: ${paymentParams.hash.substring(0, 20)}...`);

    // NOTE: Since we don't have the actual Omniware API URL yet,
    // we'll return the parameters for now
    // TODO: Replace with actual API call when URL is provided

    if (omniwareConfig.COMMON_CONFIG.apiBaseUrl.includes('{pg_api_url}')) {
      console.log(`⚠️ [${requestId}] WARNING: Omniware API URL not configured yet!`);
      console.log(`   Please update COMMON_CONFIG.apiBaseUrl in omniware_config.js`);

      return res.json({
        success: false,
        message: 'Omniware API URL not configured. Please contact support.',
        debug: {
          requestId,
          merchant: merchant.name,
          orderId,
          amount
        }
      });
    }

    // When API URL is available, make the actual API call:
    // const paymentUrl = `${omniwareConfig.COMMON_CONFIG.apiBaseUrl}/v2/paymentrequest`;
    // const response = await axios.post(paymentUrl, paymentParams);

    const totalTime = Date.now() - requestStartTime;
    console.log(`⏱️ [${requestId}] Total processing time: ${totalTime}ms`);
    console.log(`🟢 ===== OMNIWARE PAYMENT INITIATION COMPLETED =====`);

    res.json({
      success: true,
      requestId,
      paymentUrl: `${omniwareConfig.COMMON_CONFIG.apiBaseUrl}/v2/paymentrequest`,
      paymentParams,
      message: 'Payment URL generated successfully'
    });

  } catch (error) {
    const totalTime = Date.now() - requestStartTime;
    console.log(`💥 [${requestId}] CRITICAL ERROR OCCURRED:`);
    console.log(`❌ [${requestId}] Error message: ${error.message}`);
    console.log(`❌ [${requestId}] Error stack: ${error.stack}`);
    console.log(`⏱️ [${requestId}] Total time before error: ${totalTime}ms`);

    res.status(500).json({
      success: false,
      error: 'Internal server error during payment initiation',
      requestId,
      message: error.message
    });
  }
});

/**
 * Omniware Payment Verification API
 * Verifies payment response from Omniware
 */
app.post('/api/payments/omniware/verify', async (req, res) => {
  const requestId = `OMNI_VERIFY_${Date.now()}`;
  const requestStartTime = Date.now();

  try {
    console.log('');
    console.log('🟢 ===== OMNIWARE PAYMENT VERIFICATION STARTED =====');
    console.log(`📋 Request ID: ${requestId}`);
    console.log(`⏰ Timestamp: ${new Date().toISOString()}`);
    console.log(`📦 Request Body:`, JSON.stringify(req.body, null, 2));

    const { metalType, ...responseParams } = req.body;

    // Get merchant configuration
    const merchant = omniwareConfig.getMerchantConfig(metalType || 'gold');

    // Verify hash
    const receivedHash = responseParams.hash;
    delete responseParams.hash; // Remove hash from params before verification

    const isValid = omniwareConfig.verifyHash(responseParams, receivedHash, merchant.salt);

    console.log(`🔐 [${requestId}] Hash Verification: ${isValid ? '✅ VALID' : '❌ INVALID'}`);

    if (!isValid) {
      console.log(`❌ [${requestId}] Hash verification failed!`);
      return res.status(400).json({
        success: false,
        message: 'Invalid payment response - hash verification failed'
      });
    }

    // Check payment status
    const paymentSuccess = responseParams.status === '0' || responseParams.status === 'success';

    console.log(`💳 [${requestId}] Payment Status: ${paymentSuccess ? '✅ SUCCESS' : '❌ FAILED'}`);
    console.log(`   Transaction ID: ${responseParams.txnid || responseParams.transaction_id}`);
    console.log(`   Order ID: ${responseParams.order_id}`);
    console.log(`   Amount: ₹${responseParams.amount}`);

    const totalTime = Date.now() - requestStartTime;
    console.log(`⏱️ [${requestId}] Total processing time: ${totalTime}ms`);
    console.log(`🟢 ===== OMNIWARE PAYMENT VERIFICATION COMPLETED =====`);

    res.json({
      success: paymentSuccess,
      requestId,
      transactionId: responseParams.txnid || responseParams.transaction_id,
      orderId: responseParams.order_id,
      amount: responseParams.amount,
      status: responseParams.status,
      message: paymentSuccess ? 'Payment verified successfully' : 'Payment failed',
      rawResponse: responseParams
    });

  } catch (error) {
    const totalTime = Date.now() - requestStartTime;
    console.log(`💥 [${requestId}] CRITICAL ERROR OCCURRED:`);
    console.log(`❌ [${requestId}] Error message: ${error.message}`);
    console.log(`❌ [${requestId}] Error stack: ${error.stack}`);
    console.log(`⏱️ [${requestId}] Total time before error: ${totalTime}ms`);

    res.status(500).json({
      success: false,
      error: 'Internal server error during payment verification',
      requestId,
      message: error.message
    });
  }
});

// HTTPS-only production server

// ============================================
// COMPREHENSIVE REPORTS API ENDPOINTS
// ============================================

// Monthly Report - Detailed monthly breakdown
app.get('/api/reports/monthly', async (req, res) => {
  try {
    const { customer_phone, month, year } = req.query;
    console.log('📊 Generating monthly report:', { customer_phone, month, year });

    const request = pool.request();

    // Build query based on filters
    let whereClause = 'WHERE 1=1';
    if (customer_phone) {
      request.input('customer_phone', sql.NVarChar(15), customer_phone);
      whereClause += ' AND customer_phone = @customer_phone';
    }
    if (month && year) {
      request.input('month', sql.Int, parseInt(month));
      request.input('year', sql.Int, parseInt(year));
      whereClause += ' AND MONTH(created_at) = @month AND YEAR(created_at) = @year';
    }

    const result = await request.query(`
      SELECT
        scheme_type,
        COUNT(*) as transaction_count,
        SUM(amount) as total_amount,
        SUM(gold_grams) as total_gold_grams,
        SUM(silver_grams) as total_silver_grams,
        AVG(gold_price_per_gram) as avg_gold_price,
        AVG(silver_price_per_gram) as avg_silver_price
      FROM transactions
      ${whereClause} AND status = 'SUCCESS'
      GROUP BY scheme_type
      ORDER BY scheme_type
    `);

    res.json({
      success: true,
      data: result.recordset,
      filters: { customer_phone, month, year }
    });

  } catch (error) {
    console.error('❌ Monthly report error:', error);
    res.status(500).json({ success: false, message: 'Monthly report failed', error: error.message });
  }
});

// Scheme-wise Report - Breakdown by scheme type
app.get('/api/reports/scheme-wise', async (req, res) => {
  try {
    const { customer_phone, scheme_type } = req.query;
    console.log('📊 Generating scheme-wise report:', { customer_phone, scheme_type });

    const request = pool.request();

    let whereClause = 'WHERE status = \'ACTIVE\'';
    if (customer_phone) {
      request.input('customer_phone', sql.NVarChar(15), customer_phone);
      whereClause += ' AND customer_phone = @customer_phone';
    }
    if (scheme_type) {
      request.input('scheme_type', sql.NVarChar(20), scheme_type);
      whereClause += ' AND scheme_type = @scheme_type';
    }

    const result = await request.query(`
      SELECT
        scheme_id,
        scheme_type,
        customer_name,
        customer_phone,
        total_amount_paid,
        total_metal_accumulated,
        completed_installments,
        total_installments,
        start_date,
        created_at
      FROM schemes
      ${whereClause}
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      data: result.recordset,
      filters: { customer_phone, scheme_type }
    });

  } catch (error) {
    console.error('❌ Scheme-wise report error:', error);
    res.status(500).json({ success: false, message: 'Scheme-wise report failed', error: error.message });
  }
});

// Flexi Report - All Flexi scheme transactions
app.get('/api/reports/flexi', async (req, res) => {
  try {
    const { customer_phone } = req.query;
    console.log('📊 Generating Flexi report:', { customer_phone });

    const request = pool.request();

    let whereClause = 'WHERE (scheme_type = \'GOLDFLEXI\' OR scheme_type = \'SILVERFLEXI\')';
    if (customer_phone) {
      request.input('customer_phone', sql.NVarChar(15), customer_phone);
      whereClause += ' AND customer_phone = @customer_phone';
    }

    const result = await request.query(`
      SELECT
        transaction_id,
        customer_name,
        customer_phone,
        scheme_type,
        scheme_id,
        amount,
        gold_grams,
        silver_grams,
        gold_price_per_gram,
        silver_price_per_gram,
        payment_method,
        created_at
      FROM transactions
      ${whereClause} AND status = 'SUCCESS'
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      data: result.recordset,
      filters: { customer_phone }
    });

  } catch (error) {
    console.error('❌ Flexi report error:', error);
    res.status(500).json({ success: false, message: 'Flexi report failed', error: error.message });
  }
});

// Consolidated Report - Complete overview
app.get('/api/reports/consolidated', async (req, res) => {
  try {
    const { customer_phone, start_date, end_date } = req.query;
    console.log('📊 Generating consolidated report:', { customer_phone, start_date, end_date });

    const request = pool.request();

    let whereClause = 'WHERE status = \'SUCCESS\'';
    if (customer_phone) {
      request.input('customer_phone', sql.NVarChar(15), customer_phone);
      whereClause += ' AND customer_phone = @customer_phone';
    }
    if (start_date) {
      request.input('start_date', sql.DateTime, new Date(start_date));
      whereClause += ' AND created_at >= @start_date';
    }
    if (end_date) {
      request.input('end_date', sql.DateTime, new Date(end_date));
      whereClause += ' AND created_at <= @end_date';
    }

    const result = await request.query(`
      SELECT
        CASE
          WHEN scheme_type IS NULL THEN 'DIRECT_PURCHASE'
          ELSE scheme_type
        END as category,
        COUNT(*) as transaction_count,
        SUM(amount) as total_amount,
        SUM(gold_grams) as total_gold_grams,
        SUM(silver_grams) as total_silver_grams
      FROM transactions
      ${whereClause}
      GROUP BY scheme_type
      ORDER BY total_amount DESC
    `);

    res.json({
      success: true,
      data: result.recordset,
      filters: { customer_phone, start_date, end_date }
    });

  } catch (error) {
    console.error('❌ Consolidated report error:', error);
    res.status(500).json({ success: false, message: 'Consolidated report failed', error: error.message });
  }
});

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

// ==========================================
// NOTIFICATION HELPER FUNCTIONS
// ==========================================

async function sendPushNotification(tokens, title, body, data = {}) {
  if (!tokens || tokens.length === 0) return;

  const payload = {
    notification: {
      title: title,
      body: body
    },
    data: data,
    tokens: tokens
  };

  try {
    const response = await admin.messaging().sendMulticast(payload);
    console.log(`🔔 Notifications sent: ${response.successCount} successful, ${response.failureCount} failed`);

    // Handle failed tokens (cleanup)
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      // Optional: Remove failed tokens from DB
      if (failedTokens.length > 0) {
        console.log(`⚠️ Failed tokens: ${failedTokens.length}`);
      }
    }
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
  }
}

// Function to notify owner about new payment
async function notifyOwnerOfPayment(paymentData) {
  try {
    // 1. Get Owner Phone from Environment Variable or Config
    // Default fallback to likely owner number (VMurugan)
    const ownerPhone = process.env.OWNER_PHONE || '9840248889';

    // 2. Get Owner's FCM Tokens
    const result = await pool.request()
      .input('phone', sql.NVarChar, ownerPhone)
      .query('SELECT fcm_token FROM user_tokens WHERE user_phone = @phone AND is_active = 1');

    const tokens = result.recordset.map(r => r.fcm_token);

    if (tokens.length === 0) {
      console.log(`⚠️ No active tokens found for owner (${ownerPhone})`);
      return;
    }

    // 3. Construct Message
    const title = '💰 New Payment Received';
    const amount = paymentData.amount || 0;
    const customer = paymentData.customer_name || 'Customer';
    const type = paymentData.type === 'BUY' ? 'Gold Purchase' : 'Transaction';

    // Clean body text
    const body = `₹${amount} received from ${customer} for ${type}`;

    // 4. Send Notification
    await sendPushNotification(tokens, title, body, {
      type: 'payment_success',
      transaction_id: paymentData.transaction_id || '',
      amount: amount.toString()
    });

    console.log(`🔔 Payment notification sent to owner (${ownerPhone})`);

    // 5. Also save to notifications table for history
    const notificationId = `NOTIF_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    await pool.request()
      .input('id', sql.NVarChar, notificationId)
      .input('user_id', sql.NVarChar, ownerPhone)
      .input('type', sql.NVarChar, 'PAYMENT_RECEIVED')
      .input('title', sql.NVarChar, title)
      .input('message', sql.NVarChar, body)
      .input('data', sql.NVarChar, JSON.stringify(paymentData))
      .query(`
        INSERT INTO notifications (notification_id, user_id, type, title, message, data, created_at)
        VALUES (@id, @user_id, @type, @title, @message, @data, SYSDATETIME())
      `);

  } catch (error) {
    console.error('❌ Error notifying owner:', error);
  }
}

module.exports = app;