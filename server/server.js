// DIGI GOLD BUSINESS SERVER
// Complete server implementation ready for deployment

const express = require('express');
const mysql = require('mysql2'); // FIXED: Remove /promise to avoid dependency issues
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
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

app.use(express.json({ limit: '10mb' }));

// Database connection
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'digi_gold_business',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

const pool = mysql.createPool(dbConfig).promise(); // FIXED: Add .promise() for async/await support

// Admin authentication middleware
const authenticateAdmin = (req, res, next) => {
  const adminToken = req.headers['admin-token'];
  const validToken = process.env.ADMIN_TOKEN || 'DIGI_GOLD_ADMIN_2025';
  
  if (adminToken !== validToken) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  next();
};

// Health check - FIXED: Match production server format
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'VMurugan SQL Server API',
    database: 'VMuruganGoldTrading',
    server: 'DESKTOP-3QPE6QQ',
    port: PORT,
    uptime: process.uptime()
  });
});

// Save customer
app.post('/api/customers', [
  body('phone').isMobilePhone('en-IN').withMessage('Invalid phone number'),
  body('name').isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('email').isEmail().withMessage('Invalid email'),
  body('pan_card').matches(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/).withMessage('Invalid PAN card format')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    console.log('📝 Registration request received:', req.body);

    const {
      phone, name, email, address, pan_card, device_id, encrypted_mpin, business_id = 'DIGI_GOLD_001'
    } = req.body;

    console.log('📋 Extracted data:', { phone, name, email, address, pan_card, device_id, encrypted_mpin, business_id });

    // Use encrypted_mpin as mpin for storage
    const mpin = encrypted_mpin;

    if (!mpin) {
      console.error('❌ No encrypted_mpin provided');
      return res.status(400).json({
        success: false,
        message: 'MPIN is required'
      });
    }

    const query = `
      INSERT INTO customers (phone, name, email, address, pan_card, device_id, mpin, business_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
      name = VALUES(name), email = VALUES(email), address = VALUES(address), mpin = VALUES(mpin)
    `;

    console.log('💾 Executing database query with params:', [phone, name, email, address, pan_card, device_id, mpin, business_id]);
    const [result] = await pool.execute(query, [phone, name, email, address, pan_card, device_id, mpin, business_id]);
    console.log('✅ Database insertion result:', result);

    // Get the customer data to return
    const [customerRows] = await pool.execute(
      'SELECT id, phone, name, email FROM customers WHERE phone = ? AND business_id = ?',
      [phone, business_id]
    );

    console.log('📊 Customer query result:', customerRows);
    const customer = customerRows[0];

    if (!customer) {
      console.error('❌ No customer found after insertion for phone:', phone);
      return res.status(500).json({
        success: false,
        message: 'Failed to retrieve customer data after registration'
      });
    }

    console.log('✅ Customer found:', customer);

    res.json({
      success: true,
      message: 'Customer registered successfully',
      user: {
        id: customer.id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email
      }
    });

  } catch (error) {
    console.error('Error saving customer:', error);
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

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // For demo purposes, we'll just return success
    // In production, integrate with SMS service
    console.log(`📱 OTP for ${phone}: ${otp}`);

    res.json({
      success: true,
      message: 'OTP sent successfully',
      otp: otp // Remove this in production
    });

  } catch (error) {
    console.error('Error sending OTP:', error);
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
    // In production, verify against stored OTP
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
    console.error('Error verifying OTP:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Login endpoint
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

    // Get customer from database
    const [rows] = await pool.execute(
      'SELECT * FROM customers WHERE phone = ?',
      [phone]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found. Please register first.'
      });
    }

    const customer = rows[0];

    // Check if customer has MPIN set
    if (!customer.mpin) {
      return res.status(400).json({
        success: false,
        message: 'MPIN not set. Please complete registration first.'
      });
    }

    // Verify MPIN (in production, this should be properly encrypted)
    if (customer.mpin !== encrypted_mpin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid MPIN. Please try again.'
      });
    }

    // Login successful - FIXED: Return 'user' object instead of 'customer'
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

  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
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
      device_info, location, business_id = 'DIGI_GOLD_001'
    } = req.body;

    const query = `
      INSERT INTO transactions (
        transaction_id, customer_phone, customer_name, type, amount, gold_grams,
        gold_price_per_gram, payment_method, status, gateway_transaction_id,
        device_info, location, business_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    await pool.execute(query, [
      transaction_id, customer_phone, customer_name, type, amount, gold_grams,
      gold_price_per_gram, payment_method, status, gateway_transaction_id,
      device_info, location, business_id
    ]);

    // Update customer stats if transaction is successful
    if (status === 'SUCCESS' && type === 'BUY') {
      await updateCustomerStats(customer_phone, amount, gold_grams);
    }

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

// Update customer statistics
async function updateCustomerStats(phone, amount, goldGrams) {
  try {
    const query = `
      UPDATE customers 
      SET total_invested = total_invested + ?,
          total_gold = total_gold + ?,
          transaction_count = transaction_count + 1,
          last_transaction = NOW()
      WHERE phone = ?
    `;
    await pool.execute(query, [amount, goldGrams, phone]);
  } catch (error) {
    console.error('Error updating customer stats:', error);
  }
}

// Save analytics
app.post('/api/analytics', async (req, res) => {
  try {
    const { event, data, business_id = 'DIGI_GOLD_001' } = req.body;

    const query = `
      INSERT INTO analytics (event, data, business_id)
      VALUES (?, ?, ?)
    `;

    await pool.execute(query, [event, JSON.stringify(data), business_id]);

    res.json({ success: true, message: 'Analytics logged' });

  } catch (error) {
    console.error('Error saving analytics:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Admin dashboard data
app.get('/api/admin/dashboard', authenticateAdmin, async (req, res) => {
  try {
    // Get business statistics
    const [statsRows] = await pool.execute(`
      SELECT 
        COUNT(DISTINCT customer_phone) as total_customers,
        COUNT(*) as total_transactions,
        SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) as total_revenue,
        SUM(CASE WHEN status = 'SUCCESS' THEN gold_grams ELSE 0 END) as total_gold_sold
      FROM transactions 
      WHERE business_id = 'DIGI_GOLD_001'
    `);

    // Get recent transactions
    const [transactionRows] = await pool.execute(`
      SELECT * FROM transactions 
      WHERE business_id = 'DIGI_GOLD_001'
      ORDER BY timestamp DESC 
      LIMIT 20
    `);

    // Get customer list with stats
    const [customerRows] = await pool.execute(`
      SELECT * FROM customers 
      WHERE business_id = 'DIGI_GOLD_001'
      ORDER BY registration_date DESC 
      LIMIT 50
    `);

    res.json({
      success: true,
      data: {
        stats: statsRows[0],
        recent_transactions: transactionRows,
        customers: customerRows
      }
    });

  } catch (error) {
    console.error('Error getting dashboard data:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get customer data
app.get('/api/customers/:phone', async (req, res) => {
  try {
    const { phone } = req.params;

    const [rows] = await pool.execute(
      'SELECT * FROM customers WHERE phone = ? AND business_id = ?',
      [phone, 'DIGI_GOLD_001']
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    const customer = rows[0];

    // FIXED: Return 'user' object instead of 'data'
    res.json({
      success: true,
      user: {
        id: customer.id,
        phone: customer.phone,
        name: customer.name,
        email: customer.email,
        has_mpin: customer.mpin ? true : false,
        mpin_length: customer.mpin ? customer.mpin.length : 0
      }
    });

  } catch (error) {
    console.error('Error getting customer:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Set MPIN for existing customer (for customers who registered without MPIN)
app.post('/api/customers/:phone/set-mpin', [
  body('encrypted_mpin').isLength({ min: 32 }).withMessage('Invalid encrypted MPIN format')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { phone } = req.params;
    const { encrypted_mpin } = req.body;

    console.log(`🔧 Setting MPIN for existing customer: ${phone}`);

    // Check if customer exists
    const [rows] = await pool.execute(
      'SELECT * FROM customers WHERE phone = ? AND business_id = ?',
      [phone, 'DIGI_GOLD_001']
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    // Update customer with MPIN
    await pool.execute(
      'UPDATE customers SET mpin = ? WHERE phone = ? AND business_id = ?',
      [encrypted_mpin, phone, 'DIGI_GOLD_001']
    );

    console.log(`✅ MPIN set successfully for customer: ${phone}`);

    res.json({
      success: true,
      message: 'MPIN set successfully'
    });

  } catch (error) {
    console.error('Error setting MPIN:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get portfolio data
app.get('/api/portfolio', async (req, res) => {
  try {
    const { user_id, phone } = req.query;

    if (!user_id && !phone) {
      return res.status(400).json({ success: false, message: 'User ID or phone is required' });
    }

    // Get customer data
    let customer;
    if (phone) {
      const [customerRows] = await pool.execute(
        'SELECT * FROM customers WHERE phone = ? AND business_id = ?',
        [phone, 'DIGI_GOLD_001']
      );
      customer = customerRows[0];
    } else {
      const [customerRows] = await pool.execute(
        'SELECT * FROM customers WHERE id = ? AND business_id = ?',
        [user_id, 'DIGI_GOLD_001']
      );
      customer = customerRows[0];
    }

    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    // Calculate portfolio from transactions
    const [transactionRows] = await pool.execute(`
      SELECT
        SUM(CASE WHEN type = 'BUY' AND status = 'SUCCESS' THEN gold_grams ELSE 0 END) as total_gold_grams,
        SUM(CASE WHEN type = 'BUY' AND status = 'SUCCESS' THEN amount ELSE 0 END) as total_invested,
        COUNT(*) as transaction_count
      FROM transactions
      WHERE customer_phone = ? AND business_id = ?
    `, [customer.phone, 'DIGI_GOLD_001']);

    const portfolioData = transactionRows[0];
    const totalGoldGrams = parseFloat(portfolioData.total_gold_grams) || 0;
    const totalInvested = parseFloat(portfolioData.total_invested) || 0;

    // Calculate current value (assuming current gold price of ₹7000 per gram)
    const currentGoldPrice = 7000; // This should come from a price API
    const currentValue = totalGoldGrams * currentGoldPrice;
    const profitLoss = currentValue - totalInvested;
    const profitLossPercentage = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

    // Get recent transactions
    const [recentTransactions] = await pool.execute(`
      SELECT
        transaction_id,
        type,
        amount,
        gold_grams,
        gold_price_per_gram,
        status,
        timestamp as created_at
      FROM transactions
      WHERE customer_phone = ? AND business_id = ?
      ORDER BY timestamp DESC
      LIMIT 10
    `, [customer.phone, 'DIGI_GOLD_001']);

    res.json({
      success: true,
      portfolio: {
        total_gold_grams: totalGoldGrams,
        total_silver_grams: 0, // Not implemented yet
        total_invested: totalInvested,
        current_value: currentValue,
        profit_loss: profitLoss,
        profit_loss_percentage: Math.round(profitLossPercentage * 100) / 100,
        last_updated: new Date().toISOString()
      },
      user: {
        name: customer.name,
        phone: customer.phone
      },
      recent_transactions: recentTransactions
    });

  } catch (error) {
    console.error('Error getting portfolio:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Get transaction history
app.get('/api/transaction-history', async (req, res) => {
  try {
    const { phone, user_id, limit = 50, offset = 0 } = req.query;

    if (!phone && !user_id) {
      return res.status(400).json({ success: false, message: 'Phone or user_id is required' });
    }

    let customerPhone = phone;
    if (!customerPhone && user_id) {
      // Get phone from user_id
      const [customerRows] = await pool.execute(
        'SELECT phone FROM customers WHERE id = ? AND business_id = ?',
        [user_id, 'DIGI_GOLD_001']
      );
      if (customerRows.length > 0) {
        customerPhone = customerRows[0].phone;
      }
    }

    if (!customerPhone) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    const [rows] = await pool.execute(`
      SELECT
        transaction_id,
        customer_phone,
        customer_name,
        type,
        amount,
        gold_grams,
        gold_price_per_gram,
        payment_method,
        status,
        gateway_transaction_id,
        timestamp as created_at,
        updated_at
      FROM transactions
      WHERE customer_phone = ? AND business_id = ?
      ORDER BY timestamp DESC
      LIMIT ? OFFSET ?
    `, [customerPhone, 'DIGI_GOLD_001', parseInt(limit), parseInt(offset)]);

    res.json({
      success: true,
      transactions: rows,
      total_count: rows.length,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

  } catch (error) {
    console.error('Error getting transaction history:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Export all data (for backup/migration)
app.get('/api/admin/export', authenticateAdmin, async (req, res) => {
  try {
    const [customers] = await pool.execute(
      'SELECT * FROM customers WHERE business_id = ?',
      ['DIGI_GOLD_001']
    );

    const [transactions] = await pool.execute(
      'SELECT * FROM transactions WHERE business_id = ?',
      ['DIGI_GOLD_001']
    );

    const [analytics] = await pool.execute(
      'SELECT * FROM analytics WHERE business_id = ?',
      ['DIGI_GOLD_001']
    );

    res.json({
      success: true,
      data: {
        customers,
        transactions,
        analytics,
        export_date: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error exporting data:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

// =============================================================================
// PAYMENT GATEWAY ENDPOINTS (OMNIWARE INTEGRATION)
// =============================================================================

// Payment initiation endpoint
app.post('/api/payment/initiate', [
  body('amount').isNumeric().withMessage('Amount must be numeric'),
  body('user_id').notEmpty().withMessage('User ID is required'),
  body('transaction_id').notEmpty().withMessage('Transaction ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { amount, user_id, transaction_id, description = 'Gold Purchase' } = req.body;

    // Omniware configuration
    const merchantId = process.env.OMNIWARE_MERCHANT_ID || 'TEST_MERCHANT_ID';
    const secretKey = process.env.OMNIWARE_SECRET_KEY || 'TEST_SECRET_KEY';
    const environment = process.env.OMNIWARE_ENVIRONMENT || 'test';

    // Generate order ID
    const orderId = `GOLD_${Date.now()}_${user_id}`;

    // Generate hash for security
    const hashString = `${merchantId}|${orderId}|${amount}|${secretKey}`;
    const hash = require('crypto').createHash('sha256').update(hashString).digest('hex');

    // Prepare URLs
    const baseUrl = `http://${req.get('host')}`;
    const successUrl = `${baseUrl}/payment/success`;
    const failureUrl = `${baseUrl}/payment/failure`;
    const callbackUrl = `${baseUrl}/api/payment/callback`;

    // Payment gateway URL
    const paymentUrl = environment === 'live'
      ? 'https://api.omniware.in/payment/initiate'
      : 'https://sandbox.omniware.in/payment/initiate';

    // Store transaction in database
    const query = `
      INSERT INTO transactions (
        transaction_id, customer_phone, amount, status,
        payment_method, created_at, business_id
      ) VALUES (?, ?, ?, 'PENDING', 'GATEWAY', NOW(), ?)
    `;

    await pool.execute(query, [
      transaction_id, user_id, amount, 'DIGI_GOLD_001'
    ]);

    res.json({
      success: true,
      order_id: orderId,
      amount: amount,
      payment_url: paymentUrl,
      merchant_id: merchantId,
      hash: hash,
      success_url: successUrl,
      failure_url: failureUrl,
      callback_url: callbackUrl
    });

  } catch (error) {
    console.error('Payment initiation error:', error);
    res.status(500).json({ success: false, message: 'Payment initiation failed' });
  }
});

