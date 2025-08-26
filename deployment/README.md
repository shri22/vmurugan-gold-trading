# VMurugan Gold Trading API - Deployment Guide

## 🚀 Quick Deployment (15 minutes)

### **Option 1: DigitalOcean (Recommended)**

1. **Create Account & Droplet**
   ```bash
   # Go to digitalocean.com
   # Create account → Create Droplet
   # Choose: Ubuntu 22.04, Basic $4/month
   # Add SSH key or password
   ```

2. **Upload Code**
   ```bash
   # From your local machine
   scp -r sql_server_api root@YOUR_SERVER_IP:/var/www/vmurugan-api/
   scp -r server root@YOUR_SERVER_IP:/var/www/vmurugan-api/
   scp deployment/deploy.sh root@YOUR_SERVER_IP:/root/
   ```

3. **Run Deployment**
   ```bash
   # SSH to server
   ssh root@YOUR_SERVER_IP
   
   # Run deployment script
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. **Update Configuration**
   ```bash
   # Edit SQL Server API config
   nano /var/www/vmurugan-api/sql_server_api/.env
   
   # Update these values:
   SQL_SERVER=YOUR_SQL_SERVER_IP
   SQL_USERNAME=your_username
   SQL_PASSWORD=your_password
   
   # Restart services
   pm2 restart all
   ```

5. **Test APIs**
   ```bash
   curl http://YOUR_SERVER_IP/api/health
   curl http://YOUR_SERVER_IP/health
   ```

### **Option 2: Railway (Easiest)**

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Deploy to Railway"
   git push origin main
   ```

2. **Deploy on Railway**
   - Go to [railway.app](https://railway.app)
   - Connect GitHub
   - Deploy from repo
   - Add environment variables

### **Option 3: Heroku**

1. **Install Heroku CLI**
   ```bash
   npm install -g heroku
   heroku login
   ```

2. **Deploy**
   ```bash
   heroku create vmurugan-api
   git push heroku main
   ```

## 📱 Update Flutter App

After deployment, update your Flutter app configuration:

```dart
// lib/core/config/sql_server_config.dart
static const String serverIP = 'YOUR_PUBLIC_SERVER_IP';

// lib/core/config/client_server_config.dart
static const String serverDomain = 'YOUR_PUBLIC_SERVER_IP';
```

Then rebuild APK:
```bash
flutter build apk --release
```

## 🔧 Configuration Files

### SQL Server API (.env)
```env
PORT=3001
SQL_SERVER=your_sql_server_ip
SQL_USERNAME=your_username
SQL_PASSWORD=your_password
SQL_DATABASE=VMuruganGoldTrading
```

### Main Server (.env)
```env
PORT=3000
NODE_ENV=production
```

## 🌐 Public Access

After deployment, your APIs will be accessible at:
- **SQL Server API**: `http://YOUR_PUBLIC_IP:3001/api/`
- **Main Server**: `http://YOUR_PUBLIC_IP:3000/`

## 💰 Cost Breakdown

| Service | Cost | Features |
|---------|------|----------|
| DigitalOcean | $4-6/month | Full control, SSH access |
| Railway | Free tier | Easy deployment, auto-scaling |
| Heroku | $7/month | Simple deployment |

## 🔒 Security Setup

1. **SSL Certificate** (Free)
   ```bash
   sudo certbot --nginx -d yourdomain.com
   ```

2. **Firewall**
   ```bash
   sudo ufw allow 22,80,443
   sudo ufw enable
   ```

3. **Environment Variables**
   - Never commit .env files
   - Use strong passwords
   - Rotate secrets regularly

## 📊 Monitoring

```bash
# Check service status
pm2 status

# View logs
pm2 logs

# Monitor resources
htop
```

## 🆘 Troubleshooting

### API Not Responding
```bash
pm2 restart all
pm2 logs
```

### SQL Connection Issues
```bash
# Test SQL connection
sqlcmd -S your_server -U username -P password
```

### Port Issues
```bash
# Check what's using ports
netstat -tulpn | grep :3001
```

## 📞 Support

If you need help with deployment:
1. Check the logs: `pm2 logs`
2. Verify configuration files
3. Test SQL Server connectivity
4. Check firewall settings

## 🎯 Next Steps

1. **Deploy to production server**
2. **Update Flutter app configuration**
3. **Test with real device**
4. **Setup domain name (optional)**
5. **Configure SSL certificate**
6. **Setup monitoring and backups**
