// Simple Login Test
const axios = require('axios');

const baseUrl = 'http://localhost:3001/api';

async function testLogin() {
  console.log('🔐 Testing Login Flow...\n');

  try {
    const testPhone = '+919876543210';
    
    // Step 1: Send OTP
    console.log('📱 Step 1: Sending OTP...');
    const otpResponse = await axios.post(`${baseUrl}/auth/send-otp`, {
      phone: testPhone
    });
    console.log('Response:', otpResponse.data);
    
    if (!otpResponse.data.success) {
      throw new Error('Failed to send OTP');
    }
    
    const otp = otpResponse.data.otp;
    console.log(`Generated OTP: ${otp}\n`);
    
    // Step 2: Verify OTP immediately
    console.log('✅ Step 2: Verifying OTP...');
    const verifyResponse = await axios.post(`${baseUrl}/auth/verify-otp`, {
      phone: testPhone,
      otp: otp
    });
    console.log('Response:', verifyResponse.data);
    
    if (verifyResponse.data.success) {
      console.log('🎉 Login flow working correctly!');
      
      if (verifyResponse.data.isNewUser) {
        console.log('👤 New user detected - registration flow would continue');
      } else {
        console.log('👤 Existing user - login successful');
      }
    } else {
      console.log('❌ OTP verification failed');
    }
    
  } catch (error) {
    console.error('❌ Test Failed:', error.response?.data || error.message);
    
    // Additional debugging
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
    }
  }
}

// Run test
testLogin();
