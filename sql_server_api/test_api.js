const axios = require('axios');

const BASE_URL = 'http://localhost:3001/api'; // Port 3001 as per server.js

async function runApiTests() {
    console.log('🧪 Starting API Health Check...');

    try {
        // 1. Test Customer Lookup (Public endpoint)
        // Using a known phone number for testing or a dummy one
        const testPhone = '9677944711';
        console.log(`📡 Testing Customer Lookup for: ${testPhone}`);
        const customerRes = await axios.get(`${BASE_URL}/customers/${testPhone}`);
        if (customerRes.status === 200 && customerRes.data.success) {
            console.log('✅ Customer API: PASS');
        } else {
            console.log('❌ Customer API: FAIL');
        }

        // 2. Test Schemes Endpoint (if exists)
        // Let's test the scheme details endpoint we recently fixed
        const testSchemeId = 'GF_P1';
        console.log(`📡 Testing Scheme Details for: ${testSchemeId}`);
        try {
            const schemeRes = await axios.get(`${BASE_URL}/schemes/details/${testSchemeId}`);
            if (schemeRes.status === 200) {
                console.log('✅ Scheme Details API: PASS');
            }
        } catch (e) {
            console.log('⚠️ Scheme Details API: FAILED (Expected if scheme ID is invalid)');
        }

        // 3. Test Gold Price Connectivity
        console.log('📡 Testing Gold Price Endpoint...');
        try {
            // Assuming you have an endpoint for live prices
            const priceRes = await axios.get(`${BASE_URL}/prices/gold/current`);
            if (priceRes.status === 200) {
                console.log('✅ Gold Price API: PASS');
            }
        } catch (e) {
            console.log('⚠️ Prices API: Not found or Offline');
        }

        console.log('✨ API Health Check Completed!');

    } catch (error) {
        console.error('❌ API Test Suite Error:', error.message);
    }
}

runApiTests();
