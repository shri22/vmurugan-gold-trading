# VMurugan Gold Trading API - Windows Server Deployment Script (Fixed)
# Run this script as Administrator on your Windows Server

Write-Host "🚀 Starting VMurugan API Deployment on Windows Server..." -ForegroundColor Green

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-NOT $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Install Chocolatey (Windows package manager)
Write-Host "📦 Installing Chocolatey..." -ForegroundColor Cyan
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "✅ Chocolatey installed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Chocolatey installation failed, continuing..." -ForegroundColor Yellow
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Node.js
Write-Host "📦 Installing Node.js..." -ForegroundColor Cyan
try {
    choco install nodejs -y
    Write-Host "✅ Node.js installed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Please install Node.js manually from nodejs.org" -ForegroundColor Yellow
}

# Install PM2 globally
Write-Host "📦 Installing PM2..." -ForegroundColor Cyan
try {
    npm install -g pm2
    npm install -g pm2-windows-startup
    pm2-startup install
    Write-Host "✅ PM2 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ PM2 installation failed" -ForegroundColor Yellow
}

# Create application directory
$AppPath = "C:\VMuruganAPI"
Write-Host "📁 Creating application directory: $AppPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $AppPath | Out-Null
New-Item -ItemType Directory -Force -Path "$AppPath\sql_server_api" | Out-Null
New-Item -ItemType Directory -Force -Path "$AppPath\server" | Out-Null
New-Item -ItemType Directory -Force -Path "$AppPath\logs" | Out-Null

Write-Host "📋 Application directories created:" -ForegroundColor Yellow
Write-Host "   SQL Server API: $AppPath\sql_server_api" -ForegroundColor White
Write-Host "   Main Server: $AppPath\server" -ForegroundColor White
Write-Host "   Logs: $AppPath\logs" -ForegroundColor White

# Get current server IP for SQL Server configuration
$CurrentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"} | Select-Object -First 1).IPAddress
if (-not $CurrentIP) {
    $CurrentIP = "localhost"
}

Write-Host "🗄️ SQL Server Configuration Options:" -ForegroundColor Cyan
Write-Host "1. Use SQL Server on this machine (localhost)" -ForegroundColor White
Write-Host "2. Use SQL Server on network ($CurrentIP)" -ForegroundColor White
Write-Host "3. Use existing SQL Server (192.168.1.18)" -ForegroundColor White
Write-Host "4. Enter custom SQL Server IP" -ForegroundColor White
$SqlChoice = Read-Host "Choose option (1-4)"

switch ($SqlChoice) {
    "1" { $SqlServerIP = "localhost" }
    "2" { $SqlServerIP = $CurrentIP }
    "3" { $SqlServerIP = "192.168.1.18" }
    "4" { $SqlServerIP = Read-Host "Enter SQL Server IP address" }
    default { $SqlServerIP = "192.168.1.18" }
}

Write-Host "Using SQL Server: $SqlServerIP" -ForegroundColor Green

# Test SQL Server connection
Write-Host "🔍 Testing SQL Server connection..." -ForegroundColor Cyan
try {
    $testConnection = sqlcmd -S "$SqlServerIP,1433" -U "DakData" -P "Test@123" -Q "SELECT @@VERSION" -h -1 2>$null
    if ($testConnection) {
        Write-Host "✅ SQL Server connection successful!" -ForegroundColor Green
        Write-Host "Database: VMuruganGoldTrading" -ForegroundColor White
        Write-Host "User: DakData" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️ Could not test SQL Server connection automatically" -ForegroundColor Yellow
    Write-Host "Please ensure SQL Server is running and accessible" -ForegroundColor Yellow
}

# Create production environment files
Write-Host "⚙️ Creating production environment files..." -ForegroundColor Cyan

# SQL Server API .env
$SqlApiEnvContent = @"
# VMurugan SQL Server API - Production Configuration
PORT=3001
NODE_ENV=production
HOST=0.0.0.0

# SQL Server Configuration
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

$SqlApiEnvContent | Out-File -FilePath "$AppPath\sql_server_api\.env" -Encoding UTF8

# Main Server .env
$MainServerEnvContent = @"
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

$MainServerEnvContent | Out-File -FilePath "$AppPath\server\.env" -Encoding UTF8

# Configure Windows Firewall
Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Cyan
try {
    New-NetFirewallRule -DisplayName "VMurugan SQL API" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "VMurugan Main API" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "✅ Firewall rules configured" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not configure firewall automatically" -ForegroundColor Yellow
}

# Create startup scripts
Write-Host "🚀 Creating startup scripts..." -ForegroundColor Cyan

$StartScriptContent = @'
@echo off
echo ========================================
echo   VMurugan Gold Trading API Server
echo   Starting Production Services...
echo ========================================

echo Starting SQL Server API...
cd /d C:\VMuruganAPI\sql_server_api
call npm install --production
pm2 start server.js --name "vmurugan-sql-api"

echo Starting Main Server...
cd /d C:\VMuruganAPI\server
call npm install --production
pm2 start server.js --name "vmurugan-main-api"

pm2 save
echo VMurugan APIs started successfully!
echo.
echo APIs accessible at:
echo SQL Server API: http://localhost:3001/api/
echo Main Server: http://localhost:3000/
echo.
pause
'@

$StartScriptContent | Out-File -FilePath "$AppPath\start-apis.bat" -Encoding ASCII

$StopScriptContent = @'
@echo off
echo Stopping VMurugan APIs...
pm2 stop all
echo VMurugan APIs stopped!
pause
'@

$StopScriptContent | Out-File -FilePath "$AppPath\stop-apis.bat" -Encoding ASCII

Write-Host "✅ Windows Server deployment setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy your application files to $AppPath" -ForegroundColor White
Write-Host "2. Run $AppPath\start-apis.bat to start the services" -ForegroundColor White
Write-Host "3. Test APIs at http://localhost:3001/api/ and http://localhost:3000/" -ForegroundColor White
Write-Host "4. Update Flutter app with your public IP" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Your APIs will be accessible at:" -ForegroundColor Cyan
Write-Host "   SQL Server API: http://YOUR_PUBLIC_IP:3001/api/" -ForegroundColor White
Write-Host "   Main Server: http://YOUR_PUBLIC_IP:3000/" -ForegroundColor White
Write-Host ""
Write-Host "📁 Files created:" -ForegroundColor Cyan
Write-Host "   Environment: $AppPath\sql_server_api\.env" -ForegroundColor White
Write-Host "   Environment: $AppPath\server\.env" -ForegroundColor White
Write-Host "   Start Script: $AppPath\start-apis.bat" -ForegroundColor White
Write-Host "   Stop Script: $AppPath\stop-apis.bat" -ForegroundColor White

Read-Host "Press Enter to exit"
