# iOS Monthly Payment Debugging Guide

**Date:** December 6, 2025, 10:06 PM  
**Issue:** Monthly payment restriction not working on iOS

---

## 🔍 **Quick Checks**

### **1. Did you rebuild iOS app?**
The validation code was added today. If you're running an old build, it won't have the validation.

**Solution:**
```bash
# Build iOS with latest code
flutter build ios --no-codesign

# OR run directly
flutter run
```

### **2. Is server restarted?**
The server-side fix needs the server to be restarted.

**Check:**
```bash
# Check if server is running
pm2 list

# Restart
pm2 restart vmurugan-api
```

### **3. Are you testing with PLUS scheme?**
Only PLUS schemes have monthly restrictions.

**✅ Test with:**
- Gold Plus
- Silver Plus

**❌ Don't test with:**
- Gold Flexi (no restrictions)
- Silver Flexi (no restrictions)

---

## 🧪 **How to Test on iOS**

### **Step 1: Check Xcode Console Logs**

When you make a payment, you should see these logs:

```
🔍 BUY GOLD: This is a scheme payment
🔍 BUY GOLD: Scheme ID: SCH_GOLDPLUS_XXX
🔍 BUY GOLD: Starting validation...
🔍 BUY GOLD: Validation result: SchemePaymentValidationResult(canPay: false, ...)
❌ BUY GOLD: Validation failed: You have already made your payment for this month
```

**If you DON'T see these logs:**
- App doesn't have validation code
- Need to rebuild iOS app

### **Step 2: Check Server Logs**

On server side, you should see:

```
📊 Checking monthly payment for scheme: SCH_XXX, Month: 12, Year: 2025
✅ Scheme found, type: GOLDPLUS
```

**If you DON'T see these logs:**
- Server not receiving API call
- Check network connection
- Check API URL in app

---

## 🔧 **Fix Steps for iOS**

### **Option 1: Run from Xcode (Recommended)**

1. **Open workspace:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Clean build:**
   - Product → Clean Build Folder (Cmd+Shift+K)

3. **Run:**
   - Product → Run (Cmd+R)
   - Watch console for validation logs

4. **Test:**
   - Make payment for Gold Plus
   - Try to pay again
   - Should see error message

### **Option 2: Run from Terminal**

```bash
# Run on iOS simulator/device
flutter run

# Watch for logs:
# 🔍 BUY GOLD: Starting validation...
```

### **Option 3: Build and Install**

```bash
# Build iOS
flutter build ios --no-codesign

# Install via Xcode or TestFlight
```

---

## 📊 **Debugging Checklist**

Run through this checklist:

- [ ] **iOS app rebuilt** after validation code was added
- [ ] **Server restarted** with latest code
- [ ] **Testing with PLUS scheme** (not FLEXI)
- [ ] **Network connection** working (app can reach server)
- [ ] **Xcode console** shows validation logs
- [ ] **Server logs** show API calls

---

## 🎯 **Most Common Issue**

**Problem:** Running old iOS build without validation code.

**Solution:**
```bash
# Stop current app
# Rebuild
flutter build ios --no-codesign

# OR just run
flutter run

# This will hot reload with latest code
```

---

## 📱 **Test Scenario**

### **Scenario 1: First Payment (Should Work)**
```
1. Open Gold Plus scheme
2. Click "Pay Monthly Installment"
3. Enter ₹5000
4. Complete payment
5. ✅ Payment succeeds
```

### **Scenario 2: Second Payment (Should Block)**
```
1. Same Gold Plus scheme
2. Click "Pay Monthly Installment" again
3. Enter ₹5000
4. Click "Proceed to Payment"
5. ❌ Should show orange snackbar:
   "You have already made your payment for this month.
    Please pay next month."
```

**If Scenario 2 doesn't show error:**
- App is using old code
- Rebuild iOS app

---

## 🔍 **Check Validation Code**

The validation happens in `buy_gold_screen.dart` line 658.

**To verify it's in your build:**

1. Add a print statement:
```dart
print('🔍 VALIDATION CODE IS PRESENT');
```

2. Rebuild and run

3. Check console - should see the print

**If you DON'T see it:**
- Code not in your build
- Need to rebuild

---

## 📞 **Still Not Working?**

**Run this command and send me output:**

```bash
# Run app with verbose logging
flutter run -v 2>&1 | grep -i "validation\|scheme"
```

**Also check:**
1. Xcode console logs
2. Server logs
3. Which scheme type you're testing with

---

## ✅ **Quick Fix**

```bash
# 1. Rebuild iOS
flutter build ios --no-codesign

# 2. Run in Xcode
open ios/Runner.xcworkspace
# Then: Product → Run

# 3. Test with Gold Plus
# Make payment → Try again → Should block
```

**The validation code is correct. Just need to rebuild iOS!** 🚀
