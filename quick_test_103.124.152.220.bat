@echo off
echo ========================================
echo 🧪 VMurugan Gold Trading - Quick Test
echo Server IP: 103.124.152.220
echo ========================================
echo.

echo Testing your VMurugan Gold Trading server...
echo.

echo Step 1: Testing Client Server (Port 3000)...
echo ============================================
curl -s http://103.124.152.220:3000/health
if %errorlevel% equ 0 (
    echo ✅ Client Server is ONLINE
) else (
    echo ❌ Client Server is OFFLINE
)
echo.

echo Step 2: Testing SQL Server API (Port 3001)...
echo ===============================================
curl -s http://103.124.152.220:3001/health
if %errorlevel% equ 0 (
    echo ✅ SQL Server API is ONLINE
) else (
    echo ❌ SQL Server API is OFFLINE
)
echo.

echo Step 3: Testing User Registration...
echo ====================================
curl -s -X POST http://103.124.152.220:3000/api/customers ^
  -H "Content-Type: application/json" ^
  -d "{\"phone\":\"9876543210\",\"name\":\"Test User\",\"email\":\"test@example.com\",\"address\":\"Test Address\",\"pan_card\":\"ABCDE1234F\",\"device_id\":\"test123\"}"
if %errorlevel% equ 0 (
    echo ✅ User Registration API is WORKING
) else (
    echo ❌ User Registration API has ISSUES
)
echo.

echo Step 4: Testing User Login...
echo ==============================
curl -s -X POST http://103.124.152.220:3000/api/login ^
  -H "Content-Type: application/json" ^
  -d "{\"phone\":\"9876543210\",\"encrypted_mpin\":\"1234\"}"
if %errorlevel% equ 0 (
    echo ✅ User Login API is WORKING
) else (
    echo ❌ User Login API has ISSUES
)
echo.

echo Step 5: Testing Payment Success Page...
echo ========================================
curl -s http://103.124.152.220:3000/payment/success > nul
if %errorlevel% equ 0 (
    echo ✅ Payment Success Page is ACCESSIBLE
) else (
    echo ❌ Payment Success Page is NOT ACCESSIBLE
)
echo.

echo Step 6: Testing Payment Failure Page...
echo ========================================
curl -s http://103.124.152.220:3000/payment/failure > nul
if %errorlevel% equ 0 (
    echo ✅ Payment Failure Page is ACCESSIBLE
) else (
    echo ❌ Payment Failure Page is NOT ACCESSIBLE
)
echo.

echo Step 7: Testing Payment Callback...
echo ====================================
curl -s -X POST http://103.124.152.220:3000/api/payment/callback ^
  -H "Content-Type: application/json" ^
  -d "{\"orderId\":\"TEST123\",\"status\":\"success\",\"amount\":1000}"
if %errorlevel% equ 0 (
    echo ✅ Payment Callback API is WORKING
) else (
    echo ❌ Payment Callback API has ISSUES
)
echo.

echo ========================================
echo 📊 TEST SUMMARY
echo ========================================
echo.
echo 🌐 Your Server URLs:
echo    Client Server:    http://103.124.152.220:3000
echo    SQL Server API:   http://103.124.152.220:3001
echo.
echo 💳 Payment URLs for Bank:
echo    Callback:  http://103.124.152.220:3000/api/payment/callback
echo    Success:   http://103.124.152.220:3000/payment/success
echo    Failure:   http://103.124.152.220:3000/payment/failure
echo    Cancel:    http://103.124.152.220:3000/payment/cancel
echo.
echo 📱 Mobile App Configuration:
echo    Server Domain: 103.124.152.220
echo    Server Port:   3000
echo    Protocol:      http
echo.
echo 🧪 For detailed testing, open:
echo    test_server_apis.html (Web Dashboard)
echo    TESTING_GUIDE_103.124.152.220.md (Complete Guide)
echo.

echo Opening web testing dashboard...
start "" test_server_apis.html

echo.
echo Press any key to exit...
pause >nul
