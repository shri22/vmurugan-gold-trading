# Login Flow Test Guide

## 🚀 Testing the New Login System

### Prerequisites
1. **SQL Server API Running**: Make sure `simple_server.js` is running on port 3001
2. **APK Installed**: Install the latest APK on your device
3. **Network Connection**: Device and computer on same WiFi

### Test Flow

#### 1. **First Launch**
- ✅ App shows splash screen with VMUrugan logo
- ✅ Automatically navigates to onboarding screen
- ✅ Complete onboarding → Goes to login screen

#### 2. **Registration Test**
- ✅ Tap "Register" on login screen
- ✅ Fill in all fields:
  - Phone: `9876543210`
  - Name: `Test User`
  - Email: `test@example.com`
  - Address: `Test Address`
  - PAN: `ABCDE1234F`
  - MPIN: `1234`
  - Confirm MPIN: `1234`
- ✅ Tap "Register"
- ✅ Should show success message
- ✅ Should navigate to home page with gold prices

#### 3. **Login Test**
- ✅ If already registered, use login screen
- ✅ Enter phone: `9876543210`
- ✅ Enter MPIN: `1234`
- ✅ Tap "Login"
- ✅ Should show success message
- ✅ Should navigate to home page with gold prices

#### 4. **Home Page Test**
- ✅ Gold prices should be visible
- ✅ All navigation should work
- ✅ User menu should show logout option

#### 5. **Logout Test**
- ✅ Tap menu (3 dots) in top right
- ✅ Tap "Logout"
- ✅ Confirm logout
- ✅ Should navigate back to onboarding screen

#### 6. **Subsequent Launches**
- ✅ If user is logged in → Goes directly to home page
- ✅ If user is logged out → Goes to onboarding screen

### Expected Behavior

#### ✅ **Success Cases**
- Registration with valid data → Home page with gold prices
- Login with correct credentials → Home page with gold prices
- Logout → Returns to onboarding screen
- App restart when logged in → Direct to home page

#### ❌ **Error Cases**
- Invalid MPIN → Error message, stays on login screen
- Network error → Error message with retry option
- Server down → Error message

### Troubleshooting

#### **Black Screen Issues**
- Check if SQL Server API is running
- Check network connectivity
- Check device logs for errors

#### **Login Fails**
- Verify SQL Server API is accessible
- Check if customer exists in database
- Verify MPIN encryption is working

#### **Navigation Issues**
- Check if login state is properly saved
- Verify navigation flow in app logs

### Database Verification

You can verify the data in SQL Server Management Studio:

```sql
-- Check registered customers
SELECT phone, name, email, encrypted_mpin 
FROM customers 
ORDER BY created_at DESC;

-- Check login attempts (if logging is implemented)
SELECT * FROM login_logs 
ORDER BY timestamp DESC;
```

### API Testing

Test the API endpoints directly:

```bash
# Health check
curl http://192.168.31.129:3001/health

# Test registration
curl -X POST http://192.168.31.129:3001/api/customers \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","name":"Test User","email":"test@example.com","address":"Test Address","pan_card":"ABCDE1234F","device_id":"test_device","encrypted_mpin":"encrypted_hash_here"}'

# Test login
curl -X POST http://192.168.31.129:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","encrypted_mpin":"encrypted_hash_here"}'
```

### Success Criteria

✅ **Login System Working** if:
1. Registration saves data to SQL Server with encrypted MPIN
2. Login verifies against encrypted MPIN in database
3. Gold prices only show after successful login
4. Logout properly clears session and returns to onboarding
5. App remembers login state between launches

🎯 **Your secure login system is ready for testing!**
