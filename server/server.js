// DIGI GOLD BUSINESS SERVER
// Complete server implementation ready for deployment

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

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

const pool = mysql.createPool(dbConfig);

// Admin authentication middleware
const authenticateAdmin = (req, res, next) => {
  const adminToken = req.headers['admin-token'];
  const validToken = process.env.ADMIN_TOKEN || 'DIGI_GOLD_ADMIN_2025';
  
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
    service: 'Digi Gold Business API'
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

    const {
      phone, name, email, address, pan_card, device_id, business_id = 'DIGI_GOLD_001'
    } = req.body;

    const query = `
      INSERT INTO customers (phone, name, email, address, pan_card, device_id, business_id)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
      name = VALUES(name), email = VALUES(email), address = VALUES(address)
    `;

    await pool.execute(query, [phone, name, email, address, pan_card, device_id, business_id]);

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

    res.json({ success: true, data: rows[0] });

  } catch (error) {
    console.error('Error getting customer:', error);
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

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Digi Gold Business Server running on port ${PORT}`);
  console.log(`📊 Admin Dashboard: http://localhost:${PORT}/api/admin/dashboard`);
  console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
});

module.exports = app;
