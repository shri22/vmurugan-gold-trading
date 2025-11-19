# Debug SSL Setup Script for VMurugan Jewellery
# This script will show detailed output and not close automatically

Write-Host "=== VMurugan Jewellery SSL Debug Setup ===" -ForegroundColor Cyan
Write-Host "Domain: api.vmuruganjewellery.co.in" -ForegroundColor Green
Write-Host "Email: info@dakroot.com" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan

$Domain = "api.vmuruganjewellery.co.in"
$Email = "info@dakroot.com"

# Function to pause and wait for user input
function PauseScript($message = "Press Enter to continue...") {
    Write-Host $message -ForegroundColor Yellow
    Read-Host
}

# Check if running as Administrator
Write-Host "Checking Administrator privileges..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell" -ForegroundColor Yellow
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "3. Run this script again" -ForegroundColor Yellow
    PauseScript "Press Enter to exit..."
    exit 1
} else {
    Write-Host "✅ Running as Administrator - Good!" -ForegroundColor Green
}

# Check internet connectivity
Write-Host "Checking internet connectivity..." -ForegroundColor Yellow
try {
    $ping = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
    if ($ping) {
        Write-Host "✅ Internet connection: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ No internet connection detected" -ForegroundColor Red
        PauseScript "Please check your internet connection and press Enter to continue..."
    }
} catch {
    Write-Host "⚠️  Could not test internet connection" -ForegroundColor Yellow
}

# Check if domain resolves to this server
Write-Host "Checking DNS resolution for $Domain..." -ForegroundColor Yellow
try {
    $dnsResult = Resolve-DnsName -Name $Domain -ErrorAction SilentlyContinue
    if ($dnsResult) {
        Write-Host "✅ Domain resolves to: $($dnsResult.IPAddress)" -ForegroundColor Green
        
        # Get local IP addresses
        $localIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1"} | Select-Object -ExpandProperty IPAddress
        Write-Host "🖥️  Local server IPs: $($localIPs -join ', ')" -ForegroundColor Cyan
        
        $domainPointsHere = $false
        foreach ($ip in $localIPs) {
            if ($dnsResult.IPAddress -contains $ip) {
                Write-Host "✅ Domain points to this server!" -ForegroundColor Green
                $domainPointsHere = $true
                break
            }
        }
        
        if (-not $domainPointsHere) {
            Write-Host "⚠️  WARNING: Domain does not point to this server" -ForegroundColor Yellow
            Write-Host "Domain IP: $($dnsResult.IPAddress)" -ForegroundColor Yellow
            Write-Host "Server IPs: $($localIPs -join ', ')" -ForegroundColor Yellow
            PauseScript "This may cause SSL certificate generation to fail. Press Enter to continue anyway..."
        }
    } else {
        Write-Host "❌ Domain does not resolve" -ForegroundColor Red
        PauseScript "This will cause SSL certificate generation to fail. Press Enter to continue anyway..."
    }
} catch {
    Write-Host "⚠️  Could not check DNS resolution: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Check if ports 80 and 443 are available
Write-Host "Checking if ports 80 and 443 are available..." -ForegroundColor Yellow
$port80Free = $true
$port443Free = $true

try {
    $port80Test = Get-NetTCPConnection -LocalPort 80 -ErrorAction SilentlyContinue
    if ($port80Test) {
        Write-Host "⚠️  Port 80 is in use by: $($port80Test.OwningProcess)" -ForegroundColor Yellow
        $port80Free = $false
    } else {
        Write-Host "✅ Port 80 is available" -ForegroundColor Green
    }
} catch {
    Write-Host "✅ Port 80 appears to be available" -ForegroundColor Green
}

try {
    $port443Test = Get-NetTCPConnection -LocalPort 443 -ErrorAction SilentlyContinue
    if ($port443Test) {
        Write-Host "⚠️  Port 443 is in use by: $($port443Test.OwningProcess)" -ForegroundColor Yellow
        $port443Free = $false
    } else {
        Write-Host "✅ Port 443 is available" -ForegroundColor Green
    }
} catch {
    Write-Host "✅ Port 443 appears to be available" -ForegroundColor Green
}

if (-not $port80Free) {
    Write-Host "⚠️  Port 80 is in use. SSL certificate generation may fail." -ForegroundColor Yellow
    Write-Host "You may need to stop the service using port 80 temporarily." -ForegroundColor Yellow
    PauseScript "Press Enter to continue..."
}

# Check if Chocolatey is installed
Write-Host "Checking for Chocolatey..." -ForegroundColor Yellow
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "✅ Chocolatey is already installed" -ForegroundColor Green
} else {
    Write-Host "❌ Chocolatey not found. Installing..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "✅ Chocolatey installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to install Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
        PauseScript "Press Enter to continue anyway..."
    }
}

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Check if Certbot is installed
Write-Host "Checking for Certbot..." -ForegroundColor Yellow
if (Get-Command certbot -ErrorAction SilentlyContinue) {
    Write-Host "✅ Certbot is already installed" -ForegroundColor Green
    & certbot --version
} else {
    Write-Host "❌ Certbot not found. Installing..." -ForegroundColor Yellow
    try {
        choco install certbot -y
        Write-Host "✅ Certbot installed successfully!" -ForegroundColor Green
        
        # Refresh environment variables again
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Get-Command certbot -ErrorAction SilentlyContinue) {
            & certbot --version
        } else {
            Write-Host "⚠️  Certbot installed but not found in PATH. You may need to restart PowerShell." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to install Certbot: $($_.Exception.Message)" -ForegroundColor Red
        PauseScript "Press Enter to continue anyway..."
    }
}

