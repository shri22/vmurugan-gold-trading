#!/bin/bash
echo "--- VMurugan Node.js Env Tester ---"
echo "Please enter your server password when prompted."
ssh root@193.203.160.3 '
    cd /root/sql_server_api
    node -e "
    require(\"dotenv\").config();
    console.log(\"=== Dotenv Config Loaded by Node.js ===\");
    console.log(\"SQL_SERVER:\", process.env.SQL_SERVER);
    console.log(\"SQL_USERNAME:\", process.env.SQL_USERNAME);
    console.log(\"SQL_PASSWORD length:\", process.env.SQL_PASSWORD ? process.env.SQL_PASSWORD.length : 0);
    console.log(\"SQL_PASSWORD (first 3 chars):\", process.env.SQL_PASSWORD ? process.env.SQL_PASSWORD.substring(0, 3) : \"none\");
    
    const sql = require(\"mssql\");
    const config = {
        server: process.env.SQL_SERVER || \"localhost\",
        port: parseInt(process.env.SQL_PORT) || 1433,
        database: process.env.SQL_DATABASE || \"VMuruganGoldTrading\",
        user: process.env.SQL_USERNAME || \"sa\",
        password: process.env.SQL_PASSWORD,
        options: { encrypt: false, trustServerCertificate: true }
    };
    console.log(\"\nTesting connection with dotenv config...\");
    sql.connect(config).then(() => {
        console.log(\"✅ Success!\");
        sql.close();
    }).catch(err => {
        console.log(\"❌ Failed:\", err.message);
    });
    "
'
