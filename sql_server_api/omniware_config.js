/**
 * OMNIWARE PAYMENT GATEWAY CONFIGURATION
 * 
 * This file contains the merchant credentials for Omniware payment gateway.
 * We have two separate merchant accounts:
 * - Gold Merchant (779285): For Gold Plus and Gold Flexi schemes
 * - Silver Merchant (779295): For Silver Plus and Silver Flexi schemes
 */

const crypto = require('crypto');

// Environment configuration
const ENVIRONMENT = 'PRODUCTION'; // 'TEST' or 'PRODUCTION'

// Gold Merchant Configuration
const GOLD_MERCHANT = {
    name: 'V MURUGAN JEWELLERY',
    merchantId: '779285',
    apiKey: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
    salt: '47cdd26963f53e3181f93adcf3af487ec28d7643',
    email: 'sellamuthu19661234@gmail.com'
};

// Silver Merchant Configuration
const SILVER_MERCHANT = {
    name: 'V MURUGAN NAGAI KADAI',
    merchantId: '779295',
    apiKey: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
    salt: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
    email: 'gopinath24949991@gmail.com'
};

// Common Configuration
const COMMON_CONFIG = {
    currency: 'INR',
    country: 'IND',
    returnUrl: 'https://vmuruganjewellery.co.in/payment/success',
    returnUrlFailure: 'https://vmuruganjewellery.co.in/payment/failure',
    returnUrlCancel: 'https://vmuruganjewellery.co.in/payment/cancel',
    // NOTE: Replace {pg_api_url} with actual Omniware API URL when provided
    apiBaseUrl: 'https://{pg_api_url}' // PLACEHOLDER - Get actual URL from Omniware team
};

/**
 * Get merchant configuration based on metal type
 * @param {string} metalType - 'gold' or 'silver'
 * @returns {object} Merchant configuration
 */
function getMerchantConfig(metalType) {
    const normalizedType = (metalType || 'gold').toLowerCase();
    
    if (normalizedType === 'silver') {
        return SILVER_MERCHANT;
    }
    
    // Default to Gold merchant
    return GOLD_MERCHANT;
}

/**
 * Generate SHA-512 hash for Omniware payment request
 * Hash calculation: SHA-512(SALT|param1|param2|param3...) - alphabetically sorted
 * 
 * @param {object} params - Payment parameters
 * @param {string} salt - Merchant SALT
 * @returns {string} Uppercase SHA-512 hash
 */
function generateHash(params, salt) {
    // Sort parameters alphabetically by key
    const sortedKeys = Object.keys(params).sort();
    
    // Create pipe-delimited string: SALT|value1|value2|value3...
    const hashString = salt + '|' + sortedKeys.map(key => params[key]).join('|');
    
    console.log('🔐 Hash String:', hashString);
    
    // Generate SHA-512 hash
    const hash = crypto.createHash('sha512').update(hashString).digest('hex');
    
    // Convert to uppercase
    return hash.toUpperCase();
}

/**
 * Verify hash from Omniware response
 * @param {object} params - Response parameters
 * @param {string} receivedHash - Hash received from Omniware
 * @param {string} salt - Merchant SALT
 * @returns {boolean} True if hash is valid
 */
function verifyHash(params, receivedHash, salt) {
    const calculatedHash = generateHash(params, salt);
    return calculatedHash === receivedHash.toUpperCase();
}

/**
 * Build payment request parameters
 * @param {object} paymentData - Payment data from Flutter app
 * @param {string} metalType - 'gold' or 'silver'
 * @returns {object} Payment request parameters
 */
function buildPaymentRequest(paymentData, metalType) {
    const merchant = getMerchantConfig(metalType);
    
    const params = {
        api_key: merchant.apiKey,
        order_id: paymentData.orderId,
        mode: ENVIRONMENT === 'PRODUCTION' ? 'LIVE' : 'TEST',
        amount: paymentData.amount.toFixed(2),
        currency: COMMON_CONFIG.currency,
        description: paymentData.description,
        name: paymentData.customer.name,
        email: paymentData.customer.email,
        phone: paymentData.customer.phone,
        city: paymentData.customer.city,
        state: paymentData.customer.state || 'Tamil Nadu',
        country: COMMON_CONFIG.country,
        zip_code: paymentData.customer.zipcode,
        return_url: COMMON_CONFIG.returnUrl
    };
    
    // Add optional address fields if provided
    if (paymentData.customer.address) {
        params.address_line_1 = paymentData.customer.address;
    }
    
    // Generate hash
    params.hash = generateHash(params, merchant.salt);
    
    return params;
}

module.exports = {
    ENVIRONMENT,
    GOLD_MERCHANT,
    SILVER_MERCHANT,
    COMMON_CONFIG,
    getMerchantConfig,
    generateHash,
    verifyHash,
    buildPaymentRequest
};

