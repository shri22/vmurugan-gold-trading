# SSL Certificate Setup for Windows Server

## 🚀 Quick Setup (Automated)

### Step 1: Run PowerShell as Administrator
1. Press `Win + X`
2. Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

### Step 2: Execute the Setup Script
```powershell
# Navigate to the project directory
cd "E:\Projects\vmurugan-gold-trading"

# Run the SSL setup script
.\setup-ssl-windows.ps1 -Domain "yourdomain.com" -Email "admin@yourdomain.com"
```

Replace `yourdomain.com` with your actual domain name.

## 📋 What the Script Does

1. ✅ Installs Chocolatey (Windows package manager)
2. ✅ Installs Certbot (Let's Encrypt client)
3. ✅ Generates free SSL certificate from Let's Encrypt
4. ✅ Converts certificate to PFX format (Windows compatible)
5. ✅ Imports certificate to Windows Certificate Store
6. ✅ Configures IIS HTTPS binding (if IIS is installed)
7. ✅ Sets up automatic renewal task

## 🔧 Manual Setup (Alternative)

### Option 1: Using Certbot on Windows

```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Certbot
choco install certbot -y

# Generate certificate
certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

### Option 2: Using Win-ACME (Windows-specific)

```powershell
# Download Win-ACME
Invoke-WebRequest -Uri "https://github.com/win-acme/win-acme/releases/latest/download/win-acme.v2.2.0.1431.x64.pluggable.zip" -OutFile "win-acme.zip"

# Extract and run
Expand-Archive -Path "win-acme.zip" -DestinationPath "C:\win-acme"
cd "C:\win-acme"
.\wacs.exe
```

## 🌐 IIS Configuration

### Create HTTPS Binding in IIS Manager:

1. Open IIS Manager
2. Select your website
3. Click "Bindings" in Actions panel
4. Click "Add"
5. Select:
   - Type: https
   - Port: 443
   - Host name: yourdomain.com
   - SSL certificate: Select your imported certificate

### Web.config for HTTPS Redirect:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="Redirect to HTTPS" stopProcessing="true">
          <match url=".*" />
          <conditions>
            <add input="{HTTPS}" pattern="off" ignoreCase="true" />
          </conditions>
          <action type="Redirect" url="https://{HTTP_HOST}/{R:0}" redirectType="Permanent" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

## 🔥 Windows Firewall Configuration

```powershell
# Open ports 80 and 443
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
```

## 📁 Certificate File Locations

After successful setup:

- **Certificate**: `C:\Certbot\live\yourdomain.com\fullchain.pem`
- **Private Key**: `C:\Certbot\live\yourdomain.com\privkey.pem`
- **PFX File**: `C:\Certbot\live\yourdomain.com\certificate.pfx`
- **PFX Password**: `VMurugan123!`

## 🔄 Auto-Renewal

The script sets up a Windows Scheduled Task that runs daily at 2:00 AM to check and renew certificates automatically.

To manually check renewal:
```powershell
certbot renew --dry-run
```

## 🛠️ Troubleshooting

### Common Issues:

1. **Port 80 blocked**: Ensure Windows Firewall allows port 80
2. **IIS running**: Stop IIS temporarily during certificate generation
3. **DNS not pointing**: Verify domain points to your server's IP
4. **Admin privileges**: Run PowerShell as Administrator

### Test Your SSL:

```powershell
# Test SSL certificate
Invoke-WebRequest -Uri "https://yourdomain.com" -UseBasicParsing
```

## 📞 Support Commands

```powershell
# Check certificate status
certbot certificates

# Force renewal
certbot renew --force-renewal

# View scheduled tasks
Get-ScheduledTask -TaskName "Certbot Auto Renewal"
```

## 🎯 Prerequisites

1. **Domain ownership**: You must own the domain
2. **DNS configuration**: Domain must point to your server's IP
3. **Administrator access**: Required for certificate installation
4. **Internet connectivity**: Required for Let's Encrypt validation
5. **Ports 80/443**: Must be accessible from the internet
