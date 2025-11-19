#!/bin/bash

# SSL Certificate Setup Script for Production Server
# Usage: ./setup-ssl.sh yourdomain.com

DOMAIN=$1
EMAIL="admin@$DOMAIN"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain.com>"
    echo "Example: $0 vmurugan-gold.com"
    exit 1
fi

echo "Setting up SSL certificate for: $DOMAIN"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
else
    echo "Unsupported OS. This script works on Ubuntu/Debian and CentOS/RHEL"
    exit 1
fi

# Install Certbot
echo "Installing Certbot..."
if [ "$OS" = "debian" ]; then
    apt update
    apt install -y certbot python3-certbot-nginx
elif [ "$OS" = "redhat" ]; then
    yum install -y epel-release
    yum install -y certbot python3-certbot-nginx
fi

# Stop nginx temporarily
echo "Stopping nginx..."
systemctl stop nginx

# Generate SSL certificate
echo "Generating SSL certificate for $DOMAIN..."
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ $? -eq 0 ]; then
    echo "SSL certificate generated successfully!"
    
    # Create nginx configuration
    cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        # Start nginx
        systemctl start nginx
        systemctl enable nginx
        
        # Setup auto-renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx") | crontab -
        
        echo "✅ SSL setup completed successfully!"
        echo "Your website is now available at: https://$DOMAIN"
        echo "Certificate will auto-renew every 12 hours"
        
        # Test the certificate
        echo "Testing SSL certificate..."
        sleep 5
        curl -I https://$DOMAIN
        
    else
        echo "❌ Nginx configuration error. Please check the configuration."
        exit 1
    fi
    
else
    echo "❌ Failed to generate SSL certificate."
    echo "Make sure:"
    echo "1. Domain $DOMAIN points to this server's IP"
    echo "2. Ports 80 and 443 are open"
    echo "3. No other service is using port 80"
    exit 1
fi
