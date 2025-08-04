// MOCK SERVER FOR TESTING - NO DATABASE REQUIRED
console.log('🚀 Starting VMurugan Mock API Server...');

const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage for testing
let customers = {};
let otpStore = {};
let transactions = [];
let schemes = [];

console.log('📋 Mock Server Configuration:');
console.log('   Port:', PORT);
console.log('   Mode: Testing (No Database)');
console.log('   Network: Accessible on all interfaces');

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    message: 'VMurugan Mock API Server is running',
    timestamp: new Date().toISOString(),
    mode: 'testing'
  });
});

// Test network access page
app.get('/test_network_access.html', (req, res) => {
  res.sendFile(__dirname + '/test_network_access.html');
});

// Send OTP
app.post('/api/auth/send-otp', (req, res) => {
  try {
    const { phone } = req.body;
    
    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }
    
    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP
    otpStore[phone] = {
      otp: otp,
      timestamp: Date.now(),
      attempts: 0
    };
    
    console.log(`📱 OTP for ${phone}: ${otp}`);
    
    res.json({
      success: true,
      message: 'OTP sent successfully',
      otp: otp // For testing only
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send OTP'
    });
  }
});

// Verify OTP
app.post('/api/auth/verify-otp', (req, res) => {
  try {
    const { phone, otp } = req.body;
    
    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }
    
    // Check OTP
    const storedOtpData = otpStore[phone];
    if (!storedOtpData) {
      return res.status(400).json({
        success: false,
        message: 'OTP not found or expired'
      });
    }
    
    // Check if OTP is expired (5 minutes)
    if (Date.now() - storedOtpData.timestamp > 5 * 60 * 1000) {
      delete otpStore[phone];
      return res.status(400).json({
        success: false,
        message: 'OTP expired'
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
    delete otpStore[phone];
    
    // Check if customer exists
    let customer = customers[phone];
    let isNewUser = false;
    
    if (!customer) {
      // New user
      isNewUser = true;
      customer = {
        customer_id: `CUST_${Date.now()}`,
        phone: phone,
        name: 'New User',
        email: '',
        address: '',
        registration_date: new Date().toISOString()
      };
      customers[phone] = customer;
    }
    
    console.log(`✅ OTP verified for ${phone} - ${isNewUser ? 'New' : 'Existing'} user`);
    
    res.json({
      success: true,
      message: 'Login successful',
      isNewUser: isNewUser,
      customer: customer
    });
    
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
});

// Login with MPIN
app.post('/api/login', (req, res) => {
  try {
    const { phone, encrypted_mpin } = req.body;

    if (!phone || !encrypted_mpin) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and MPIN are required'
      });
    }

    const customer = customers[phone];
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found. Please register first.'
      });
    }

    // Check if customer has MPIN set
    if (!customer.encrypted_mpin) {
      return res.status(400).json({
        success: false,
        message: 'MPIN not set. Please complete registration first.'
      });
    }

    // Verify MPIN (in production, this should be properly encrypted)
    if (customer.encrypted_mpin !== encrypted_mpin) {
      console.log(`❌ Invalid MPIN attempt for ${phone}`);
      return res.status(401).json({
        success: false,
        message: 'Invalid MPIN. Please try again.'
      });
    }

    console.log(`✅ MPIN Login successful for ${phone}`);

    res.json({
      success: true,
      message: 'Login successful',
      customer: customer
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
app.post('/api/customers', (req, res) => {
  try {
    const { phone, name, email, address, encrypted_mpin } = req.body;

    if (!phone || !name) {
      return res.status(400).json({
        success: false,
        message: 'Phone and name are required'
      });
    }

    // Update customer data
    if (customers[phone]) {
      customers[phone] = {
        ...customers[phone],
        name: name,
        email: email || '',
        address: address || '',
        encrypted_mpin: encrypted_mpin
      };
    } else {
      customers[phone] = {
        customer_id: `CUST_${Date.now()}`,
        phone: phone,
        name: name,
        email: email || '',
        address: address || '',
        encrypted_mpin: encrypted_mpin,
        registration_date: new Date().toISOString()
      };
    }

    console.log(`👤 Customer saved: ${name} (${phone}) with MPIN: ${encrypted_mpin ? 'Set' : 'Not Set'}`);

    res.json({
      success: true,
      message: 'Customer saved successfully',
      customer: customers[phone]
    });

  } catch (error) {
    console.error('Error saving customer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save customer'
    });
  }
});

// Get customer
app.get('/api/customers/:phone', (req, res) => {
  try {
    const { phone } = req.params;
    const customer = customers[phone];
    
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }
    
    res.json({
      success: true,
      customer: customer
    });
    
  } catch (error) {
    console.error('Error getting customer:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get customer'
    });
  }
});

// Test database connection (mock)
app.get('/api/test-connection', (req, res) => {
  res.json({
    success: true,
    message: 'Mock database connection successful',
    timestamp: new Date().toISOString(),
    mode: 'testing'
  });
});

// Save transaction (mock)
app.post('/api/transactions', (req, res) => {
  try {
    const transaction = {
      ...req.body,
      transaction_id: `TXN_${Date.now()}`,
      timestamp: new Date().toISOString()
    };
    
    transactions.push(transaction);
    
    console.log(`💰 Transaction saved: ${transaction.transaction_id}`);
    
    res.json({
      success: true,
      message: 'Transaction saved successfully',
      transaction: transaction
    });
    
  } catch (error) {
    console.error('Error saving transaction:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save transaction'
    });
  }
});

// Get transactions
app.get('/api/transactions', (req, res) => {
  res.json({
    success: true,
    transactions: transactions
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 VMurugan Mock API Server running on port ${PORT}`);
  console.log(`📊 Health Check: http://localhost:${PORT}/health`);
  console.log(`🌐 Network Access: http://192.168.31.129:${PORT}/health`);
  console.log(`📱 Mobile can access: http://192.168.31.129:${PORT}`);
  console.log(`🧪 Mode: Testing (No Database Required)`);
  console.log(`📝 All data stored in memory for testing`);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down Mock API Server...');
  process.exit(0);
});
