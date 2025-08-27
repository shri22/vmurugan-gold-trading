# 💳 VMurugan Gold Trading - Payment Integration Guide

## 🏦 **URLs to Provide to Bank for Whitelisting**

### **🔗 EXACT URLs for Bank Whitelisting:**

✅ **CONFIGURED WITH YOUR ACTUAL PUBLIC IP: 103.124.152.220**

#### **1. Payment Callback/Webhook URL** ⭐ (MOST IMPORTANT)
```
http://103.124.152.220:3000/api/payment/callback
```

#### **2. Payment Success URL**
```
http://103.124.152.220:3000/payment/success
```

#### **3. Payment Failure URL**
```
http://103.124.152.220:3000/payment/failure
```

#### **4. Payment Cancel URL**
```
http://103.124.152.220:3000/payment/cancel
```

#### **5. Payment Status Check URL**
```
http://103.124.152.220:3000/api/payment/status/{orderId}
```

#### **6. Payment Initiation URL**
```
http://103.124.152.220:3000/api/payment/initiate
```

---

## 📋 **Information to Provide to Bank/Payment Gateway**

### **Business Information:**
- **Business Name:** V Murugan Gold Trading
- **Business Type:** Digital Gold Trading Platform
- **App Name:** VMurugan Gold Trading
- **Package Name:** `com.vmurugan.goldtrading`

### **Technical Information:**
- **Server Technology:** Node.js with Express
- **Database:** MySQL
- **Security:** Hash-based verification
- **Environment:** HTTP (testing) / HTTPS (production)

### **Contact Information:**
- **Technical Contact:** [Your email]
- **Business Contact:** [Your phone]
- **Server IP:** [Your public IP]
- **Server Port:** 3000

---

## 🔧 **Payment Flow Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │────│  Your Node.js   │────│  Bank/Payment   │
│   (Customer)    │    │     Server      │    │    Gateway      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. Initiate Payment   │                       │
         │──────────────────────▶│                       │
         │                       │ 2. Create Order       │
         │                       │──────────────────────▶│
         │                       │                       │
         │                       │ 3. Payment URL        │
         │                       │◀──────────────────────│
         │ 4. Redirect to Pay    │                       │
         │◀──────────────────────│                       │
         │                       │                       │
         │ 5. Complete Payment   │                       │
         │──────────────────────────────────────────────▶│
         │                       │                       │
         │                       │ 6. Payment Callback   │
         │                       │◀──────────────────────│
         │                       │                       │
         │ 7. Success/Failure    │                       │
         │◀──────────────────────│                       │
```

---

## 🧪 **Testing Your Payment Integration**

### **Step 1: Test Payment Endpoints**

```bash
# Test payment initiation
curl -X POST http://YOUR_PUBLIC_IP:3000/api/payment/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "user_id": "9876543210",
    "transaction_id": "TXN_TEST_123",
    "description": "Test Gold Purchase"
  }'

# Test payment status
curl -X GET http://YOUR_PUBLIC_IP:3000/api/payment/status/TXN_TEST_123

# Test callback (simulate bank callback)
curl -X POST http://YOUR_PUBLIC_IP:3000/api/payment/callback \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "GOLD_123456_9876543210",
    "status": "success",
    "transactionId": "BANK_TXN_789",
    "amount": 1000
  }'
```

### **Step 2: Test Success/Failure Pages**

Open in browser:
- `http://YOUR_PUBLIC_IP:3000/payment/success`
- `http://YOUR_PUBLIC_IP:3000/payment/failure`
- `http://YOUR_PUBLIC_IP:3000/payment/cancel`

---

## 🔐 **Security Configuration**

### **Environment Variables for Production**

Create `.env` file in your server directory:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=vmurugan_user
DB_PASSWORD=your_secure_password
DB_NAME=digi_gold_business

# Payment Gateway Configuration
OMNIWARE_MERCHANT_ID=your_actual_merchant_id
OMNIWARE_SECRET_KEY=your_actual_secret_key
OMNIWARE_API_KEY=your_actual_api_key
OMNIWARE_ENVIRONMENT=test

# Server Configuration
PORT=3000
ALLOWED_ORIGINS=http://YOUR_PUBLIC_IP:3000,https://yourdomain.com
ADMIN_TOKEN=your_secure_admin_token
```

### **Hash Verification**

Your server automatically verifies payment callbacks using SHA256 hash:
```
Hash = SHA256(orderId|status|amount|secretKey)
```

---

## 📱 **Mobile App Integration**

### **Update App Configuration**

In `lib/core/config/client_server_config.dart`:
```dart
// Payment endpoints
static const String paymentInitiateEndpoint = '$baseUrl/payment/initiate';
static const String paymentCallbackEndpoint = '$baseUrl/payment/callback';
static const String paymentStatusEndpoint = '$baseUrl/payment/status';
```

### **Payment Flow in App**

1. **User selects gold amount**
2. **App calls payment initiate API**
3. **Server returns payment URL**
4. **App opens payment URL in browser**
5. **User completes payment**
6. **Bank sends callback to server**
7. **Server updates transaction status**
8. **App checks payment status**
9. **App updates user portfolio**

---

## 🚀 **Production Deployment**

### **For Production (Recommended):**

1. **Get Domain Name**
   ```
   https://api.vmurugan.com/api/payment/callback
   ```

2. **Install SSL Certificate**
   ```bash
   sudo certbot --nginx -d api.vmurugan.com
   ```

3. **Update URLs to HTTPS**
   ```
   https://api.vmurugan.com/api/payment/callback
   https://api.vmurugan.com/payment/success
   https://api.vmurugan.com/payment/failure
   ```

4. **Update Environment**
   ```env
   OMNIWARE_ENVIRONMENT=live
   ```

---

## ✅ **Checklist for Bank Integration**

### **Before Contacting Bank:**
- [ ] Payment endpoints added to Node.js server
- [ ] Server running on public IP
- [ ] All URLs accessible from internet
- [ ] Hash verification implemented
- [ ] Database configured for transactions
- [ ] Success/failure pages working

### **Information to Provide Bank:**
- [ ] **Callback URL:** `http://YOUR_IP:3000/api/payment/callback`
- [ ] **Success URL:** `http://YOUR_IP:3000/payment/success`
- [ ] **Failure URL:** `http://YOUR_IP:3000/payment/failure`
- [ ] **Business details:** V Murugan Gold Trading
- [ ] **Technical contact:** Your email/phone
- [ ] **Server IP:** Your public IP address

### **Testing with Bank:**
- [ ] Bank can access all URLs
- [ ] Callback endpoint receives data correctly
- [ ] Hash verification works
- [ ] Transaction status updates properly
- [ ] Success/failure redirects work

---

## 🎯 **Next Steps**

1. **Restart Your Node.js Server**
   ```bash
   cd server
   node server.js
   ```

2. **Test All Payment Endpoints**
   - Use the testing commands above
   - Verify all URLs are accessible

3. **Contact Bank/Payment Gateway**
   - Provide the URLs listed at the top
   - Share business and technical details
   - Schedule integration testing

4. **Complete Integration Testing**
   - Test with bank's sandbox environment
   - Verify end-to-end payment flow
   - Test error scenarios

5. **Go Live**
   - Switch to production environment
   - Update to HTTPS URLs
   - Monitor transactions

**Your payment integration is now ready for bank whitelisting! 🏆**
