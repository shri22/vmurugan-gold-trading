# 📚 V MURUGAN GOLD TRADING - API DOCUMENTATION

## 🌐 **API OVERVIEW**

### **Base URL**
```
Production: https://client-domain.com:3001/api
Development: http://localhost:3001/api
```

### **Authentication**
- **Type**: Phone-based authentication with encrypted MPIN
- **Headers**: `Content-Type: application/json`
- **Response Format**: JSON

---

## 👤 **USER MANAGEMENT APIs**

### **1. User Registration**
**Endpoint:** `POST /api/customers`

**Request Body:**
```json
{
  "phone": "9876543210",
  "name": "John Doe",
  "email": "john@example.com",
  "encrypted_mpin": "encrypted_hash_here"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Customer registered successfully",
  "customer": {
    "id": 1,
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com",
    "registration_date": "2024-01-15T10:30:00.000Z"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Phone number already exists",
  "errors": [
    {
      "field": "phone",
      "message": "Phone number must be unique"
    }
  ]
}
```

### **2. User Login**
**Endpoint:** `POST /api/login`

**Request Body:**
```json
{
  "phone": "9876543210",
  "encrypted_mpin": "encrypted_hash_here"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Login successful",
  "customer": {
    "id": 1,
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com",
    "last_login": "2024-01-15T10:30:00.000Z"
  }
}
```

---

## 💰 **PORTFOLIO MANAGEMENT APIs**

### **3. Get Portfolio**
**Endpoint:** `GET /api/portfolio`

**Query Parameters:**
- `user_id` (optional): User ID
- `phone` (optional): User phone number

**Example:** `GET /api/portfolio?phone=9876543210`

**Response:**
```json
{
  "success": true,
  "portfolio": {
    "total_gold_grams": 5.2500,
    "total_silver_grams": 10.5000,
    "total_invested": 50000.00,
    "current_value": 52000.00,
    "profit_loss": 2000.00,
    "profit_loss_percentage": 4.00,
    "last_updated": "2024-01-15T10:30:00.000Z"
  },
  "user": {
    "id": 1,
    "name": "John Doe",
    "phone": "9876543210",
    "email": "john@example.com"
  }
}
```

---

## 📋 **TRANSACTION MANAGEMENT APIs**

### **4. Create Transaction**
**Endpoint:** `POST /api/transactions`

**Request Body:**
```json
{
  "transaction_id": "TXN_20240115_001",
  "customer_phone": "9876543210",
  "amount": 25000.00,
  "gold_grams": 2.5000,
  "silver_grams": 0.0000,
  "metal_type": "GOLD",
  "transaction_type": "BUY",
  "status": "PENDING",
  "payment_method": "NET_BANKING",
  "gold_price_per_gram": 10000.00
}
```

**Response:**
```json
{
  "success": true,
  "message": "Transaction created successfully",
  "transaction": {
    "id": 123,
    "transaction_id": "TXN_20240115_001",
    "customer_phone": "9876543210",
    "amount": 25000.00,
    "gold_grams": 2.5000,
    "silver_grams": 0.0000,
    "metal_type": "GOLD",
    "transaction_type": "BUY",
    "status": "PENDING",
    "timestamp": "2024-01-15T10:30:00.000Z"
  }
}
```

### **5. Get Transaction History**
**Endpoint:** `GET /api/transaction-history`

