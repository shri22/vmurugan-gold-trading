@echo off
echo VMurugan SSL Setup - Windows Native Version
echo ===========================================
echo.

echo Step 1: Checking Administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo SUCCESS: Running as Administrator
) else (
    echo ERROR: Not running as Administrator
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo Step 2: Creating SSL certificate directory...
if not exist "C:\VMurugan-SSL" (
    mkdir "C:\VMurugan-SSL"
    echo SUCCESS: Created directory C:\VMurugan-SSL
) else (
    echo INFO: Directory C:\VMurugan-SSL already exists
)

echo.
echo Step 3: Downloading Certbot directly...
echo This will download Certbot without using Chocolatey...

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://dl.eff.org/certbot-auto' -OutFile 'C:\VMurugan-SSL\certbot-auto'}"

if %errorLevel% == 0 (
    echo SUCCESS: Certbot downloaded
) else (
    echo ERROR: Failed to download Certbot
    echo Trying alternative method...
    
    echo Downloading Certbot Windows installer...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/certbot/certbot/releases/latest/download/certbot-beta-installer-win32.exe' -OutFile 'C:\VMurugan-SSL\certbot-installer.exe'}"
    
    if %errorLevel% == 0 (
        echo SUCCESS: Certbot installer downloaded
        echo Installing Certbot...
        "C:\VMurugan-SSL\certbot-installer.exe" /S
        
        echo Waiting for installation to complete...
        timeout /t 30 /nobreak >nul
        
        if exist "C:\Program Files (x86)\Certbot\bin\certbot.exe" (
            echo SUCCESS: Certbot installed
            set "CERTBOT_PATH=C:\Program Files (x86)\Certbot\bin\certbot.exe"
        ) else (
            echo ERROR: Certbot installation failed
            goto :manual_ssl
        )
    ) else (
        echo ERROR: Could not download Certbot installer
        goto :manual_ssl
    )
)

echo.
echo Step 4: Checking domain DNS...
echo Checking if api.vmuruganjewellery.co.in points to this server...
nslookup api.vmuruganjewellery.co.in
echo.
echo IMPORTANT: Verify the IP address above matches your server's IP
echo.
pause

echo.
echo Step 5: Stopping IIS and other services on port 80...
net stop W3SVC /y >nul 2>&1
net stop WAS /y >nul 2>&1
net stop "World Wide Web Publishing Service" /y >nul 2>&1

echo Checking if port 80 is free...
netstat -an | findstr ":80 " | findstr "LISTENING"
if %errorLevel% == 0 (
    echo WARNING: Port 80 is still in use
    echo Attempting to find and stop the process...
    
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":80 " ^| findstr "LISTENING"') do (
        echo Stopping process ID: %%a
        taskkill /PID %%a /F >nul 2>&1
    )
) else (
    echo SUCCESS: Port 80 is free
)

echo.
echo Step 6: Opening Windows Firewall...
netsh advfirewall firewall add rule name="HTTP-VMurugan" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
netsh advfirewall firewall add rule name="HTTPS-VMurugan" dir=in action=allow protocol=TCP localport=443 >nul 2>&1
echo Firewall rules added

echo.
echo Step 7: Generating SSL certificate...
echo Domain: api.vmuruganjewellery.co.in
echo Email: info@dakroot.com
echo.
echo This may take several minutes...

if defined CERTBOT_PATH (
    "%CERTBOT_PATH%" certonly --standalone --non-interactive --agree-tos --email info@dakroot.com -d api.vmuruganjewellery.co.in
) else (
    echo ERROR: Certbot not available
    goto :manual_ssl
)

echo.
echo Certbot exit code: %errorLevel%

if %errorLevel% == 0 (
    echo.
    echo SUCCESS: SSL certificate generated!
    echo.
    echo Checking for certificate files...
    
    if exist "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem" (
        echo SUCCESS: Certificate found at C:\Certbot\live\api.vmuruganjewellery.co.in\
        dir "C:\Certbot\live\api.vmuruganjewellery.co.in\"
        
        echo.
        echo Copying certificates to VMurugan-SSL directory...
        copy "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem" "C:\VMurugan-SSL\"
        copy "C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem" "C:\VMurugan-SSL\"
        
        echo.
        echo SUCCESS: SSL certificates are ready!
        echo Certificate: C:\VMurugan-SSL\fullchain.pem
        echo Private Key: C:\VMurugan-SSL\privkey.pem
        echo.
        echo Your server.js needs to be updated to use these paths.
        
    ) else (
        echo Searching for certificates in other locations...
        dir C:\ /s /b 2>nul | findstr "fullchain.pem" | findstr "vmuruganjewellery"
    )
    
    goto :end
    
) else (
    echo.
    echo ERROR: SSL certificate generation failed!
    echo This usually means the domain does not point to this server.
    goto :manual_ssl
)

:manual_ssl
echo.
echo ==========================================
echo Creating Self-Signed Certificate Instead
echo ==========================================
echo.
echo Since Let's Encrypt failed, creating a self-signed certificate for testing...

powershell -Command "& {$cert = New-SelfSignedCertificate -DnsName 'api.vmuruganjewellery.co.in' -CertStoreLocation 'cert:\LocalMachine\My' -KeyAlgorithm RSA -KeyLength 2048 -Provider 'Microsoft RSA SChannel Cryptographic Provider' -KeyExportPolicy Exportable -KeyUsage DigitalSignature,KeyEncipherment -Type SSLServerAuthentication -ValidityPeriod Years -ValidityPeriodUnits 2; $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert); $certPem = '-----BEGIN CERTIFICATE-----' + [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks) + '-----END CERTIFICATE-----'; $certPem | Out-File -FilePath 'C:\VMurugan-SSL\fullchain.pem' -Encoding ASCII; Write-Host 'Self-signed certificate created at C:\VMurugan-SSL\fullchain.pem'}"

if %errorLevel% == 0 (
    echo SUCCESS: Self-signed certificate created
    echo.
    echo WARNING: This is a self-signed certificate
    echo Browsers will show security warnings
    echo For production, you need a proper SSL certificate
    echo.
    echo Certificate: C:\VMurugan-SSL\fullchain.pem
    echo Note: Private key is in Windows Certificate Store
) else (
    echo ERROR: Failed to create self-signed certificate
)

:end
echo.
echo Starting IIS back up...
net start W3SVC >nul 2>&1

echo.
echo ==========================================
echo SSL Setup Complete
echo ==========================================
echo.
echo Certificate files location: C:\VMurugan-SSL\
echo.
echo Next steps:
echo 1. Update your server.js to use the certificate files
echo 2. Restart your Node.js server
echo 3. Test HTTPS access
echo.
echo This window will stay open. Press any key to exit...
pause >nul
