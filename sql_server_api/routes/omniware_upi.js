const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const axios = require('axios');

// Omniware API Configuration
const OMNIWARE_API_URL = 'https://pgbiz.omniware.in';

// Merchant Credentials
const MERCHANTS = {
  gold: {
    merchantId: '779285',
    apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
    salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
    name: 'V MURUGAN JEWELLERY'
  },
  silver: {
    merchantId: '779295',
    apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
    salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
    name: 'V MURUGAN NAGAI KADAI'
  }
};

/**
 * Generate SHA-512 hash for Omniware API
 * Hash format: SALT|param1|param2|... (sorted alphabetically by key)
 */
function generateHash(params, salt) {
  // Sort parameters alphabetically by key
  const sortedKeys = Object.keys(params).sort();

  // Create pipe-delimited string starting with salt
  let hashString = salt;
  sortedKeys.forEach(key => {
    const value = params[key];
    // Only include non-empty values
    if (value !== null && value !== undefined && value !== '') {
      // Sanitize value: remove newlines (\r\n), normalize whitespace, and trim
      // This prevents hash validation errors for customers with line breaks in their address
      const sanitizedValue = String(value)
        .replace(/[\r\n]+/g, ' ')  // Replace all \r and \n with space
        .replace(/\s+/g, ' ')       // Replace multiple spaces with single space
        .trim();                     // Remove leading/trailing whitespace

      hashString += '|' + sanitizedValue;
    }
  });

  console.log('Hash String:', hashString);

  // Generate SHA-512 hash and convert to uppercase
  const hash = crypto.createHash('sha512').update(hashString).digest('hex').toUpperCase();

  return hash;
}

/**
 * POST /api/omniware/check-payment-status
 * Check payment status by order ID
 * Used by UPI Mode (Payment Page) to verify payment after return_url callback
 */
