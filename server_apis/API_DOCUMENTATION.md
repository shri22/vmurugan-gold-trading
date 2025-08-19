# V Murugan Gold Trading - Server APIs Documentation

## Overview
Complete server-side APIs for the V Murugan Gold Trading mobile application with secure data storage and Omniware payment integration.

## Base URL
```
https://yourdomain.com/api/
```

## Authentication
All APIs use user_id for authentication. In production, implement JWT tokens or session-based authentication.

---

## 1. USER MANAGEMENT APIs

### 1.1 User Registration
**Endpoint:** `POST /user_register.php`

**Request Body:**
```json
{
  "phone": "9876543210",
  "name": "John Doe",
  "email": "john@example.com",
  "encrypted_mpin": "encrypted_mpin_hash",
  "address": "123 Main St",
  "pan_card": "ABCDE1234F",
  "device_id": "device_unique_id"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### 1.2 User Login
**Endpoint:** `POST /user_login.php`

**Request Body:**
```json
{
  "phone": "9876543210",
  "encrypted_mpin": "encrypted_mpin_hash"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": 1,
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "portfolio": {
    "total_gold_grams": 5.25,
    "total_silver_grams": 10.50,
    "total_invested": 50000.00,
    "current_value": 52000.00
  }
}
```

---

## 2. PORTFOLIO MANAGEMENT APIs

### 2.1 Get Portfolio
**Endpoint:** `GET /portfolio_get.php?user_id=1`

**Response:**
```json
{
  "success": true,
  "portfolio": {
    "total_gold_grams": 5.25,
    "total_silver_grams": 10.50,
    "total_invested": 50000.00,
    "current_value": 52000.00,
    "profit_loss": 2000.00,
    "profit_loss_percentage": 4.00,
    "last_updated": "2024-01-15 10:30:00"
  },
  "recent_transactions": [...]
}
```

### 2.2 Update Portfolio
**Endpoint:** `POST /portfolio_update.php`

**Request Body:**
```json
{
  "user_id": 1,
  "metal_type": "GOLD",
  "quantity": 2.5,
  "amount": 25000.00,
  "operation": "ADD",
  "current_price": 10000.00
}
```

---

## 3. TRANSACTION MANAGEMENT APIs

### 3.1 Create Transaction
**Endpoint:** `POST /transaction_create.php`

**Request Body:**
```json
{
  "user_id": 1,
  "transaction_id": "TXN_20240115_001",
  "type": "BUY",
  "metal_type": "GOLD",
  "quantity": 2.5,
  "price_per_gram": 10000.00,
  "total_amount": 25000.00,
  "payment_method": "NET_BANKING",
  "payment_status": "PENDING",
  "gateway_transaction_id": "OMN_12345"
}
```

### 3.2 Update Transaction Status
**Endpoint:** `POST /transaction_update_status.php`

**Request Body:**
```json
{
  "transaction_id": "TXN_20240115_001",
  "payment_status": "SUCCESS",
  "gateway_transaction_id": "OMN_12345",
  "callback_data": {...}
}
```

### 3.3 Get Transaction History
**Endpoint:** `GET /transaction_history.php?user_id=1&limit=20&offset=0`

**Query Parameters:**
- `user_id` (required): User ID
- `limit` (optional): Number of records (default: 50, max: 100)
- `offset` (optional): Pagination offset (default: 0)
- `metal_type` (optional): GOLD or SILVER
- `type` (optional): BUY or SELL
- `status` (optional): PENDING, SUCCESS, FAILED, CANCELLED

---

## 4. PAYMENT APIs

### 4.1 Payment Initiate
**Endpoint:** `POST /payment_initiate.php`

**Request Body:**
```json
{
  "user_id": 1,
  "amount": 25000.00,
  "metal_type": "GOLD",
  "quantity": 2.5,
  "customer_name": "John Doe",
  "customer_email": "john@example.com",
  "customer_phone": "9876543210"
}
```

### 4.2 Payment Callback
**Endpoint:** `POST /payment_callback.php`

**Request Body:** (Sent by Omniware)
```json
{
  "order_id": "ORD_20240115_001",
  "transaction_id": "OMN_12345",
  "status": "SUCCESS",
  "amount": "25000.00",
  "hash": "calculated_hash"
}
```

---

## 5. NOTIFICATION APIs

### 5.1 Send Notification
**Endpoint:** `POST /notification_send.php`

**Request Body:**
```json
{
  "user_id": 1,
  "title": "Purchase Successful",
  "message": "Your gold purchase of 2.5g has been completed successfully.",
  "type": "TRANSACTION",
  "data": {
    "transaction_id": "TXN_20240115_001",
    "amount": 25000.00
  }
}
```

### 5.2 Get Notifications
**Endpoint:** `GET /notification_get.php?user_id=1&limit=20&unread_only=false`

### 5.3 Mark Notifications as Read
**Endpoint:** `POST /notification_mark_read.php`

**Request Body:**
```json
{
  "user_id": 1,
  "notification_id": 123,
  "mark_all": false
}
```

---

## Error Responses

All APIs return consistent error responses:

```json
{
  "success": false,
  "message": "Error description"
}
```

**HTTP Status Codes:**
- `200`: Success
- `400`: Bad Request (validation errors)
- `401`: Unauthorized
- `405`: Method Not Allowed
- `500`: Internal Server Error

---

## Security Features

1. **Input Validation**: All inputs are validated and sanitized
2. **SQL Injection Protection**: Prepared statements used throughout
3. **CORS Headers**: Proper cross-origin resource sharing
4. **Error Logging**: Comprehensive error logging for debugging
5. **Hash Verification**: Omniware payment hash verification
6. **Database Transactions**: Atomic operations for data consistency

---

## Deployment Checklist

1. ✅ Upload all PHP files to server
2. ✅ Create MySQL database using `database_schema.sql`
3. ✅ Update `config/database.php` with actual credentials
4. ✅ Configure Omniware credentials
5. ✅ Set up SSL certificate (required for payments)
6. ✅ Test all API endpoints
7. ✅ Update app configuration with server URLs

---

## File Structure

```
server_apis/
├── config/
│   └── database.php
├── user_register.php
├── user_login.php
├── portfolio_get.php
├── portfolio_update.php
├── transaction_create.php
├── transaction_update_status.php
├── transaction_history.php
├── payment_initiate.php
├── payment_callback.php
├── notification_send.php
├── notification_get.php
├── notification_mark_read.php
├── database_schema.sql
└── API_DOCUMENTATION.md
```

**Total APIs Created: 11 Complete Server APIs**
