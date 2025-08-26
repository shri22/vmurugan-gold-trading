# VMurugan Gold Trading API - Windows Server Deployment Script
# Run this script as Administrator on your Windows Server

Write-Host "🚀 Starting VMurugan API Deployment on Windows Server..." -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Install Chocolatey (Windows package manager)
Write-Host "📦 Installing Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Node.js
Write-Host "📦 Installing Node.js..." -ForegroundColor Cyan
choco install nodejs -y

# Install PM2 globally
Write-Host "📦 Installing PM2..." -ForegroundColor Cyan
npm install -g pm2
npm install -g pm2-windows-startup

# Setup PM2 Windows service
Write-Host "🔧 Setting up PM2 Windows service..." -ForegroundColor Cyan
pm2-startup install

# Create application directory
$AppPath = "C:\VMuruganAPI"
Write-Host "📁 Creating application directory: $AppPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $AppPath
New-Item -ItemType Directory -Force -Path "$AppPath\sql_server_api"
New-Item -ItemType Directory -Force -Path "$AppPath\server"
New-Item -ItemType Directory -Force -Path "$AppPath\logs"

# Copy application files (you'll need to copy your files here)
Write-Host "📋 Application files should be copied to:" -ForegroundColor Yellow
Write-Host "   SQL Server API: $AppPath\sql_server_api" -ForegroundColor Yellow
Write-Host "   Main Server: $AppPath\server" -ForegroundColor Yellow

# Create production environment files
Write-Host "⚙️ Creating production environment files..." -ForegroundColor Cyan

# Get current server IP for SQL Server configuration
$CurrentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"} | Select-Object -First 1).IPAddress
if (-not $CurrentIP) {
    $CurrentIP = "localhost"
}

Write-Host "🗄️ SQL Server Configuration Options:" -ForegroundColor Cyan
Write-Host "1. Use existing SQL Server on this machine (localhost)" -ForegroundColor White
Write-Host "2. Use existing SQL Server on network ($CurrentIP)" -ForegroundColor White
Write-Host "3. Use remote SQL Server (enter custom IP)" -ForegroundColor White
$SqlChoice = Read-Host "Choose option (1-3)"

switch ($SqlChoice) {
    "1" { $SqlServerIP = "localhost" }
    "2" { $SqlServerIP = $CurrentIP }
    "3" { $SqlServerIP = Read-Host "Enter SQL Server IP address" }
    default { $SqlServerIP = "localhost" }
}

Write-Host "Using SQL Server: $SqlServerIP" -ForegroundColor Green

