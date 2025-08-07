@echo off
echo 🔄 Restarting VMurugan SQL Server API...

echo 🛑 Stopping existing Node.js processes...
taskkill /f /im node.exe 2>nul

echo ⏳ Waiting 2 seconds...
timeout /t 2 /nobreak >nul

echo 🚀 Starting SQL Server API...
cd sql_server_api
start "VMurugan API" node simple_server.js

echo ✅ API restart complete!
echo 📊 API should be running on http://192.168.29.139:3001
echo 🔗 Test at: http://192.168.29.139:3001/health

pause
