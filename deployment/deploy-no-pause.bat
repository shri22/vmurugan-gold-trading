@echo off
echo ========================================
echo   VMurugan Gold Trading API
echo   Windows Server Deployment
echo ========================================

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running as Administrator
) else (
    echo [ERROR] This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    timeout /t 10
    exit /b 1
)

echo.
echo [STEP 1] Checking Node.js installation...
where node >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Node.js is installed
    node --version
) else (
    echo [ERROR] Node.js not found
    echo Please install Node.js from https://nodejs.org
    echo Download LTS version, install it, then run this script again
    timeout /t 15
    exit /b 1
)

echo.
echo [STEP 2] Installing PM2...
call npm install -g pm2
if %errorLevel% == 0 (
    echo [OK] PM2 installed successfully
) else (
    echo [WARNING] PM2 installation may have failed
)

call npm install -g pm2-windows-startup
call pm2-startup install

echo.
echo [STEP 3] Creating application directories...
set APP_PATH=C:\VMuruganAPI
mkdir "%APP_PATH%" 2>nul
mkdir "%APP_PATH%\sql_server_api" 2>nul
mkdir "%APP_PATH%\server" 2>nul
mkdir "%APP_PATH%\logs" 2>nul

echo [OK] Created directories:
echo    %APP_PATH%\sql_server_api
echo    %APP_PATH%\server
echo    %APP_PATH%\logs

echo.
echo [STEP 4] Configuring Windows Firewall...
netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001 >nul 2>&1
netsh advfirewall firewall add rule name="VMurugan Main API" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443 >nul 2>&1
echo [OK] Firewall rules configured

echo.
echo [STEP 5] Creating environment files...

REM Create SQL Server API .env file
(
echo PORT=3001
echo NODE_ENV=production
echo HOST=0.0.0.0
echo.
echo SQL_SERVER=192.168.1.18
echo SQL_PORT=1433
echo SQL_DATABASE=VMuruganGoldTrading
echo SQL_USERNAME=DakData
echo SQL_PASSWORD=Test@123
echo SQL_ENCRYPT=false
echo SQL_TRUST_SERVER_CERTIFICATE=true
echo.
echo ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
echo JWT_SECRET=vmurugan_production_jwt_secret_2025
echo.
echo ALLOWED_ORIGINS=*
echo.
echo BUSINESS_ID=VMURUGAN_001
echo BUSINESS_NAME=VMurugan Gold Trading
) > "%APP_PATH%\sql_server_api\.env"

REM Create Main Server .env file
(
echo PORT=3000
echo NODE_ENV=production
echo HOST=0.0.0.0
echo.
echo ADMIN_TOKEN=VMURUGAN_MAIN_ADMIN_PRODUCTION_2025
echo JWT_SECRET=vmurugan_main_production_jwt_secret_2025
echo.
echo ALLOWED_ORIGINS=*
) > "%APP_PATH%\server\.env"

echo [OK] Environment files created

echo.
echo [STEP 6] Creating management scripts...

REM Create start script
(
echo @echo off
echo echo Starting VMurugan APIs...
echo echo.
echo echo [1/4] Installing SQL Server API dependencies...
echo cd /d C:\VMuruganAPI\sql_server_api
echo call npm install --production
echo echo [2/4] Starting SQL Server API...
echo pm2 start server.js --name "vmurugan-sql-api"
echo echo.
echo echo [3/4] Installing Main Server dependencies...
echo cd /d C:\VMuruganAPI\server
echo call npm install --production
echo echo [4/4] Starting Main Server...
echo pm2 start server.js --name "vmurugan-main-api"
echo echo.
echo pm2 save
echo echo ========================================
echo echo   VMurugan APIs Started Successfully!
echo echo ========================================
echo echo.
echo echo APIs are now running:
echo echo   SQL Server API: http://localhost:3001/api/
echo echo   Main Server: http://localhost:3000/
echo echo.
echo echo To check status: pm2 status
echo echo To view logs: pm2 logs
echo echo To stop: pm2 stop all
echo echo.
echo timeout /t 10
) > "%APP_PATH%\start-apis.bat"

REM Create stop script
(
echo @echo off
echo echo Stopping VMurugan APIs...
echo pm2 stop all
echo echo VMurugan APIs stopped successfully!
echo timeout /t 5
) > "%APP_PATH%\stop-apis.bat"

REM Create status script
(
echo @echo off
echo echo VMurugan API Status:
echo echo ========================================
echo pm2 status
echo echo.
echo echo Recent logs:
echo echo ========================================
echo pm2 logs --lines 10
echo echo.
echo timeout /t 15
) > "%APP_PATH%\check-status.bat"

echo [OK] Management scripts created

echo.
echo ========================================
echo   DEPLOYMENT SETUP COMPLETED!
echo ========================================
echo.
echo NEXT STEPS:
echo.
echo 1. Copy your application files:
echo    - Copy contents of sql_server_api folder to: %APP_PATH%\sql_server_api\
echo    - Copy contents of server folder to: %APP_PATH%\server\
echo.
echo 2. Start the APIs:
echo    - Double-click: %APP_PATH%\start-apis.bat
echo    - Or run: %APP_PATH%\start-apis.bat
echo.
echo 3. Check status:
echo    - Run: %APP_PATH%\check-status.bat
echo    - Or run: pm2 status
echo.
echo 4. Test the APIs:
echo    - SQL Server API: http://localhost:3001/api/health
echo    - Main Server: http://localhost:3000/health
echo.
echo 5. Update Flutter app with your public IP
echo.
echo MANAGEMENT COMMANDS:
echo   Start APIs: %APP_PATH%\start-apis.bat
echo   Stop APIs: %APP_PATH%\stop-apis.bat
echo   Check Status: %APP_PATH%\check-status.bat
echo.
echo Your APIs will be publicly accessible at:
echo   SQL Server API: http://YOUR_PUBLIC_IP:3001/api/
echo   Main Server: http://YOUR_PUBLIC_IP:3000/
echo.
echo ========================================
echo   Setup completed successfully!
echo ========================================

timeout /t 20