router.post('/check-payment-status', async (req, res) => {
  try {
    const { metalType, orderId } = req.body;

    // Validate required fields
    if (!metalType || !orderId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: metalType and orderId'
      });
    }

    // Get merchant credentials based on metal type
    const merchant = MERCHANTS[metalType.toLowerCase()];
    if (!merchant) {
      return res.status(400).json({
        success: false,
        error: 'Invalid metal type. Must be "gold" or "silver"'
      });
    }

    console.log(`\n=== Checking Payment Status for ${merchant.name} ===`);
    console.log('Order ID:', orderId);

    // Prepare payment status request parameters
    const params = {
      api_key: merchant.apiKey,
      order_id: orderId
    };

    // Generate hash
    const hash = generateHash(params, merchant.salt);
    params.hash = hash;

    console.log('Status Check Parameters:', JSON.stringify(params, null, 2));

    // Call Omniware Payment Status API
    const response = await axios.post(
      `${OMNIWARE_API_URL}/v2/paymentstatus`,
      new URLSearchParams(params).toString(),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    console.log('Payment Status Response:', JSON.stringify(response.data, null, 2));

    if (response.data && response.data.data) {
      const paymentData = response.data.data;

      // Check if it's an array (multiple transactions) or single object
      const transaction = Array.isArray(paymentData) ? paymentData[0] : paymentData;

      console.log('\n=== Payment Status Check ===');
      console.log('Response Code:', transaction.response_code);
      console.log('Response Message:', transaction.response_message);
      console.log('Payment DateTime:', transaction.payment_datetime);
      console.log('Amount:', transaction.amount);
      console.log('Order ID:', transaction.order_id);

      // Determine payment status based on response code and payment_datetime
      let status;

      // IMPORTANT: Omniware UPI Intent payments have a known issue where response_code
      // stays at 1030 (TRANSACTION-INCOMPLETE) even after payment is successful at bank level.
      //
      // According to Omniware documentation and real-world behavior:
      // - response_code 0 = SUCCESS (explicit success)
      // - response_code 1030 = TRANSACTION-INCOMPLETE (could be pending OR successful)
      // - payment_datetime is populated ONLY when payment is actually processed by bank
      //
      // Therefore, if payment_datetime exists and is valid, the payment IS successful,
      // regardless of response_code being 1030.

      const hasValidPaymentTime = transaction.payment_datetime &&
        transaction.payment_datetime !== '' &&
        transaction.payment_datetime !== null &&
        transaction.payment_datetime !== '0000-00-00 00:00:00';

      // Check if amount matches (additional validation)
      const amountMatches = transaction.amount && parseFloat(transaction.amount) > 0;

      if (transaction.response_code === 0) {
        status = 'success';
      } else if (transaction.response_code === 1006 || transaction.response_code === 1030) {
        status = 'pending';
      } else {
        status = 'failed';
      }

      // --- FETCH SCHEMES FOR FRONTEND SELECTION ---
      let activeSchemes = [];
      let customerName = transaction.customer_name || 'Customer';

      if (status === 'success') {
        try {
          const pool = await require('mssql').connect();
          const phone = transaction.customer_phone;

          if (phone) {
            const metalTypeResolved = (transaction.order_id.includes('_SILVER_') || transaction.order_id.includes('_S_')) ? 'SILVER' : 'GOLD';
            const schemeRes = await pool.request()
              .input('p', require('mssql').NVarChar(15), phone)
              .input('m', require('mssql').NVarChar(10), metalTypeResolved)
              .query("SELECT scheme_id, scheme_type, metal_type, monthly_amount, completed_installments FROM schemes WHERE customer_phone = @p AND metal_type = @m AND status = 'ACTIVE'");
            activeSchemes = schemeRes.recordset;

            const custRes = await pool.request().input('p', require('mssql').NVarChar(15), phone).query("SELECT name FROM customers WHERE phone = @p");
            if (custRes.recordset.length > 0) customerName = custRes.recordset[0].name;
          }
        } catch (e) { console.error('Scheme Fetch Error:', e.message); }
      }

      // If dry run, just return info and stop
      if (req.body.dryRun && status === 'success') {
        return res.json({
          success: true,
          data: {
            ...transaction,
            status: 'success',
            active_schemes: activeSchemes,
            customer_name: customerName
          }
        });
      }

      console.log('Determined Status:', status);
      console.log('===========================\n');

      // SAFETY NET: If payment is successful, update database and credit customer
      // This handles cases where the webhook might be delayed or misconfigured
      if (status === 'success') {
        try {
          const pool = await require('mssql').connect();

          // 1. Get transaction details to find gold/silver grams
          const existingTxn = await pool.request()
            .input('order_id', require('mssql').VarChar(50), transaction.order_id)
            .query(`SELECT status, customer_phone, gold_grams, silver_grams, amount, scheme_id, scheme_type FROM transactions WHERE transaction_id = @order_id OR gateway_transaction_id = @order_id`);

          if (existingTxn.recordset.length > 0) {
            const txn = existingTxn.recordset[0];

            // Only proceed if not already marked success
            if (txn.status !== 'SUCCESS') {
              console.log('🔄 Auto-updating pending transaction to SUCCESS...');

              // 2. Update transaction status
              await pool.request()
                .input('order_id', require('mssql').VarChar(50), transaction.order_id)
                .input('gateway_id', require('mssql').VarChar(100), transaction.transaction_id)
                .input('response_raw', require('mssql').NVarChar(require('mssql').MAX), JSON.stringify(transaction))
                .query(`
                  UPDATE transactions 
                  SET status = 'SUCCESS', 
                      gateway_transaction_id = @gateway_id,
                      gateway_response = @response_raw,
                      updated_at = GETDATE() 
                  WHERE transaction_id = @order_id OR gateway_transaction_id = @order_id
                `);

              // --- SCHEME LINKING ---
              let schemeId = req.body.schemeId || txn.scheme_id;

              if (!schemeId && txn.customer_phone) {
                const metalTypeCurrent = (transaction.order_id.includes('_SILVER_') || transaction.order_id.includes('_S_')) ? 'SILVER' : 'GOLD';
                const schemeDiscovery = await pool.request()
                  .input('phone', require('mssql').NVarChar(15), txn.customer_phone)
                  .input('metal', require('mssql').NVarChar(10), metalTypeCurrent)
                  .query("SELECT scheme_id, scheme_type FROM schemes WHERE customer_phone = @phone AND metal_type = @metal AND status = 'ACTIVE'");

                if (schemeDiscovery.recordset.length === 1) {
                  schemeId = schemeDiscovery.recordset[0].scheme_id;
                }
              }

              if (schemeId) {
                await pool.request()
                  .input('order_id', require('mssql').VarChar(50), transaction.order_id)
                  .input('sid', require('mssql').NVarChar(100), schemeId)
                  .query("UPDATE transactions SET scheme_id = @sid WHERE transaction_id = @order_id");
              }

              // 3. Update scheme if linked
              if (schemeId) {
                try {
                  const metalGrams = (txn.gold_grams || 0) + (txn.silver_grams || 0);
                  await pool.request()
                    .input('scheme_id', require('mssql').NVarChar(100), schemeId)
                    .input('amount', require('mssql').Decimal(12, 2), txn.amount)
                    .input('metal_grams', require('mssql').Decimal(10, 4), metalGrams)
                    .query(`
                      UPDATE schemes
                      SET total_invested = ISNULL(total_invested, 0) + @amount,
                          total_amount_paid = ISNULL(total_amount_paid, 0) + @amount,
                          total_metal_accumulated = ISNULL(total_metal_accumulated, 0) + @metal_grams,
                          completed_installments = completed_installments + 1,
                          updated_at = GETDATE()
                      WHERE scheme_id = @scheme_id
                    `);
                } catch (schemeError) {
                  console.error('❌ Error updating scheme:', schemeError.message);
                }
              }

              // 4. Credit customer balance
              if (txn.customer_phone) {
                await pool.request()
                  .input('phone', require('mssql').NVarChar(15), txn.customer_phone)
                  .input('gold', require('mssql').Decimal(10, 4), txn.gold_grams || 0)
                  .input('silver', require('mssql').Decimal(10, 4), txn.silver_grams || 0)
                  .input('amt', require('mssql').Decimal(12, 2), txn.amount || 0)
                  .query(`
                    UPDATE customers 
                    SET total_gold = ISNULL(total_gold, 0) + @gold,
                        total_silver = ISNULL(total_silver, 0) + @silver,
                        total_invested = ISNULL(total_invested, 0) + @amt,
                        transaction_count = ISNULL(transaction_count, 0) + 1,
                        last_transaction = GETDATE(),
                        updated_at = GETDATE()
                    WHERE phone = @phone
                  `);
              }
            }
          } else {
            // TRANSACTION MISSING ENTIRELY FROM DB
            console.log('🚨 Transaction missing. Running Smart Match & Recovery...');

            const metalTypeResolved = (transaction.order_id.includes('_SILVER_') || transaction.order_id.includes('_S_')) ? 'SILVER' : 'GOLD';
            const amt = parseFloat(transaction.amount);
            const txnPhone = transaction.customer_phone;
            const payTime = transaction.payment_datetime || new Date().toISOString();

            // 🛑 STEP 1: SMART MATCH FOR MANUAL RECORDS (UPI_...)
            // Search for any manual SUCCESS record with same phone and amount on the same day
            const smartMatch = await pool.request()
              .input('p', require('mssql').NVarChar(15), txnPhone)
              .input('a', require('mssql').Decimal(12, 2), amt)
              .input('m', require('mssql').NVarChar(10), metalTypeResolved)
              .input('pay_time', require('mssql').DateTime, payTime)
              .query(`
                    SELECT transaction_id FROM transactions 
                    WHERE customer_phone = @p 
                    AND status = 'SUCCESS' 
                    AND amount = @a 
                    AND metal_type = @m
                    AND gateway_transaction_id IS NULL -- Only match manual records without a bank ref
                    AND DATEDIFF(hour, created_at, @pay_time) BETWEEN -24 AND 24 -- Tight window: +/- 24 hours from payment time
                `);

            if (smartMatch.recordset.length > 0) {
              const existingId = smartMatch.recordset[0].transaction_id;
              console.log(`✨ Smart Match Found! Updating manual record ${existingId} with Bank Ref.`);

              await pool.request()
                .input('eid', require('mssql').VarChar(50), existingId)
                .input('gtid', require('mssql').VarChar(100), transaction.transaction_id)
                .input('resp', require('mssql').NVarChar(require('mssql').MAX), JSON.stringify(transaction))
                .query(`
                        UPDATE transactions 
                        SET gateway_transaction_id = @gtid,
                            gateway_response = @resp,
                            updated_at = GETDATE()
                        WHERE transaction_id = @eid
                    `);

              // Add determined status to the returned object for frontend consistency
              const responseData = { ...transaction, status: status };
              return res.json({ success: true, message: 'Updated existing record with bank verification.', data: responseData });
            }

            // 🛑 STEP 2: HISTORICAL RATE RECOVERY
            // Try to find the rate used on the actual payment date
            let recoveryRate = 0;

            const historicalRes = await pool.request()
              .input('pt', require('mssql').DateTime, payTime)
              .input('m', require('mssql').NVarChar(10), metalTypeResolved)
              .query(`
                    SELECT TOP 1 
                        CASE WHEN @m = 'GOLD' THEN gold_price_per_gram ELSE silver_price_per_gram END as rate
                    FROM transactions 
                    WHERE status = 'SUCCESS' 
                    AND metal_type = @m
                    AND DATEDIFF(day, created_at, @pt) = 0
                    ORDER BY created_at DESC
                `);

            if (historicalRes.recordset.length > 0) {
              recoveryRate = parseFloat(historicalRes.recordset[0].rate);
              console.log(`📅 Found historical ${metalTypeResolved} rate for ${payTime}: ₹${recoveryRate}`);
            } else {
              // Fallback to latest known rate if no historical match
              const rateRes = await pool.request()
                .input('m', require('mssql').NVarChar(10), metalTypeResolved)
                .query(`SELECT TOP 1 ${metalTypeResolved === 'GOLD' ? 'gold_price_per_gram' : 'silver_price_per_gram'} as rate FROM transactions WHERE status = 'SUCCESS' AND metal_type = @m ORDER BY created_at DESC`);
              if (rateRes.recordset.length > 0) recoveryRate = rateRes.recordset[0].rate;
            }

            // Default fallback if all rate discovery fails
            if (!recoveryRate || recoveryRate < 10) recoveryRate = metalTypeResolved === 'GOLD' ? 6500 : 100;

            const goldG = metalTypeResolved === 'GOLD' ? (amt / recoveryRate) : 0;
            const silverG = metalTypeResolved === 'SILVER' ? (amt / recoveryRate) : 0;

            // Find Customer Name
            let customerName = 'Recovered Customer';
            if (txnPhone) {
              const custRes = await pool.request()
                .input('p', require('mssql').NVarChar(15), txnPhone)
                .query("SELECT name FROM customers WHERE phone = @p");
              if (custRes.recordset.length > 0) customerName = custRes.recordset[0].name;
            }

            // 🛑 STEP 3: CREATE VERIFIED RECORD
            await pool.request()
              .input('oid', require('mssql').VarChar(50), transaction.order_id)
              .input('gtid', require('mssql').VarChar(100), transaction.transaction_id)
              .input('phone', require('mssql').NVarChar(15), txnPhone)
              .input('name', require('mssql').NVarChar(100), customerName)
              .input('amt', require('mssql').Decimal(12, 2), amt)
              .input('gold', require('mssql').Decimal(10, 4), goldG)
              .input('silver', require('mssql').Decimal(10, 4), silverG)
              .input('metal', require('mssql').NVarChar(10), metalTypeResolved)
              .input('grate', require('mssql').Decimal(10, 2), metalTypeResolved === 'GOLD' ? recoveryRate : 0)
              .input('srate', require('mssql').Decimal(10, 2), metalTypeResolved === 'SILVER' ? recoveryRate : 0)
              .input('pay_time', require('mssql').DateTime, payTime)
              .input('resp', require('mssql').NVarChar(require('mssql').MAX), JSON.stringify(transaction))
              .query(`
                INSERT INTO transactions (
                  transaction_id, gateway_transaction_id, customer_phone, customer_name, 
                  type, amount, status, payment_method, metal_type, business_id,
                  gold_grams, silver_grams, gold_price_per_gram, silver_price_per_gram,
                  gateway_response, created_at, updated_at
                ) VALUES (
                  @oid, @gtid, @phone, @name, 
                  'BUY', @amt, 'SUCCESS', 'OMNIWARE_RECOVERY', @metal, 'VMURUGAN_001',
                  @gold, @silver, @grate, @srate,
                  @resp, @pay_time, GETDATE()
                )
              `);

            // 🛑 STEP 4: CREDIT CUSTOMER & SCHEME
            if (txnPhone) {
              // Update Customer
              await pool.request()
                .input('phone', require('mssql').NVarChar(15), txnPhone)
                .input('gold', require('mssql').Decimal(10, 4), goldG)
                .input('silver', require('mssql').Decimal(10, 4), silverG)
                .input('amt', require('mssql').Decimal(12, 2), amt)
                .query(`UPDATE customers SET total_gold = ISNULL(total_gold, 0) + @gold, total_silver = ISNULL(total_silver, 0) + @silver, total_invested = ISNULL(total_invested, 0) + @amt, updated_at = GETDATE() WHERE phone = @phone`);

              // Update Scheme Selection
              let sidSelected = req.body.schemeId;

              if (!sidSelected) {
                const schemeMatch = await pool.request()
                  .input('phone', require('mssql').NVarChar(15), txnPhone)
                  .input('metal', require('mssql').NVarChar(10), metalTypeResolved)
                  .query("SELECT scheme_id FROM schemes WHERE customer_phone = @phone AND metal_type = @metal AND status = 'ACTIVE'");

                if (schemeMatch.recordset.length === 1) {
                  sidSelected = schemeMatch.recordset[0].scheme_id;
                }
              }

              if (sidSelected) {
                await pool.request()
                  .input('sid', require('mssql').NVarChar(100), sidSelected)
                  .input('amt', require('mssql').Decimal(12, 2), amt)
                  .input('grams', require('mssql').Decimal(10, 4), goldG + silverG)
                  .query(`UPDATE schemes SET total_invested = ISNULL(total_invested, 0) + @amt, total_amount_paid = ISNULL(total_amount_paid, 0) + @amt, total_metal_accumulated = ISNULL(total_metal_accumulated, 0) + @grams, completed_installments = completed_installments + 1, updated_at = GETDATE() WHERE scheme_id = @sid`);

                // Link transaction to this scheme
                await pool.request()
                  .input('oid', require('mssql').VarChar(50), transaction.order_id)
                  .input('sid', require('mssql').NVarChar(100), sidSelected)
                  .query("UPDATE transactions SET scheme_id = @sid WHERE transaction_id = @oid");
              }
            }
            console.log('✅ Missing transaction recovered and credited successfully.');
          }
        } catch (dbError) {
          console.error('❌ Database update error:', dbError.message);
        }
      }

      return res.json({
        success: true,
        data: {
          transactionId: transaction.transaction_id,
          orderId: transaction.order_id,
          amount: transaction.amount,
          currency: transaction.currency,
          responseCode: transaction.response_code,
          responseMessage: transaction.response_message,
          paymentMode: transaction.payment_mode,
          paymentChannel: transaction.payment_channel,
          paymentDatetime: transaction.payment_datetime,
          status: status,
          hash: transaction.hash
        }
      });
    } else if (response.data && response.data.error) {
      return res.json({
        success: false,
        error: response.data.error.message,
        errorCode: response.data.error.code
      });
    } else {
      throw new Error('Invalid response from Omniware API');
    }

  } catch (error) {
    console.error('Error checking payment status:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.response?.data || error.message
    });
  }
});

