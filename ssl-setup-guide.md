# SSL Certificate Setup Guide for Production Server

## Option 1: Let's Encrypt (Free SSL Certificate)

### Prerequisites:
- Domain name pointing to your server
- Server with root/sudo access
- Port 80 and 443 open

### Ubuntu/Debian Server Setup:

```bash
# Install Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Generate SSL certificate for your domain
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal setup
sudo crontab -e
# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet
```

### CentOS/RHEL Server Setup:

```bash
# Install EPEL and Certbot
sudo yum install epel-release
sudo yum install certbot python3-certbot-nginx

# Generate certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## Option 2: Manual Certificate Installation

If you have a certificate from a commercial CA:

### Nginx Configuration:
```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;
    
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    ssl_certificate /path/to/your/ca_bundle.crt;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

### Apache Configuration:
```apache
<VirtualHost *:443>
    ServerName yourdomain.com
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile /path/to/your/certificate.crt
    SSLCertificateKeyFile /path/to/your/private.key
    SSLCertificateChainFile /path/to/your/ca_bundle.crt
    
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
</VirtualHost>
```

## Option 3: Cloud Provider SSL

### AWS Certificate Manager:
1. Go to AWS Certificate Manager
2. Request a public certificate
3. Add your domain name
4. Choose DNS validation
5. Add CNAME records to your DNS
6. Use certificate with ALB/CloudFront

### Cloudflare SSL:
1. Add your domain to Cloudflare
2. Change nameservers to Cloudflare
3. Enable SSL/TLS encryption
4. Choose "Full (strict)" mode

## Testing Your SSL Certificate:

```bash
# Test SSL certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Check certificate expiry
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates
```

## Important Notes:

1. **Domain Validation Required**: You must own the domain to get a valid SSL certificate
2. **DNS Configuration**: Your domain must point to your server's IP address
3. **Firewall**: Ensure ports 80 and 443 are open
4. **Auto-Renewal**: Set up automatic renewal for Let's Encrypt certificates
5. **Security Headers**: Add security headers for better protection

## Quick Let's Encrypt Command:

Replace `yourdomain.com` with your actual domain:

```bash
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

This will generate:
- Certificate: `/etc/letsencrypt/live/yourdomain.com/fullchain.pem`
- Private Key: `/etc/letsencrypt/live/yourdomain.com/privkey.pem`
