@echo off
echo ===================================================
echo VMurugan Jewellery SSL Certificate Setup
echo Domain: api.vmuruganjewellery.co.in
echo Email: info@dakroot.com
echo ===================================================
echo.
echo This will install a FREE SSL certificate from Let's Encrypt
echo.
pause

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator - Good!
    echo.
) else (
    echo ERROR: This script must be run as Administrator
    echo Right-click on this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Choose which script to run:
echo 1. Debug SSL Setup (shows detailed output)
echo 2. Regular SSL Setup
echo.
set /p choice="Enter your choice (1 or 2): "

if "%choice%"=="1" (
    echo Running debug SSL setup...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0debug-ssl-setup.ps1"
) else (
    echo Running regular SSL setup...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup-vmurugan-ssl.ps1"
)

echo.
echo Setup completed. Check the output above for results.
echo.
pause
