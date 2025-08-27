@echo off
echo ========================================
echo 🏆 VMurugan Gold Trading - Simple Setup
echo ========================================
echo.
echo This is a simplified setup script that won't close automatically.
echo Each step will wait for your confirmation.
echo.
echo Your Public IP: 103.124.152.220
echo.

:ADMIN_CHECK
echo Checking if running as Administrator...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ❌ ERROR: This script must be run as Administrator!
    echo.
    echo HOW TO FIX:
    echo 1. Close this window
    echo 2. Right-click on simple_setup.bat
    echo 3. Select "Run as administrator"
    echo 4. Click "Yes" when prompted
    echo.
    goto END_SCRIPT
)
echo ✅ Running as Administrator
echo.
echo Press any key to continue...
pause >nul

:CREATE_DIRECTORIES
echo.
echo ========================================
echo STEP 1: Creating Directory Structure
echo ========================================
echo.

if not exist "C:\VMuruganAPI" (
    mkdir "C:\VMuruganAPI"
    echo ✅ Created C:\VMuruganAPI
) else (
    echo ⚠️  C:\VMuruganAPI already exists
)

if not exist "C:\VMuruganAPI\sql_server_api" (
    mkdir "C:\VMuruganAPI\sql_server_api"
    echo ✅ Created sql_server_api folder
) else (
    echo ⚠️  sql_server_api folder already exists
)

if not exist "C:\VMuruganAPI\server" (
    mkdir "C:\VMuruganAPI\server"
    echo ✅ Created server folder
) else (
    echo ⚠️  server folder already exists
)

if not exist "C:\VMuruganAPI\logs" (
    mkdir "C:\VMuruganAPI\logs"
    echo ✅ Created logs folder
) else (
    echo ⚠️  logs folder already exists
)

echo.
echo ✅ Directory structure completed!
echo Press any key to continue...
pause >nul

:CHECK_NODEJS
echo.
echo ========================================
echo STEP 2: Checking Node.js Installation
echo ========================================
echo.

node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ Node.js is NOT installed!
    echo.
    echo MANUAL TASK REQUIRED:
    echo 1. Download Node.js from: https://nodejs.org/
    echo 2. Install Node.js (LTS version)
    echo 3. Restart this script after installation
    echo.
    echo Opening Node.js website...
    start https://nodejs.org/
    echo.
    goto END_SCRIPT
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo ✅ Node.js is installed: %NODE_VERSION%
)

npm --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ NPM is NOT available!
    echo Please reinstall Node.js
    goto END_SCRIPT
) else (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
    echo ✅ NPM is available: %NPM_VERSION%
)

echo.
echo ✅ Node.js and NPM are ready!
echo Press any key to continue...
pause >nul

:CHECK_SQL_SERVER
echo.
echo ========================================
echo STEP 3: Checking SQL Server
echo ========================================
echo.

sc query MSSQLSERVER >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ SQL Server (MSSQLSERVER) found
    set SQL_INSTANCE=MSSQLSERVER
    set SQL_SERVER_NAME=localhost
    goto SQL_STATUS_CHECK
)

sc query "MSSQL$SQLEXPRESS" >nul 2>&1
if %errorLevel% equ 0 (
    echo ✅ SQL Server Express found
    set SQL_INSTANCE=MSSQL$SQLEXPRESS
    set SQL_SERVER_NAME=localhost\SQLEXPRESS
    goto SQL_STATUS_CHECK
)

echo ❌ SQL Server is NOT installed!
echo.
echo MANUAL TASK REQUIRED:
echo 1. Install SQL Server or SQL Server Express
echo 2. Start the SQL Server service
echo 3. Restart this script
echo.
echo Download from: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
start https://www.microsoft.com/en-us/sql-server/sql-server-downloads
echo.
goto END_SCRIPT

