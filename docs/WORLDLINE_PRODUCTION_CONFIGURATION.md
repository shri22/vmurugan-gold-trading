# Worldline Payment Gateway - Production Configuration

## ✅ Configuration Complete

This document outlines the production payment gateway configuration for VMurugan Jewellery.

---

## 📋 Merchant Accounts

### **Gold Merchant (779285)**
- **Name:** V MURUGAN JEWELLERY
- **Merchant ID:** 779285
- **Email:** sellamuthu19661234@gmail.com
- **API KEY:** e2b108a7-1ea4-4cc7-89d9-3ba008dfc334
- **SALT:** 47cdd26963f53e3181f93adcf3af487ec28d7643
- **Scheme Code:** first
- **Used For:** Gold Plus and Gold Flexi schemes

### **Silver Merchant (779295)**
- **Name:** V MURUGAN NAGAI KADAI
- **Merchant ID:** 779295
- **Email:** gopinath24949991@gmail.com
- **API KEY:** f1f7f413-3826-4980-ad4d-c22f64ad54d3
- **SALT:** 5ea7c9cb63d933192ac362722d6346e1efa67f7f
- **Scheme Code:** first
- **Used For:** Silver Plus and Silver Flexi schemes

---

## 🔧 Configuration Files

### **1. Server Configuration**
**File:** `sql_server_api/worldline_config.js`

This file contains:
- Production merchant credentials for both Gold and Silver
- Test/UAT credentials for development
- Common configuration (URLs, payment methods, etc.)
- Helper functions to select the correct merchant based on metal type

### **2. Server Integration**
**File:** `sql_server_api/server.js`

Updated sections:
- Line ~2601: Worldline configuration import
- Line ~2808: Token generation endpoint with metal type support
- Merchant selection based on `metalType` parameter

### **3. Flutter App**
**Files:**
- `lib/features/payment/screens/enhanced_payment_screen.dart`
  - Added `metalType` parameter
  - Passes metal type to token request
  
- `lib/features/payment/widgets/payment_options_dialog.dart`
  - Passes metal type to payment screen

---

## 🔄 Payment Flow

```
1. User selects Gold/Silver scheme
   ↓
2. User proceeds to payment
   ↓
3. App determines metal type (gold/silver)
   ↓
4. App requests payment token with metalType parameter
   ↓
5. Server selects correct merchant:
   - Gold → 779285 (V MURUGAN JEWELLERY)
   - Silver → 779295 (V MURUGAN NAGAI KADAI)
   ↓
6. Server generates token with merchant-specific credentials
   ↓
7. App initiates Worldline payment
   ↓
8. Payment processed through correct merchant account
```

---

## 🌐 URLs

- **Payment Gateway:** https://www.paynimo.com/api/paynimoV2.req
- **Return URL:** https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/verify
- **Cancel URL:** https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/cancel

---

## 💳 Payment Methods Enabled

- ✅ Credit Card
- ✅ Debit Card
- ✅ Net Banking
- ✅ UPI
- ✅ Wallets (Paytm, PhonePe, Google Pay, etc.)

---

## 🔒 Security

- All credentials stored in `worldline_config.js`
- HTTPS-only communication
- SHA-512 hash generation for token security
- Separate merchant accounts for Gold and Silver
- Production environment enabled

---

## 🧪 Testing

To test the configuration:

1. **Gold Payment Test:**
   - Join a Gold Plus or Gold Flexi scheme
   - Proceed to payment
   - Verify merchant ID 779285 is used

2. **Silver Payment Test:**
   - Join a Silver Plus or Silver Flexi scheme
   - Proceed to payment
   - Verify merchant ID 779295 is used

---

## 📝 Environment Variables

Set in `sql_server_api/.env`:

```env
WORLDLINE_ENVIRONMENT=PRODUCTION
```

To switch to test mode:
```env
WORLDLINE_ENVIRONMENT=TEST
```

---

## ⚠️ Important Notes

1. **Production Mode:** Currently set to PRODUCTION
2. **Amount Limits:** ₹1 to ₹10,00,000 (10 lakhs)
3. **Currency:** INR only
4. **Transaction Timeout:** 15 minutes
5. **Merchant Selection:** Automatic based on metal type

---

## 🔍 Debugging

Check logs in:
- Server: `sql_server_api/logs/worldline_*.log`
- Flutter App: Device logs or `payment_log_*.txt` in app documents

---

## 📞 Support

For Worldline support:
- Contact Worldline technical team
- Reference Merchant IDs: 779285 (Gold) or 779295 (Silver)
- Integration Guide: `docs/Worldline_Payment_Gateway_Integration_Guide.pdf`

---

**Configuration Date:** 2025-11-30  
**Status:** ✅ Production Ready  
**Environment:** PRODUCTION

