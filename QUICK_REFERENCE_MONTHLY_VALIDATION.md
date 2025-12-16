# Monthly Payment Validation - Quick Reference

## 📋 Summary

**Problem**: Users could make duplicate monthly payments for PLUS schemes  
**Solution**: Database-driven validation with UI-level blocking

---

## ✅ What Was Done (Client-Side)

1. **BuyGoldScreen & BuySilverScreen**
   - Added `isFirstMonth` and `isAmountEditable` parameters
   - Amount field is READ-ONLY for subsequent months
   - Shows info message for non-editable fields

2. **Documentation Created**
   - `DATABASE_MIGRATION.md` - Database changes needed
   - `SERVER_CHANGES_REQUIRED.md` - API implementation guide
   - `MONTHLY_PAYMENT_FIX_STATUS.md` - Implementation status

---

## 🔴 Required Database Changes

### Add 4 New Columns:

**schemes table:**
```sql
ALTER TABLE schemes ADD has_paid_this_month BIT DEFAULT 0;
ALTER TABLE schemes ADD last_payment_date DATETIME2(3) NULL;
```

**transactions table:**
```sql
ALTER TABLE transactions ADD payment_month INT NULL;
ALTER TABLE transactions ADD payment_year INT NULL;
```

**Run the complete migration script in `DATABASE_MIGRATION.md`**

---

## 🔴 Required Server Changes

### 1. Update GET /schemes/:customerPhone

Calculate `has_paid_this_month` dynamically:

```javascript
const query = `
  SELECT 
    s.*,
    CASE 
      WHEN EXISTS (
        SELECT 1 FROM transactions p
        WHERE p.scheme_id = s.scheme_id 
          AND p.payment_year = @currentYear
          AND p.payment_month = @currentMonth
          AND p.status = 'SUCCESS'
      ) THEN 1 ELSE 0
    END AS has_paid_this_month
  FROM schemes s
  WHERE s.customer_phone = @customerPhone
`;
```

### 2. Update Payment Recording

When recording successful payment:

```javascript
await pool.request()
  .input('payment_month', sql.Int, new Date().getMonth() + 1)
  .input('payment_year', sql.Int, new Date().getFullYear())
  .query(`
    INSERT INTO transactions (
      transaction_id, scheme_id, customer_phone,
      amount, payment_month, payment_year, status
    ) VALUES (
      @txnId, @schemeId, @phone,
      @amount, @payment_month, @payment_year, 'SUCCESS'
    )
  `);
```

### 3. Monthly Reset (Cron Job)

Run on 1st of each month at 00:01:

```javascript
cron.schedule('1 0 1 * *', async () => {
  await pool.request().query(`
    UPDATE schemes 
    SET has_paid_this_month = 0
    WHERE scheme_type IN ('GOLDPLUS', 'SILVERPLUS')
  `);
});
```

---

## 🔄 Remaining Flutter Work

### Update SchemeDetailsScreen

File: `lib/features/schemes/screens/scheme_details_screen.dart`

In `_viewScheme()` method:

```dart
// Check if paid this month
if (hasPaidThisMonth) {
  showDialog(...); // Block user
  return; // Don't navigate
}

// Calculate if first month
final isFirstMonth = (created this month);

// Navigate with parameters
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BuyGoldScreen(
      isFirstMonth: isFirstMonth,
      isAmountEditable: isFirstMonth,
      prefilledAmount: isFirstMonth ? null : monthlyAmount,
      // ... other params
    ),
  ),
);
```

---

## 📁 Files to Review

1. **DATABASE_MIGRATION.md** - SQL migration script (run this first!)
2. **SERVER_CHANGES_REQUIRED.md** - Complete API implementation guide
3. **MONTHLY_PAYMENT_FIX_STATUS.md** - Detailed implementation status

---

## 🎯 Testing Checklist

- [ ] Run database migration script
- [ ] Update server API code
- [ ] Deploy server changes
- [ ] Update SchemeDetailsScreen in Flutter
- [ ] Test first month payment (editable amount)
- [ ] Test second month payment (read-only amount)
- [ ] Test blocking when already paid
- [ ] Test FLEXI schemes (should work normally)

---

## 🚀 Deployment Steps

1. **Database**: Run migration script
2. **Server**: Update API code and deploy
3. **Flutter**: Update SchemeDetailsScreen
4. **Test**: All scenarios
5. **Monitor**: Check logs for issues

---

**All documentation is ready. Start with DATABASE_MIGRATION.md!** 📚