:SQL_STATUS_CHECK
echo Checking SQL Server service status...
sc query %SQL_INSTANCE% | findstr "RUNNING" >nul 2>&1
if %errorLevel% neq 0 (
    echo ⚠️  SQL Server service is not running
    echo Attempting to start SQL Server...
    net start %SQL_INSTANCE%
    if %errorLevel% neq 0 (
        echo ❌ Failed to start SQL Server
        echo.
        echo MANUAL TASK REQUIRED:
        echo 1. Open Services (services.msc)
        echo 2. Find SQL Server service
        echo 3. Start the service manually
        echo.
        goto END_SCRIPT
    ) else (
        echo ✅ SQL Server started successfully
    )
) else (
    echo ✅ SQL Server is running
)

echo.
echo ✅ SQL Server is ready!
echo Press any key to continue...
pause >nul

:CREATE_CONFIG_FILES
echo.
echo ========================================
echo STEP 4: Creating Configuration Files
echo ========================================
echo.

REM Create SQL Server API .env file
if not exist "C:\VMuruganAPI\sql_server_api\.env" (
    echo Creating SQL Server API configuration...
    (
        echo PORT=3001
        echo SQL_SERVER=%SQL_SERVER_NAME%
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
) else (
    echo ⚠️  SQL Server API .env already exists
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
    echo ⚠️  Client Server .env already exists
)

echo.
echo ✅ Configuration files created!
echo.
echo ⚠️  IMPORTANT: You need to edit the SQL password!
echo Edit: C:\VMuruganAPI\sql_server_api\.env
echo Change: SQL_PASSWORD=CHANGE_THIS_PASSWORD
echo.
echo Press any key to continue...
pause >nul

:CREATE_PACKAGE_FILES
echo.
echo ========================================
echo STEP 5: Creating Package Files
echo ========================================
echo.

REM Create SQL Server API package.json
if not exist "C:\VMuruganAPI\sql_server_api\package.json" (
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
) else (
    echo ⚠️  SQL Server API package.json already exists
)

REM Create Client Server package.json
if not exist "C:\VMuruganAPI\server\package.json" (
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
) else (
    echo ⚠️  Client Server package.json already exists
)

echo.
echo ✅ Package files created!
echo Press any key to continue...
pause >nul

:COPY_SERVER_FILES
echo.
echo ========================================
echo STEP 6: Copying Server Files
echo ========================================
echo.

REM Copy SQL Server API server.js
if not exist "C:\VMuruganAPI\sql_server_api\server.js" (
    if exist "sql_server_api\server.js" (
        copy "sql_server_api\server.js" "C:\VMuruganAPI\sql_server_api\" >nul
        echo ✅ Copied SQL Server API server.js
    ) else (
        echo ❌ sql_server_api\server.js not found in current directory
        echo.
        echo MANUAL TASK REQUIRED:
        echo Copy sql_server_api\server.js to C:\VMuruganAPI\sql_server_api\
    )
) else (
    echo ⚠️  SQL Server API server.js already exists
)

REM Copy Client Server files
if not exist "C:\VMuruganAPI\server\server.js" (
    if exist "server\server_clean.js" (
        copy "server\server_clean.js" "C:\VMuruganAPI\server\server.js" >nul
        echo ✅ Copied Client Server server.js
    ) else (
        echo ❌ server\server_clean.js not found in current directory
        echo.
        echo MANUAL TASK REQUIRED:
        echo Copy server\server_clean.js to C:\VMuruganAPI\server\server.js
    )
) else (
    echo ⚠️  Client Server server.js already exists
)

echo.
echo ✅ Server files processed!
echo Press any key to continue...
pause >nul

:INSTALL_DEPENDENCIES
echo.
echo ========================================
echo STEP 7: Installing Dependencies
echo ========================================
echo.

echo Installing SQL Server API dependencies...
cd /d "C:\VMuruganAPI\sql_server_api"
if not exist "node_modules" (
    echo Running npm install for SQL Server API...
    npm install
    if %errorLevel% neq 0 (
        echo ❌ Failed to install SQL Server API dependencies
        echo Check your internet connection and try again
        goto END_SCRIPT
    ) else (
        echo ✅ SQL Server API dependencies installed
    )
) else (
    echo ⚠️  SQL Server API dependencies already installed
)

echo.
echo Installing Client Server dependencies...
cd /d "C:\VMuruganAPI\server"
if not exist "node_modules" (
    echo Running npm install for Client Server...
    npm install
    if %errorLevel% neq 0 (
        echo ❌ Failed to install Client Server dependencies
        echo Check your internet connection and try again
        goto END_SCRIPT
    ) else (
        echo ✅ Client Server dependencies installed
    )
) else (
    echo ⚠️  Client Server dependencies already installed
)

echo.
echo ✅ All dependencies installed!
echo Press any key to continue...
pause >nul

:CONFIGURE_FIREWALL
echo.
echo ========================================
echo STEP 8: Configuring Windows Firewall
echo ========================================
echo.

echo Adding firewall rules...

netsh advfirewall firewall show rule name="VMurugan Client Server" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="VMurugan Client Server" dir=in action=allow protocol=TCP localport=3000
    echo ✅ Added firewall rule for port 3000
) else (
    echo ⚠️  Firewall rule for port 3000 already exists
)

