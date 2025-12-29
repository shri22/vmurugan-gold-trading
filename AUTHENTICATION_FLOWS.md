# 🔐 Authentication Flow Diagrams

## Visual Guide to JWT Authentication

---

## 📊 Admin Authentication Flow

```
┌─────────────┐
│ Admin Portal│
│   (Browser) │
└──────┬──────┘
       │
       │ 1. POST /api/admin/login
       │    {username, password}
       ▼
┌─────────────────────────────────────┐
│         Backend Server              │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ Validate Credentials         │  │
│  │ - Check username/password    │  │
│  │ - Against .env variables     │  │
│  └────────┬─────────────────────┘  │
│           │                         │
│           ▼                         │
│  ┌──────────────────────────────┐  │
│  │ Generate JWT Token           │  │
│  │ - Payload: {username, role}  │  │
│  │ - Expiration: 24 hours       │  │
│  │ - Signed with JWT_SECRET     │  │
│  └────────┬─────────────────────┘  │
│           │                         │
└───────────┼─────────────────────────┘
            │
            │ 2. Response
            │    {success, token, expiresIn}
            ▼
┌─────────────────────────────────────┐
│ Admin Portal                        │
│  - Save token to localStorage       │
│  - Show dashboard                   │
└──────┬──────────────────────────────┘
       │
       │ 3. GET /api/admin/analytics/dashboard
       │    Headers: {Authorization: Bearer <token>}
       ▼
┌─────────────────────────────────────┐
│ Backend Server                      │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ authenticateAdmin Middleware │  │
│  │ - Extract token from header  │  │
│  │ - Verify token signature     │  │
│  │ - Check expiration           │  │
│  │ - Validate role = 'admin'    │  │
│  └────────┬─────────────────────┘  │
│           │                         │
│           ▼                         │
│  ┌──────────────────────────────┐  │
│  │ Return Dashboard Data        │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 📱 Customer Authentication Flow

```
┌─────────────┐
│ Flutter App │
│  (Customer) │
└──────┬──────┘
       │
       │ 1. POST /api/auth/send-otp
       │    {phone: "9876543210"}
       ▼
┌─────────────────────────────────────┐
│ Backend Server                      │
│  - Generate 6-digit OTP             │
│  - Send SMS (demo: any 6 digits)    │
│  - Rate limit: 5 per 5 minutes      │
└───────────┬─────────────────────────┘
            │
            │ 2. Response {success: true}
            ▼
┌─────────────────────────────────────┐
│ Flutter App                         │
│  - Show OTP input screen            │
│  - User enters OTP                  │
└──────┬──────────────────────────────┘
       │
       │ 3. POST /api/auth/verify-otp
       │    {phone: "9876543210", otp: "123456"}
       ▼
┌─────────────────────────────────────┐
│ Backend Server                      │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ Verify OTP                   │  │
│  │ - Check OTP is valid         │  │
│  │ - Fetch customer from DB     │  │
│  └────────┬─────────────────────┘  │
│           │                         │
│           ▼                         │
│  ┌──────────────────────────────┐  │
│  │ Generate JWT Token (NEW!)    │  │
│  │ - Payload: {customer_id,     │  │
│  │            phone, name,       │  │
│  │            role: 'customer'}  │  │
│  │ - Expiration: 30 days        │  │
│  │ - Signed with JWT_SECRET     │  │
│  └────────┬─────────────────────┘  │
│           │                         │
└───────────┼─────────────────────────┘
            │
            │ 4. Response (NEW!)
            │    {success, token, customer, expiresIn}
            ▼
┌─────────────────────────────────────┐
│ Flutter App                         │
│  - Save token to secure storage     │
│  - Save customer data               │
│  - Navigate to home screen          │
└──────┬──────────────────────────────┘
       │
       │ 5. GET /api/schemes/9876543210
       │    Headers: {Authorization: Bearer <token>}
       ▼
