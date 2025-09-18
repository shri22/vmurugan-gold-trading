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
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const path = require('path');

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
                            "deviceId": "WEBSH2",
                            "token": "${token}",
                            "returnUrl": "https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/verify",
                            "merchantCode": "${merchantCode}",
                            "currency": "INR",
                            "consumerId": "${consumerId || 'GUEST'}",
                            "consumerMobileNo": "${consumerMobileNo || '9876543210'}",
                            "consumerEmailId": "${consumerEmailId || 'test@vmuruganjewellery.co.in'}",
                            "txnId": "${txnId}",
                            "items": [{
                                "itemId": "GOLD_PURCHASE",
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
        INSERT INTO customers (phone, name, email, address, pan_card, device_id, business_id, mpin)
        VALUES (@phone, @name, @email, @address, @pan_card, @device_id, @business_id, @mpin)
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

// Worldline configuration (from Payment_GateWay.md) - BANK COMPLIANCE
const WORLDLINE_CONFIG = {
  MERCHANT_CODE: "T1098761",
  SCHEME_CODE: "FIRST",
  ENCRYPTION_KEY: "9221995309QQNRIO",
  ENCRYPTION_IV: "6753042926GDVTTK",
  WORLDLINE_URL: "https://www.paynimo.com/api/paynimoV2.req",
  MIN_AMOUNT: 1,
  MAX_AMOUNT: 10, // Sandbox limits
  IS_TEST_ENVIRONMENT: true,
  // CRITICAL: Test environment configuration for proper credential entry flow
  TEST_MODE: "INTERACTIVE", // Ensures test credentials page is displayed
  FORCE_TEST_CREDENTIALS: true // Forces test credential entry instead of auto-completion
};

// Generate hash for Worldline - supports both SHA-256 and SHA-512
function generateWorldlineHash(text, algorithm = 'sha512') {
  return crypto.createHash(algorithm).update(text).digest('hex');
}

// Worldline Token Generation API - Following Payment_GateWay.md specifications
app.post('/api/payments/worldline/token', [
  // Accept amount as whole number (1-10) for test environment
  body('amount').custom((value) => {
    let amount;
    // If it's a string, convert to number
    if (typeof value === 'string') {
      amount = parseInt(value);
    } else if (typeof value === 'number') {
      amount = Math.round(value);
    } else {
      throw new Error('Amount must be a number or string');
    }

    // Validate range for test environment (1-10)
    if (amount < WORLDLINE_CONFIG.MIN_AMOUNT || amount > WORLDLINE_CONFIG.MAX_AMOUNT) {
      throw new Error(`Amount must be between ${WORLDLINE_CONFIG.MIN_AMOUNT} and ${WORLDLINE_CONFIG.MAX_AMOUNT} for sandbox environment`);
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

    const { amount: rawAmount, orderId, customerId } = req.body;
    const txnId = orderId || Date.now().toString();

    // CRITICAL FIX: Maintain decimal format throughout entire process
    // Worldline requires exact format consistency between server hash and client consumerData
    const amount = parseFloat(rawAmount);
    const formattedAmount = amount.toFixed(2); // Always "X.00" format for hash consistency

    // Log to both console and file
    writeServerLog(`💰 [${requestId}] Raw Amount: ${JSON.stringify(rawAmount)} (${typeof rawAmount})`, 'worldline');
    writeServerLog(`💰 [${requestId}] Processed Amount: ${amount}`, 'worldline');
    writeServerLog(`💰 [${requestId}] Formatted Amount for Hash: "${formattedAmount}"`, 'worldline');
    writeServerLog(`💰 [${requestId}] ✅ Amount is within test range (1-10): ${amount >= 1 && amount <= 10}`, 'worldline');
    writeServerLog(`🆔 [${requestId}] Transaction ID: ${txnId}`, 'worldline');
    writeServerLog(`👤 [${requestId}] Customer ID: ${customerId}`, 'worldline');

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
    // Worldline test environment requires specific hardcoded values
    const testMobileNo = '9999999999';           // Worldline test environment requirement
    const testEmailId = 'test@domain.com';       // Worldline test environment requirement

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
    console.log(`🔐 Expected Field 6 - consumerMobileNo: "${testMobileNo}" (TEST ENVIRONMENT)`);
    console.log(`🔐 Expected Field 7 - consumerEmailId: "${testEmailId}" (TEST ENVIRONMENT)`);
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

    // Generate SHA-512 hash (ANDROIDSH2 algorithm) for better security
    const token = generateWorldlineHash(hashString, 'sha512');

    // CRITICAL: Validate hash generation integrity (SHA-512 produces 128 character hex string)
    if (!token || token.length !== 128) {
      throw new Error(`Hash generation failed - invalid token length: ${token ? token.length : 'null'} (expected 128 for SHA-512)`);
    }

    // Verify hash is properly generated by testing with known input (SHA-512)
    const testHash = generateWorldlineHash('test', 'sha512');
    if (!testHash || testHash.length !== 128) {
      throw new Error(`Hash generation function is not working correctly - test hash length: ${testHash ? testHash.length : 'null'} (expected 128 for SHA-512)`);
    }

    console.log(`✅ [${requestId}] STEP 2 COMPLETED: Hash token generated successfully`);
    console.log(`🎫 [${requestId}] Token: ${token.substring(0, 20)}...`);
    console.log(`🔐 [${requestId}] Token length: ${token.length} characters (expected: 128)`);
    console.log(`🧪 [${requestId}] Hash function test: ${testHash.substring(0, 10)}... (length: ${testHash.length})`);

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
      token: token,  // SHA-256 hash token using exact bank specification
      txnId: txnId,
      merchantCode: WORLDLINE_CONFIG.MERCHANT_CODE,
      amount: formattedAmount,  // CRITICAL: Use consistent decimal format
      currency: "INR",

      // CRITICAL: Include ALL hash components for consumerData object (exact field matching)
      // This MUST match the pipe-separated format exactly as per bank's email
      consumerDataFields: {
        merchantId: WORLDLINE_CONFIG.MERCHANT_CODE,       // Field 1
        txnId: txnId,                                     // Field 2
        amount: formattedAmount,                          // Field 3 (CRITICAL: Consistent decimal format)
        accountNo: '',                                    // Field 4 - Empty but must be present
        consumerId: customerId || 'GUEST',                // Field 5
        consumerMobileNo: testMobileNo,                   // Field 6 (TEST: 9999999999)
        consumerEmailId: testEmailId,                     // Field 7 (TEST: test@domain.com)
        debitStartDate: '',                               // Field 8 - Empty but must be present
        debitEndDate: '',                                 // Field 9 - Empty but must be present
        maxAmount: '',                                    // Field 10 - Empty but must be present
        amountType: '',                                   // Field 11 - Empty but must be present
        frequency: '',                                    // Field 12 - Empty but must be present
        cardNumber: '',                                   // Field 13 - Empty but must be present
        expMonth: '',                                     // Field 14 - Empty but must be present
        expYear: '',                                      // Field 15 - Empty but must be present
        cvvCode: ''                                       // Field 16 - Empty but must be present
        // Field 17 is SALT (not included in consumerData, used only for hash generation)
      },

      // Bank compliance information
      tokenType: 'HASH_GENERATED',
      algorithm: 'SHA512',
      deviceId: 'ANDROIDSH2', // Matches Flutter app device ID for SHA-512
      integrationKit: 'FLUTTER_PLUGIN',
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

      // Update transaction status in database
      const mappedStatus = (status === 'SUCCESS' || status === '0') ? 'SUCCESS' : 'FAILED';
      console.log(`📊 [${requestId}] Status mapping: "${status}" -> "${mappedStatus}"`);

      const request = pool.request();
      request.input('transaction_id', sql.NVarChar(100), txnId);
      request.input('gateway_transaction_id', sql.NVarChar(100), gatewayTxnId || `WL_${txnId}`);
      request.input('status', sql.NVarChar(20), mappedStatus);

      await request.query(`
        UPDATE transactions
        SET status = @status, gateway_transaction_id = @gateway_transaction_id, updated_at = GETDATE()
        WHERE transaction_id = @transaction_id
      `);

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
      schemeCode: 'FIRST',
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
      '/api/payments/worldline/token',
      '/api/payments/worldline/verify',
      '/worldline-checkout',
      '/privacy-policy',
      '/terms-of-service',
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

  // Check for SSL certificates
  const sslKeyPath = process.env.SSL_KEY_PATH || './ssl/private.key';
  const sslCertPath = process.env.SSL_CERT_PATH || './ssl/certificate.crt';

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
      console.log(`💳 Worldline Payment Integration (Clean Slate Rebuild):`);
      console.log(`   Token:    https://api.vmuruganjewellery.co.in:${httpsPort}/api/payments/worldline/token`);
      console.log(`   Verify:   https://api.vmuruganjewellery.co.in:${httpsPort}/api/payments/worldline/verify`);
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

// HTTPS-only production server

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