# Test SQL Server connection
Write-Host "🔍 Testing SQL Server connection..." -ForegroundColor Cyan
try {
    $testConnection = sqlcmd -S "$SqlServerIP,1433" -U "DakData" -P "Test@123" -Q "SELECT @@VERSION" -h -1
    if ($testConnection) {
        Write-Host "✅ SQL Server connection successful!" -ForegroundColor Green
        Write-Host "Database: VMuruganGoldTrading" -ForegroundColor White
        Write-Host "User: DakData" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️ Could not test SQL Server connection automatically" -ForegroundColor Yellow
    Write-Host "Please ensure SQL Server is running and accessible" -ForegroundColor Yellow
}

# SQL Server API .env
$SqlApiEnv = @"
# VMurugan SQL Server API - Production Configuration
PORT=3001
NODE_ENV=production
HOST=0.0.0.0

# SQL Server Configuration
# Using your existing SQL Server setup
SQL_SERVER=$SqlServerIP
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=DakData
SQL_PASSWORD=Test@123
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true
SQL_CONNECTION_TIMEOUT=30000
SQL_REQUEST_TIMEOUT=30000

# Security Configuration
ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_production_jwt_secret_2025_secure_key

# CORS Configuration (Allow all origins for now)
ALLOWED_ORIGINS=*

# Business Configuration
BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMurugan Gold Trading

# Logging
LOG_LEVEL=info
LOG_FILE=C:\VMuruganAPI\logs\sql-api.log
"@

$SqlApiEnv | Out-File -FilePath "$AppPath\sql_server_api\.env" -Encoding UTF8

# Main Server .env
$MainServerEnv = @"
# VMurugan Main Server - Production Configuration
PORT=3000
NODE_ENV=production
HOST=0.0.0.0

# Security Configuration
ADMIN_TOKEN=VMURUGAN_MAIN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_main_production_jwt_secret_2025

# CORS Configuration
ALLOWED_ORIGINS=*

# Logging
LOG_LEVEL=info
LOG_FILE=C:\VMuruganAPI\logs\main-server.log
"@

$MainServerEnv | Out-File -FilePath "$AppPath\server\.env" -Encoding UTF8

# Configure Windows Firewall
Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Cyan
New-NetFirewallRule -DisplayName "VMurugan SQL API" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow
New-NetFirewallRule -DisplayName "VMurugan Main API" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# Create startup scripts
Write-Host "🚀 Creating startup scripts..." -ForegroundColor Cyan

$StartScript = @"
@echo off
echo Starting VMurugan APIs...
cd /d C:\VMuruganAPI\sql_server_api
call npm install
pm2 start server.js --name "vmurugan-sql-api"

cd /d C:\VMuruganAPI\server
call npm install
pm2 start server.js --name "vmurugan-main-api"

pm2 save
echo VMurugan APIs started successfully!
pause
"@

$StartScript | Out-File -FilePath "$AppPath\start-apis.bat" -Encoding ASCII

$StopScript = @"
@echo off
echo Stopping VMurugan APIs...
pm2 stop all
echo VMurugan APIs stopped!
pause
"@

$StopScript | Out-File -FilePath "$AppPath\stop-apis.bat" -Encoding ASCII

# Create IIS configuration (optional)
Write-Host "🌐 Setting up IIS reverse proxy (optional)..." -ForegroundColor Cyan
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpLogging, IIS-RequestFiltering, IIS-StaticContent, IIS-DefaultDocument -All

# Install URL Rewrite module for IIS (for reverse proxy)
Write-Host "📦 Installing IIS URL Rewrite module..." -ForegroundColor Cyan
$urlRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$urlRewritePath = "$env:TEMP\urlrewrite.msi"
Invoke-WebRequest -Uri $urlRewriteUrl -OutFile $urlRewritePath
Start-Process msiexec.exe -ArgumentList "/i $urlRewritePath /quiet" -Wait

# Create web.config for IIS reverse proxy
$WebConfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="SQL API" stopProcessing="true">
                    <match url="^api/(.*)" />
                    <action type="Rewrite" url="http://localhost:3001/api/{R:1}" />
                </rule>
                <rule name="Main API" stopProcessing="true">
                    <match url="^(.*)" />
                    <action type="Rewrite" url="http://localhost:3000/{R:1}" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
"@

$WebConfig | Out-File -FilePath "C:\inetpub\wwwroot\web.config" -Encoding UTF8

Write-Host "✅ Windows Server deployment setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy your application files to C:\VMuruganAPI\" -ForegroundColor White
Write-Host "2. Update SQL Server connection in C:\VMuruganAPI\sql_server_api\.env" -ForegroundColor White
Write-Host "3. Run C:\VMuruganAPI\start-apis.bat to start the services" -ForegroundColor White
Write-Host "4. Test APIs at http://YOUR_PUBLIC_IP:3001/api/ and http://YOUR_PUBLIC_IP:3000/" -ForegroundColor White
Write-Host "5. Configure your domain/DNS to point to this server" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Your APIs will be accessible at:" -ForegroundColor Cyan
Write-Host "   SQL Server API: http://YOUR_PUBLIC_IP:3001/api/" -ForegroundColor White
Write-Host "   Main Server: http://YOUR_PUBLIC_IP:3000/" -ForegroundColor White
Write-Host "   Via IIS (port 80): http://YOUR_PUBLIC_IP/api/" -ForegroundColor White