**Query Parameters:**
- `phone` (required): User phone number
- `limit` (optional): Number of records (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Example:** `GET /api/transaction-history?phone=9876543210&limit=20`

**Response:**
```json
{
  "success": true,
  "transactions": [
    {
      "id": 123,
      "transaction_id": "TXN_20240115_001",
      "customer_phone": "9876543210",
      "amount": 25000.00,
      "gold_grams": 2.5000,
      "silver_grams": 0.0000,
      "metal_type": "GOLD",
      "transaction_type": "BUY",
      "status": "SUCCESS",
      "payment_method": "NET_BANKING",
      "timestamp": "2024-01-15T10:30:00.000Z",
      "customer_name": "John Doe"
    }
  ],
  "pagination": {
    "limit": 20,
    "offset": 0,
    "has_more": false
  }
}
```

### **6. Update Transaction Status**
**Endpoint:** `POST /api/transaction-status`

**Request Body:**
```json
{
  "transaction_id": "TXN_20240115_001",
  "status": "SUCCESS",
  "gateway_transaction_id": "OMN_12345",
  "callback_data": {
    "payment_method": "NET_BANKING",
    "bank_reference": "REF123456"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Transaction status updated successfully",
  "transaction_id": "TXN_20240115_001",
  "new_status": "SUCCESS"
}
```

---

## 🏥 **SYSTEM APIs**

### **7. Health Check**
**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 3600,
  "memory": {
    "rss": 45678592,
    "heapTotal": 18874368,
    "heapUsed": 12345678,
    "external": 1234567
  },
  "database": "connected",
  "version": "1.0.0"
}
```

### **8. Database Connection Test**
**Endpoint:** `GET /api/test-connection`

**Response:**
```json
{
  "success": true,
  "message": "Database connection successful",
  "database": "VMuruganGoldTrading",
  "server": "localhost",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

---

## 📊 **ADMIN APIs**

### **9. Get Dashboard Data**
**Endpoint:** `GET /api/admin/dashboard`

**Headers:** `Authorization: Bearer ADMIN_TOKEN`

**Response:**
```json
{
  "success": true,
  "data": {
    "statistics": {
      "total_customers": 150,
      "total_transactions": 500,
      "total_amount": 2500000.00,
      "total_gold_grams": 250.0000,
      "avg_transaction_amount": 5000.00
    },
    "recent_transactions": [
      {
        "id": 123,
        "transaction_id": "TXN_20240115_001",
        "customer_name": "John Doe",
        "amount": 25000.00,
        "status": "SUCCESS",
        "timestamp": "2024-01-15T10:30:00.000Z"
      }
    ],
    "monthly_data": [
      {
        "month": "2024-01",
        "transaction_count": 50,
        "total_amount": 250000.00,
        "total_gold_grams": 25.0000
      }
    ]
  }
}
```

---

## 🔧 **ERROR HANDLING**

### **Standard Error Response Format**
```json
{
  "success": false,
  "message": "Error description",
  "error_code": "ERROR_CODE",
  "errors": [
    {
      "field": "field_name",
      "message": "Field-specific error message"
    }
  ],
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### **HTTP Status Codes**
| Code | Description | Usage |
|------|-------------|-------|
| **200** | OK | Successful request |
| **201** | Created | Resource created successfully |
| **400** | Bad Request | Invalid request data |
| **401** | Unauthorized | Authentication required |
| **403** | Forbidden | Access denied |
| **404** | Not Found | Resource not found |
| **409** | Conflict | Resource already exists |
| **422** | Unprocessable Entity | Validation errors |
| **500** | Internal Server Error | Server error |

### **Common Error Codes**
| Error Code | Description |
|------------|-------------|
| `PHONE_EXISTS` | Phone number already registered |
| `INVALID_MPIN` | Incorrect MPIN provided |
| `USER_NOT_FOUND` | User does not exist |
| `TRANSACTION_NOT_FOUND` | Transaction does not exist |
| `INVALID_AMOUNT` | Invalid transaction amount |
| `DATABASE_ERROR` | Database operation failed |
| `VALIDATION_ERROR` | Input validation failed |

---

## 🔒 **SECURITY CONSIDERATIONS**

### **Input Validation**
- All inputs are validated and sanitized
- SQL injection protection via parameterized queries
- XSS protection via input encoding
- Rate limiting applied to prevent abuse

### **Data Encryption**
- MPIN stored as encrypted hash
- Sensitive data encrypted in transit (HTTPS)
- Database connections encrypted

### **Authentication**
- Phone-based authentication
- Encrypted MPIN verification
- Session management for admin APIs

---

## 📝 **RATE LIMITING**

### **API Rate Limits**
| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/customers` | 5 requests | 15 minutes |
| `/api/login` | 10 requests | 15 minutes |
| `/api/transactions` | 20 requests | 15 minutes |
| `/api/portfolio` | 100 requests | 15 minutes |
| `/api/transaction-history` | 50 requests | 15 minutes |
| `/health` | Unlimited | - |

### **Rate Limit Headers**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248000
```

---

## 🧪 **TESTING**

### **API Testing Tools**
- **Postman Collection**: Available for import
- **cURL Examples**: Provided for each endpoint
- **Automated Tests**: Jest test suite included

### **Test Environment**
```
Base URL: http://localhost:3001/api
Test Database: VMuruganGoldTrading_Test
Test User: phone=9999999999, mpin=test123
```

### **Sample cURL Commands**
```bash
# Health Check
curl http://localhost:3001/health

# User Registration
curl -X POST http://localhost:3001/api/customers \
-H "Content-Type: application/json" \
-d '{"phone":"9876543210","name":"Test User","email":"test@example.com","encrypted_mpin":"test123"}'

# User Login
curl -X POST http://localhost:3001/api/login \
-H "Content-Type: application/json" \
-d '{"phone":"9876543210","encrypted_mpin":"test123"}'

# Get Portfolio
curl http://localhost:3001/api/portfolio?phone=9876543210

# Create Transaction
curl -X POST http://localhost:3001/api/transactions \
-H "Content-Type: application/json" \
-d '{"transaction_id":"TXN_TEST_001","customer_phone":"9876543210","amount":1000,"gold_grams":0.1,"metal_type":"GOLD","transaction_type":"BUY","status":"SUCCESS"}'
```

---

## 📞 **SUPPORT**

### **API Support**
- **Documentation**: This document
- **Technical Support**: [Your contact information]
- **Issue Reporting**: [GitHub issues or support email]
- **Updates**: [How to get API updates]

### **Versioning**
- **Current Version**: 1.0.0
- **Versioning Scheme**: Semantic Versioning (SemVer)
- **Backward Compatibility**: Maintained for major versions
- **Deprecation Notice**: 6 months advance notice

---

*API Documentation Version: 1.0*  
*Last Updated: [Current Date]*  
*Base URL: https://client-domain.com:3001/api*
