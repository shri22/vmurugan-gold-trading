# VMurugan SSL Certificate Setup - PowerShell Version
# Run this as Administrator

Write-Host "VMurugan SSL Certificate Setup" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "SUCCESS: Running as Administrator" -ForegroundColor Green
Write-Host ""

# Create SSL directory
$sslDir = "C:\VMurugan-SSL"
if (!(Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force
    Write-Host "Created directory: $sslDir" -ForegroundColor Green
}

# Check domain DNS
Write-Host "Checking domain DNS resolution..." -ForegroundColor Yellow
try {
    $dnsResult = Resolve-DnsName -Name "api.vmuruganjewellery.co.in" -ErrorAction Stop
    Write-Host "Domain resolves to: $($dnsResult.IPAddress)" -ForegroundColor Green
    
    # Get local IP
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1" -and $_.PrefixOrigin -eq "Manual"}).IPAddress
    Write-Host "Server IP: $localIP" -ForegroundColor Cyan
    
    if ($dnsResult.IPAddress -contains $localIP) {
        Write-Host "SUCCESS: Domain points to this server!" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Domain does not point to this server" -ForegroundColor Yellow
        Write-Host "SSL certificate generation may fail" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not resolve domain" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to continue"

# Stop IIS
Write-Host "Stopping IIS..." -ForegroundColor Yellow
try {
    Stop-Service W3SVC -Force -ErrorAction SilentlyContinue
    Stop-Service WAS -Force -ErrorAction SilentlyContinue
    Write-Host "IIS stopped" -ForegroundColor Green
} catch {
    Write-Host "IIS not running or not installed" -ForegroundColor Gray
}

# Open firewall ports
Write-Host "Opening firewall ports..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "HTTP-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "HTTPS-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "Firewall ports opened" -ForegroundColor Green
} catch {
    Write-Host "Could not configure firewall" -ForegroundColor Yellow
}

# Try to install Certbot using winget (Windows Package Manager)
Write-Host "Checking for Certbot..." -ForegroundColor Yellow
if (Get-Command certbot -ErrorAction SilentlyContinue) {
    Write-Host "Certbot is already installed" -ForegroundColor Green
} else {
    Write-Host "Installing Certbot using winget..." -ForegroundColor Yellow
    try {
        winget install certbot
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Certbot installed successfully" -ForegroundColor Green
        } else {
            throw "Winget installation failed"
        }
    } catch {
        Write-Host "Winget installation failed, trying direct download..." -ForegroundColor Yellow
        
        # Download Certbot installer
        $installerPath = "$sslDir\certbot-installer.exe"
        try {
            Invoke-WebRequest -Uri "https://github.com/certbot/certbot/releases/latest/download/certbot-beta-installer-win32.exe" -OutFile $installerPath
            Write-Host "Downloaded Certbot installer" -ForegroundColor Green
            
            # Run installer silently
            Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
            Write-Host "Certbot installation completed" -ForegroundColor Green
            
            # Add to PATH
            $env:Path += ";C:\Program Files (x86)\Certbot\bin"
            
        } catch {
            Write-Host "Failed to download/install Certbot" -ForegroundColor Red
            Write-Host "Will create self-signed certificate instead" -ForegroundColor Yellow
        }
    }
}

# Generate SSL certificate
Write-Host ""
Write-Host "Generating SSL certificate..." -ForegroundColor Yellow
Write-Host "Domain: api.vmuruganjewellery.co.in" -ForegroundColor Cyan
Write-Host "Email: info@dakroot.com" -ForegroundColor Cyan
Write-Host ""

if (Get-Command certbot -ErrorAction SilentlyContinue) {
    # Try Let's Encrypt
    Write-Host "Using Let's Encrypt..." -ForegroundColor Yellow
    
    $certbotArgs = @(
        "certonly",
        "--standalone",
        "--non-interactive",
        "--agree-tos",
        "--email", "info@dakroot.com",
        "-d", "api.vmuruganjewellery.co.in"
    )
    
    & certbot @certbotArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Let's Encrypt certificate generated!" -ForegroundColor Green
        
        # Check for certificate files
        $certPath = "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem"
        $keyPath = "C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem"
        
        if (Test-Path $certPath) {
            Write-Host "Certificate: $certPath" -ForegroundColor Green
            Copy-Item $certPath "$sslDir\fullchain.pem"
        }
        
        if (Test-Path $keyPath) {
            Write-Host "Private Key: $keyPath" -ForegroundColor Green
            Copy-Item $keyPath "$sslDir\privkey.pem"
        }
        
        Write-Host "Certificates copied to: $sslDir" -ForegroundColor Green
        
    } else {
        Write-Host "Let's Encrypt failed, creating self-signed certificate..." -ForegroundColor Yellow
        & {
            $cert = New-SelfSignedCertificate -DnsName "api.vmuruganjewellery.co.in" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -Provider "Microsoft RSA SChannel Cryptographic Provider" -KeyExportPolicy Exportable -KeyUsage DigitalSignature,KeyEncipherment -Type SSLServerAuthentication -ValidityPeriod Years -ValidityPeriodUnits 2
            
            # Export certificate
            $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            $certPem = "-----BEGIN CERTIFICATE-----`n" + [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks) + "`n-----END CERTIFICATE-----"
            $certPem | Out-File -FilePath "$sslDir\fullchain.pem" -Encoding ASCII
            
            Write-Host "Self-signed certificate created: $sslDir\fullchain.pem" -ForegroundColor Green
            Write-Host "WARNING: This is self-signed - browsers will show warnings" -ForegroundColor Yellow
        }
    }
} else {
    # Create self-signed certificate
    Write-Host "Creating self-signed certificate..." -ForegroundColor Yellow
    
    $cert = New-SelfSignedCertificate -DnsName "api.vmuruganjewellery.co.in" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -Provider "Microsoft RSA SChannel Cryptographic Provider" -KeyExportPolicy Exportable -KeyUsage DigitalSignature,KeyEncipherment -Type SSLServerAuthentication -ValidityPeriod Years -ValidityPeriodUnits 2
    
    # Export certificate
    $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $certPem = "-----BEGIN CERTIFICATE-----`n" + [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks) + "`n-----END CERTIFICATE-----"
    $certPem | Out-File -FilePath "$sslDir\fullchain.pem" -Encoding ASCII
    
    Write-Host "Self-signed certificate created: $sslDir\fullchain.pem" -ForegroundColor Green
    Write-Host "WARNING: This is self-signed - browsers will show warnings" -ForegroundColor Yellow
}

# Start IIS back up
Write-Host ""
Write-Host "Starting IIS..." -ForegroundColor Yellow
try {
    Start-Service W3SVC -ErrorAction SilentlyContinue
    Write-Host "IIS started" -ForegroundColor Green
} catch {
    Write-Host "Could not start IIS" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "SSL Setup Complete!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Certificate files are in: $sslDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update your server.js to use these certificate paths" -ForegroundColor White
Write-Host "2. Restart your Node.js server" -ForegroundColor White
Write-Host "3. Test HTTPS access" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
