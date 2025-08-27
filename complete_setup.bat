@echo off
setlocal enabledelayedexpansion

echo ========================================
echo 🏆 VMurugan Gold Trading - Complete Setup
echo ========================================
echo.
echo This script will set up your entire server infrastructure.
echo Some steps require MANUAL intervention - we'll guide you!
echo.
echo Your Public IP: 103.124.152.220
echo.
echo Press any key to start the setup process...
pause >nul
echo.
echo Starting setup process...
echo.

REM Check if running as administrator
echo Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ❌ ERROR: This script must be run as Administrator!
    echo.
    echo 🔧 HOW TO FIX:
    echo    1. Close this window
    echo    2. Right-click on complete_setup.bat
    echo    3. Select "Run as administrator"
    echo    4. Click "Yes" when prompted
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo ✅ Running as Administrator
echo.

REM =============================================================================
echo 📁 STEP 1: Creating Directory Structure
echo =============================================================================
if not exist "C:\VMuruganAPI" (
    mkdir "C:\VMuruganAPI"
    echo ✅ Created C:\VMuruganAPI
) else (
    echo ⚠️  C:\VMuruganAPI already exists - skipping
)

if not exist "C:\VMuruganAPI\sql_server_api" (
    mkdir "C:\VMuruganAPI\sql_server_api"
    echo ✅ Created C:\VMuruganAPI\sql_server_api
) else (
    echo ⚠️  sql_server_api folder already exists - skipping
)

if not exist "C:\VMuruganAPI\server" (
    mkdir "C:\VMuruganAPI\server"
    echo ✅ Created C:\VMuruganAPI\server
) else (
    echo ⚠️  server folder already exists - skipping
)

if not exist "C:\VMuruganAPI\logs" (
    mkdir "C:\VMuruganAPI\logs"
    echo ✅ Created C:\VMuruganAPI\logs
) else (
    echo ⚠️  logs folder already exists - skipping
)

echo.
echo ✅ Directory structure created successfully!
echo Press any key to continue...
pause >nul
echo.

REM =============================================================================
echo 📦 STEP 2: Checking Node.js Installation
echo =============================================================================
echo Checking Node.js installation...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ❌ Node.js is not installed!
    echo.
    echo 🔧 MANUAL TASK REQUIRED:
    echo    1. Download Node.js from: https://nodejs.org/
    echo    2. Install Node.js (LTS version recommended)
    echo    3. Restart this script after installation
    echo.
    echo Press any key to exit and install Node.js...
    pause >nul
    start https://nodejs.org/
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo ✅ Node.js is installed: !NODE_VERSION!
)

echo Checking NPM availability...
npm --version >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ❌ NPM is not available!
    echo Please reinstall Node.js to get NPM
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
    echo ✅ NPM is available: !NPM_VERSION!
)
echo.
echo ✅ Node.js and NPM are ready!
echo Press any key to continue...
pause >nul
echo.

REM =============================================================================
echo 🗄️  STEP 3: Checking SQL Server Installation
echo =============================================================================
sc query MSSQLSERVER >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ SQL Server (MSSQLSERVER) service found
    set SQL_INSTANCE=MSSQLSERVER
    set SQL_SERVER_NAME=localhost
) else (
    sc query "MSSQL$SQLEXPRESS" >nul 2>&1
    if %errorLevel% equ 0 (
        echo ✅ SQL Server Express service found
        set SQL_INSTANCE=MSSQL$SQLEXPRESS
        set SQL_SERVER_NAME=localhost\SQLEXPRESS
    ) else (
        echo ❌ SQL Server is not installed or not running!
        echo.
        echo 🔧 MANUAL TASK REQUIRED:
        echo    1. Install SQL Server or SQL Server Express
        echo    2. Start the SQL Server service
        echo    3. Restart this script
        echo.
        echo Download from: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
        pause
        exit /b 1
    )
)

REM Check if SQL Server is running
sc query !SQL_INSTANCE! | findstr "RUNNING" >nul 2>&1
if %errorLevel% neq 0 (
    echo ⚠️  SQL Server service is not running. Starting...
    net start !SQL_INSTANCE!
    if %errorLevel% neq 0 (
        echo ❌ Failed to start SQL Server service
        echo.
        echo 🔧 MANUAL TASK REQUIRED:
        echo    1. Open Services (services.msc)
        echo    2. Find SQL Server service
        echo    3. Start the service manually
        echo    4. Restart this script
        pause
        exit /b 1
    ) else (
        echo ✅ SQL Server service started successfully
    )
) else (
    echo ✅ SQL Server service is running
)
echo.

