@echo off
echo VMurugan SSL Setup - Debug Version
echo ==================================
echo.

echo Step 1: Checking if running as Administrator...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo SUCCESS: Running as Administrator
) else (
    echo ERROR: Not running as Administrator
    echo Please right-click this file and select "Run as administrator"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo.
echo Step 2: Testing basic commands...
echo Current directory: %CD%
echo Current user: %USERNAME%
echo.

echo Step 3: Checking internet connection...
ping -n 1 google.com
if %errorLevel% == 0 (
    echo SUCCESS: Internet connection working
) else (
    echo ERROR: No internet connection
)

echo.
echo Step 4: Checking if Chocolatey is installed...
where choco >nul 2>&1
if %errorLevel% == 0 (
    echo SUCCESS: Chocolatey is already installed
    choco --version
) else (
    echo INFO: Chocolatey not found, will install it
    echo.
    echo Installing Chocolatey... This may take a few minutes...
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& {[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))}"
    
    if %errorLevel% == 0 (
        echo SUCCESS: Chocolatey installed
        
        echo Refreshing environment...
        call refreshenv
        
        where choco >nul 2>&1
        if %errorLevel% == 0 (
            echo SUCCESS: Chocolatey is now available
        ) else (
            echo WARNING: Chocolatey installed but not in PATH yet
            echo You may need to restart this script
        )
    ) else (
        echo ERROR: Failed to install Chocolatey
        echo.
        echo Press any key to continue anyway...
        pause >nul
    )
)

echo.
echo Step 5: Checking if Certbot is installed...
where certbot >nul 2>&1
if %errorLevel% == 0 (
    echo SUCCESS: Certbot is already installed
    certbot --version
) else (
    echo INFO: Certbot not found, installing...
    
    choco install certbot -y
    
    if %errorLevel% == 0 (
        echo SUCCESS: Certbot installed
        
        echo Refreshing environment...
        call refreshenv
        
        where certbot >nul 2>&1
        if %errorLevel% == 0 (
            echo SUCCESS: Certbot is now available
            certbot --version
        ) else (
            echo WARNING: Certbot installed but not in PATH yet
        )
    ) else (
        echo ERROR: Failed to install Certbot
        echo.
        echo Press any key to continue anyway...
        pause >nul
    )
)

echo.
echo Step 6: Checking domain DNS...
echo Checking if api.vmuruganjewellery.co.in points to this server...
nslookup api.vmuruganjewellery.co.in
echo.
echo IMPORTANT: Make sure the IP address above matches your server's IP
echo If not, SSL certificate generation will fail
echo.

echo Step 7: Checking ports...
echo Checking if port 80 is free...
netstat -an | findstr ":80 " | findstr "LISTENING"
if %errorLevel% == 0 (
    echo WARNING: Port 80 is in use
    echo This may cause SSL certificate generation to fail
) else (
    echo SUCCESS: Port 80 appears to be free
)

echo.
echo Step 8: Stopping IIS if running...
net stop W3SVC /y >nul 2>&1
net stop WAS /y >nul 2>&1
echo IIS stopped (if it was running)

echo.
echo Step 9: Opening firewall ports...
netsh advfirewall firewall add rule name="HTTP-VMurugan-Debug" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
netsh advfirewall firewall add rule name="HTTPS-VMurugan-Debug" dir=in action=allow protocol=TCP localport=443 >nul 2>&1
echo Firewall rules added

echo.
echo Step 10: Ready to generate SSL certificate
echo Domain: api.vmuruganjewellery.co.in
echo Email: info@dakroot.com
echo.
echo Press any key to start SSL certificate generation...
pause >nul

echo.
echo Generating SSL certificate... This may take several minutes...
echo Command: certbot certonly --standalone --non-interactive --agree-tos --email info@dakroot.com -d api.vmuruganjewellery.co.in --verbose

certbot certonly --standalone --non-interactive --agree-tos --email info@dakroot.com -d api.vmuruganjewellery.co.in --verbose

echo.
echo Certbot exit code: %errorLevel%

if %errorLevel% == 0 (
    echo.
    echo SUCCESS: SSL certificate should be generated!
    echo.
    echo Checking for certificate files...
    
    if exist "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem" (
        echo SUCCESS: Certificate file found
        dir "C:\Certbot\live\api.vmuruganjewellery.co.in\"
    ) else (
        echo ERROR: Certificate file not found at expected location
        echo Searching for certificate files...
        dir C:\Certbot\ /s /b | findstr "vmuruganjewellery"
    )
    
    echo.
    echo Setting up auto-renewal...
    schtasks /create /tn "VMurugan SSL Auto Renewal Debug" /tr "certbot renew --quiet" /sc daily /st 02:00 /ru SYSTEM /f >nul 2>&1
    echo Auto-renewal task created
    
) else (
    echo.
    echo ERROR: SSL certificate generation failed!
    echo Exit code: %errorLevel%
    echo.
    echo This usually means:
    echo 1. Domain does not point to this server
    echo 2. Port 80 is blocked or in use
    echo 3. Firewall is blocking connections
    echo 4. Internet connectivity issues
)

echo.
echo Starting IIS back up...
net start W3SVC >nul 2>&1

echo.
echo ===================================
echo SSL Setup Debug Complete
echo ===================================
echo.
echo This window will stay open so you can see all messages.
echo Press any key to exit...
pause >nul
