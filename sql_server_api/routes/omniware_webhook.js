const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const sql = require('mssql');

// Omniware credentials (same as omniware_upi.js)
const OMNIWARE_CONFIG = {
  GOLD: {
    merchantId: '779285',
    apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
    salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
    name: 'V MURUGAN JEWELLERY'
  },
  SILVER: {
    merchantId: '779295',
    apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
    salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
    name: 'V MURUGAN NAGAI KADAI'
  }
};

/**
 * Verify hash from Omniware webhook
 * Hash calculation as per Omniware documentation (Appendix 2)
 */
function verifyWebhookHash(data, receivedHash, salt) {
  try {
    // Build hash string as per Omniware documentation
    // Format: transaction_id|order_id|amount|response_code
    const hashString = `${data.transaction_id}|${data.order_id}|${data.amount}|${data.response_code}|${salt}`;
    
    // Calculate SHA-512 hash
    const calculatedHash = crypto.createHash('sha512').update(hashString).digest('hex').toUpperCase();
    
    console.log('Hash Verification:');
    console.log('  Received Hash:', receivedHash);
    console.log('  Calculated Hash:', calculatedHash);
    console.log('  Match:', calculatedHash === receivedHash.toUpperCase());
    
    return calculatedHash === receivedHash.toUpperCase();
  } catch (error) {
    console.error('Error verifying hash:', error);
    return false;
  }
}

/**
 * Determine metal type from order_id
 * Order ID format: ORD_timestamp_GOLD or ORD_timestamp_SILVER
 */
function getMetalTypeFromOrderId(orderId) {
  if (orderId.includes('_GOLD_')) return 'GOLD';
  if (orderId.includes('_SILVER_')) return 'SILVER';
  return null;
}

/**
 * Save transaction to database
 */
async function saveTransactionToDatabase(webhookData) {
  try {
    const pool = await sql.connect();
    
    // Extract data
    const transactionId = webhookData.transaction_id;
    const orderId = webhookData.order_id;
    const amount = parseFloat(webhookData.amount);
    const responseCode = parseInt(webhookData.response_code);
    const paymentDatetime = webhookData.payment_datetime;
    const paymentMethod = webhookData.payment_method || 'UPI';
    const customerPhone = webhookData.phone;
    const customerEmail = webhookData.email;
    const customerName = webhookData.name;
    
    // Determine status
    const status = responseCode === 0 ? 'SUCCESS' : 'FAILED';
    
    console.log('💾 Saving transaction to database via webhook:');
    console.log('   Transaction ID:', transactionId);
    console.log('   Order ID:', orderId);
    console.log('   Amount: ₹' + amount);
    console.log('   Status:', status);
    console.log('   Payment DateTime:', paymentDatetime);
    
    // Insert/Update transaction in database
    const result = await pool.request()
      .input('transaction_id', sql.VarChar(50), transactionId)
      .input('order_id', sql.VarChar(50), orderId)
      .input('customer_phone', sql.VarChar(20), customerPhone)
      .input('customer_email', sql.VarChar(100), customerEmail)
      .input('customer_name', sql.VarChar(100), customerName)
      .input('amount', sql.Decimal(10, 2), amount)
      .input('payment_method', sql.VarChar(50), paymentMethod)
      .input('status', sql.VarChar(20), status)
      .input('gateway_transaction_id', sql.VarChar(100), transactionId)
      .input('gateway_response', sql.NVarChar(sql.MAX), JSON.stringify(webhookData))
      .input('payment_datetime', sql.DateTime, new Date(paymentDatetime))
      .query(`
        MERGE transactions AS target
        USING (SELECT @order_id AS order_id) AS source
        ON target.gateway_transaction_id = @gateway_transaction_id
        WHEN MATCHED THEN
          UPDATE SET 
            status = @status,
            gateway_response = @gateway_response,
            updated_at = GETDATE()
        WHEN NOT MATCHED THEN
          INSERT (transaction_id, customer_phone, customer_email, customer_name, amount, 
                  payment_method, status, gateway_transaction_id, gateway_response, created_at)
          VALUES (@transaction_id, @customer_phone, @customer_email, @customer_name, @amount,
                  @payment_method, @status, @gateway_transaction_id, @gateway_response, GETDATE());
      `);
    
    console.log('✅ Transaction saved successfully via webhook');
    return true;
  } catch (error) {
    console.error('❌ Error saving transaction via webhook:', error);
    return false;
  }
}

/**
 * POST /api/omniware/webhook/payment
 * Receives payment notifications from Omniware
 */
router.post('/payment', async (req, res) => {
  try {
    console.log('\n🔔 ========== OMNIWARE WEBHOOK RECEIVED ========== 🔔');
    console.log('Timestamp:', new Date().toISOString());
    console.log('Webhook Data:', JSON.stringify(req.body, null, 2));
    
    const webhookData = req.body;
    
    // Validate required fields
    if (!webhookData.transaction_id || !webhookData.order_id || !webhookData.hash) {
      console.log('❌ Missing required fields in webhook');
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }
    
    // Determine metal type and get appropriate SALT
    const metalType = getMetalTypeFromOrderId(webhookData.order_id);
    if (!metalType) {
      console.log('❌ Cannot determine metal type from order_id:', webhookData.order_id);
      return res.status(400).json({ success: false, error: 'Invalid order_id format' });
    }
    
    const salt = OMNIWARE_CONFIG[metalType].salt;
    
    // Verify hash
    const isValidHash = verifyWebhookHash(webhookData, webhookData.hash, salt);
    if (!isValidHash) {
      console.log('❌ Invalid hash - possible tampering detected!');
      return res.status(403).json({ success: false, error: 'Invalid hash' });
    }

    console.log('✅ Hash verified successfully');

    // Save transaction to database
    const saved = await saveTransactionToDatabase(webhookData);

    if (saved) {
      console.log('✅ ========== WEBHOOK PROCESSED SUCCESSFULLY ========== ✅\n');

      // Return success response to Omniware
      return res.status(200).json({
        success: true,
        message: 'Webhook received and processed',
        transaction_id: webhookData.transaction_id
      });
    } else {
      console.log('❌ Failed to save transaction\n');
      return res.status(500).json({ success: false, error: 'Failed to save transaction' });
    }

  } catch (error) {
    console.error('❌ Error processing webhook:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/omniware/webhook/settlement
 * Receives settlement notifications from Omniware
 */
router.post('/settlement', async (req, res) => {
  try {
    console.log('\n🔔 ========== OMNIWARE SETTLEMENT WEBHOOK ========== 🔔');
    console.log('Settlement Data:', JSON.stringify(req.body, null, 2));

    // TODO: Implement settlement webhook handling if needed

    return res.status(200).json({ success: true, message: 'Settlement webhook received' });
  } catch (error) {
    console.error('Error processing settlement webhook:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/omniware/webhook/test
 * Test endpoint to verify webhook is accessible
 */
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Omniware webhook endpoint is active',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;