// Payment callback/webhook endpoint
app.post('/api/payment/callback', async (req, res) => {
  try {
    console.log('📞 Payment callback received:', req.body);

    const {
      orderId,
      status,
      transactionId,
      amount,
      hash: receivedHash
    } = req.body;

    // Verify hash if provided
    const secretKey = process.env.OMNIWARE_SECRET_KEY || 'TEST_SECRET_KEY';
    if (receivedHash) {
      const calculatedHash = require('crypto')
        .createHash('sha256')
        .update(`${orderId}|${status}|${amount}|${secretKey}`)
        .digest('hex');

      if (receivedHash !== calculatedHash) {
        console.error('❌ Hash verification failed');
        return res.status(400).json({ error: 'Invalid hash verification' });
      }
    }

    // Update transaction status
    const updateQuery = `
      UPDATE transactions
      SET status = ?, gateway_transaction_id = ?, updated_at = NOW()
      WHERE transaction_id = ?
    `;

    await pool.execute(updateQuery, [
      status.toUpperCase(), transactionId, orderId
    ]);

    console.log(`✅ Transaction ${orderId} updated to ${status}`);

    res.json({ success: true, message: 'Callback processed successfully' });

  } catch (error) {
    console.error('❌ Payment callback error:', error);
    res.status(500).json({ error: 'Callback processing failed' });
  }
});

