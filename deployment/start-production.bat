@echo off
echo ========================================
echo   VMurugan Gold Trading API Server
echo   Starting Production Services...
echo ========================================

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator - OK
) else (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Set application path
set APP_PATH=C:\VMuruganAPI

REM Check if application directory exists
if not exist "%APP_PATH%" (
    echo ERROR: Application directory not found: %APP_PATH%
    echo Please run the deployment script first.
    pause
    exit /b 1
)

echo.
echo Starting SQL Server API...
cd /d "%APP_PATH%\sql_server_api"
if exist "server.js" (
    call npm install --production
    pm2 start server.js --name "vmurugan-sql-api" --log-file "%APP_PATH%\logs\sql-api.log"
    echo ✅ SQL Server API started
) else (
    echo ❌ SQL Server API files not found
)

echo.
echo Starting Main Server...
cd /d "%APP_PATH%\server"
if exist "server.js" (
    call npm install --production
    pm2 start server.js --name "vmurugan-main-api" --log-file "%APP_PATH%\logs\main-server.log"
    echo ✅ Main Server started
) else (
    echo ❌ Main Server files not found
)

echo.
echo Saving PM2 configuration...
pm2 save

echo.
echo ========================================
echo   Services Status
echo ========================================
pm2 status

echo.
echo ========================================
echo   API Endpoints
echo ========================================
echo SQL Server API: http://localhost:3001/api/
echo Main Server:    http://localhost:3000/
echo.
echo With your public IP:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        echo SQL Server API: http://%%b:3001/api/
        echo Main Server:    http://%%b:3000/
        goto :found
    )
)
:found

echo.
echo ========================================
echo   Testing APIs...
echo ========================================
echo Testing SQL Server API...
curl -s http://localhost:3001/health
echo.
echo Testing Main Server...
curl -s http://localhost:3000/health

echo.
echo ========================================
echo   Production Services Started!
echo ========================================
echo.
echo To stop services: run stop-production.bat
echo To view logs: pm2 logs
echo To restart: pm2 restart all
echo.
pause
