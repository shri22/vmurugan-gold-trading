# Windows SSL Certificate Setup Script for VMurugan Jewellery
# Run as Administrator in PowerShell

param(
    [string]$Domain = "api.vmuruganjewellery.co.in",
    [string]$Email = "info@dakroot.com"
)

Write-Host "Setting up SSL certificate for VMurugan Jewellery API: $Domain" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not present
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install Certbot via Chocolatey
Write-Host "Installing Certbot..." -ForegroundColor Yellow
choco install certbot -y

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Stop IIS if running
Write-Host "Stopping IIS..." -ForegroundColor Yellow
try {
    Stop-Service W3SVC -Force -ErrorAction SilentlyContinue
    Stop-Service WAS -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "IIS not running or not installed" -ForegroundColor Gray
}

# Generate SSL certificate using standalone mode
Write-Host "Generating SSL certificate for $Domain..." -ForegroundColor Yellow
$certbotArgs = @(
    "certonly",
    "--standalone",
    "--non-interactive",
    "--agree-tos",
    "--email", $Email,
    "-d", $Domain,
    "-d", "www.$Domain"
)

& certbot @certbotArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "SSL certificate generated successfully!" -ForegroundColor Green
    
    # Certificate paths
    $certPath = "C:\Certbot\live\$Domain\fullchain.pem"
    $keyPath = "C:\Certbot\live\$Domain\privkey.pem"
    
    Write-Host "Certificate files created at:" -ForegroundColor Green
    Write-Host "Certificate: $certPath" -ForegroundColor Cyan
    Write-Host "Private Key: $keyPath" -ForegroundColor Cyan
    
    # Convert PEM to PFX for Windows/IIS
    $pfxPath = "C:\Certbot\live\$Domain\certificate.pfx"
    $pfxPassword = "VMurugan123!"
    
    Write-Host "Converting to PFX format for Windows..." -ForegroundColor Yellow
    
    # Install OpenSSL via Chocolatey if not present
    if (!(Get-Command openssl -ErrorAction SilentlyContinue)) {
        choco install openssl -y
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    # Convert to PFX
    & openssl pkcs12 -export -out $pfxPath -inkey $keyPath -in $certPath -password "pass:$pfxPassword"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PFX certificate created: $pfxPath" -ForegroundColor Green
        Write-Host "PFX Password: $pfxPassword" -ForegroundColor Cyan
        
        # Import certificate to Windows Certificate Store
        Write-Host "Importing certificate to Windows Certificate Store..." -ForegroundColor Yellow
        $securePwd = ConvertTo-SecureString -String $pfxPassword -Force -AsPlainText
        Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\My -Password $securePwd
        
        Write-Host "Certificate imported successfully!" -ForegroundColor Green
    }
    
    # Create IIS binding if IIS is available
    if (Get-WindowsFeature -Name IIS-WebServerRole -ErrorAction SilentlyContinue) {
        Write-Host "Configuring IIS SSL binding..." -ForegroundColor Yellow
        
        # Import WebAdministration module
        Import-Module WebAdministration -ErrorAction SilentlyContinue
        
        # Get the certificate thumbprint
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$Domain*"} | Select-Object -First 1
        
        if ($cert) {
            # Remove existing bindings
            Remove-WebBinding -Name "Default Web Site" -Protocol https -ErrorAction SilentlyContinue
            
            # Add HTTPS binding
            New-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -HostHeader $Domain
            
            # Associate certificate with binding
            $binding = Get-WebBinding -Name "Default Web Site" -Protocol https
            $binding.AddSslCertificate($cert.Thumbprint, "my")
            
            Write-Host "IIS HTTPS binding configured!" -ForegroundColor Green
        }
    }
    
    # Setup auto-renewal task
    Write-Host "Setting up auto-renewal task..." -ForegroundColor Yellow
    
    $action = New-ScheduledTaskAction -Execute "certbot" -Argument "renew --quiet"
    $trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
    $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName "Certbot Auto Renewal" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    
    Write-Host "✅ SSL setup completed successfully!" -ForegroundColor Green
    Write-Host "Your website is now available at: https://$Domain" -ForegroundColor Cyan
    Write-Host "Certificate will auto-renew daily at 2:00 AM" -ForegroundColor Cyan
    
    # Start IIS back up
    try {
        Start-Service W3SVC -ErrorAction SilentlyContinue
        Write-Host "IIS started successfully" -ForegroundColor Green
    } catch {
        Write-Host "Could not start IIS. Please start it manually if needed." -ForegroundColor Yellow
    }
    
} else {
    Write-Host "❌ Failed to generate SSL certificate." -ForegroundColor Red
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "1. Domain $Domain points to this server's IP" -ForegroundColor Yellow
    Write-Host "2. Ports 80 and 443 are open in Windows Firewall" -ForegroundColor Yellow
    Write-Host "3. No other service is using port 80" -ForegroundColor Yellow
}