┌─────────────────────────────────────┐
│ Backend Server                      │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ optionalCustomerAuth         │  │
│  │ - Extract token (if present) │  │
│  │ - Verify token signature     │  │
│  │ - Check expiration           │  │
│  │ - Validate role = 'customer' │  │
│  │ - Set req.customer           │  │
│  └────────┬─────────────────────┘  │
│           │                         │
│           ▼                         │
│  ┌──────────────────────────────┐  │
│  │ Return Schemes Data          │  │
│  │ - Use customer_id from token │  │
│  │   (can't be faked!)          │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 🔄 Backward Compatibility

### **Customer API Call - Both Methods Work**

```
┌─────────────┐
│ Flutter App │
│  (Old/New)  │
└──────┬──────┘
       │
       ├─────────────────────────────────────┐
       │                                     │
       │ OLD METHOD (Still Works)            │ NEW METHOD (Recommended)
       │                                     │
       │ GET /api/schemes/9876543210         │ GET /api/schemes/9876543210
       │ Headers: {Content-Type: ...}        │ Headers: {Authorization: Bearer <token>}
       │                                     │
       ▼                                     ▼
┌──────────────────────────────────────────────────────────┐
│ Backend Server                                           │
│                                                          │
│  ┌────────────────────────┐    ┌────────────────────┐  │
│  │ optionalCustomerAuth   │    │ optionalCustomerAuth│  │
│  │ - No token found       │    │ - Token found       │  │
│  │ - Continue anyway ✅   │    │ - Verify token ✅   │  │
│  │                        │    │ - Set req.customer  │  │
│  └────────┬───────────────┘    └────────┬───────────┘  │
│           │                              │              │
│           └──────────┬───────────────────┘              │
│                      ▼                                  │
│           ┌────────────────────┐                        │
│           │ Return Schemes     │                        │
│           │ - Both work! ✅    │                        │
│           └────────────────────┘                        │
└──────────────────────────────────────────────────────────┘
```

---

## 🔐 Token Structure

### **Admin JWT Token**

```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "username": "admin",
  "role": "admin",
  "iat": 1735219813,
  "exp": 1735306213
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  JWT_SECRET
)

Full Token:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFkbWluIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzM1MjE5ODEzLCJleHAiOjE3MzUzMDYyMTN9.abc123...
```

### **Customer JWT Token**

```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "customer_id": "VM25",
  "phone": "9876543210",
  "name": "John Doe",
  "role": "customer",
  "iat": 1735219813,
  "exp": 1737811813
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  JWT_SECRET
)

Full Token:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjdXN0b21lcl9pZCI6IlZNMjUiLCJwaG9uZSI6Ijk4NzY1NDMyMTAiLCJuYW1lIjoiSm9obiBEb2UiLCJyb2xlIjoiY3VzdG9tZXIiLCJpYXQiOjE3MzUyMTk4MTMsImV4cCI6MTczNzgxMTgxM30.xyz789...
```

---

## 🛡️ Security Layers

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT REQUEST                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │   1. CORS Check      │
          │   - Origin allowed?  │
          └──────────┬───────────┘
                     │ ✅ Pass
                     ▼
          ┌──────────────────────┐
          │   2. Rate Limiting   │
          │   - Under limit?     │
          └──────────┬───────────┘
                     │ ✅ Pass
                     ▼
          ┌──────────────────────┐
          │   3. Authentication  │
          │   - Valid JWT token? │
          └──────────┬───────────┘
                     │ ✅ Pass
                     ▼
          ┌──────────────────────┐
          │   4. HMAC Validation │
          │   - Valid signature? │
          │   (if enabled)       │
          └──────────┬───────────┘
                     │ ✅ Pass
                     ▼
          ┌──────────────────────┐
          │   5. SQL Injection   │
          │   - Parameterized?   │
          └──────────┬───────────┘
                     │ ✅ Pass
                     ▼
          ┌──────────────────────┐
          │   6. Process Request │
          │   - Execute logic    │
          └──────────┬───────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │   7. Return Response │
          └──────────────────────┘
```

---

## 🔄 Token Lifecycle

### **Admin Token (24 hours)**

```
Hour 0:  Login → Token Generated
         ├─ Valid for 24 hours
         └─ Stored in localStorage

Hour 1-23: Token Used
         ├─ Every admin API call
         ├─ Validated on each request
         └─ No refresh needed

Hour 24: Token Expires
         ├─ Next API call returns 401
         ├─ User redirected to login
         └─ Must login again
```

### **Customer Token (30 days)**

```
Day 0:  OTP Verified → Token Generated
        ├─ Valid for 30 days
        └─ Stored in secure storage

Day 1-29: Token Used
        ├─ Every customer API call
        ├─ Validated on each request
        └─ No refresh needed

Day 30: Token Expires
        ├─ Next API call returns 401
        ├─ User redirected to OTP screen
        └─ Must verify OTP again
```

---

## 📊 Request/Response Examples

### **Admin Login Request**

```http
POST /api/admin/login HTTP/1.1
Host: localhost:3001
Content-Type: application/json

{
  "username": "admin",
  "password": "Admin@2025"
}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h",
  "user": {
    "username": "admin",
    "role": "admin"
  }
}
```

### **Admin API Request**

```http
GET /api/admin/analytics/dashboard HTTP/1.1
Host: localhost:3001
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "data": {
    "totalCustomers": 150,
    "activeSchemes": 89,
    ...
  }
}
```

### **Customer OTP Verification**

```http
POST /api/auth/verify-otp HTTP/1.1
Host: localhost:3001
Content-Type: application/json

{
  "phone": "9876543210",
  "otp": "123456"
}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "message": "OTP verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "30d",
  "customer": {
    "id": 1,
    "customer_id": "VM25",
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com",
    "business_id": "VMURUGAN_001"
  }
}
```

### **Customer API Request**

```http
GET /api/schemes/9876543210 HTTP/1.1
Host: localhost:3001
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "schemes": [
    {
      "scheme_id": "SCHEME123",
      "scheme_type": "GOLDPLUS",
      ...
    }
  ]
}
```

---

## 🎯 Summary

This visual guide shows:

✅ **Admin Authentication Flow** - Login → JWT → API calls  
✅ **Customer Authentication Flow** - OTP → JWT → API calls  
✅ **Backward Compatibility** - Both old and new methods work  
✅ **Token Structure** - What's inside the JWT  
✅ **Security Layers** - Multiple protection levels  
✅ **Token Lifecycle** - Creation to expiration  
✅ **Request/Response Examples** - Real HTTP examples  

**All authentication flows are implemented and working!** 🎉

---

**Created:** 2025-12-26  
**Version:** 2.0.0  
**Status:** ✅ COMPLETE
