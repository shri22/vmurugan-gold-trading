# SSL Integration Guide for VMurugan Jewellery Server

## 🔍 Current SSL Status in server.js

### ✅ What's Already Configured:
1. **HTTPS module imported**: `const https = require('https');`
2. **SSL certificate paths updated** for your domain:
   - **Key**: `C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem`
   - **Certificate**: `C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem`
3. **HTTPS server creation** with SSL options
4. **Automatic certificate validation**
5. **Error handling** for SSL issues

### 📁 SSL Certificate Paths:

After running the SSL setup script, your certificates will be located at:
```
C:\Certbot\live\api.vmuruganjewellery.co.in\
├── privkey.pem      (Private Key)
├── fullchain.pem    (Certificate + Chain)
├── cert.pem         (Certificate only)
└── chain.pem        (Certificate Chain)
```

## 🚀 How SSL Works with Your Server:

### **Step 1: SSL Certificate Generation**
```powershell
# Run this to generate SSL certificates
.\setup-vmurugan-ssl.ps1
```

### **Step 2: Server Startup Process**
1. **Database Connection**: Server connects to SQL Server
2. **SSL Certificate Check**: Looks for certificates at the configured paths
3. **Certificate Validation**: Validates certificate format and content
4. **HTTPS Server Creation**: Creates secure HTTPS server on port 443 (or 3001)
5. **HTTP Redirect**: Redirects all HTTP traffic to HTTPS

### **Step 3: Server Behavior**

**With SSL Certificates (Production Mode):**
```
🔒 HTTPS PRODUCTION SERVER STARTED!
🔒 VMurugan HTTPS Server running on port 443
🏥 Health Check: https://api.vmuruganjewellery.co.in/health
🔗 API Base URL: https://api.vmuruganjewellery.co.in/api
✅ HTTPS-only production mode
🔒 All connections encrypted
```

**Without SSL Certificates (Development Mode):**
```
❌ SSL certificates not found!
🔧 To fix this:
1. Run the SSL setup script: .\setup-vmurugan-ssl.ps1
2. Or run manually: .\setup-ssl.bat
3. Ensure domain api.vmuruganjewellery.co.in points to this server
4. Restart server after SSL certificates are generated
```

## 🔧 SSL Configuration Details:

### **HTTPS Options in server.js:**
```javascript
httpsOptions = {
  key: keyContent,                    // Private key content
  cert: certContent,                  // Certificate content
  secureProtocol: 'TLSv1_2_method',  // TLS 1.2 protocol
  honorCipherOrder: true,             // Server cipher preference
  ciphers: [                          // Secure cipher suites
    'ECDHE-RSA-AES128-GCM-SHA256',
    'ECDHE-RSA-AES256-GCM-SHA384',
    'ECDHE-RSA-AES128-SHA256',
    'ECDHE-RSA-AES256-SHA384'
  ].join(':'),
  rejectUnauthorized: false,          // Allow self-signed certificates
  requestCert: false,                 // Don't require client certificates
  agent: false                        // Disable connection pooling
};
```

### **Server Ports:**
- **HTTPS Port**: 443 (production) or 3001 (development)
- **HTTP Port**: 80 (redirects to HTTPS)

## 🌐 API Endpoints After SSL Setup:

### **Secure API URLs:**
- **Health Check**: `https://api.vmuruganjewellery.co.in/health`
- **Authentication**: `https://api.vmuruganjewellery.co.in/api/auth/login`
- **Gold Trading**: `https://api.vmuruganjewellery.co.in/api/gold/buy`
- **Silver Trading**: `https://api.vmuruganjewellery.co.in/api/silver/buy`
- **Worldline Payments**: `https://api.vmuruganjewellery.co.in/api/payments/worldline/token`
- **Schemes**: `https://api.vmuruganjewellery.co.in/api/schemes`

### **Admin Portal:**
- **Privacy Policy**: `https://api.vmuruganjewellery.co.in/privacy-policy`
- **Terms of Service**: `https://api.vmuruganjewellery.co.in/terms-of-service`

## 🔄 SSL Certificate Auto-Renewal:

The SSL setup script creates a Windows Scheduled Task that:
- **Runs daily at 2:00 AM**
- **Checks certificate expiry**
- **Automatically renews certificates**
- **Restarts server if needed**

## 🛠️ Troubleshooting:

### **Common SSL Issues:**

1. **Certificate Not Found:**
   ```
   ❌ SSL certificates not found!
   ```
   **Solution**: Run `.\setup-vmurugan-ssl.ps1`

2. **Invalid Certificate Format:**
   ```
   ❌ SSL certificates invalid format!
   ```
   **Solution**: Re-run SSL setup script

3. **Port Already in Use:**
   ```
   ❌ HTTPS server error: EADDRINUSE
   ```
   **Solution**: Stop existing server or change port

4. **Domain Not Pointing to Server:**
   ```
   ❌ Failed to generate SSL certificate
   ```
   **Solution**: Update DNS to point to your server's IP

### **Manual Certificate Check:**
```powershell
# Check if certificates exist
Test-Path "C:\Certbot\live\api.vmuruganjewellery.co.in\privkey.pem"
Test-Path "C:\Certbot\live\api.vmuruganjewellery.co.in\fullchain.pem"

# Check certificate expiry
certbot certificates
```

## 📋 Next Steps:

1. **Run SSL Setup**: Execute `.\setup-vmurugan-ssl.ps1` as Administrator
2. **Verify DNS**: Ensure `api.vmuruganjewellery.co.in` points to your server
3. **Start Server**: Run `node server.js` in the `sql_server_api` directory
4. **Test HTTPS**: Visit `https://api.vmuruganjewellery.co.in/health`
5. **Update Flutter App**: Change API base URL to HTTPS

## 🔒 Security Features:

- ✅ **TLS 1.2 Encryption**
- ✅ **Secure Cipher Suites**
- ✅ **HTTP to HTTPS Redirect**
- ✅ **Certificate Auto-Renewal**
- ✅ **Production-Ready Configuration**

Your server is now fully configured to work with SSL certificates from Let's Encrypt!
