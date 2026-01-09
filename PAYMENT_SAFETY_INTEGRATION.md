# Payment Safety Integration Guide

## 🎯 Quick Setup (5 steps)

---

## **Step 1: Add Backend Endpoints**

Open `sql_server_api/server.js` and add these lines around **line 2800** (after transaction routes):

```javascript
// PAYMENT SAFETY MECHANISMS
require('./payment_safety_endpoints.js');
```

**OR** copy the entire content from `payment_safety_endpoints.js` and paste it into `server.js` at line 2800.

---

## **Step 2: Configure Your Payment Gateway**

In your payment gateway dashboard (Razorpay, Paytm, etc.):

1. Find **Webhook Settings**
2. Add webhook URL: `https://api.vmuruganjewellery.co.in:3001/api/payment-webhook`
3. Enable events: `payment.success`, `payment.failed`
4. Save webhook secret in `.env`:
   ```
   PAYMENT_GATEWAY_SECRET=your_webhook_secret_here
   ```

---

## **Step 3: Integrate in Flutter App**

Add to `lib/main.dart` - in the `initState()` or app startup:

```dart
import 'features/payment/services/payment_reconciliation_service.dart';

// In your main app widget's initState or after login:
@override
void initState() {
  super.initState();
  _checkPendingPayments();
}

Future<void> _checkPendingPayments() async {
  // Wait for user to be logged in
  await Future.delayed(const Duration(seconds: 2));
  
  // Check and reconcile pending payments
  final result = await PaymentReconciliationService.checkPendingPayments();
  
  if (result['success'] == true && result['pending_count'] > 0) {
    // Show notification to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found ${result['pending_count']} pending payment(s). Verifying...'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

---

## **Step 4: Add Manual Verification Button** (Optional)

In your payment success/failure screen, add a "Verify Payment" button:

```dart
ElevatedButton(
  onPressed: () async {
    final result = await PaymentReconciliationService.verifyTransaction(
      transactionId
    );
    
    if (result['success'] == true) {
      setState(() {
        _status = result['status'];
      });
    }
  },
  child: const Text('Verify Payment Status'),
)
```

---

## **Step 5: Test the Flow**

### **Test Case 1: Normal Flow**
1. Make payment
2. Return to app
3. ✅ Payment credited immediately

### **Test Case 2: App Killed**
1. Make payment
2. Kill app (don't return)
3. Reopen app after 1 minute
4. ✅ App auto-checks and credits payment

### **Test Case 3: Webhook Only**
1. Make payment
2. Kill app
3. Gateway sends webhook
4. ✅ Payment credited via webhook
5. User opens app later, sees credited balance

---

## 🔧 **Troubleshooting**

### **Webhook not working?**
- Check gateway webhook logs
- Verify URL is accessible: `curl https://api.vmuruganjewellery.co.in:3001/api/payment-webhook`
- Check server logs: `tail -f sql_server_api/logs/payments_*.log`

### **App not checking pending payments?**
- Check console for: `🔍 Checking for pending payments...`
- Ensure customer is logged in
- Verify JWT token exists

### **Payments stuck as PENDING?**
- Run manual reconciliation in admin portal
- Check if > 15 minutes old (auto-failed)
- Verify gateway is sending success callback

---

## 📊 **Admin Panel - Reconciliation**

Add this to `admin_portal/index.html`:

```html
<button onclick="reconcileAllPayments()">Reconcile All Pending</button>

<script>
async function reconcileAllPayments() {
  const response = await fetch('https://api.vmuruganjewellery.co.in:3001/api/admin/payment/reconcile-all', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  });
  
  const result = await response.json();
  alert(`Reconciled ${result.stats.verified} transactions`);
}
</script>
```

---

## ✅ **Production Checklist**

- [ ] Backend endpoints added
- [ ] Webhook configured in payment gateway
- [ ] Webhook secret in `.env`
- [ ] Flutter service integrated
- [ ] Auto-check on app startup working
- [ ] Manual verify button added
- [ ] Admin reconciliation panel added
- [ ] Tested all 3 scenarios
- [ ] Webhook logs monitored
- [ ] Payment logs reviewed

---

## 🔐 **Security Notes**

1. **Always verify webhook signature** - Prevents fake payment notifications
2. **Use HTTPS only** - Webhook URL must be HTTPS
3. **Rate limit verification API** - Prevent abuse (already implemented)
4. **Log all payment events** - For audit trail
5. **Monitor pending payments** - Alert if > 10 pending for > 1 hour

---

**All done! No more lost payments!** 🎉

**Questions?** Check `PAYMENT_SAFETY_IMPLEMENTATION.md` for detailed docs.
