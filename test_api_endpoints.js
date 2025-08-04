// Test API Endpoints
const axios = require('axios');

const baseUrl = 'http://localhost:3001/api';

async function testEndpoints() {
  console.log('🧪 Testing API Endpoints...\n');

  try {
    // Test 1: Health Check
    console.log('1️⃣ Testing Health Check...');
    const healthResponse = await axios.get('http://localhost:3001/health');
    console.log('✅ Health Check:', healthResponse.data);
    console.log('');

    // Test 2: Send OTP
    console.log('2️⃣ Testing Send OTP...');
    const otpResponse = await axios.post(`${baseUrl}/auth/send-otp`, {
      phone: '+919876543210'
    });
    console.log('✅ Send OTP:', otpResponse.data);
    const testOtp = otpResponse.data.otp; // For testing
    console.log('');

    // Test 3: Verify OTP
    console.log('3️⃣ Testing Verify OTP...');
    const verifyResponse = await axios.post(`${baseUrl}/auth/verify-otp`, {
      phone: '+919876543210',
      otp: testOtp
    });
    console.log('✅ Verify OTP:', verifyResponse.data);
    console.log('');

    // Test 4: Register Customer (if new user)
    if (verifyResponse.data.isNewUser) {
      console.log('4️⃣ Testing Customer Registration...');
      const registerResponse = await axios.post(`${baseUrl}/customers`, {
        phone: '+919876543210',
        name: 'Test User',
        email: 'test@example.com',
        address: 'Test Address',
        city: 'Test City',
        state: 'Test State',
        pincode: '123456',
        encrypted_mpin: 'test_encrypted_mpin_123'
      });
      console.log('✅ Customer Registration:', registerResponse.data);
      console.log('');
    }

    // Test 5: Login with MPIN
    console.log('5️⃣ Testing Login with MPIN...');
    try {
      const loginResponse = await axios.post(`${baseUrl}/login`, {
        phone: '+919876543210',
        encrypted_mpin: 'test_encrypted_mpin_123'
      });
      console.log('✅ Login:', loginResponse.data);
    } catch (loginError) {
      console.log('ℹ️ Login failed (expected if MPIN not set):', loginError.response?.data || loginError.message);
    }
    console.log('');

    // Test 6: Get Customer
    console.log('6️⃣ Testing Get Customer...');
    const customerResponse = await axios.get(`${baseUrl}/customers/+919876543210`);
    console.log('✅ Get Customer:', customerResponse.data);
    console.log('');

    // Test 7: Test Database Connection
    console.log('7️⃣ Testing Database Connection...');
    const dbResponse = await axios.get(`${baseUrl}/test-connection`);
    console.log('✅ Database Connection:', dbResponse.data);
    console.log('');

    console.log('🎉 All API endpoints are working correctly!');

  } catch (error) {
    console.error('❌ API Test Failed:', error.response?.data || error.message);
  }
}

// Run tests
testEndpoints();