REM =============================================================================
echo 📝 STEP 4: Creating Configuration Files
echo =============================================================================

REM Create SQL Server API .env file
if not exist "C:\VMuruganAPI\sql_server_api\.env" (
    echo Creating SQL Server API configuration...
    (
        echo PORT=3001
        echo SQL_SERVER=!SQL_SERVER_NAME!
        echo SQL_PORT=1433
        echo SQL_DATABASE=VMuruganGoldTrading
        echo SQL_USERNAME=sa
        echo SQL_PASSWORD=CHANGE_THIS_PASSWORD
        echo SQL_ENCRYPT=false
        echo SQL_TRUST_SERVER_CERTIFICATE=true
        echo SQL_CONNECTION_TIMEOUT=30000
        echo SQL_REQUEST_TIMEOUT=30000
        echo ADMIN_TOKEN=VMURUGAN_ADMIN_2025
        echo ALLOWED_ORIGINS=*
    ) > "C:\VMuruganAPI\sql_server_api\.env"
    echo ✅ Created SQL Server API .env file
    echo.
    echo 🔧 MANUAL TASK REQUIRED:
    echo    Edit C:\VMuruganAPI\sql_server_api\.env
    echo    Change SQL_PASSWORD to your actual SA password
    echo.
) else (
    echo ⚠️  SQL Server API .env already exists - skipping
)

REM Create Client Server .env file
if not exist "C:\VMuruganAPI\server\.env" (
    echo Creating Client Server configuration...
    (
        echo PORT=3000
        echo SQL_API_URL=http://localhost:3001
        echo ALLOWED_ORIGINS=*
        echo PUBLIC_IP=103.124.152.220
    ) > "C:\VMuruganAPI\server\.env"
    echo ✅ Created Client Server .env file
) else (
    echo ⚠️  Client Server .env already exists - skipping
)
echo.

REM =============================================================================
echo 📄 STEP 5: Creating Server Files
echo =============================================================================

REM Check if server files exist, if not copy from project
if not exist "C:\VMuruganAPI\sql_server_api\server.js" (
    if exist "sql_server_api\server.js" (
        copy "sql_server_api\server.js" "C:\VMuruganAPI\sql_server_api\" >nul
        echo ✅ Copied SQL Server API server.js
    ) else (
        echo ❌ SQL Server API server.js not found in current directory
        echo.
        echo 🔧 MANUAL TASK REQUIRED:
        echo    Copy sql_server_api\server.js to C:\VMuruganAPI\sql_server_api\
        echo.
    )
) else (
    echo ⚠️  SQL Server API server.js already exists - skipping
)

if not exist "C:\VMuruganAPI\sql_server_api\package.json" (
    if exist "sql_server_api\package.json" (
        copy "sql_server_api\package.json" "C:\VMuruganAPI\sql_server_api\" >nul
        echo ✅ Copied SQL Server API package.json
    ) else (
        echo Creating SQL Server API package.json...
        (
            echo {
            echo   "name": "vmurugan-sql-server-api",
            echo   "version": "1.0.0",
            echo   "description": "VMurugan Gold Trading SQL Server API",
            echo   "main": "server.js",
            echo   "scripts": {
            echo     "start": "node server.js"
            echo   },
            echo   "dependencies": {
            echo     "express": "^4.18.2",
            echo     "mssql": "^10.0.1",
            echo     "cors": "^2.8.5",
            echo     "helmet": "^7.1.0",
            echo     "express-rate-limit": "^7.1.5",
            echo     "express-validator": "^7.0.1",
            echo     "dotenv": "^16.3.1"
            echo   }
            echo }
        ) > "C:\VMuruganAPI\sql_server_api\package.json"
        echo ✅ Created SQL Server API package.json
    )
) else (
    echo ⚠️  SQL Server API package.json already exists - skipping
)

if not exist "C:\VMuruganAPI\server\server.js" (
    if exist "server\server_clean.js" (
        copy "server\server_clean.js" "C:\VMuruganAPI\server\server.js" >nul
        echo ✅ Copied Client Server server.js
    ) else (
        echo ❌ Client Server server_clean.js not found in current directory
        echo.
        echo 🔧 MANUAL TASK REQUIRED:
        echo    Copy server\server_clean.js to C:\VMuruganAPI\server\server.js
        echo.
    )
) else (
    echo ⚠️  Client Server server.js already exists - skipping
)

