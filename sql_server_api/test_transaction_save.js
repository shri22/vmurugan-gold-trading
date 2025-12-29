// Test script to simulate transaction save
// Run: node test_transaction_save.js

const https = require('https');

const testData = {
    transaction_id: 'TEST_' + Date.now(),
    customer_phone: '9715569313',
    customer_name: 'Test Customer',
    type: 'BUY',
    amount: 1000,
    payment_method: 'UPI',
    status: 'SUCCESS',
    gateway_transaction_id: 'GATEWAY_TEST_123'
};

// Test WITHOUT token (should fail with 401)
console.log('🧪 TEST 1: Transaction save WITHOUT token');
console.log('Expected: 401 Unauthorized');
console.log('='.repeat(60));

const options1 = {
    hostname: 'api.vmuruganjewellery.co.in',
    port: 3001,
    path: '/api/transactions',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    rejectUnauthorized: false
};

const req1 = https.request(options1, (res) => {
    console.log(`Status: ${res.statusCode}`);

    let data = '';
    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log('Response:', data);
        console.log('\n');

        // Test WITH token (should succeed)
        console.log('🧪 TEST 2: Transaction save WITH valid token');
        console.log('You need to get a real token from login first');
        console.log('='.repeat(60));
        console.log('To get token:');
        console.log('1. Login via app');
        console.log('2. Check app logs for: "✅ AuthService: Backend JWT token saved"');
        console.log('3. Copy the token');
        console.log('4. Add it to this script and run again');
    });
});

req1.on('error', (e) => {
    console.error('❌ Error:', e.message);
});

req1.write(JSON.stringify(testData));
req1.end();
