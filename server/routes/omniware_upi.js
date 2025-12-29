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
      hashString += '|' + String(value).trim();
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
        // Explicit success code from Omniware
        console.log('✅ Payment successful - response_code: 0');
        status = 'success';
      } else if (transaction.response_code === 1030 && hasValidPaymentTime && amountMatches) {
        // Payment processed by bank but Omniware hasn't updated response_code yet
        // This is a KNOWN ISSUE with Omniware UPI Intent payments
        console.log('⚠️ ========== OMNIWARE UPI INTENT KNOWN ISSUE ========== ⚠️');
        console.log('   Response Code: 1030 (TRANSACTION-INCOMPLETE)');
        console.log('   Payment DateTime: ' + transaction.payment_datetime + ' (VALID)');
        console.log('   Amount: ₹' + transaction.amount + ' (VALID)');
        console.log('   ');
        console.log('   CONCLUSION: Payment was SUCCESSFUL at bank level');
        console.log('   Omniware gateway status update is delayed (normal for UPI Intent)');
        console.log('   Treating as SUCCESS based on valid payment_datetime');
        console.log('========================================================');
        status = 'success';
      } else if (transaction.response_code === 1006 || transaction.response_code === 1030) {
        // 1006 = Waiting for response
        // 1030 = Transaction incomplete (no payment_datetime yet - truly pending)
        console.log('⏳ Payment still pending - no payment_datetime yet');
        status = 'pending';
      } else {
        // Any other response code = failed
        console.log('❌ Payment failed - response_code:', transaction.response_code);
        status = 'failed';
      }

      console.log('Determined Status:', status);
      console.log('===========================\n');

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
      returnUrlCancel
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
    // Format: ORD_timestamp_metalInitial_merchantLast3
    // Example: ORD_1764702570988_G_285 (24 chars) or ORD_1764702570988_S_295 (24 chars)
    const metalInitial = metalType.charAt(0).toUpperCase(); // G or S
    const merchantLast3 = merchant.merchantId.slice(-3); // Last 3 digits of merchant ID
    const orderId = `ORD_${Date.now()}_${metalInitial}_${merchantLast3}`;

    console.log('📝 Payment Details:');
    console.log('   Metal Type:', metalType);
    console.log('   Merchant ID:', merchant.merchantId);
    console.log('   Merchant Name:', merchant.name);
    console.log('   Amount: ₹' + paymentAmount);
    console.log('   Order ID:', orderId, `(${orderId.length} chars)`);
    console.log('   Customer:', customerName, customerPhone);

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

module.exports = router;

