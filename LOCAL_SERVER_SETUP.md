# Local Server Setup for APK Testing

## Quick Setup Guide

Your Flutter app is now configured to connect to a local MySQL server instead of Firebase. Follow these steps to connect to your teammate's server:

### Step 1: Get Your Teammate's Server Details

Ask your teammate for:
1. **IP Address** of their computer
2. **Port** (usually 3000)
3. **Admin Token** (if different from default)

### Step 2: Find Your Teammate's IP Address

**On Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" (usually 192.168.x.x)

**On Mac/Linux:**
```bash
ifconfig
```
Look for "inet" address (usually 192.168.x.x)

### Step 3: Update Configuration

Edit `lib/core/config/server_config.dart`:

```dart
// Replace 'YOUR_TEAMMATE_IP' with actual IP
static const String teammateIP = '192.168.1.100'; // Example IP
```

### Step 4: Common IP Configurations

**For Android Emulator:**
```dart
static const String teammateIP = '10.0.2.2'; // Special emulator IP
```

**For iOS Simulator:**
```dart
static const String teammateIP = 'localhost';
```

**For Physical Device (same WiFi):**
```dart
static const String teammateIP = '192.168.1.XXX'; // Replace XXX with actual IP
```

### Step 5: Ensure Your Teammate's Server is Running

Your teammate should:
1. Navigate to the `server` folder
2. Run: `npm install` (first time only)
3. Run: `npm start`
4. Server should show: "🚀 Digi Gold Business Server running on port 3000"

### Step 6: Test Connection

1. Add the test widget to your app (optional)
2. Build and run your APK
3. Test customer registration or transactions

### Step 7: Verify Database Connection

Your teammate can check if data is being saved by:
1. Opening MySQL/phpMyAdmin
2. Checking the `digi_gold_business` database
3. Looking at `customers` and `transactions` tables

## Troubleshooting

### Connection Issues

1. **"Connection refused"**
   - Check if server is running
   - Verify IP address is correct
   - Ensure you're on the same WiFi network

2. **"Timeout"**
   - Check firewall settings
   - Try different IP configurations
   - Verify port 3000 is open

3. **"Unauthorized"**
   - Check admin token matches
   - Verify headers are correct

### Network Issues

1. **Different WiFi Networks**
   - Both devices must be on same network
   - Use mobile hotspot if needed

2. **Corporate/School Networks**
   - May block local connections
   - Try personal hotspot

### Database Issues

1. **MySQL not running**
   - Your teammate needs to start MySQL service
   - Run database setup: `npm run setup`

2. **Database doesn't exist**
   - Run: `node setup.js` in server folder

## Testing Checklist

- [ ] Teammate's server is running
- [ ] IP address is correct in config
- [ ] Both devices on same WiFi
- [ ] MySQL database is set up
- [ ] App builds without errors
- [ ] Can register test customer
- [ ] Data appears in database

## Current Configuration

- **API Mode**: Custom Server (not Firebase)
- **Base URL**: Configured in `server_config.dart`
- **Admin Token**: VMURUGAN_ADMIN_2025
- **Business ID**: VMURUGAN_001

## Files Modified

1. `lib/core/config/server_config.dart` - Server configuration
2. `lib/core/services/api_service.dart` - Switched to custom server
3. `lib/core/services/custom_server_service.dart` - Updated for local server
4. `lib/core/widgets/server_test_widget.dart` - Connection testing (optional)

## Next Steps

1. Update IP address in configuration
2. Build APK: `flutter build apk`
3. Install on device and test
4. Verify data in teammate's database
5. Test all app features (registration, transactions, etc.)

## Support

If you encounter issues:
1. Check server logs on teammate's computer
2. Use browser to test: `http://TEAMMATE_IP:3000/health`
3. Verify network connectivity
4. Check app logs for error messages