netsh advfirewall firewall show rule name="VMurugan SQL API" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001
    echo ✅ Added firewall rule for port 3001
) else (
    echo ⚠️  Firewall rule for port 3001 already exists
)

netsh advfirewall firewall show rule name="SQL Server" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433
    echo ✅ Added firewall rule for SQL Server port 1433
) else (
    echo ⚠️  Firewall rule for SQL Server port 1433 already exists
)

echo.
echo ✅ Firewall configured!
echo Press any key to continue...
pause >nul

:CREATE_HELPER_SCRIPTS
echo.
echo ========================================
echo STEP 9: Creating Helper Scripts
echo ========================================
echo.

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
    echo ⚠️  start_servers.bat already exists
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
    echo ⚠️  test_servers.bat already exists
)

echo.
echo ✅ Helper scripts created!
echo Press any key to continue...
pause >nul

:SETUP_COMPLETE
echo.
echo ========================================
echo 🎉 AUTOMATED SETUP COMPLETED!
echo ========================================
echo.
echo ✅ What was completed automatically:
echo    📁 Directory structure created
echo    ⚙️  Configuration files created
echo    📦 Dependencies installed
echo    🔥 Firewall configured
echo    🔧 Helper scripts created
echo.
echo 🔧 MANUAL TASKS YOU STILL NEED TO DO:
echo.
echo 1️⃣  EDIT SQL PASSWORD:
echo    📁 File: C:\VMuruganAPI\sql_server_api\.env
echo    🔑 Change: SQL_PASSWORD=CHANGE_THIS_PASSWORD
echo.
echo 2️⃣  ENABLE SQL SERVER AUTHENTICATION:
echo    🖥️  Open SQL Server Management Studio
echo    ⚙️  Server Properties → Security → Mixed Mode
echo    🔄 Restart SQL Server service
echo.
echo 3️⃣  CREATE DATABASE:
echo    🖥️  Run sql_server_setup.sql in SSMS
echo.
echo 4️⃣  START SERVERS:
echo    🚀 Run: C:\VMuruganAPI\start_servers.bat
echo.
echo 5️⃣  TEST EVERYTHING:
echo    🧪 Run: C:\VMuruganAPI\test_servers.bat
echo.
echo ========================================
echo 📁 Installation Directory: C:\VMuruganAPI
echo 🌐 Your Server URLs:
echo    Client Server:    http://103.124.152.220:3000
echo    SQL Server API:   http://103.124.152.220:3001
echo ========================================
echo.
echo Opening installation directory...
start "" "C:\VMuruganAPI"
echo.

:END_SCRIPT
echo Press any key to exit...
pause >nul
cd /d "%~dp0"
