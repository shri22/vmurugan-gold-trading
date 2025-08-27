@echo off
title VMurugan Gold Trading - Server Manager
color 0B

:MAIN_MENU
cls
echo.
echo ========================================
echo 🏆 VMurugan Gold Trading - Server Manager
echo ========================================
echo.
echo Server IP: 103.124.152.220
echo.
echo Please select an option:
echo.
echo 1. 🚀 Start Servers
echo 2. 🛑 Stop Servers  
echo 3. 🔄 Restart Servers
echo 4. 📊 Check Server Status
echo 5. 🧪 Test All Endpoints
echo 6. 🔥 Configure Firewall
echo 7. 📋 Show Server URLs
echo 8. 🚪 Exit
echo.
set /p choice="Enter your choice (1-8): "

if "%choice%"=="1" goto START_SERVERS
if "%choice%"=="2" goto STOP_SERVERS
if "%choice%"=="3" goto RESTART_SERVERS
if "%choice%"=="4" goto CHECK_STATUS
if "%choice%"=="5" goto TEST_ENDPOINTS
if "%choice%"=="6" goto CONFIGURE_FIREWALL
if "%choice%"=="7" goto SHOW_URLS
if "%choice%"=="8" goto EXIT
goto MAIN_MENU

:START_SERVERS
echo.
echo 🚀 Starting VMurugan Gold Trading Servers...
echo.
call VMurugan_AutoStart.bat
goto MAIN_MENU

:STOP_SERVERS
echo.
echo 🛑 Stopping VMurugan Gold Trading Servers...
echo.
taskkill /IM node.exe /F >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ All Node.js servers stopped
) else (
    echo ℹ️  No Node.js servers were running
)
echo.
pause
goto MAIN_MENU

:RESTART_SERVERS
echo.
echo 🔄 Restarting VMurugan Gold Trading Servers...
echo.
echo Stopping existing servers...
taskkill /IM node.exe /F >nul 2>&1
timeout /t 3 /nobreak >nul
echo Starting servers...
call VMurugan_AutoStart.bat
goto MAIN_MENU

:CHECK_STATUS
echo.
echo 📊 Checking VMurugan Server Status...
echo =====================================
echo.

echo Testing SQL Server API (Port 3001)...
curl -s http://localhost:3001/health
echo.
echo.

echo Testing Client Server (Port 3000)...
curl -s http://localhost:3000/health
echo.
echo.

echo Testing External Access...
echo SQL API External: http://103.124.152.220:3001/health
curl -s http://103.124.152.220:3001/health
echo.
echo Client Server External: http://103.124.152.220:3000/health
curl -s http://103.124.152.220:3000/health
echo.
echo.

echo Process Status:
tasklist | findstr node.exe
echo.
pause
goto MAIN_MENU

:TEST_ENDPOINTS
echo.
echo 🧪 Testing All VMurugan API Endpoints...
echo ========================================
echo.

echo 1. Health Check:
curl -s http://localhost:3001/health
echo.
echo.

echo 2. Database Connection Test:
curl -s http://localhost:3001/api/test-connection
echo.
echo.

echo 3. Client Server Health:
curl -s http://localhost:3000/health
echo.
echo.

echo 4. Payment Success Page:
echo Testing: http://103.124.152.220:3000/payment/success
curl -s -I http://localhost:3000/payment/success | findstr "200"
echo.

echo 5. Payment Failure Page:
echo Testing: http://103.124.152.220:3000/payment/failure
curl -s -I http://localhost:3000/payment/failure | findstr "200"
echo.

echo 6. Payment Cancel Page:
echo Testing: http://103.124.152.220:3000/payment/cancel
curl -s -I http://localhost:3000/payment/cancel | findstr "200"
echo.
pause
goto MAIN_MENU

:CONFIGURE_FIREWALL
echo.
echo 🔥 Configuring Windows Firewall for VMurugan...
echo ===============================================
echo.

echo Adding firewall rules...
netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001
netsh advfirewall firewall add rule name="VMurugan Client Server" dir=in action=allow protocol=TCP localport=3000
netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433

echo.
echo ✅ Firewall rules added successfully!
echo.
echo Current firewall rules:
netsh advfirewall firewall show rule name="VMurugan SQL API"
netsh advfirewall firewall show rule name="VMurugan Client Server"
echo.
pause
goto MAIN_MENU

:SHOW_URLS
echo.
echo 📋 VMurugan Gold Trading - All URLs
echo ===================================
echo.
echo 🔗 API ENDPOINTS (For Mobile App):
echo    Base URL:          http://103.124.152.220:3001
echo    Health Check:      http://103.124.152.220:3001/health
echo    Test Connection:   http://103.124.152.220:3001/api/test-connection
echo    Customer Register: http://103.124.152.220:3001/api/customers
echo    User Login:        http://103.124.152.220:3001/api/login
echo    Save Transaction:  http://103.124.152.220:3001/api/transactions
echo    Transaction History: http://103.124.152.220:3001/api/transaction-history
echo.
echo 💳 PAYMENT URLS (For Bank Integration):
echo    Success URL:       http://103.124.152.220:3000/payment/success
echo    Failure URL:       http://103.124.152.220:3000/payment/failure
echo    Cancel URL:        http://103.124.152.220:3000/payment/cancel
echo    Callback URL:      http://103.124.152.220:3000/api/payment/callback
echo.
echo 🏦 BANK INTEGRATION ENDPOINTS:
echo    Payment Callback:  POST http://103.124.152.220:3000/api/payment/callback
echo    Transaction Verify: GET http://103.124.152.220:3001/api/transaction-history?phone=XXXXXXXXXX
echo    Health Check:      GET http://103.124.152.220:3001/health
echo.
echo 📱 MOBILE APP CONFIGURATION:
echo    API_BASE_URL = "http://103.124.152.220:3001"
echo    PAYMENT_SUCCESS_URL = "http://103.124.152.220:3000/payment/success"
echo    PAYMENT_FAILURE_URL = "http://103.124.152.220:3000/payment/failure"
echo    PAYMENT_CANCEL_URL = "http://103.124.152.220:3000/payment/cancel"
echo.
echo 🌐 EXTERNAL ACCESS TEST:
echo    You can test these URLs from any device on the internet
echo    Example: Open http://103.124.152.220:3001/health in any browser
echo.
pause
goto MAIN_MENU

:EXIT
echo.
echo 🚪 Exiting VMurugan Server Manager...
echo.
echo ⚠️  Note: Servers will continue running in background
echo    To stop servers, use option 2 from this menu
echo.
echo Thank you for using VMurugan Gold Trading Server Manager!
echo.
pause
exit /b 0
