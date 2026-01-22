# ✅ CLEANUP ABANDONED PAYMENTS - QUICK GUIDE

## 🎯 What It Does

Automatically finds and marks abandoned payment transactions as FAILED.

**Before:** PENDING transactions stay forever → Confusing reports  
**After:** Abandoned payments marked as FAILED → Clean, accurate data

---

## 🚀 How to Use (Super Easy!)

### Option 1: Admin Portal Button (Recommended) ⭐

```
1. Open Admin Portal
2. Go to: Reports → Gateway Reconciliation
3. Click: 🧹 Cleanup Abandoned Payments
4. Confirm → Done!
```

**You'll see:**
- ✅ Total transactions checked
- ❌ How many marked as FAILED (abandoned)
- ⏳ How many still PENDING (legitimate)
- 🔔 How many need manual reconciliation

---

## 📊 What Gets Cleaned Up?

### ✅ Marked as FAILED:
- Transactions older than 1 hour
- Not found in Omniware gateway
- Customer never completed payment

### ⏳ Kept as PENDING:
- Still processing in gateway
- Customer payment in progress

### 🔔 Flagged for Review:
- Successful in gateway
- But PENDING in database
- Needs manual reconciliation

---

## 🎨 Visual Example

```
Before Cleanup:
┌─────────────────────┬──────────┬─────────┐
│ Transaction ID      │ Status   │ Age     │
├─────────────────────┼──────────┼─────────┤
│ ORD_123...SILVER    │ PENDING  │ 5 hours │ ← Abandoned!
│ ORD_456...GOLD      │ PENDING  │ 3 hours │ ← Abandoned!
│ ORD_789...SILVER    │ SUCCESS  │ 1 hour  │
└─────────────────────┴──────────┴─────────┘

After Cleanup:
┌─────────────────────┬──────────┬─────────┐
│ Transaction ID      │ Status   │ Age     │
├─────────────────────┼──────────┼─────────┤
│ ORD_123...SILVER    │ FAILED   │ 5 hours │ ✅ Cleaned!
│ ORD_456...GOLD      │ FAILED   │ 3 hours │ ✅ Cleaned!
│ ORD_789...SILVER    │ SUCCESS  │ 1 hour  │
└─────────────────────┴──────────┴─────────┘
```

---

## 🔧 Technical Details

**API Endpoint:** `/api/omniware/cleanup-abandoned`  
**Method:** POST  
**Parameters:** `{ hoursOld: 1 }`  
**Location:** Admin Portal → Reports → Gateway Reconciliation

**Backend File:** `sql_server_api/routes/omniware_upi.js`  
**Frontend:** `admin_portal/index.html` (Gateway Reconciliation section)

---

## ✨ Benefits

1. **Clean Reports** - No confusing PENDING transactions
2. **Accurate Metrics** - Real revenue numbers
3. **One Click** - No technical knowledge needed
4. **Safe** - Only marks as FAILED if confirmed with gateway
5. **Transparent** - Shows exactly what was done

---

## 🎯 When to Use

- **Daily:** Click the button once a day to keep data clean
- **Before Reports:** Clean up before generating analytics
- **After Issues:** If you notice old PENDING transactions
- **Anytime:** It's safe to run anytime!

---

## 📝 Status Meanings

| Status | Meaning |
|--------|---------|
| **PENDING** | Payment initiated, waiting for completion |
| **SUCCESS** | Payment completed successfully |
| **FAILED** | Payment abandoned or failed |
| **CANCELLED** | Payment cancelled by user/admin |

---

## 🆘 Need Help?

**Q: Will this delete customer data?**  
A: No! It only changes status from PENDING to FAILED. All data is preserved.

**Q: What if I clean up by mistake?**  
A: It only affects transactions older than 1 hour that don't exist in the gateway. Safe!

**Q: How often should I run this?**  
A: Daily is good. Or whenever you see old PENDING transactions.

**Q: Can I undo it?**  
A: The status change is logged. Contact support if needed.

---

## 🎉 You're All Set!

Just click the button whenever you want to clean up abandoned payments. It's that simple!
