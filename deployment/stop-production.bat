@echo off
echo ========================================
echo   VMurugan Gold Trading API Server
echo   Stopping Production Services...
echo ========================================

echo Stopping all PM2 services...
pm2 stop all

echo.
echo Services stopped. Current status:
pm2 status

echo.
echo ========================================
echo   All Services Stopped
echo ========================================
echo.
echo To start services again: run start-production.bat
echo.
pause