if not exist "C:\VMuruganAPI\server\package.json" (
    if exist "server\package_clean.json" (
        copy "server\package_clean.json" "C:\VMuruganAPI\server\package.json" >nul
        echo ✅ Copied Client Server package.json
    ) else (
        echo Creating Client Server package.json...
        (
            echo {
            echo   "name": "vmurugan-client-server",
            echo   "version": "1.0.0",
            echo   "description": "VMurugan Gold Trading Client Server",
            echo   "main": "server.js",
            echo   "scripts": {
            echo     "start": "node server.js"
            echo   },
            echo   "dependencies": {
            echo     "express": "^4.18.2",
            echo     "cors": "^2.8.5",
            echo     "dotenv": "^16.3.1",
            echo     "axios": "^1.6.2"
            echo   }
            echo }
        ) > "C:\VMuruganAPI\server\package.json"
        echo ✅ Created Client Server package.json
    )
) else (
    echo ⚠️  Client Server package.json already exists - skipping
)
echo.

REM =============================================================================
echo 📦 STEP 6: Installing Dependencies
echo =============================================================================
echo Installing SQL Server API dependencies...
cd /d "C:\VMuruganAPI\sql_server_api"
if not exist "node_modules" (
    npm install
    if %errorLevel% neq 0 (
        echo ❌ Failed to install SQL Server API dependencies
        pause
        exit /b 1
    ) else (
        echo ✅ SQL Server API dependencies installed
    )
) else (
    echo ⚠️  SQL Server API dependencies already installed - skipping
)

echo Installing Client Server dependencies...
cd /d "C:\VMuruganAPI\server"
if not exist "node_modules" (
    npm install
    if %errorLevel% neq 0 (
        echo ❌ Failed to install Client Server dependencies
        pause
        exit /b 1
    ) else (
        echo ✅ Client Server dependencies installed
    )
) else (
    echo ⚠️  Client Server dependencies already installed - skipping
)
echo.

REM =============================================================================
echo 🔥 STEP 7: Configuring Windows Firewall
echo =============================================================================
echo Configuring firewall rules...

netsh advfirewall firewall show rule name="VMurugan Client Server" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="VMurugan Client Server" dir=in action=allow protocol=TCP localport=3000
    echo ✅ Added firewall rule for port 3000
) else (
    echo ⚠️  Firewall rule for port 3000 already exists - skipping
)

netsh advfirewall firewall show rule name="VMurugan SQL API" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001
    echo ✅ Added firewall rule for port 3001
) else (
    echo ⚠️  Firewall rule for port 3001 already exists - skipping
)

netsh advfirewall firewall show rule name="SQL Server" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433
    echo ✅ Added firewall rule for SQL Server port 1433
) else (
    echo ⚠️  Firewall rule for SQL Server port 1433 already exists - skipping
)
echo.

REM =============================================================================
echo 📋 STEP 8: Creating Helper Scripts
echo =============================================================================

REM Create start script
if not exist "C:\VMuruganAPI\start_servers.bat" (
    (
        echo @echo off
        echo echo Starting VMurugan Gold Trading Servers...
        echo echo.
        echo echo Starting SQL Server API ^(Port 3001^)...
        echo start "VMurugan SQL API" cmd /k "cd /d C:\VMuruganAPI\sql_server_api && node server.js"
        echo timeout /t 5 /nobreak ^> nul
        echo echo Starting Client Server ^(Port 3000^)...
        echo start "VMurugan Client Server" cmd /k "cd /d C:\VMuruganAPI\server && node server.js"
        echo echo.
        echo echo ✅ Both servers are starting...
        echo echo Check the opened windows for status
        echo pause
    ) > "C:\VMuruganAPI\start_servers.bat"
    echo ✅ Created start_servers.bat
) else (
    echo ⚠️  start_servers.bat already exists - skipping
)

REM Create stop script
if not exist "C:\VMuruganAPI\stop_servers.bat" (
    (
        echo @echo off
        echo echo Stopping VMurugan Gold Trading Servers...
        echo taskkill /f /im node.exe
        echo echo ✅ All Node.js processes stopped
        echo pause
    ) > "C:\VMuruganAPI\stop_servers.bat"
    echo ✅ Created stop_servers.bat
) else (
    echo ⚠️  stop_servers.bat already exists - skipping
)

