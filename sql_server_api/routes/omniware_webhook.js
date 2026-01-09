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
 * Save transaction to database AND credit gold/silver to customer
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

    // Get existing transaction to find gold/silver grams
    const existingTxn = await pool.request()
      .input('order_id', sql.VarChar(50), orderId)
      .query(`SELECT * FROM transactions WHERE transaction_id = @order_id OR gateway_transaction_id = @order_id`);

    let goldGrams = 0;
    let silverGrams = 0;

    if (existingTxn.recordset.length > 0) {
      goldGrams = existingTxn.recordset[0].gold_grams || 0;
      silverGrams = existingTxn.recordset[0].silver_grams || 0;
      console.log(`   Found existing transaction: ${goldGrams}g gold, ${silverGrams}g silver`);
    }

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
        ON target.gateway_transaction_id = @gateway_transaction_id OR target.transaction_id = @order_id
        WHEN MATCHED THEN
          UPDATE SET 
            status = @status,
            gateway_transaction_id = @gateway_transaction_id,
            gateway_response = @gateway_response,
            updated_at = GETDATE()
        WHEN NOT MATCHED THEN
          INSERT (transaction_id, customer_phone, customer_email, customer_name, amount, 
                  payment_method, status, gateway_transaction_id, gateway_response, created_at)
          VALUES (@transaction_id, @customer_phone, @customer_email, @customer_name, @amount,
                  @payment_method, @status, @gateway_transaction_id, @gateway_response, GETDATE());
      `);

    console.log('✅ Transaction saved successfully via webhook');

    // PAYMENT SAFETY: Credit gold/silver if payment succeeded
    if (status === 'SUCCESS' && customerPhone) {
      // Check if ALREADY successful to avoid double crediting
      if (existingTxn.recordset.length > 0 && existingTxn.recordset[0].status === 'SUCCESS') {
        console.log('⚠️ Transaction already marked as SUCCESS. Skipping double credit.');
        return true;
      }

      console.log('💰 Payment SUCCESS - Crediting gold/silver to customer...');

      try {
        // Find if this transaction was linked to a scheme (IMPORTANT for calculation fixes)
        const txnWithScheme = await pool.request()
          .input('order_id', sql.VarChar(50), orderId)
          .query(`SELECT scheme_id, installment_number FROM transactions WHERE transaction_id = @order_id OR gateway_transaction_id = @order_id`);

        if (txnWithScheme.recordset.length > 0 && txnWithScheme.recordset[0].scheme_id) {
          const schemeId = txnWithScheme.recordset[0].scheme_id;
          console.log('📈 Updating linked scheme via webhook:', schemeId);

          await pool.request()
            .input('scheme_id', sql.NVarChar(100), schemeId)
            .input('amount', sql.Decimal(12, 2), amount)
            .input('metal_grams', sql.Decimal(10, 4), goldGrams + silverGrams)
            .query(`
              UPDATE schemes 
              SET total_invested = ISNULL(total_invested, 0) + @amount,
                  total_amount_paid = ISNULL(total_amount_paid, 0) + @amount,
                  total_metal_accumulated = ISNULL(total_metal_accumulated, 0) + @metal_grams,
                  completed_installments = completed_installments + 1,
                  updated_at = GETDATE()
              WHERE scheme_id = @scheme_id
            `);
          console.log('✅ Scheme updated successfully via webhook');
        }

        await pool.request()
          .input('phone', sql.NVarChar(15), customerPhone)
          .input('gold_grams', sql.Decimal(10, 4), goldGrams)
          .input('silver_grams', sql.Decimal(10, 4), silverGrams)
          .input('amount', sql.Decimal(12, 2), amount)
          .query(`
            UPDATE customers 
            SET total_gold = ISNULL(total_gold, 0) + @gold_grams,
                total_silver = ISNULL(total_silver, 0) + @silver_grams,
                total_invested = ISNULL(total_invested, 0) + @amount,
                transaction_count = ISNULL(transaction_count, 0) + 1,
                last_transaction = GETDATE(),
                updated_at = GETDATE()
            WHERE phone = @phone
          `);

        console.log(`✅ Customer ${customerPhone} credited via webhook:`);
        console.log(`   Gold: +${goldGrams}g`);
        console.log(`   Silver: +${silverGrams}g`);
        console.log(`   Amount: +₹${amount}`);

        // TODO: Send push notification to customer
        // notifyCustomer(customerPhone, 'Payment successful! Gold/Silver credited.');

      } catch (creditError) {
        console.error('❌ Error crediting customer:', creditError);
        // Transaction saved but credit failed - will be picked up by reconciliation
      }
    }

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

