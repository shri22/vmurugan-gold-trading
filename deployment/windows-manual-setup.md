# VMurugan API - Windows Server Manual Deployment

## 🖥️ **Prerequisites**

Your Windows Server should have:
- Windows Server 2016/2019/2022 or Windows 10/11
- Administrator access
- Internet connection
- Public IP address
- SQL Server already installed (which you have)

## 🚀 **Quick Deployment (Option 1: Automated)**

1. **Download & Run Script**
   ```powershell
   # Run PowerShell as Administrator
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Navigate to your project folder
   cd E:\Projects\vmurugan-gold-trading\deployment
   
   # Run deployment script
   .\windows-deploy.ps1
   ```

2. **Copy Your Files**
   ```powershell
   # Copy SQL Server API
   Copy-Item -Path "E:\Projects\vmurugan-gold-trading\sql_server_api\*" -Destination "C:\VMuruganAPI\sql_server_api\" -Recurse -Force
   
   # Copy Main Server
   Copy-Item -Path "E:\Projects\vmurugan-gold-trading\server\*" -Destination "C:\VMuruganAPI\server\" -Recurse -Force
   ```

3. **Start Services**
   ```powershell
   # Run the startup script
   C:\VMuruganAPI\start-apis.bat
   ```

## 🔧 **Manual Deployment (Option 2: Step by Step)**

### **Step 1: Install Node.js**
1. Download Node.js from [nodejs.org](https://nodejs.org)
2. Install Node.js (LTS version recommended)
3. Verify installation:
   ```cmd
   node --version
   npm --version
   ```

### **Step 2: Install PM2**
```cmd
npm install -g pm2
npm install -g pm2-windows-startup
pm2-startup install
```

### **Step 3: Create Application Directory**
```cmd
mkdir C:\VMuruganAPI
mkdir C:\VMuruganAPI\sql_server_api
mkdir C:\VMuruganAPI\server
mkdir C:\VMuruganAPI\logs
```

### **Step 4: Copy Application Files**
Copy your project files:
- `sql_server_api\*` → `C:\VMuruganAPI\sql_server_api\`
- `server\*` → `C:\VMuruganAPI\server\`

### **Step 5: Install Dependencies**
```cmd
cd C:\VMuruganAPI\sql_server_api
npm install

cd C:\VMuruganAPI\server
npm install
```

### **Step 6: Configure Environment**
Create `C:\VMuruganAPI\sql_server_api\.env`:
```env
PORT=3001
NODE_ENV=production
HOST=0.0.0.0

# Your existing SQL Server (already working)
SQL_SERVER=192.168.1.18
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=DakData
SQL_PASSWORD=Test@123
SQL_ENCRYPT=false
SQL_TRUST_SERVER_CERTIFICATE=true

ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
JWT_SECRET=vmurugan_production_jwt_secret_2025

# Allow all origins for now
ALLOWED_ORIGINS=*

BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMurugan Gold Trading
```

### **Step 7: Configure Windows Firewall**
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "VMurugan SQL API" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow
New-NetFirewallRule -DisplayName "VMurugan Main API" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
```

### **Step 8: Start Services**
```cmd
cd C:\VMuruganAPI\sql_server_api
pm2 start server.js --name "vmurugan-sql-api"

cd C:\VMuruganAPI\server
pm2 start server.js --name "vmurugan-main-api"

pm2 save
pm2 startup
```

## 🌐 **Configure Public Access**

### **Option 1: Direct Port Access**
Your APIs will be accessible at:
- SQL Server API: `http://YOUR_PUBLIC_IP:3001/api/`
- Main Server: `http://YOUR_PUBLIC_IP:3000/`

### **Option 2: IIS Reverse Proxy (Recommended)**
1. **Enable IIS**:
   - Control Panel → Programs → Turn Windows features on/off
   - Enable Internet Information Services

2. **Install URL Rewrite Module**:
   - Download from Microsoft website
   - Install the module

3. **Configure IIS**:
   Create `C:\inetpub\wwwroot\web.config`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <configuration>
       <system.webServer>
           <rewrite>
               <rules>
                   <rule name="SQL API" stopProcessing="true">
                       <match url="^api/(.*)" />
                       <action type="Rewrite" url="http://localhost:3001/api/{R:1}" />
                   </rule>
               </rules>
           </rewrite>
       </system.webServer>
   </configuration>
   ```

Now your API will be accessible at:
- `http://YOUR_PUBLIC_IP/api/` (SQL Server API)
- `http://YOUR_PUBLIC_IP/` (Main Server)

## 📱 **Update Flutter App**

Update your Flutter app configuration:

```dart
// lib/core/config/sql_server_config.dart
static const String serverIP = 'YOUR_PUBLIC_IP'; // Your Windows server public IP

// lib/core/config/client_server_config.dart
static const String serverDomain = 'YOUR_PUBLIC_IP';
```

Then rebuild:
```bash
flutter build apk --release
```

## 🔧 **Management Commands**

### **Start Services**
```cmd
pm2 start all
```

### **Stop Services**
```cmd
pm2 stop all
```

### **Restart Services**
```cmd
pm2 restart all
```

### **View Logs**
```cmd
pm2 logs
```

### **Check Status**
```cmd
pm2 status
```

## 🧪 **Testing**

Test your APIs:
```cmd
# Test SQL Server API
curl http://YOUR_PUBLIC_IP:3001/api/health
curl http://YOUR_PUBLIC_IP:3001/api/test-connection

# Test Main Server
curl http://YOUR_PUBLIC_IP:3000/health
```

## 🔒 **Security Considerations**

1. **Firewall**: Only open necessary ports (80, 443, 3000, 3001)
2. **SSL Certificate**: Consider adding SSL for HTTPS
3. **Authentication**: Your APIs already have admin tokens
4. **Regular Updates**: Keep Node.js and dependencies updated

## 📊 **Monitoring**

1. **PM2 Monitoring**:
   ```cmd
   pm2 monit
   ```

2. **Windows Event Viewer**: Check for application errors

3. **Performance Monitor**: Monitor CPU, memory usage

## 🆘 **Troubleshooting**

### **API Not Starting**
```cmd
pm2 logs
# Check for errors in logs
```

### **Port Already in Use**
```cmd
netstat -ano | findstr :3001
# Kill process if needed
taskkill /PID <process_id> /F
```

### **SQL Connection Issues**
- Verify SQL Server is running
- Check connection string in .env file
- Test with sqlcmd

## 💡 **Advantages of Windows Server Deployment**

✅ **Full Control**: Complete control over your server
✅ **Cost Effective**: No monthly hosting fees
✅ **Performance**: Dedicated resources
✅ **Integration**: Easy integration with existing SQL Server
✅ **Security**: Your own security policies
✅ **Scalability**: Can upgrade hardware as needed

Your Windows server deployment will be more cost-effective and give you complete control over your APIs!
