@echo off
title VMurugan Gold Trading - Clean Deployment

echo ========================================
echo VMurugan Gold Trading - Clean Deployment
echo ========================================
echo.
echo This will deploy the cleaned-up version to production.
echo.
pause

echo.
echo Step 1: Stop existing services...
taskkill /f /im node.exe 2>nul
pm2 stop all 2>nul
pm2 delete all 2>nul
echo ✅ Services stopped

echo.
echo Step 2: Create deployment directories...
if not exist "C:\VMuruganAPI" mkdir "C:\VMuruganAPI"
if not exist "C:\VMuruganAPI\sql_server_api" mkdir "C:\VMuruganAPI\sql_server_api"
if not exist "C:\VMuruganAPI\server" mkdir "C:\VMuruganAPI\server"

echo.
echo Step 3: Deploy SQL Server API...
copy "sql_server_api\server.js" "C:\VMuruganAPI\sql_server_api\"
copy "sql_server_api\package_clean.json" "C:\VMuruganAPI\sql_server_api\package.json"
echo PORT=3001 > "C:\VMuruganAPI\sql_server_api\.env"
echo SQL_SERVER=192.168.1.200 >> "C:\VMuruganAPI\sql_server_api\.env"
echo SQL_USERNAME=sa >> "C:\VMuruganAPI\sql_server_api\.env"
echo SQL_PASSWORD=git@#12345 >> "C:\VMuruganAPI\sql_server_api\.env"
echo SQL_DATABASE=VMuruganGoldTrading >> "C:\VMuruganAPI\sql_server_api\.env"

echo.
echo Step 4: Deploy Client Server...
copy "server\server_clean.js" "C:\VMuruganAPI\server\server.js"
copy "server\package_clean.json" "C:\VMuruganAPI\server\package.json"
echo PORT=3000 > "C:\VMuruganAPI\server\.env"
echo SQL_API_URL=http://localhost:3001 >> "C:\VMuruganAPI\server\.env"

echo.
echo Step 5: Install dependencies...
cd /d "C:\VMuruganAPI\sql_server_api"
call npm install
cd /d "C:\VMuruganAPI\server"
call npm install

echo.
echo Step 6: Start services with PM2...
cd /d "C:\VMuruganAPI\sql_server_api"
pm2 start server.js --name "vmurugan-sql-api"

cd /d "C:\VMuruganAPI\server"
pm2 start server.js --name "vmurugan-client"

pm2 save
pm2 status

echo.
echo ========================================
echo DEPLOYMENT COMPLETED!
echo ========================================
echo.
echo Services running:
echo - SQL Server API: http://localhost:3001
echo - Client Server: http://localhost:3000
echo - Admin Portal: http://localhost:3000/admin
echo.
echo External URLs (after router config):
echo - API: http://103.124.152.220:3001
echo - Client: http://103.124.152.220:3000
echo - Admin: http://103.124.152.220:3000/admin
echo.
echo Flutter App Configuration:
echo final String apiBaseUrl = 'http://103.124.152.220:3000';
echo.
pause
