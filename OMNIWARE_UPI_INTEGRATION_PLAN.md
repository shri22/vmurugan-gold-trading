# Omniware UPI Integration Plan

## 📋 Summary from PDF Analysis

I've successfully read the **Omniware Payment Gateway Integration Guide (69 pages)**.

### ✅ Key Findings:

1. **UPI Intent URL API EXISTS** - Section 5 (Page 17)
   - Endpoint: `https://{pg_api_url}/v2/getpaymentrequestintenturl`
   - Method: POST
   - Returns: UPI deep link that opens UPI apps directly

2. **Payment Status API** - Section 6 (Page 18)
   - Endpoint: `https://{pg_api_url}/v2/paymentstatus`
   - Method: POST
   - Used to check payment status after UPI payment

3. **Hash Calculation** - Appendix 2 (Page 53)
   - Algorithm: SHA-512
   - Format: `SALT|param1|param2|...` (sorted alphabetically)
   - Convert to UPPERCASE

---

## 🔍 What We Know:

### ✅ Your Merchant Credentials:

**Gold Merchant (779285):**
- API Key: `e2b108a7-1ea4-4cc7-89d9-3ba008dfc334`
- Salt: `47cdd26963f53e3181f93adcf3af487ec28d7643`

**Silver Merchant (779295):**
- API Key: `f1f7f413-3826-4980-ad4d-c22f64ad54d3`
- Salt: `5ea7c9cb63d933192ac362722d6346e1efa67f7f`

### ❌ What We Still Need:

**API Base URL** - The documentation shows `{pg_api_url}` as a placeholder.

Examples of what it might be:
- `https://api.omniware.in`
- `https://pg.omniware.in`
- `https://payment.omniware.in`
- Or something else entirely

---

## 🎯 Integration Approach:

### **Step 1: Create UPI Intent URL (Server-Side)**

**Endpoint:** `POST https://{pg_api_url}/v2/getpaymentrequestintenturl`

**Parameters:**
- `api_key` - Merchant API Key
- `order_id` - Unique order ID
- `mode` - "LIVE" or "TEST"
- `amount` - Payment amount
- `currency` - "INR"
- `description` - Payment description
- `name` - Customer name
- `email` - Customer email
- `phone` - Customer phone
- `city`, `state`, `country`, `zip_code` - Customer address
- `return_url` - Callback URL
- `hash` - SHA-512 hash of all parameters

**Response:**
```json
{
  "data": {
    "upi_intent_url": "upi://pay?pa=MERCUAT@bank&pn=...",
    "payment_request_id": 6478789,
    "order_id": 123456
  }
}
```

### **Step 2: Open UPI App (Flutter)**

Use `url_launcher` package to open the `upi_intent_url`:
```dart
await launchUrl(Uri.parse(upiIntentUrl));
```

This will open UPI apps like GPay, PhonePe, Paytm, etc.

### **Step 3: Check Payment Status (Server-Side)**

**Endpoint:** `POST https://{pg_api_url}/v2/paymentstatus`

**Parameters:**
- `api_key`
- `order_id`
- `hash`

**Response:**
```json
{
  "data": {
    "transaction_id": "HDVISC1299876438",
    "response_code": 0,
    "response_message": "Transaction successful",
    "amount": "100.00",
    ...
  }
}
```

---

## 📧 Next Steps:

### **URGENT: Contact Omniware Support**

Ask them:
1. **What is the API base URL for production?**
   - `https://{pg_api_url}` → Need actual URL

2. **Confirm UPI Intent URL API works with UPI-only merchant accounts**

3. **Any additional configuration needed for mobile apps?**

---

## 🚀 Implementation Ready:

Once you provide the API base URL, I will:

1. ✅ Create Node.js API endpoints:
   - `/api/omniware/create-upi-payment` - Generate UPI Intent URL
   - `/api/omniware/check-payment-status` - Check payment status

2. ✅ Update Flutter app:
   - Remove SDK-based payment
   - Implement UPI Intent URL flow
   - Add payment status polling

3. ✅ Test end-to-end UPI payment flow

---

**Waiting for API base URL from Omniware!** 🎯

