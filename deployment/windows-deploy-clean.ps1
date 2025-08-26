# VMurugan Gold Trading API - Windows Server Deployment Script
# Run this script as Administrator

Write-Host "Starting VMurugan API Deployment on Windows Server..." -ForegroundColor Green

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-NOT $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Install Node.js check
Write-Host "Checking Node.js installation..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version
    Write-Host "Node.js is installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js not found. Please install from nodejs.org" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install PM2
Write-Host "Installing PM2..." -ForegroundColor Cyan
try {
    npm install -g pm2
    npm install -g pm2-windows-startup
    pm2-startup install
    Write-Host "PM2 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "PM2 installation failed" -ForegroundColor Yellow
}

# Create application directory
$AppPath = "C:\VMuruganAPI"
Write-Host "Creating application directory: $AppPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $AppPath | Out-Null
New-Item -ItemType Directory -Force -Path "$AppPath\sql_server_api" | Out-Null
New-Item -ItemType Directory -Force -Path "$AppPath\server" | Out-Null
New-Item -ItemType Directory -Force -Path "$AppPath\logs" | Out-Null

Write-Host "Application directories created successfully" -ForegroundColor Green

# SQL Server configuration
Write-Host "SQL Server Configuration Options:" -ForegroundColor Cyan
Write-Host "1. Use existing SQL Server (192.168.1.18) - Recommended" -ForegroundColor White
Write-Host "2. Use localhost" -ForegroundColor White
Write-Host "3. Enter custom IP" -ForegroundColor White
$SqlChoice = Read-Host "Choose option (1-3)"

switch ($SqlChoice) {
    "1" { $SqlServerIP = "192.168.1.18" }
    "2" { $SqlServerIP = "localhost" }
    "3" { $SqlServerIP = Read-Host "Enter SQL Server IP address" }
    default { $SqlServerIP = "192.168.1.18" }
}

Write-Host "Using SQL Server: $SqlServerIP" -ForegroundColor Green

# Create SQL Server API environment file
Write-Host "Creating SQL Server API environment file..." -ForegroundColor Cyan
$sqlEnvPath = Join-Path $AppPath "sql_server_api\.env"
$sqlEnvContent = @"
PORT=3001
NODE_ENV=production
HOST=0.0.0.0

SQL_SERVER=$SqlServerIP
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=DakData
SQL_PASSWORD=Test@123
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true

ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_production_jwt_secret_2025

ALLOWED_ORIGINS=*

BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMurugan Gold Trading
"@

$sqlEnvContent | Out-File -FilePath $sqlEnvPath -Encoding UTF8

# Create Main Server environment file
Write-Host "Creating Main Server environment file..." -ForegroundColor Cyan
$mainEnvPath = Join-Path $AppPath "server\.env"
$mainEnvContent = @"
PORT=3000
NODE_ENV=production
HOST=0.0.0.0

ADMIN_TOKEN=VMURUGAN_MAIN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_main_production_jwt_secret_2025

ALLOWED_ORIGINS=*
"@

$mainEnvContent | Out-File -FilePath $mainEnvPath -Encoding UTF8

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall..." -ForegroundColor Cyan
try {
    New-NetFirewallRule -DisplayName "VMurugan SQL API" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "VMurugan Main API" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "Firewall rules configured successfully" -ForegroundColor Green
} catch {
    Write-Host "Could not configure firewall automatically" -ForegroundColor Yellow
}

# Create startup script
Write-Host "Creating startup script..." -ForegroundColor Cyan
$startScriptPath = Join-Path $AppPath "start-apis.bat"
$startScriptContent = @'
@echo off
echo Starting VMurugan APIs...

echo Installing SQL Server API dependencies...
cd /d C:\VMuruganAPI\sql_server_api
call npm install --production

echo Starting SQL Server API...
pm2 start server.js --name "vmurugan-sql-api"

echo Installing Main Server dependencies...
cd /d C:\VMuruganAPI\server
call npm install --production

echo Starting Main Server...
pm2 start server.js --name "vmurugan-main-api"

pm2 save
echo VMurugan APIs started successfully!
echo.
echo APIs accessible at:
echo   SQL Server API: http://localhost:3001/api/
echo   Main Server: http://localhost:3000/
echo.
pause
'@

$startScriptContent | Out-File -FilePath $startScriptPath -Encoding ASCII

# Create stop script
Write-Host "Creating stop script..." -ForegroundColor Cyan
$stopScriptPath = Join-Path $AppPath "stop-apis.bat"
$stopScriptContent = @'
@echo off
echo Stopping VMurugan APIs...
pm2 stop all
echo VMurugan APIs stopped!
pause
'@

$stopScriptContent | Out-File -FilePath $stopScriptPath -Encoding ASCII

Write-Host "Windows Server deployment setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy your application files to $AppPath" -ForegroundColor White
Write-Host "2. Run $AppPath\start-apis.bat to start the services" -ForegroundColor White
Write-Host "3. Test APIs at http://localhost:3001/api/ and http://localhost:3000/" -ForegroundColor White
Write-Host ""
Write-Host "Your APIs will be accessible at:" -ForegroundColor Cyan
Write-Host "   SQL Server API: http://YOUR_PUBLIC_IP:3001/api/" -ForegroundColor White
Write-Host "   Main Server: http://YOUR_PUBLIC_IP:3000/" -ForegroundColor White

Read-Host "Press Enter to exit"
