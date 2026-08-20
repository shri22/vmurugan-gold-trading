#!/bin/bash
echo "--- VMurugan One-Click Deploy ---"
echo "Please enter your server password when prompted."

cd /Users/admin/Documents/Win-Projects/AntiGravity/vmurugan-gold-trading

# Package the files locally
tar -czf update.tar.gz sql_server_api/server.js sql_server_api/cleanup_pending_transactions.js download.html admin_portal/index.html VM-LOGO1.png
 
# Send and execute in one SSH connection
cat update.tar.gz | ssh root@193.203.160.3 '
    # Find the directory where server.js is running via PM2
    EXEC_PATH=$(pm2 jlist 2>/dev/null | grep -o "\"pm_exec_path\":\"[^\"]*\"" | cut -d "\"" -f 4 | grep server.js | head -1)
    
    if [ -n "$EXEC_PATH" ]; then
        API_DIR=$(dirname "$EXEC_PATH")
    else
        # Fallback search if pm2 jlist fails
        API_DIR=$(find / -type f -name "worldline_config.js" 2>/dev/null | head -n 1 | xargs dirname)
    fi
    
    if [ -z "$API_DIR" ]; then
        echo "Error: Could not locate API directory on server."
        exit 1
    fi
    
    echo "Deploying files to: $API_DIR"
    
    cd /tmp
    cat > update.tar.gz
    tar -xzf update.tar.gz
    
    cp sql_server_api/server.js "$API_DIR/server.js"
    cp sql_server_api/cleanup_pending_transactions.js "$API_DIR/cleanup_pending_transactions.js"
    cp download.html "$API_DIR/download.html"
    
    # Ensure admin_portal directory exists on server and copy the updated report template
    mkdir -p "$API_DIR/../admin_portal"
    cp admin_portal/index.html "$API_DIR/../admin_portal/index.html"
    cp VM-LOGO1.png "$API_DIR/../VM-LOGO1.png"
    
    rm -rf sql_server_api download.html admin_portal VM-LOGO1.png update.tar.gz
    
    echo "Restarting API server..."
    pm2 restart vmurugan-api
    
    echo ""
    echo "✅ Success! The new route and admin portal reports are live."
'

# Clean up local tar file
rm -f update.tar.gz
