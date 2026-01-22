const axios = require('axios');
const crypto = require('crypto');

const OMNIWARE_API_URL = 'https://pgbiz.omniware.in';
const merchant = {
    merchantId: '779285',
    apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
    salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
    name: 'V MURUGAN JEWELLERY'
};

function generateHash(params, salt) {
    const sortedKeys = Object.keys(params).sort();
    let hashString = salt;
    sortedKeys.forEach(key => {
        const value = params[key];
        if (value !== null && value !== undefined && value !== '') {
            hashString += '|' + String(value).trim();
        }
    });
    return crypto.createHash('sha512').update(hashString).digest('hex').toUpperCase();
}

async function testSettlementDetails() {
    console.log('\n🔍 Testing Omniware Settlement Details API (Section 10.2)...');

    // Testing for Jan 2nd, 2026 based on bank response
    // Logic: Use date_from and date_to in DD-MM-YYYY format
    const params = {
        api_key: merchant.apiKey,
        date_from: '01-01-2026',
        date_to: '05-01-2026'
    };

    params.hash = generateHash(params, merchant.salt);

    console.log('📡 Request Endpoint:', `${OMNIWARE_API_URL}/v2/getsettlementdetails`);
    console.log('📡 Request Params:', JSON.stringify(params, null, 2));

    try {
        const response = await axios.post(
            `${OMNIWARE_API_URL}/v2/getsettlementdetails`,
            new URLSearchParams(params).toString(),
            {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                timeout: 30000
            }
        );

        console.log('\n✅ Response Status:', response.status);
        if (response.data.error) {
            console.log('❌ API Error:', JSON.stringify(response.data.error, null, 2));
        } else {
            console.log('📦 Data Received!');
            const data = response.data.data;
            if (Array.isArray(data)) {
                console.log(`📊 Found ${data.length} transactions.`);
                console.log('📝 Sample:', JSON.stringify(data[0], null, 2));

                const total = data.reduce((sum, item) => sum + parseFloat(item.gross_transaction_amount || 0), 0);
                console.log(`💰 Total Gross Amount: ₹${total.toFixed(2)}`);
            } else {
                console.log('📝 Raw Data:', JSON.stringify(data, null, 2));
            }
        }
    } catch (error) {
        console.error('\n❌ HTTP Error:', error.message);
    }
}

async function testSettlementSummary() {
    console.log('\n🔍 Testing Omniware Settlement Summary API (Section 10.1)...');

    const params = {
        api_key: merchant.apiKey,
        date_from: '01-01-2026',
        date_to: '05-01-2026'
    };

    params.hash = generateHash(params, merchant.salt);

    console.log('📡 Request Endpoint:', `${OMNIWARE_API_URL}/v2/getsettlements`);

    try {
        const response = await axios.post(
            `${OMNIWARE_API_URL}/v2/getsettlements`,
            new URLSearchParams(params).toString(),
            {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                timeout: 30000
            }
        );

        console.log('\n✅ Response Status:', response.status);
        console.log('📦 Data:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error('\n❌ HTTP Error:', error.message);
    }
}

async function run() {
    await testSettlementDetails();
    await testSettlementSummary();
}

run();
