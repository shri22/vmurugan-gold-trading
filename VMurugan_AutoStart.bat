@echo off
title VMurugan Gold Trading - Auto Start Server
color 0A

echo.
echo ========================================
echo 🏆 VMurugan Gold Trading - Auto Start
echo ========================================
echo.
echo Server IP: 103.124.152.220
echo Starting servers automatically...
echo.

REM Set error handling
setlocal enabledelayedexpansion

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ ERROR: Please run as Administrator!
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo ✅ Running as Administrator
echo.

REM Kill any existing Node.js processes
echo 🔄 Stopping existing Node.js processes...
taskkill /IM node.exe /F >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ Stopped existing Node.js processes
) else (
    echo ℹ️  No existing Node.js processes found
)
timeout /t 2 /nobreak >nul

REM Check if directories exist
if not exist "C:\VMuruganAPI\sql_server_api" (
    echo ❌ ERROR: SQL Server API directory not found!
    echo Expected: C:\VMuruganAPI\sql_server_api
    echo.
    pause
    exit /b 1
)

if not exist "C:\VMuruganAPI\server" (
    echo ❌ ERROR: Client Server directory not found!
    echo Expected: C:\VMuruganAPI\server
    echo.
    pause
    exit /b 1
)

echo ✅ Server directories found
echo.

REM Check if server files exist
if not exist "C:\VMuruganAPI\sql_server_api\server.js" (
    echo ❌ ERROR: SQL Server API file not found!
    echo Expected: C:\VMuruganAPI\sql_server_api\server.js
    echo.
    pause
    exit /b 1
)

if not exist "C:\VMuruganAPI\server\server.js" (
    echo ❌ ERROR: Client Server file not found!
    echo Expected: C:\VMuruganAPI\server\server.js
    echo.
    pause
    exit /b 1
)

echo ✅ Server files found
echo.

REM Check Node.js installation
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ ERROR: Node.js is not installed or not in PATH!
    echo Please install Node.js from https://nodejs.org/
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo ✅ Node.js found: %NODE_VERSION%
echo.

REM Check SQL Server service
echo 🔍 Checking SQL Server service...
sc query MSSQLSERVER | findstr "RUNNING" >nul 2>&1
if %errorLevel% neq 0 (
    echo ⚠️  SQL Server not running, attempting to start...
    net start MSSQLSERVER >nul 2>&1
    if %errorLevel% neq 0 (
        echo ❌ Failed to start SQL Server
        echo Please start SQL Server manually
        echo.
        pause
        exit /b 1
    )
)
echo ✅ SQL Server is running
echo.

REM Check if ports are available
echo 🔍 Checking port availability...
netstat -an | findstr ":3001" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo ⚠️  Port 3001 is already in use, killing process...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3001" ^| findstr "LISTENING"') do (
        taskkill /PID %%a /F >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

netstat -an | findstr ":3000" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo ⚠️  Port 3000 is already in use, killing process...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
        taskkill /PID %%a /F >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

echo ✅ Ports are available
echo.

REM Configure Windows Firewall
echo 🔥 Configuring Windows Firewall...
netsh advfirewall firewall show rule name="VMurugan SQL API" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001 >nul 2>&1
    echo ✅ Added firewall rule for port 3001
)

netsh advfirewall firewall show rule name="VMurugan Client Server" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="VMurugan Client Server" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
    echo ✅ Added firewall rule for port 3000
)

echo ✅ Firewall configured
echo.

REM Start SQL Server API (Port 3001)
echo 🚀 Starting SQL Server API (Port 3001)...
echo ========================================
start "VMurugan SQL Server API" cmd /k "cd /d C:\VMuruganAPI\sql_server_api && echo 🚀 Starting SQL Server API... && node server.js"

REM Wait for SQL Server API to start
echo ⏳ Waiting for SQL Server API to initialize...
timeout /t 8 /nobreak >nul

REM Test SQL Server API
echo 🧪 Testing SQL Server API...
curl -s http://localhost:3001/health >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ SQL Server API is responding
) else (
    echo ⚠️  SQL Server API may still be starting...
)
echo.

REM Start Client Server (Port 3000)
echo 🚀 Starting Client Server (Port 3000)...
echo ========================================
start "VMurugan Client Server" cmd /k "cd /d C:\VMuruganAPI\server && echo 🚀 Starting Client Server... && node server.js"

REM Wait for Client Server to start
echo ⏳ Waiting for Client Server to initialize...
timeout /t 5 /nobreak >nul

REM Test Client Server
echo 🧪 Testing Client Server...
curl -s http://localhost:3000/health >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ Client Server is responding
) else (
    echo ⚠️  Client Server may still be starting...
)
echo.

REM Final status check
echo ========================================
echo 🎉 VMurugan Gold Trading Servers Started!
echo ========================================
echo.
echo 📊 Server Status:
echo ✅ SQL Server API:    http://103.124.152.220:3001
echo ✅ Client Server:     http://103.124.152.220:3000
echo.
echo 🔗 API Endpoints:
echo    Health Check:      http://103.124.152.220:3001/health
echo    Test Connection:   http://103.124.152.220:3001/api/test-connection
echo    Customer API:      http://103.124.152.220:3001/api/customers
echo    Login API:         http://103.124.152.220:3001/api/login
echo    Transaction API:   http://103.124.152.220:3001/api/transactions
echo.
echo 💳 Payment URLs:
echo    Success:           http://103.124.152.220:3000/payment/success
echo    Failure:           http://103.124.152.220:3000/payment/failure
echo    Cancel:            http://103.124.152.220:3000/payment/cancel
echo.
echo 📱 Mobile App Configuration:
echo    API Base URL:      http://103.124.152.220:3001
echo    Payment Base URL:  http://103.124.152.220:3000
echo.
echo ⚠️  IMPORTANT NOTES:
echo    - Both servers are running in separate windows
echo    - Do not close the server windows
echo    - To stop servers: Close the server windows or run this script again
echo    - Check Windows Firewall if external access fails
echo.
echo 🏦 Bank Integration URLs:
echo    Callback URL:      http://103.124.152.220:3000/api/payment/callback
echo    Verify URL:        http://103.124.152.220:3001/api/transaction-history
echo.

REM Test external access
echo 🌐 Testing external access...
curl -s http://103.124.152.220:3001/health >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ External access working for API
) else (
    echo ⚠️  External access may be blocked by firewall
)

curl -s http://103.124.152.220:3000/health >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ External access working for Client Server
) else (
    echo ⚠️  External access may be blocked by firewall
)

echo.
echo 🎯 Next Steps:
echo    1. Test the URLs above in your browser
echo    2. Configure your mobile app with the provided URLs
echo    3. Share bank integration URLs with your payment gateway provider
echo    4. Test end-to-end functionality
echo.
echo Press any key to exit (servers will continue running)...
pause >nul

REM Create a status check script
echo @echo off > C:\VMuruganAPI\check_status.bat
echo echo VMurugan Gold Trading - Server Status >> C:\VMuruganAPI\check_status.bat
echo echo ======================================= >> C:\VMuruganAPI\check_status.bat
echo curl http://localhost:3001/health >> C:\VMuruganAPI\check_status.bat
echo echo. >> C:\VMuruganAPI\check_status.bat
echo curl http://localhost:3000/health >> C:\VMuruganAPI\check_status.bat
echo pause >> C:\VMuruganAPI\check_status.bat

echo.
echo ✅ Created status check script: C:\VMuruganAPI\check_status.bat
echo.

exit /b 0
