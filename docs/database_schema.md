# Digi Gold Database Schema

## 1. USERS Collection
```json
{
  "userId": "unique_user_id",
  "personalInfo": {
    "firstName": "John",
    "lastName": "Doe", 
    "email": "john@example.com",
    "phone": "+91-9876543210",
    "dateOfBirth": "1990-01-01",
    "gender": "male"
  },
  "address": {
    "street": "123 Main St",
    "city": "Mumbai",
    "state": "Maharashtra", 
    "pincode": "400001",
    "country": "India"
  },
  "kycStatus": {
    "isVerified": false,
    "documents": {
      "aadhar": "aadhar_url",
      "pan": "pan_url",
      "bankStatement": "bank_url"
    },
    "verificationDate": null
  },
  "bankDetails": {
    "accountNumber": "encrypted_account",
    "ifscCode": "HDFC0001234",
    "bankName": "HDFC Bank",
    "accountHolderName": "John Doe"
  },
  "preferences": {
    "priceAlerts": true,
    "emailNotifications": true,
    "pushNotifications": true,
    "currency": "INR"
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-15T10:30:00Z"
}
```

## 2. PORTFOLIO Collection
```json
{
  "portfolioId": "unique_portfolio_id",
  "userId": "user_id_reference",
  "summary": {
    "totalGoldGrams": 25.5,
    "totalInvestment": 250000.00,
    "currentValue": 275000.00,
    "profitLoss": 25000.00,
    "profitLossPercentage": 10.0,
    "averageBuyPrice": 9803.92
  },
  "holdings": [
    {
      "holdingId": "holding_1",
      "goldType": "22K",
      "grams": 10.5,
      "purchasePrice": 9800.00,
      "purchaseDate": "2024-01-01T00:00:00Z",
      "currentValue": 102900.00
    }
  ],
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

## 3. TRANSACTIONS Collection
```json
{
  "transactionId": "unique_transaction_id",
  "userId": "user_id_reference",
  "type": "BUY", // BUY, SELL
  "status": "COMPLETED", // PENDING, COMPLETED, FAILED, CANCELLED
  "goldDetails": {
    "type": "22K",
    "grams": 5.25,
    "pricePerGram": 9285.00,
    "totalAmount": 48746.25
  },
  "paymentDetails": {
    "method": "UPI", // UPI, CARD, NET_BANKING
    "gateway": "RAZORPAY",
    "gatewayTransactionId": "pay_xyz123",
    "gatewayOrderId": "order_abc456"
  },
  "timestamps": {
    "createdAt": "2024-01-15T10:00:00Z",
    "completedAt": "2024-01-15T10:02:00Z"
  },
  "fees": {
    "transactionFee": 50.00,
    "gst": 9.00,
    "totalFees": 59.00
  },
  "notes": "Purchase via mobile app"
}
```

## 4. PRICE_HISTORY Collection
```json
{
  "priceId": "unique_price_id",
  "goldType": "22K",
  "pricePerGram": 9285.00,
  "source": "MJDTA_CHENNAI",
  "timestamp": "2024-01-15T10:30:00Z",
  "change": {
    "amount": 15.00,
    "percentage": 0.16,
    "trend": "UP"
  }
}
```

## 5. PRICE_ALERTS Collection
```json
{
  "alertId": "unique_alert_id",
  "userId": "user_id_reference",
  "goldType": "22K",
  "condition": "BELOW", // ABOVE, BELOW
  "targetPrice": 9200.00,
  "isActive": true,
  "isTriggered": false,
  "createdAt": "2024-01-15T10:30:00Z",
  "triggeredAt": null
}
```

## 6. KYC_DOCUMENTS Collection
```json
{
  "documentId": "unique_document_id",
  "userId": "user_id_reference",
  "documentType": "AADHAR", // AADHAR, PAN, BANK_STATEMENT
  "fileUrl": "secure_cloud_storage_url",
  "status": "PENDING", // PENDING, APPROVED, REJECTED
  "uploadedAt": "2024-01-15T10:30:00Z",
  "verifiedAt": null,
  "rejectionReason": null
}
```

## 7. NOTIFICATIONS Collection
```json
{
  "notificationId": "unique_notification_id",
  "userId": "user_id_reference",
  "type": "PRICE_ALERT", // PRICE_ALERT, TRANSACTION, KYC, GENERAL
  "title": "Gold Price Alert",
  "message": "22K Gold price dropped to ₹9200/gram",
  "isRead": false,
  "createdAt": "2024-01-15T10:30:00Z",
  "data": {
    "alertId": "alert_reference",
    "currentPrice": 9200.00
  }
}
```
