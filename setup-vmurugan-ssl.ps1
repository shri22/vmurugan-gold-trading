# VMurugan Jewellery SSL Certificate Setup
# Run as Administrator in PowerShell
# Domain: api.vmuruganjewellery.co.in
# Email: info@dakroot.com

Write-Host "=== VMurugan Jewellery SSL Certificate Setup ===" -ForegroundColor Cyan
Write-Host "Domain: api.vmuruganjewellery.co.in" -ForegroundColor Green
Write-Host "Email: info@dakroot.com" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan

$Domain = "api.vmuruganjewellery.co.in"
$Email = "info@dakroot.com"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Setting up SSL certificate for: $Domain" -ForegroundColor Yellow

# Install Chocolatey if not present
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
}

# Install Certbot via Chocolatey
Write-Host "Installing Certbot..." -ForegroundColor Yellow
choco install certbot -y

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Stop IIS if running
Write-Host "Stopping IIS temporarily..." -ForegroundColor Yellow
try {
    Stop-Service W3SVC -Force -ErrorAction SilentlyContinue
    Stop-Service WAS -Force -ErrorAction SilentlyContinue
    Write-Host "IIS stopped successfully" -ForegroundColor Green
} catch {
    Write-Host "IIS not running or not installed" -ForegroundColor Gray
}

# Open Windows Firewall ports
Write-Host "Opening Windows Firewall ports 80 and 443..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "HTTP-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "HTTPS-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "Firewall ports opened successfully" -ForegroundColor Green
} catch {
    Write-Host "Could not configure firewall. Please check manually." -ForegroundColor Yellow
}

# Generate SSL certificate using standalone mode
Write-Host "Generating SSL certificate for $Domain..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

$certbotArgs = @(
    "certonly",
    "--standalone",
    "--non-interactive",
    "--agree-tos",
    "--email", $Email,
    "-d", $Domain
)

& certbot @certbotArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SSL certificate generated successfully!" -ForegroundColor Green
    
    # Certificate paths
    $certPath = "C:\Certbot\live\$Domain\fullchain.pem"
    $keyPath = "C:\Certbot\live\$Domain\privkey.pem"
    
    Write-Host "Certificate files created at:" -ForegroundColor Green
    Write-Host "Certificate: $certPath" -ForegroundColor Cyan
    Write-Host "Private Key: $keyPath" -ForegroundColor Cyan
    
    # Convert PEM to PFX for Windows/IIS
    $pfxPath = "C:\Certbot\live\$Domain\certificate.pfx"
    $pfxPassword = "VMurugan2024!"
    
    Write-Host "Converting to PFX format for Windows..." -ForegroundColor Yellow
    
    # Install OpenSSL via Chocolatey if not present
    if (!(Get-Command openssl -ErrorAction SilentlyContinue)) {
        Write-Host "Installing OpenSSL..." -ForegroundColor Yellow
        choco install openssl -y
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    # Convert to PFX
    & openssl pkcs12 -export -out $pfxPath -inkey $keyPath -in $certPath -password "pass:$pfxPassword"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PFX certificate created: $pfxPath" -ForegroundColor Green
        Write-Host "PFX Password: $pfxPassword" -ForegroundColor Cyan
        
        # Import certificate to Windows Certificate Store
        Write-Host "Importing certificate to Windows Certificate Store..." -ForegroundColor Yellow
        $securePwd = ConvertTo-SecureString -String $pfxPassword -Force -AsPlainText
        Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\My -Password $securePwd
        
        Write-Host "✅ Certificate imported successfully!" -ForegroundColor Green
    }
    
    # Setup auto-renewal task
    Write-Host "Setting up auto-renewal task..." -ForegroundColor Yellow
    
    $action = New-ScheduledTaskAction -Execute "certbot" -Argument "renew --quiet"
    $trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
    $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "VMurugan SSL Auto Renewal" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    
    Write-Host "✅ Auto-renewal task created successfully!" -ForegroundColor Green
    
    # Start IIS back up
    try {
        Start-Service W3SVC -ErrorAction SilentlyContinue
        Write-Host "✅ IIS started successfully" -ForegroundColor Green
    } catch {
        Write-Host "Could not start IIS. Please start it manually if needed." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "🎉 SSL SETUP COMPLETED SUCCESSFULLY! 🎉" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Domain: https://$Domain" -ForegroundColor Cyan
    Write-Host "Certificate Location: $pfxPath" -ForegroundColor Cyan
    Write-Host "Certificate Password: $pfxPassword" -ForegroundColor Cyan
    Write-Host "Auto-renewal: Daily at 2:00 AM" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    # Test the certificate
    Write-Host "Testing SSL certificate..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "https://$Domain" -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ SSL certificate is working correctly!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  SSL test failed. Please check your server configuration." -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ Failed to generate SSL certificate." -ForegroundColor Red
    Write-Host "Please check the following:" -ForegroundColor Yellow
    Write-Host "1. Domain $Domain points to this server's IP address" -ForegroundColor Yellow
    Write-Host "2. Ports 80 and 443 are accessible from the internet" -ForegroundColor Yellow
    Write-Host "3. No other service is using port 80" -ForegroundColor Yellow
    Write-Host "4. Windows Firewall allows incoming connections on ports 80 and 443" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
