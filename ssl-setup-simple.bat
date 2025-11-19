@echo off
title VMurugan Jewellery SSL Certificate Setup
color 0A

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
    echo [OK] Running as Administrator
    echo.
) else (
    echo [ERROR] This script must be run as Administrator
    echo Right-click on this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [INFO] Checking internet connectivity...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Internet connection available
) else (
    echo [WARNING] No internet connection detected
    echo Please check your internet connection
    pause
)

echo.
echo [INFO] Checking if domain points to this server...
nslookup api.vmuruganjewellery.co.in
echo.
echo [WARNING] Make sure the domain points to THIS server's IP address
echo If not, the SSL certificate generation will fail
echo.
pause

echo [INFO] Installing Chocolatey package manager...
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if %errorLevel% == 0 (
    echo [OK] Chocolatey installed successfully
) else (
    echo [ERROR] Failed to install Chocolatey
    pause
    exit /b 1
)

echo.
echo [INFO] Installing Certbot...
choco install certbot -y

if %errorLevel% == 0 (
    echo [OK] Certbot installed successfully
) else (
    echo [ERROR] Failed to install Certbot
    pause
    exit /b 1
)

echo.
echo [INFO] Refreshing environment variables...
call refreshenv

echo.
echo [INFO] Stopping IIS temporarily...
net stop W3SVC /y >nul 2>&1
net stop WAS /y >nul 2>&1
echo [OK] IIS stopped (if it was running)

echo.
echo [INFO] Opening Windows Firewall ports 80 and 443...
netsh advfirewall firewall add rule name="HTTP-VMurugan" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
netsh advfirewall firewall add rule name="HTTPS-VMurugan" dir=in action=allow protocol=TCP localport=443 >nul 2>&1
echo [OK] Firewall ports opened

echo.
echo [INFO] Generating SSL certificate for api.vmuruganjewellery.co.in...
echo This may take a few minutes. Please wait...
echo.

certbot certonly --standalone --non-interactive --agree-tos --email info@dakroot.com -d api.vmuruganjewellery.co.in

if %errorLevel% == 0 (
    echo.
    echo [SUCCESS] SSL certificate generated successfully!
    echo.
    echo [INFO] Checking certificate files...
    
    if exist "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem" (
        echo [OK] Certificate file found: C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem
    ) else (
        echo [ERROR] Certificate file not found
    )
    
    if exist "C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem" (
        echo [OK] Private key file found: C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem
    ) else (
        echo [ERROR] Private key file not found
    )
    
    echo.
    echo [INFO] Setting up auto-renewal...
    schtasks /create /tn "VMurugan SSL Auto Renewal" /tr "certbot renew --quiet" /sc daily /st 02:00 /ru SYSTEM /f >nul 2>&1
    echo [OK] Auto-renewal task created
    
    echo.
    echo [INFO] Starting IIS...
    net start W3SVC >nul 2>&1
    echo [OK] IIS started
    
    echo.
    echo ===================================================
    echo [SUCCESS] SSL SETUP COMPLETED!
    echo ===================================================
    echo Domain: https://api.vmuruganjewellery.co.in
    echo Certificate: C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem
    echo Private Key: C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem
    echo Auto-renewal: Daily at 2:00 AM
    echo ===================================================
    echo.
    echo Your server.js will now automatically use these certificates!
    echo.
    
) else (
    echo.
    echo [ERROR] SSL certificate generation FAILED!
    echo.
    echo Common reasons:
    echo 1. Domain api.vmuruganjewellery.co.in does not point to this server
    echo 2. Port 80 is blocked or in use by another service
    echo 3. Firewall is blocking incoming connections
    echo 4. Internet connectivity issues
    echo.
    echo [INFO] Starting IIS back up...
    net start W3SVC >nul 2>&1
    echo.
    echo Please check the issues above and try again.
)

echo.
echo Press any key to exit...
pause >nul
