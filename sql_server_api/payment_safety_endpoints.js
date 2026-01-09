// ============================================================================
// PAYMENT SAFETY MECHANISMS
// Add these endpoints to server.js after transaction routes (around line 2800)
// ============================================================================

// Payment Gateway Webhook - Called by gateway when payment succeeds/fails
// IMPORTANT: Configure this URL in your payment gateway dashboard
app.post('/api/payment-webhook', async (req, res) => {
    try {
        console.log('🔔 Payment webhook received:', req.body);

        const {
            transaction_id,
            status,
            gateway_transaction_id,
            amount,
            signature // Gateway should send HMAC signature for security
        } = req.body;

        // SECURITY: Verify webhook signature (implement based on your gateway)
        // const isValid = verifyWebhookSignature(req.body, signature);
        // if (!isValid) {
        //   console.error('❌ Invalid webhook signature');
        //   return res.status(403).json({ success: false, message: 'Invalid signature' });
        // }

        if (!transaction_id || !status) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        console.log(`📝 Updating transaction ${transaction_id} to status: ${status}`);

        // Get transaction details
        const txnResult = await pool.request()
            .input('transaction_id', sql.NVarChar, transaction_id)
            .query(`
        SELECT * FROM transactions 
        WHERE transaction_id = @transaction_id
      `);

        if (txnResult.recordset.length === 0) {
            console.error('❌ Transaction not found:', transaction_id);
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        const transaction = txnResult.recordset[0];

        // Update transaction status
        await pool.request()
            .input('transaction_id', sql.NVarChar, transaction_id)
            .input('status', sql.NVarChar, status)
            .input('gateway_txn_id', sql.NVarChar, gateway_transaction_id || null)
            .query(`
        UPDATE transactions 
        SET status = @status,
            gateway_transaction_id = @gateway_txn_id,
            updated_at = SYSDATETIME()
        WHERE transaction_id = @transaction_id
      `);

        console.log(`✅ Transaction ${transaction_id} updated to ${status}`);

        // If SUCCESS, credit gold/silver to customer
        if (status === 'SUCCESS') {
            const phone = transaction.customer_phone;
            const goldGrams = transaction.gold_grams || 0;
            const silverGrams = transaction.silver_grams || 0;

            // Update customer totals
            await pool.request()
                .input('phone', sql.NVarChar, phone)
                .input('gold_grams', sql.Decimal(10, 4), goldGrams)
                .input('silver_grams', sql.Decimal(10, 4), silverGrams)
                .input('amount', sql.Decimal(12, 2), transaction.amount)
                .query(`
          UPDATE customers 
          SET total_gold = ISNULL(total_gold, 0) + @gold_grams,
              total_silver = ISNULL(total_silver, 0) + @silver_grams,
              total_invested = ISNULL(total_invested, 0) + @amount,
              transaction_count = ISNULL(transaction_count, 0) + 1,
              last_transaction = SYSDATETIME(),
              updated_at = SYSDATETIME()
          WHERE phone = @phone
        `);

            console.log(`✅ Customer ${phone} credited: ${goldGrams}g gold, ${silverGrams}g silver`);

            // TODO: Send push notification to customer
            // await sendPushNotification(phone, {
            //   title: 'Payment Successful!',
            //   body: `Your payment of ₹${transaction.amount} was successful. ${goldGrams}g gold and ${silverGrams}g silver has been credited.`
            // });
        }

        writeServerLog(`Payment webhook: ${transaction_id} → ${status}`, 'payments');

        res.json({
            success: true,
            message: 'Webhook processed successfully',
            transaction_id
        });

    } catch (error) {
        console.error('❌ Payment webhook error:', error);
        writeServerLog(`Payment webhook error: ${error.message}`, 'errors');
        res.status(500).json({ success: false, message: 'Webhook processing failed' });
    }
});

// Verify Payment Status - Called by app to check transaction status
app.post('/api/payment/verify/:transaction_id', flexibleAuth, async (req, res) => {
    try {
        const { transaction_id } = req.params;
        console.log(`🔍 Verifying payment status for: ${transaction_id}`);

        // Get transaction from database
        const txnResult = await pool.request()
            .input('transaction_id', sql.NVarChar, transaction_id)
            .query(`
        SELECT * FROM transactions 
        WHERE transaction_id = @transaction_id
      `);

        if (txnResult.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        const transaction = txnResult.recordset[0];
        const currentStatus = transaction.status;

        console.log(`📊 Current status in DB: ${currentStatus}`);

        // If already SUCCESS or FAILED, no need to verify again
        if (currentStatus === 'SUCCESS' || currentStatus === 'FAILED') {
            return res.json({
                success: true,
                transaction_id,
                status: currentStatus,
                message: 'Transaction already finalized',
                needs_update: false
            });
        }

        // TODO: Call payment gateway API to verify actual status
        // This depends on your payment gateway's API
        // Example for Razorpay:
        // const gatewayStatus = await verifyWithGateway(transaction.gateway_transaction_id);

        // For now, we'll check if it's been pending too long (> 10 minutes)
        const createdTime = new Date(transaction.created_at).getTime();
        const now = Date.now();
        const minutesPending = (now - createdTime) / (1000 * 60);

        let newStatus = currentStatus;
        let shouldUpdate = false;

        if (minutesPending > 10 && currentStatus === 'PENDING') {
            // If pending for more than 10 minutes, mark as FAILED
            newStatus = 'FAILED';
            shouldUpdate = true;
            console.log(`⏰ Transaction pending for ${minutesPending.toFixed(1)} minutes, marking as FAILED`);
        }

        // Update if status changed
        if (shouldUpdate) {
            await pool.request()
                .input('transaction_id', sql.NVarChar, transaction_id)
                .input('status', sql.NVarChar, newStatus)
                .query(`
          UPDATE transactions 
          SET status = @status,
              updated_at = SYSDATETIME()
          WHERE transaction_id = @transaction_id
        `);

            console.log(`✅ Transaction ${transaction_id} updated to ${newStatus}`);
        }

        res.json({
            success: true,
            transaction_id,
            status: newStatus,
            previous_status: currentStatus,
            needs_update: shouldUpdate,
            minutes_pending: minutesPending
        });

    } catch (error) {
        console.error('❌ Payment verification error:', error);
        res.status(500).json({ success: false, message: 'Verification failed' });
    }
});

// Get Pending Payments - Returns all pending transactions for a customer
app.get('/api/payment/pending/:phone', flexibleAuth, async (req, res) => {
    try {
        const { phone } = req.params;
        console.log(`📋 Fetching pending payments for: ${phone}`);

        const result = await pool.request()
            .input('phone', sql.NVarChar, phone)
            .query(`
        SELECT * FROM transactions
        WHERE customer_phone = @phone 
          AND status = 'PENDING'
        ORDER BY created_at DESC
      `);

        console.log(`✅ Found ${result.recordset.length} pending transactions`);

        // Auto-verify all pending transactions
        const verified = [];
        for (const txn of result.recordset) {
            const createdTime = new Date(txn.created_at).getTime();
            const now = Date.now();
            const minutesPending = (now - createdTime) / (1000 * 60);

            let status = txn.status;

            // TODO: Call payment gateway API for each transaction
            // For now, mark as failed if > 10 minutes old
            if (minutesPending > 10) {
                status = 'FAILED';

                await pool.request()
                    .input('transaction_id', sql.NVarChar, txn.transaction_id)
                    .input('status', sql.NVarChar, status)
                    .query(`
            UPDATE transactions 
            SET status = @status,
                updated_at = SYSDATETIME()
            WHERE transaction_id = @transaction_id
          `);

                console.log(`⏰ Auto-failed transaction ${txn.transaction_id} (pending ${minutesPending.toFixed(1)} min)`);
            }

            verified.push({
                ...txn,
                status,
                minutes_pending: minutesPending
            });
        }

        res.json({
            success: true,
            pending_count: verified.length,
            transactions: verified
        });

    } catch (error) {
        console.error('❌ Error fetching pending payments:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch pending payments' });
    }
});

// Reconcile All Pending - Admin endpoint to manually reconcile all pending transactions
app.post('/api/admin/payment/reconcile-all', async (req, res) => {
    try {
        console.log('🔄 Starting bulk payment reconciliation...');

        // Get all pending transactions
        const result = await pool.request().query(`
      SELECT * FROM transactions
      WHERE status = 'PENDING'
      ORDER BY created_at ASC
    `);

        const pending = result.recordset;
        console.log(`📊 Found ${pending.length} pending transactions to reconcile`);

        const stats = {
            total: pending.length,
            verified: 0,
            success: 0,
            failed: 0,
            still_pending: 0
        };

        for (const txn of pending) {
            const createdTime = new Date(txn.created_at).getTime();
            const now = Date.now();
            const minutesPending = (now - createdTime) / (1000 * 60);

            // TODO: Call payment gateway API to verify
            // For now, fail transactions > 15 minutes old
            if (minutesPending > 15) {
                await pool.request()
                    .input('transaction_id', sql.NVarChar, txn.transaction_id)
                    .query(`
            UPDATE transactions 
            SET status = 'FAILED',
                updated_at = SYSDATETIME()
            WHERE transaction_id = @transaction_id
          `);

                stats.failed++;
                stats.verified++;
            } else {
                stats.still_pending++;
            }
        }

        console.log('✅ Bulk reconciliation complete:', stats);
        writeServerLog(`Bulk reconciliation: ${JSON.stringify(stats)}`, 'admin');

        res.json({
            success: true,
            message: 'Reconciliation complete',
            stats
        });

    } catch (error) {
        console.error('❌ Bulk reconciliation error:', error);
        res.status(500).json({ success: false, message: 'Reconciliation failed' });
    }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Verify webhook signature (implement based on your payment gateway)
function verifyWebhookSignature(payload, signature) {
    // Example for Razorpay:
    // const expectedSignature = crypto
    //   .createHmac('sha256', process.env.PAYMENT_GATEWAY_SECRET)
    //   .update(JSON.stringify(payload))
    //   .digest('hex');
    // return expectedSignature === signature;

    // For now, return true (implement proper verification)
    return true;
}

// Send push notification (implement using Firebase Admin SDK)
async function sendPushNotification(phone, notification) {
    try {
        // Get FCM token for customer
        const tokenResult = await pool.request()
            .input('phone', sql.NVarChar, phone)
            .query(`SELECT fcm_token FROM customers WHERE phone = @phone`);

        if (tokenResult.recordset.length > 0 && tokenResult.recordset[0].fcm_token) {
            const token = tokenResult.recordset[0].fcm_token;

            await admin.messaging().send({
                token,
                notification: {
                    title: notification.title,
                    body: notification.body
                }
            });

            console.log(`📱 Push notification sent to ${phone}`);
        }
    } catch (error) {
        console.error('📱 Push notification error:', error.message);
    }
}