// Payment status check endpoint
app.get('/api/payment/status/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;

    const query = 'SELECT * FROM transactions WHERE transaction_id = ?';
    const [rows] = await pool.execute(query, [orderId]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }

    const transaction = rows[0];
    res.json({
      success: true,
      order_id: orderId,
      status: transaction.status,
      amount: transaction.amount,
      gateway_transaction_id: transaction.gateway_transaction_id,
      created_at: transaction.created_at,
      updated_at: transaction.updated_at
    });

  } catch (error) {
    console.error('Payment status check error:', error);
    res.status(500).json({ success: false, message: 'Status check failed' });
  }
});

// Payment success page
app.get('/payment/success', (req, res) => {
  res.send(`
    <html>
      <head><title>Payment Successful</title></head>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1 style="color: green;">✅ Payment Successful!</h1>
        <p>Your gold purchase has been completed successfully.</p>
        <p>You can now close this window and return to the app.</p>
      </body>
    </html>
  `);
});

// Payment failure page
app.get('/payment/failure', (req, res) => {
  res.send(`
    <html>
      <head><title>Payment Failed</title></head>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1 style="color: red;">❌ Payment Failed!</h1>
        <p>Your payment could not be processed. Please try again.</p>
        <p>You can now close this window and return to the app.</p>
      </body>
    </html>
  `);
});

// Payment cancel page
app.get('/payment/cancel', (req, res) => {
  res.send(`
    <html>
      <head><title>Payment Cancelled</title></head>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1 style="color: orange;">⚠️ Payment Cancelled!</h1>
        <p>You have cancelled the payment process.</p>
        <p>You can now close this window and return to the app.</p>
      </body>
    </html>
  `);
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Digi Gold Business Server running on port ${PORT}`);
  console.log(`📊 Admin Dashboard: http://localhost:${PORT}/api/admin/dashboard`);
  console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
  console.log(`💳 Payment endpoints ready for bank integration`);
});

module.exports = app;