# Stop IIS if running
Write-Host "Stopping IIS temporarily..." -ForegroundColor Yellow
try {
    Stop-Service W3SVC -Force -ErrorAction SilentlyContinue
    Stop-Service WAS -Force -ErrorAction SilentlyContinue
    Write-Host "✅ IIS stopped successfully" -ForegroundColor Green
} catch {
    Write-Host "ℹ️  IIS not running or not installed" -ForegroundColor Gray
}

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "HTTP-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "HTTPS-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "✅ Firewall rules added successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not configure firewall: $($_.Exception.Message)" -ForegroundColor Yellow
}

PauseScript "All checks completed. Press Enter to generate SSL certificate..."

# Generate SSL certificate
Write-Host "Generating SSL certificate for $Domain..." -ForegroundColor Yellow
Write-Host "This may take a few minutes. Please wait..." -ForegroundColor Gray

$certbotArgs = @(
    "certonly",
    "--standalone",
    "--non-interactive",
    "--agree-tos",
    "--email", $Email,
    "-d", $Domain,
    "--verbose"
)

Write-Host "Running command: certbot $($certbotArgs -join ' ')" -ForegroundColor Cyan

try {
    & certbot @certbotArgs
    $certbotExitCode = $LASTEXITCODE
    
    Write-Host "Certbot exit code: $certbotExitCode" -ForegroundColor Cyan
    
    if ($certbotExitCode -eq 0) {
        Write-Host "✅ SSL certificate generated successfully!" -ForegroundColor Green
        
        # Check if certificate files exist
        $certPath = "C:\Certbot\live\$Domain\fullchain.pem"
        $keyPath = "C:\Certbot\live\$Domain\privkey.pem"
        
        if (Test-Path $certPath) {
            Write-Host "✅ Certificate file found: $certPath" -ForegroundColor Green
        } else {
            Write-Host "❌ Certificate file not found: $certPath" -ForegroundColor Red
        }
        
        if (Test-Path $keyPath) {
            Write-Host "✅ Private key file found: $keyPath" -ForegroundColor Green
        } else {
            Write-Host "❌ Private key file not found: $keyPath" -ForegroundColor Red
        }
        
        # List all files in the certificate directory
        $certDir = "C:\Certbot\live\$Domain"
        if (Test-Path $certDir) {
            Write-Host "📁 Certificate directory contents:" -ForegroundColor Cyan
            Get-ChildItem $certDir | ForEach-Object {
                Write-Host "   $($_.Name) - $($_.Length) bytes" -ForegroundColor Gray
            }
        }
        
    } else {
        Write-Host "❌ SSL certificate generation failed with exit code: $certbotExitCode" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Error running Certbot: $($_.Exception.Message)" -ForegroundColor Red
}

# Start IIS back up
Write-Host "Starting IIS..." -ForegroundColor Yellow
try {
    Start-Service W3SVC -ErrorAction SilentlyContinue
    Write-Host "✅ IIS started successfully" -ForegroundColor Green
} catch {
    Write-Host "ℹ️  Could not start IIS or IIS not installed" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== SSL Setup Debug Complete ===" -ForegroundColor Cyan
Write-Host "Check the output above for any errors or issues." -ForegroundColor Yellow
Write-Host ""

PauseScript "Press Enter to exit..."
