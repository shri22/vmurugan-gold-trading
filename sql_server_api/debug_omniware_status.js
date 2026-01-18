
const axios = require('axios');
const crypto = require('crypto');

const OMNIWARE_CONFIG = {
    GOLD: {
        merchantId: '779285',
        apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
        salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
    },
    SILVER: {
        merchantId: '779295',
        apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
        salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
    }
};

function generateOmniwareHash(params, salt) {
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

async function checkStatus(orderId) {
    let metalType = 'GOLD';
    if (orderId.includes('_SILVER_')) metalType = 'SILVER';

    const config = OMNIWARE_CONFIG[metalType];
    const params = {
        api_key: config.apiKey,
        order_id: orderId
    };
    params.hash = generateOmniwareHash(params, config.salt);

    console.log('--- Request ---');
    console.log('Order ID:', orderId);
    console.log('Metal Type:', metalType);

    try {
        const response = await axios.post(
            'https://pgbiz.omniware.in/v2/paymentstatus',
            new URLSearchParams(params).toString(),
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );
        console.log('\n--- Response ---');
        console.log(JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error('\n--- Error ---');
        console.error(error.message);
        if (error.response) console.error(error.response.data);
    }
}

const orderId = process.argv[2] || 'ORD_1768370348005_GOLD_285';
checkStatus(orderId);
