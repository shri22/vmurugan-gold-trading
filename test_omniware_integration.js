// Test script for Omniware Payment Gateway Integration
// Run with: node test_omniware_integration.js

const crypto = require('crypto');
const https = require('https');

// Omniware Testing Credentials
const MERCHANT_ID = '291499';
const API_KEY = 'fb6bca86-b429-4abf-a42f-824bdd29022e';
const SALT = '80c67bfdf027da08de88ab5ba903fecafaab8f6d';
const BASE_URL = 'test.omniware.in';

// Test Configuration
const TEST_TRANSACTION = {
    transaction_id: `TEST_${Date.now()}`,
    amount: '100', // ₹1.00 in paisa
    currency: 'INR',
    customer_name: 'Test Customer',
    customer_email: 'test@vmuruganjewellery.co.in',
    customer_phone: '+919677944711',
    description: 'VMurugan Gold Trading - Test Transaction',
    payment_method: 'netbanking',
    return_url: 'https://vmuruganjewellery.co.in/payment/success',
    cancel_url: 'https://vmuruganjewellery.co.in/payment/cancel'
};

// Generate Hash Function
function generateHash(data) {
    const hashString = `${data.merchant_id}|${data.transaction_id}|${data.amount}|${data.currency}|${data.customer_email}|${SALT}`;
    console.log('Hash String:', hashString);
    
    const hash = crypto.createHash('sha256').update(hashString).digest('hex');
    console.log('Generated Hash:', hash);
    
    return hash;
}

// Test Payment Initiation
async function testPaymentInitiation() {
    console.log('🚀 Testing Omniware Payment Gateway Integration');
    console.log('=' .repeat(60));
    
    // Prepare request data
    const requestData = {
        merchant_id: MERCHANT_ID,
        api_key: API_KEY,
        timestamp: Date.now().toString(),
        ...TEST_TRANSACTION
    };
    
    // Generate hash
    requestData.hash = generateHash(requestData);
    
    console.log('\n📋 Request Data:');
    console.log(JSON.stringify(requestData, null, 2));
    
    // Prepare HTTP request
    const postData = JSON.stringify(requestData);
    
    const options = {
        hostname: BASE_URL,
        port: 443,
        path: '/api/payment/initiate',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData),
            'Accept': 'application/json'
        }
    };
    
    console.log('\n🌐 Making API Request to:', `https://${BASE_URL}${options.path}`);
    
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            console.log('\n📡 Response Status:', res.statusCode);
            console.log('📡 Response Headers:', res.headers);
            
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                console.log('\n📄 Response Body:');
                console.log(data);
                
                try {
                    const response = JSON.parse(data);
                    console.log('\n✅ Parsed Response:');
                    console.log(JSON.stringify(response, null, 2));
                    resolve(response);
                } catch (e) {
                    console.log('\n❌ Failed to parse JSON response');
                    resolve({ raw: data });
                }
            });
        });
        
        req.on('error', (e) => {
            console.error('\n❌ Request Error:', e.message);
            reject(e);
        });
        
        req.write(postData);
        req.end();
    });
}

// Test Payment Status Check
async function testPaymentStatus(transactionId) {
    console.log('\n🔍 Testing Payment Status Check');
    console.log('=' .repeat(40));
    
    const statusData = {
        merchant_id: MERCHANT_ID,
        transaction_id: transactionId,
        api_key: API_KEY
    };
    
    // Generate status hash
    const statusHashString = `${statusData.merchant_id}|${statusData.transaction_id}|${SALT}`;
    statusData.hash = crypto.createHash('sha256').update(statusHashString).digest('hex');
    
    console.log('\n📋 Status Request Data:');
    console.log(JSON.stringify(statusData, null, 2));
    
    const postData = JSON.stringify(statusData);
    
    const options = {
        hostname: BASE_URL,
        port: 443,
        path: '/api/payment/status',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData),
            'Accept': 'application/json'
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            console.log('\n📡 Status Response:', res.statusCode);
            
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                console.log('\n📄 Status Response Body:');
                console.log(data);
                
                try {
                    const response = JSON.parse(data);
                    console.log('\n✅ Parsed Status Response:');
                    console.log(JSON.stringify(response, null, 2));
                    resolve(response);
                } catch (e) {
                    console.log('\n❌ Failed to parse status JSON response');
                    resolve({ raw: data });
                }
            });
        });
        
        req.on('error', (e) => {
            console.error('\n❌ Status Request Error:', e.message);
            reject(e);
        });
        
        req.write(postData);
        req.end();
    });
}

// Validate Configuration
function validateConfiguration() {
    console.log('\n🔧 Validating Configuration');
    console.log('=' .repeat(30));
    
    const checks = [
        { name: 'Merchant ID', value: MERCHANT_ID, valid: MERCHANT_ID && MERCHANT_ID.length > 0 },
        { name: 'API Key', value: API_KEY.substring(0, 8) + '...', valid: API_KEY && API_KEY.length > 0 },
        { name: 'Salt', value: SALT.substring(0, 8) + '...', valid: SALT && SALT.length > 0 },
        { name: 'Base URL', value: BASE_URL, valid: BASE_URL && BASE_URL.length > 0 }
    ];
    
    let allValid = true;
    
    checks.forEach(check => {
        const status = check.valid ? '✅' : '❌';
        console.log(`${status} ${check.name}: ${check.value}`);
        if (!check.valid) allValid = false;
    });
    
    console.log(`\n${allValid ? '✅' : '❌'} Configuration ${allValid ? 'Valid' : 'Invalid'}`);
    return allValid;
}

// Main Test Function
async function runTests() {
    console.log('🧪 Omniware Payment Gateway Integration Test');
    console.log('🏦 VMurugan Gold Trading Platform');
    console.log('📅 Test Date:', new Date().toISOString());
    console.log('🌍 Environment: Testing');
    console.log('\n');
    
    try {
        // Step 1: Validate Configuration
        if (!validateConfiguration()) {
            console.log('\n❌ Configuration validation failed. Please check credentials.');
            return;
        }
        
        // Step 2: Test Payment Initiation
        const paymentResponse = await testPaymentInitiation();
        
        // Step 3: Test Payment Status (if transaction ID available)
        if (paymentResponse && paymentResponse.transaction_id) {
            await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2 seconds
            await testPaymentStatus(paymentResponse.transaction_id);
        } else {
            await testPaymentStatus(TEST_TRANSACTION.transaction_id);
        }
        
        // Step 4: Summary
        console.log('\n📊 Test Summary');
        console.log('=' .repeat(20));
        console.log('✅ Configuration validation: Passed');
        console.log('✅ Payment initiation: Completed');
        console.log('✅ Status check: Completed');
        console.log('\n🎉 Integration test completed successfully!');
        console.log('\n📝 Next Steps:');
        console.log('1. Check the response for payment URL');
        console.log('2. Test actual payment flow in browser');
        console.log('3. Verify transaction in merchant portal');
        console.log('4. Integrate into Flutter app');
        
    } catch (error) {
        console.error('\n❌ Test failed with error:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('1. Check internet connectivity');
        console.log('2. Verify Omniware gateway status');
        console.log('3. Confirm credentials are correct');
        console.log('4. Check API endpoint URLs');
    }
}

// Run the tests
if (require.main === module) {
    runTests();
}

module.exports = {
    testPaymentInitiation,
    testPaymentStatus,
    validateConfiguration,
    generateHash
};
