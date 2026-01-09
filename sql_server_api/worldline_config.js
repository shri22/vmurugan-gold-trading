/**
 * Worldline Payment Gateway Configuration
 * Production credentials for V Murugan Jewellery
 * 
 * Two separate merchant accounts:
 * - Gold Merchant (779285): For Gold Plus and Gold Flexi schemes
 * - Silver Merchant (779295): For Silver Plus and Silver Flexi schemes
 */

// Environment: PRODUCTION or TEST
const ENVIRONMENT = process.env.WORLDLINE_ENVIRONMENT || 'PRODUCTION';

// Gold Merchant Configuration (779285)
const GOLD_MERCHANT_CONFIG = {
  MERCHANT_NAME: 'V MURUGAN JEWELLERY',
  MERCHANT_CODE: '779285',
  SCHEME_CODE: 'first',
  API_KEY: 'e2b108a7-1ea4-4cc7-89d9-3ba008dfc334',
  SALT: '47cdd26963f53e3181f93adcf3af487ec28d7643',
  EMAIL: 'sellamuthu19661234@gmail.com',
};

// Silver Merchant Configuration (779295)
const SILVER_MERCHANT_CONFIG = {
  MERCHANT_NAME: 'V MURUGAN NAGAI KADAI',
  MERCHANT_CODE: '779295',
  SCHEME_CODE: 'first',
  API_KEY: 'f1f7f413-3826-4980-ad4d-c22f64ad54d3',
  SALT: '5ea7c9cb63d933192ac362722d6346e1efa67f7f',
  EMAIL: 'gopinath24949991@gmail.com',
};

// Test/UAT Merchant Configuration (for development)
const TEST_MERCHANT_CONFIG = {
  MERCHANT_NAME: 'TEST MERCHANT',
  MERCHANT_CODE: 'T1098761',
  SCHEME_CODE: 'first',
  API_KEY: '9221995309QQNRIO',
  SALT: '9221995309QQNRIO',
  EMAIL: 'test@vmuruganjewellery.co.in',
};

// Master Domain from env or default
const MASTER_DOMAIN = process.env.DOMAIN_NAME || 'prodapi.vmuruganjewellery.co.in';

// Common Worldline Configuration
const WORLDLINE_COMMON_CONFIG = {
  // Payment Gateway URL (same for production and test)
  PAYMENT_URL: 'https://www.paynimo.com/api/paynimoV2.req',

  // Return URLs (Dynamically built)
  RETURN_URL: `https://${MASTER_DOMAIN}:3001/api/payments/worldline/verify`,
  CANCEL_URL: `https://${MASTER_DOMAIN}:3001/api/payments/worldline/cancel`,

  // Currency
  CURRENCY: 'INR',

  // Payment Methods (all enabled)
  PAYMENT_METHODS: {
    CREDIT_CARD: true,
    DEBIT_CARD: true,
    NET_BANKING: true,
    UPI: true,
    WALLETS: true,
  },

  // Transaction Settings
  TRANSACTION_TIMEOUT: 900, // 15 minutes in seconds
  MIN_AMOUNT: 1,
  MAX_AMOUNT: 1000000, // 10 lakhs

  // Device ID for hash generation
  DEVICE_ID: 'ANDROIDSH2',
};

/**
 * Get merchant configuration based on metal type
 * @param {string} metalType - 'gold' or 'silver'
 * @returns {object} Merchant configuration
 */
function getMerchantConfig(metalType) {
  if (ENVIRONMENT === 'TEST') {
    console.log('⚠️ Using TEST merchant configuration');
    return TEST_MERCHANT_CONFIG;
  }

  const normalizedMetalType = (metalType || 'gold').toLowerCase();

  if (normalizedMetalType === 'silver') {
    console.log('✅ Using SILVER merchant (779295) for Silver schemes');
    return SILVER_MERCHANT_CONFIG;
  } else {
    console.log('✅ Using GOLD merchant (779285) for Gold schemes');
    return GOLD_MERCHANT_CONFIG;
  }
}

/**
 * Get complete Worldline configuration for a transaction
 * @param {string} metalType - 'gold' or 'silver'
 * @returns {object} Complete configuration object
 */
function getWorldlineConfig(metalType) {
  const merchantConfig = getMerchantConfig(metalType);

  return {
    ...WORLDLINE_COMMON_CONFIG,
    ...merchantConfig,
    ENVIRONMENT,
    IS_PRODUCTION: ENVIRONMENT === 'PRODUCTION',
    IS_TEST: ENVIRONMENT === 'TEST',
  };
}

/**
 * Validate merchant configuration
 * @param {string} metalType - 'gold' or 'silver'
 * @returns {boolean} True if configuration is valid
 */
function validateConfig(metalType) {
  const config = getMerchantConfig(metalType);

  const required = ['MERCHANT_CODE', 'SCHEME_CODE', 'API_KEY', 'SALT'];
  const missing = required.filter(key => !config[key]);

  if (missing.length > 0) {
    console.error(`❌ Missing required configuration: ${missing.join(', ')}`);
    return false;
  }

  console.log(`✅ Configuration validated for ${metalType} merchant`);
  return true;
}

module.exports = {
  ENVIRONMENT,
  GOLD_MERCHANT_CONFIG,
  SILVER_MERCHANT_CONFIG,
  TEST_MERCHANT_CONFIG,
  WORLDLINE_COMMON_CONFIG,
  getMerchantConfig,
  getWorldlineConfig,
  validateConfig,
};

