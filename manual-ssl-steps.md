# Manual SSL Certificate Setup - Step by Step

## 🚨 If the automated script failed, follow these manual steps:

### Step 1: Check Prerequisites

1. **Run PowerShell as Administrator**
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Check if domain points to your server**
   ```powershell
   nslookup api.vmuruganjewellery.co.in
   ```
   This should return your server's IP address.

3. **Check if ports 80 and 443 are free**
   ```powershell
   netstat -an | findstr ":80 "
   netstat -an | findstr ":443 "
   ```

### Step 2: Install Chocolatey (if not installed)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Step 3: Install Certbot

```powershell
choco install certbot -y
```

### Step 4: Stop IIS (if running)

```powershell
Stop-Service W3SVC -Force
Stop-Service WAS -Force
```

### Step 5: Open Windows Firewall Ports

```powershell
New-NetFirewallRule -DisplayName "HTTP-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS-VMurugan" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
```

### Step 6: Generate SSL Certificate

```powershell
certbot certonly --standalone --non-interactive --agree-tos --email info@dakroot.com -d api.vmuruganjewellery.co.in --verbose
```

### Step 7: Check if certificates were created

```powershell
Test-Path "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem"
Test-Path "C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem"
```

### Step 8: List certificate files

```powershell
Get-ChildItem "C:\Certbot\live\api.vmuruganjewellery.co.in\"
```

### Step 9: Start IIS back up

```powershell
Start-Service W3SVC
```

## 🔍 Common Issues and Solutions:

### Issue 1: "Domain doesn't point to this server"
**Solution**: Update your DNS settings to point `api.vmuruganjewellery.co.in` to your server's IP address.

### Issue 2: "Port 80 is already in use"
**Solution**: 
```powershell
# Find what's using port 80
Get-Process -Id (Get-NetTCPConnection -LocalPort 80).OwningProcess

# Stop IIS if it's running
Stop-Service W3SVC -Force
```

### Issue 3: "Certbot command not found"
**Solution**: 
```powershell
# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Or restart PowerShell and try again
```

### Issue 4: "Permission denied"
**Solution**: Make sure you're running PowerShell as Administrator.

### Issue 5: "Certificate files not found"
**Solution**: Check if Certbot created files in a different location:
```powershell
# Search for certificate files
Get-ChildItem -Path "C:\" -Recurse -Name "*.pem" -ErrorAction SilentlyContinue | Where-Object {$_ -like "*vmuruganjewellery*"}
```

## 🎯 Alternative: Use Win-ACME (Windows-specific tool)

If Certbot doesn't work, try Win-ACME:

1. **Download Win-ACME**
   ```powershell
   Invoke-WebRequest -Uri "https://github.com/win-acme/win-acme/releases/latest/download/win-acme.v2.2.0.1431.x64.pluggable.zip" -OutFile "win-acme.zip"
   ```

2. **Extract and run**
   ```powershell
   Expand-Archive -Path "win-acme.zip" -DestinationPath "C:\win-acme"
   cd "C:\win-acme"
   .\wacs.exe
   ```

3. **Follow the interactive prompts**
   - Choose option 'N' for new certificate
   - Enter domain: `api.vmuruganjewellery.co.in`
   - Choose validation method: HTTP validation
   - Enter email: `info@dakroot.com`

## 🔧 Manual Certificate Creation (Last Resort)

If all else fails, you can create a self-signed certificate for testing:

```powershell
# Create certificate directory
New-Item -ItemType Directory -Force -Path "C:\Certbot\live\api.vmuruganjewellery.co.in"

# Generate self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "api.vmuruganjewellery.co.in" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -Provider "Microsoft RSA SChannel Cryptographic Provider" -KeyExportPolicy Exportable -KeyUsage DigitalSignature,KeyEncipherment -Type SSLServerAuthentication

# Export to PEM format (requires OpenSSL or manual conversion)
# Note: This creates a self-signed certificate that browsers will show warnings for
```

## 📞 Getting Help

If you're still having issues:

1. **Run the debug script**: `.\debug-ssl-setup.ps1`
2. **Check the detailed output** for specific error messages
3. **Verify DNS settings** with your domain provider
4. **Check firewall settings** on your server
5. **Ensure your server is accessible** from the internet on ports 80 and 443

## 🎯 Expected Result

After successful setup, you should have:
- Certificate: `C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem`
- Private Key: `C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem`
- Your server.js will automatically detect and use these certificates
