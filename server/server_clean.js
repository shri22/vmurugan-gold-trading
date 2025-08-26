// VMurugan Gold Trading - Client Server
// Simple proxy server

const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

console.log('🚀 VMurugan Client Server Starting...');
console.log('📊 Port:', PORT);

// Middleware
app.use(cors({ origin: '*' }));
app.use(express.json());

// SQL Server API URL
const SQL_API_URL = process.env.SQL_API_URL || 'http://localhost:3001';
console.log('🔗 SQL API:', SQL_API_URL);

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        server: 'VMurugan Client Server',
        sql_api: SQL_API_URL
    });
});

// Proxy to SQL API
app.use('/api', async (req, res) => {
    try {
        const fetch = (await import('node-fetch')).default;
        const url = `${SQL_API_URL}${req.originalUrl}`;
        
        const options = {
            method: req.method,
            headers: { 'Content-Type': 'application/json' }
        };

        if (req.method !== 'GET' && req.method !== 'HEAD') {
            options.body = JSON.stringify(req.body);
        }

        console.log(`🔄 Proxy ${req.method} ${url}`);
        const response = await fetch(url, options);
        const data = await response.json();
        
        res.status(response.status).json(data);
    } catch (error) {
        console.error('❌ Proxy error:', error.message);
        res.status(500).json({
            error: 'Failed to connect to SQL API',
            message: error.message
        });
    }
});

// Admin portal
app.get('/admin', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>VMurugan Gold Trading - Admin</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                h1 { color: #d4af37; text-align: center; }
                .status { padding: 20px; border-radius: 5px; margin: 20px 0; }
                .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
                .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
                button { padding: 12px 24px; margin: 10px; background: #d4af37; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold; }
                button:hover { background: #b8941f; }
                #results { margin-top: 20px; padding: 20px; background: #f8f9fa; border-radius: 5px; border-left: 4px solid #d4af37; }
                pre { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; overflow-x: auto; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🏆 VMurugan Gold Trading - Admin Portal</h1>
                
                <div class="status success">
                    <h3>✅ System Status</h3>
                    <p><strong>Client Server:</strong> Running on port ${PORT}</p>
                    <p><strong>SQL Server API:</strong> ${SQL_API_URL}</p>
                    <p><strong>Database:</strong> SQL Server (MSSQLSERVER)</p>
                    <p><strong>Network IP:</strong> 192.168.1.200</p>
                    <p><strong>Public IP:</strong> 103.124.152.220</p>
                </div>
                
                <div class="status info">
                    <h3>🔗 API Endpoints</h3>
                    <p><strong>Health Check:</strong> <a href="/health" target="_blank">/health</a></p>
                    <p><strong>SQL API Health:</strong> <a href="/api/health" target="_blank">/api/health</a></p>
                    <p><strong>Database Test:</strong> <a href="/api/test-connection" target="_blank">/api/test-connection</a></p>
                </div>
                
                <div class="status info">
                    <h3>📱 Flutter App Configuration</h3>
                    <p><strong>Local Testing:</strong> http://192.168.1.200:${PORT}</p>
                    <p><strong>Production:</strong> http://103.124.152.220:${PORT}</p>
                </div>
                
                <h3>🧪 Quick Tests</h3>
                <button onclick="testHealth()">Test Health</button>
                <button onclick="testDatabase()">Test Database</button>
                <button onclick="testCustomer()">Test Customer API</button>
                
                <div id="results"></div>
            </div>
            
            <script>
                async function testHealth() {
                    showResult('Testing health...', 'info');
                    try {
                        const response = await fetch('/health');
                        const data = await response.json();
                        showResult('Health Check Result', JSON.stringify(data, null, 2), 'success');
                    } catch (error) {
                        showResult('Health Check Failed', error.message, 'error');
                    }
                }
                
                async function testDatabase() {
                    showResult('Testing database connection...', 'info');
                    try {
                        const response = await fetch('/api/test-connection');
                        const data = await response.json();
                        showResult('Database Test Result', JSON.stringify(data, null, 2), 'success');
                    } catch (error) {
                        showResult('Database Test Failed', error.message, 'error');
                    }
                }
                
                async function testCustomer() {
                    showResult('Testing customer API...', 'info');
                    try {
                        const response = await fetch('/api/customers/9876543210');
                        const data = await response.json();
                        showResult('Customer API Test', JSON.stringify(data, null, 2), response.ok ? 'success' : 'warning');
                    } catch (error) {
                        showResult('Customer API Test Failed', error.message, 'error');
                    }
                }
                
                function showResult(title, content, type = 'info') {
                    const colors = {
                        success: '#d4edda',
                        error: '#f8d7da',
                        warning: '#fff3cd',
                        info: '#d1ecf1'
                    };
                    
                    document.getElementById('results').innerHTML = 
                        '<h4>' + title + '</h4>' +
                        '<pre style="background: ' + colors[type] + '; color: #333;">' + content + '</pre>';
                }
            </script>
        </body>
        </html>
    `);
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log('🎉 VMurugan Client Server Running!');
    console.log(`🌐 Local: http://localhost:${PORT}`);
    console.log(`🌐 Network: http://192.168.1.200:${PORT}`);
    console.log(`🌐 Public: http://103.124.152.220:${PORT}`);
    console.log(`👨‍💼 Admin: http://localhost:${PORT}/admin`);
    console.log('✅ Ready!');
});

process.on('SIGINT', () => {
    console.log('🛑 Client server shutting down...');
    process.exit(0);
});
