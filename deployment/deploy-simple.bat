@echo off
echo ========================================
echo   VMurugan Gold Trading API
echo   Simple Windows Server Deployment
echo ========================================

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Running as Administrator - OK
) else (
    echo ❌ ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo.
echo 📦 Step 1: Installing Node.js (if not installed)...
where node >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Node.js is already installed
    node --version
) else (
    echo ⚠️ Node.js not found. Please install from https://nodejs.org
    echo Download and install Node.js LTS version, then run this script again.
    pause
    exit /b 1
)

echo.
echo 📦 Step 2: Installing PM2...
call npm install -g pm2
call npm install -g pm2-windows-startup
call pm2-startup install

echo.
echo 📁 Step 3: Creating application directories...
set APP_PATH=C:\VMuruganAPI
mkdir "%APP_PATH%" 2>nul
mkdir "%APP_PATH%\sql_server_api" 2>nul
mkdir "%APP_PATH%\server" 2>nul
mkdir "%APP_PATH%\logs" 2>nul

echo ✅ Directories created:
echo    %APP_PATH%\sql_server_api
echo    %APP_PATH%\server
echo    %APP_PATH%\logs

echo.
echo 🔥 Step 4: Configuring Windows Firewall...
netsh advfirewall firewall add rule name="VMurugan SQL API" dir=in action=allow protocol=TCP localport=3001
netsh advfirewall firewall add rule name="VMurugan Main API" dir=in action=allow protocol=TCP localport=3000
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443

echo.
echo ⚙️ Step 5: Creating environment files...

REM Create SQL Server API .env file
(
echo # VMurugan SQL Server API - Production Configuration
echo PORT=3001
echo NODE_ENV=production
echo HOST=0.0.0.0
echo.
echo # SQL Server Configuration
echo SQL_SERVER=192.168.1.18
echo SQL_PORT=1433
echo SQL_DATABASE=VMuruganGoldTrading
echo SQL_USERNAME=DakData
echo SQL_PASSWORD=Test@123
echo SQL_ENCRYPT=false
echo SQL_TRUST_SERVER_CERTIFICATE=true
echo.
echo # Security Configuration
echo ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
echo JWT_SECRET=vmurugan_production_jwt_secret_2025
echo.
echo # CORS Configuration
echo ALLOWED_ORIGINS=*
echo.
echo # Business Configuration
echo BUSINESS_ID=VMURUGAN_001
echo BUSINESS_NAME=VMurugan Gold Trading
) > "%APP_PATH%\sql_server_api\.env"

REM Create Main Server .env file
(
echo # VMurugan Main Server - Production Configuration
echo PORT=3000
echo NODE_ENV=production
echo HOST=0.0.0.0
echo.
echo # Security Configuration
echo ADMIN_TOKEN=VMURUGAN_MAIN_ADMIN_PRODUCTION_2025
echo JWT_SECRET=vmurugan_main_production_jwt_secret_2025
echo.
echo # CORS Configuration
echo ALLOWED_ORIGINS=*
) > "%APP_PATH%\server\.env"

echo.
echo 🚀 Step 6: Creating startup scripts...

REM Create start script
(
echo @echo off
echo echo Starting VMurugan APIs...
echo cd /d C:\VMuruganAPI\sql_server_api
echo call npm install --production
echo pm2 start server.js --name "vmurugan-sql-api"
echo.
echo cd /d C:\VMuruganAPI\server
echo call npm install --production
echo pm2 start server.js --name "vmurugan-main-api"
echo.
echo pm2 save
echo echo ✅ VMurugan APIs started successfully!
echo echo.
echo echo 🌐 APIs accessible at:
echo echo    SQL Server API: http://localhost:3001/api/
echo echo    Main Server: http://localhost:3000/
echo pause
) > "%APP_PATH%\start-apis.bat"

REM Create stop script
(
echo @echo off
echo echo Stopping VMurugan APIs...
echo pm2 stop all
echo echo ✅ VMurugan APIs stopped!
echo pause
) > "%APP_PATH%\stop-apis.bat"

echo.
echo ✅ ========================================
echo    Deployment Setup Completed!
echo ========================================
echo.
echo 📋 Next Steps:
echo 1. Copy your application files to C:\VMuruganAPI\
echo    - Copy sql_server_api folder contents to C:\VMuruganAPI\sql_server_api\
echo    - Copy server folder contents to C:\VMuruganAPI\server\
echo.
echo 2. Start the APIs:
echo    - Run: C:\VMuruganAPI\start-apis.bat
echo.
echo 3. Test the APIs:
echo    - SQL Server API: http://localhost:3001/api/health
echo    - Main Server: http://localhost:3000/health
echo.
echo 4. Update Flutter app with your public IP address
echo.
echo 🌐 Your APIs will be publicly accessible at:
echo    - SQL Server API: http://YOUR_PUBLIC_IP:3001/api/
echo    - Main Server: http://YOUR_PUBLIC_IP:3000/
echo.
echo ⚙️ Management:
echo    - Start APIs: C:\VMuruganAPI\start-apis.bat
echo    - Stop APIs: C:\VMuruganAPI\stop-apis.bat
echo    - Check status: pm2 status
echo    - View logs: pm2 logs
echo.
pause