/**
 * POST /api/omniware/payment-page-url
 * Generate Omniware payment page URL (UPI Mode - not UPI Intent)
 * This opens Omniware's payment page where user can scan QR code or enter UPI ID
 *
 * Advantages over UPI Intent:
 * - Instant payment status (no 1030 delay)
 * - Automatic return to app via return_url
 * - Webhooks work reliably
 * - Better user experience
 */
router.post('/payment-page-url', async (req, res) => {
  try {
    console.log('\n🌐 ========== OMNIWARE UPI MODE (PAYMENT PAGE) ========== 🌐');
    console.log('Request Body:', JSON.stringify(req.body, null, 2));

    const {
      metalType,
      amount,
      description,
      customerName,
      customerEmail,
      customerPhone,
      customerAddress,
      customerCity,
      customerState,
      customerCountry,
      customerZipCode,
      returnUrl,
      returnUrlFailure,
      returnUrlCancel,
      goldGrams,
      silverGrams,
      scheme_id,
      scheme_type,
      installment_number
    } = req.body;

    // Validate required fields
    if (!metalType || !amount || !customerPhone) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: metalType, amount, customerPhone'
      });
    }

    // Validate metal type
    const metalTypeLower = metalType.toLowerCase();
    if (!MERCHANTS[metalTypeLower]) {
      return res.status(400).json({
        success: false,
        error: 'Invalid metal type. Must be "gold" or "silver"'
      });
    }

    const merchant = MERCHANTS[metalTypeLower];

    // Validate amount (minimum ₹10 for UPI)
    const paymentAmount = parseFloat(amount);
    if (isNaN(paymentAmount) || paymentAmount < 10) {
      return res.status(400).json({
        success: false,
        error: 'Amount must be at least ₹10 (Omniware UPI gateway minimum)'
      });
    }

    // Generate unique order ID (max 30 characters for Omniware)
    // Format: ORD_timestamp_METALTYPE_merchantLast3
    // Example: ORD_1764702570988_GOLD_285 (25 chars) or ORD_1764702570988_SILVER_295 (27 chars)
    const merchantLast3 = merchant.merchantId.slice(-3); // Last 3 digits of merchant ID
    const orderId = `ORD_${Date.now()}_${metalType.toUpperCase()}_${merchantLast3}`;

    console.log('📝 Payment Details:');
    console.log('   Metal Type:', metalType);
    console.log('   Merchant ID:', merchant.merchantId);
    console.log('   Merchant Name:', merchant.name);
    console.log('   Amount: ₹' + paymentAmount);
    console.log('   Order ID:', orderId, `(${orderId.length} chars)`);
    console.log('   Customer:', customerName, customerPhone);

    // PRE-CREATE PENDING TRANSACTION (Ensures webhook doesn't 404)
    try {
      const sql = require('mssql');
      const pool = await sql.connect();
      const request = pool.request();

      // Basic calculation for analytics (will be finalized on success)
      // This allows the admin portal to see pending volumes
      request.input('transaction_id', sql.NVarChar(100), orderId);
      request.input('customer_phone', sql.NVarChar(15), customerPhone);
      request.input('customer_name', sql.NVarChar(100), customerName || 'Customer');
      request.input('type', sql.NVarChar(10), 'BUY');
      request.input('amount', sql.Decimal(12, 2), paymentAmount);
      request.input('status', sql.NVarChar(20), 'PENDING');
      request.input('payment_method', sql.NVarChar(50), 'OMNIWARE_UPI');
      request.input('metal_type', sql.NVarChar(10), metalType.toUpperCase());
      request.input('business_id', sql.NVarChar(50), 'VMURUGAN_001');

      // Scheme context (IMPORTANT for calculation fixes)
      request.input('scheme_id', sql.NVarChar(100), scheme_id || null);
      request.input('scheme_type', sql.NVarChar(20), scheme_type || null);
      request.input('installment_number', sql.Int, installment_number ? parseInt(installment_number) : null);

      // DEFENSIVE FIX: Ensure grams go to correct column based on metal_type
      // Bug: Flutter app sometimes sends goldGrams for SILVER transactions
      let finalGoldGrams = 0;
      let finalSilverGrams = 0;
      let finalGoldPrice = 0;
      let finalSilverPrice = 0;

      if (metalType.toUpperCase() === 'GOLD') {
        // For GOLD transactions, use goldGrams (or fallback to silverGrams if app sent wrong param)
        finalGoldGrams = parseFloat(goldGrams) || parseFloat(silverGrams) || 0;
        finalGoldPrice = finalGoldGrams > 0 ? paymentAmount / finalGoldGrams : 0;
        finalSilverGrams = 0;
        finalSilverPrice = 0;
        console.log(`   🟡 GOLD Transaction: ${finalGoldGrams}g @ ₹${finalGoldPrice.toFixed(2)}/g`);
      } else if (metalType.toUpperCase() === 'SILVER') {
        // For SILVER transactions, use silverGrams (or fallback to goldGrams if app sent wrong param)
        finalSilverGrams = parseFloat(silverGrams) || parseFloat(goldGrams) || 0;
        finalSilverPrice = finalSilverGrams > 0 ? paymentAmount / finalSilverGrams : 0;
        finalGoldGrams = 0;
        finalGoldPrice = 0;
        console.log(`   ⚪ SILVER Transaction: ${finalSilverGrams}g @ ₹${finalSilverPrice.toFixed(2)}/g`);
      }

      request.input('gold_grams', sql.Decimal(10, 4), finalGoldGrams);
      request.input('gold_price_per_gram', sql.Decimal(10, 2), finalGoldPrice);
      request.input('silver_grams', sql.Decimal(10, 4), finalSilverGrams);
      request.input('silver_price_per_gram', sql.Decimal(10, 2), finalSilverPrice);

      await request.query(`
        INSERT INTO transactions (
          transaction_id, customer_phone, customer_name, type, amount, status, 
          payment_method, metal_type, business_id, gold_grams, gold_price_per_gram,
          silver_grams, silver_price_per_gram, scheme_id, scheme_type, installment_number,
          created_at, updated_at
        ) VALUES (
          @transaction_id, @customer_phone, @customer_name, @type, @amount, @status, 
          @payment_method, @metal_type, @business_id, @gold_grams, @gold_price_per_gram,
          @silver_grams, @silver_price_per_gram, @scheme_id, @scheme_type, @installment_number,
          GETDATE(), GETDATE()
        )
      `);
      console.log('✅ Pending transaction created in database:', orderId);
    } catch (dbError) {
      console.error('⚠️ Failed to pre-create pending transaction:', dbError.message);
      // Don't fail the whole request, just log it
    }

    // Prepare payment request parameters (as per Omniware Payment Request API documentation)
    const params = {
      api_key: merchant.apiKey,
      order_id: orderId,
      mode: 'LIVE', // or 'TEST' for testing
      amount: String(paymentAmount),
      currency: 'INR',
      description: description || `${metalType.toUpperCase()} Purchase - ₹${paymentAmount}`,
      name: customerName || 'Customer',
      email: customerEmail || 'customer@vmuruganjewellery.co.in',
      phone: customerPhone,
      address_line_1: customerAddress || '',
      address_line_2: '',
      city: customerCity || 'Chennai',
      state: customerState || 'Tamil Nadu',
      country: customerCountry || 'IND',
      zip_code: customerZipCode || '600001',
      return_url: returnUrl || 'vmurugangold://payment/success',
      return_url_failure: returnUrlFailure || 'vmurugangold://payment/failure',
      return_url_cancel: returnUrlCancel || 'vmurugangold://payment/cancel',
      payment_options: 'upi', // Only show UPI option
      udf1: metalType,
      udf2: merchant.merchantId,
      udf3: '',
      udf4: '',
      udf5: ''
    };

    // --- SANITIZE PARAMETERS ---
    // Specifically remove newlines and extra spaces from all parameters
    // This prevents "Expected Hash String" (1023) errors for customers with multi-line addresses
    Object.keys(params).forEach(key => {
      if (typeof params[key] === 'string') {
        params[key] = params[key]
          .replace(/[\r\n]+/g, ' ')
          .replace(/\s+/g, ' ')
          .trim();
      }
    });

    // Generate hash
    const hash = generateHash(params, merchant.salt);
    params.hash = hash;

    console.log('🔐 Hash generated successfully');
    console.log('📤 Sending payment page request to Omniware...');

    // Create payment page URL with form data
    // Since this is a POST request, we need to return the URL and parameters
    // The Flutter app will open this in a WebView or browser

    const paymentPageUrl = `${OMNIWARE_API_URL}/v2/paymentrequest`;

    console.log('✅ Payment page URL generated successfully');
    console.log('   URL:', paymentPageUrl);
    console.log('========================================\n');

    res.json({
      success: true,
      paymentPageUrl: paymentPageUrl,
      formParams: params,
      orderId: orderId,
      merchantId: merchant.merchantId,
      metalType: metalType,
      amount: paymentAmount,
      message: 'Payment page URL generated. POST these params to the URL to open payment page.'
    });

  } catch (error) {
    console.error('❌ Error generating payment page URL:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Cleanup Abandoned PENDING Transactions
 * Checks PENDING transactions with Omniware and marks as FAILED if not found
 */
router.post('/cleanup-abandoned', async (req, res) => {
  try {
    console.log('\n🧹 Starting cleanup of abandoned PENDING transactions...');

    const { hoursOld = 1 } = req.body; // Default: 1 hour old
    const pool = await require('mssql').connect();

    // Find PENDING transactions older than specified hours
    const cutoffTime = new Date();
    cutoffTime.setHours(cutoffTime.getHours() - hoursOld);

    const result = await pool.request()
      .input('cutoff', require('mssql').DateTime, cutoffTime)
      .query(`
        SELECT transaction_id, metal_type, amount, customer_name, customer_phone, created_at
        FROM transactions
        WHERE status = 'PENDING'
        AND created_at < @cutoff
        AND payment_method LIKE 'OMNIWARE%'
        ORDER BY created_at DESC
      `);

    const pendingTransactions = result.recordset;
    console.log(`📊 Found ${pendingTransactions.length} PENDING transactions older than ${hoursOld} hour(s)`);

    if (pendingTransactions.length === 0) {
      return res.json({
        success: true,
        message: 'No abandoned transactions found',
        summary: {
          total: 0,
          failed: 0,
          stillPending: 0,
          needsReconciliation: 0
        }
      });
    }

    let failedCount = 0;
    let stillPendingCount = 0;
    let successCount = 0;
    const details = [];

    for (const txn of pendingTransactions) {
      console.log(`\n🔍 Checking: ${txn.transaction_id}`);

      const metalType = txn.metal_type.toLowerCase();
      const merchant = MERCHANTS[metalType];

      if (!merchant) {
        console.log(`⚠️ Unknown metal type: ${txn.metal_type}`);
        continue;
      }

      // Check with Omniware
      const params = {
        api_key: merchant.apiKey,
        order_id: txn.transaction_id
      };
      params.hash = generateHash(params, merchant.salt);

      try {
        const response = await axios.post(
          `${OMNIWARE_API_URL}/v2/paymentstatus`,
          new URLSearchParams(params).toString(),
          { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        if (response.data && response.data.error && response.data.error.code === 1028) {
          // Transaction not found in gateway - mark as FAILED
          await pool.request()
            .input('txn_id', require('mssql').VarChar(100), txn.transaction_id)
            .query(`
              UPDATE transactions
              SET status = 'FAILED',
                  updated_at = GETDATE()
              WHERE transaction_id = @txn_id
            `);

          console.log(`   ❌ FAILED - Not found in gateway (abandoned)`);
          failedCount++;
          details.push({
            transaction_id: txn.transaction_id,
            customer_name: txn.customer_name,
            amount: txn.amount,
            action: 'FAILED',
            reason: 'Not found in gateway'
          });
        } else if (response.data && response.data.data) {
          const transaction = Array.isArray(response.data.data) ? response.data.data[0] : response.data.data;

          if (transaction.response_code === 0) {
            console.log(`   ✅ SUCCESS - Found in gateway (needs manual reconciliation)`);
            successCount++;
            details.push({
              transaction_id: txn.transaction_id,
              customer_name: txn.customer_name,
              amount: txn.amount,
              action: 'NEEDS_RECONCILIATION',
              reason: 'Successful in gateway but PENDING in database'
            });
          } else if (transaction.response_code === 1006 || transaction.response_code === 1030) {
            console.log(`   ⏳ Still PENDING in gateway`);
            stillPendingCount++;
            details.push({
              transaction_id: txn.transaction_id,
              customer_name: txn.customer_name,
              amount: txn.amount,
              action: 'STILL_PENDING',
              reason: 'Still processing in gateway'
            });
          } else {
            // Transaction explicitly FAILED in gateway
            await pool.request()
              .input('txn_id', require('mssql').VarChar(100), txn.transaction_id)
              .input('raw', require('mssql').NVarChar(require('mssql').MAX), JSON.stringify(transaction))
              .query(`
                UPDATE transactions
                SET status = 'FAILED',
                    gateway_response = @raw,
                    updated_at = GETDATE()
                WHERE transaction_id = @txn_id
              `);

            console.log(`   ❌ FAILED - Gateway returned error code: ${transaction.response_code}`);
            failedCount++;
            details.push({
              transaction_id: txn.transaction_id,
              customer_name: txn.customer_name,
              amount: txn.amount,
              action: 'FAILED',
              reason: `Failed in gateway (Code: ${transaction.response_code})`
            });
          }
        }
      } catch (error) {
        console.log(`   ⚠️ Error checking gateway: ${error.message}`);
      }

      // Small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 300));
    }

    console.log('\n' + '='.repeat(60));
    console.log('📈 CLEANUP SUMMARY');
    console.log('='.repeat(60));
    console.log(`❌ Marked as FAILED: ${failedCount}`);
    console.log(`⏳ Still PENDING: ${stillPendingCount}`);
    console.log(`🔔 Needs Reconciliation: ${successCount}`);
    console.log('='.repeat(60));

    res.json({
      success: true,
      message: `Cleanup completed: ${failedCount} marked as FAILED, ${stillPendingCount} still pending, ${successCount} need reconciliation`,
      summary: {
        total: pendingTransactions.length,
        failed: failedCount,
        stillPending: stillPendingCount,
        needsReconciliation: successCount
      },
      details: details
    });

  } catch (error) {
    console.error('❌ Cleanup failed:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

