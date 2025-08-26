#!/bin/bash
# VMurugan API Deployment Script

echo "🚀 Starting VMurugan API Deployment..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Create app directory
sudo mkdir -p /var/www/vmurugan-api
sudo chown -R $USER:$USER /var/www/vmurugan-api

# Install dependencies for SQL Server API
cd /var/www/vmurugan-api/sql_server_api
npm install

# Install dependencies for Main Server
cd /var/www/vmurugan-api/server
npm install

# Setup environment files
echo "Setting up environment variables..."

# Create SQL Server API .env
cat > /var/www/vmurugan-api/sql_server_api/.env << EOF
# Production SQL Server API Configuration
PORT=3001
NODE_ENV=production

# SQL Server Configuration (Update these)
SQL_SERVER=your_production_sql_server_ip
SQL_PORT=1433
SQL_DATABASE=VMuruganGoldTrading
SQL_USERNAME=your_production_username
SQL_PASSWORD=your_production_password
SQL_ENCRYPT=true
SQL_TRUST_SERVER_CERTIFICATE=false

# Security
ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
JWT_SECRET=your_production_jwt_secret

# CORS Configuration
ALLOWED_ORIGINS=*

# Business Configuration
BUSINESS_ID=VMURUGAN_001
BUSINESS_NAME=VMurugan Gold Trading
EOF

# Create Main Server .env
cat > /var/www/vmurugan-api/server/.env << EOF
# Production Main Server Configuration
PORT=3000
NODE_ENV=production

# Database Configuration (if using MySQL)
DB_HOST=your_mysql_host
DB_USER=your_mysql_user
DB_PASSWORD=your_mysql_password
DB_NAME=vmurugan_gold_trading

# Security
ADMIN_TOKEN=VMURUGAN_ADMIN_PRODUCTION_2025
JWT_SECRET=your_production_jwt_secret

# CORS Configuration
ALLOWED_ORIGINS=*
EOF

# Start services with PM2
echo "Starting services..."
cd /var/www/vmurugan-api/sql_server_api
pm2 start server.js --name "vmurugan-sql-api"

cd /var/www/vmurugan-api/server
pm2 start server.js --name "vmurugan-main-api"

# Save PM2 configuration
pm2 save
pm2 startup

# Setup Nginx (optional)
sudo apt install -y nginx

# Create Nginx configuration
sudo cat > /etc/nginx/sites-available/vmurugan-api << EOF
server {
    listen 80;
    server_name your_domain_or_ip;

    # SQL Server API
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Main Server API
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable Nginx site
sudo ln -s /etc/nginx/sites-available/vmurugan-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo "✅ Deployment completed!"
echo "🌐 Your API is now accessible at: http://your_server_ip"
echo "📋 SQL Server API: http://your_server_ip/api/"
echo "📋 Main Server: http://your_server_ip/"
echo ""
echo "🔧 Next steps:"
echo "1. Update SQL Server connection details in .env files"
echo "2. Configure your domain (optional)"
echo "3. Setup SSL certificate (recommended)"
echo "4. Update Flutter app with new public IP"