REM Create test script
if not exist "C:\VMuruganAPI\test_servers.bat" (
    (
        echo @echo off
        echo echo Testing VMurugan Gold Trading Servers...
        echo echo.
        echo echo Testing SQL Server API ^(Port 3001^)...
        echo curl -s http://localhost:3001/health
        echo echo.
        echo echo Testing Client Server ^(Port 3000^)...
        echo curl -s http://localhost:3000/health
        echo echo.
        echo echo Testing External Access...
        echo curl -s http://103.124.152.220:3000/health
        echo echo.
        echo pause
    ) > "C:\VMuruganAPI\test_servers.bat"
    echo ✅ Created test_servers.bat
) else (
    echo ⚠️  test_servers.bat already exists - skipping
)
echo.

REM =============================================================================
echo 🎯 SETUP COMPLETE - MANUAL TASKS REQUIRED
echo =============================================================================
echo.
echo ✅ AUTOMATED SETUP COMPLETED SUCCESSFULLY!
echo.
echo 🔧 MANUAL TASKS YOU NEED TO DO:
echo.
echo 1️⃣  CONFIGURE SQL SERVER PASSWORD:
echo    📁 Edit: C:\VMuruganAPI\sql_server_api\.env
echo    🔑 Change: SQL_PASSWORD=CHANGE_THIS_PASSWORD
echo    💡 Use your actual SA password or create new user
echo.
echo 2️⃣  ENABLE SQL SERVER AUTHENTICATION:
echo    🖥️  Open SQL Server Management Studio (SSMS)
echo    ⚙️  Right-click server → Properties → Security
echo    🔐 Select "SQL Server and Windows Authentication mode"
echo    🔄 Restart SQL Server service
echo.
echo 3️⃣  ENABLE TCP/IP PROTOCOL:
echo    🖥️  Open SQL Server Configuration Manager
echo    🌐 Protocols for [Instance] → TCP/IP → Enable
echo    🔄 Restart SQL Server service
echo.
echo 4️⃣  CREATE DATABASE:
echo    🖥️  Open SSMS and run this query:
echo    📝 CREATE DATABASE VMuruganGoldTrading;
echo.
echo 5️⃣  START THE SERVERS:
echo    🚀 Run: C:\VMuruganAPI\start_servers.bat
echo.
echo 6️⃣  TEST EVERYTHING:
echo    🧪 Run: C:\VMuruganAPI\test_servers.bat
echo    🌐 Open: test_server_apis.html (from your project)
echo.
echo ========================================
echo 📋 QUICK REFERENCE
echo ========================================
echo.
echo 📁 Installation Directory: C:\VMuruganAPI\
echo 🔧 Configuration Files:
echo    SQL API: C:\VMuruganAPI\sql_server_api\.env
echo    Client:  C:\VMuruganAPI\server\.env
echo.
echo 🚀 Control Scripts:
echo    Start:   C:\VMuruganAPI\start_servers.bat
echo    Stop:    C:\VMuruganAPI\stop_servers.bat
echo    Test:    C:\VMuruganAPI\test_servers.bat
echo.
echo 🌐 Your Server URLs:
echo    Client Server:    http://103.124.152.220:3000
echo    SQL Server API:   http://103.124.152.220:3001
echo.
echo 💳 Payment URLs for Bank:
echo    Callback: http://103.124.152.220:3000/api/payment/callback
echo    Success:  http://103.124.152.220:3000/payment/success
echo    Failure:  http://103.124.152.220:3000/payment/failure
echo.
echo ========================================
echo 🔧 TROUBLESHOOTING
echo ========================================
echo.
echo ❌ If SQL Server connection fails:
echo    1. Check SQL_PASSWORD in .env file
echo    2. Enable Mixed Mode Authentication
echo    3. Enable TCP/IP protocol
echo    4. Restart SQL Server service
echo.
echo ❌ If servers don't start:
echo    1. Check if ports 3000/3001 are free
echo    2. Run as Administrator
echo    3. Check firewall settings
echo.
echo ❌ If external access fails:
echo    1. Check Windows Firewall
echo    2. Check router/network firewall
echo    3. Verify public IP is correct
echo.
echo ========================================
echo 📞 NEXT STEPS
echo ========================================
echo.
echo After completing manual tasks:
echo.
echo 1. 🔧 Complete the 6 manual tasks above
echo 2. 🚀 Start servers: start_servers.bat
echo 3. 🧪 Test everything: test_servers.bat
echo 4. 📱 Test mobile app with your IP
echo 5. 🏦 Share payment URLs with bank
echo 6. 🏪 Submit to Play Store
echo.
echo ========================================
echo 🎉 SETUP SCRIPT COMPLETED!
echo ========================================
echo.
echo Opening installation directory...
start "" "C:\VMuruganAPI"
echo.
echo Press any key to exit...
pause >nul

cd /d "%~dp0"
