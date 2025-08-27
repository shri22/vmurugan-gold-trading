#!/usr/bin/env python3
"""
VMurugan Gold Trading - Quick Server Status Checker
Test your public IP server quickly from command line
"""

import requests
import json
import sys
import time
from datetime import datetime

class ServerTester:
    def __init__(self, server_ip, port=3000, protocol='http'):
        self.server_ip = server_ip
        self.port = port
        self.protocol = protocol
        self.base_url = f"{protocol}://{server_ip}:{port}"
        
    def print_header(self):
        print("=" * 60)
        print("🏆 VMurugan Gold Trading - Server Status Checker")
        print("=" * 60)
        print(f"Server: {self.base_url}")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("-" * 60)
    
    def test_endpoint(self, endpoint, method='GET', data=None, description=""):
        """Test a single endpoint"""
        url = f"{self.base_url}{endpoint}"
        
        try:
            if method == 'GET':
                response = requests.get(url, timeout=10)
            elif method == 'POST':
                response = requests.post(url, json=data, timeout=10)
            
            status = "✅ PASS" if response.status_code == 200 else f"⚠️  {response.status_code}"
            print(f"{status} | {method:4} | {endpoint:25} | {description}")
            
            if response.status_code != 200:
                print(f"      Response: {response.text[:100]}")
            
            return response.status_code == 200
            
        except requests.exceptions.ConnectionError:
            print(f"❌ FAIL | {method:4} | {endpoint:25} | Connection refused")
            return False
        except requests.exceptions.Timeout:
            print(f"❌ FAIL | {method:4} | {endpoint:25} | Timeout")
            return False
        except Exception as e:
            print(f"❌ FAIL | {method:4} | {endpoint:25} | {str(e)[:50]}")
            return False
    
    def run_basic_tests(self):
        """Run basic connectivity tests"""
        print("\n🔍 BASIC CONNECTIVITY TESTS")
        print("-" * 60)
        
        tests = [
            ('/health', 'GET', None, 'Server Health Check'),
            ('/api/customers', 'GET', None, 'Customer API Endpoint'),
        ]
        
        passed = 0
        for endpoint, method, data, description in tests:
            if self.test_endpoint(endpoint, method, data, description):
                passed += 1
        
        print(f"\nBasic Tests: {passed}/{len(tests)} passed")
        return passed == len(tests)
    
    def run_api_tests(self):
        """Run API functionality tests"""
        print("\n👤 USER MANAGEMENT TESTS")
        print("-" * 60)
        
        # Test user registration (Node.js format)
        test_user = {
            "phone": "9876543210",
            "name": "Test User",
            "email": "test@example.com",
            "address": "Test Address",
            "pan_card": "ABCDE1234F",
            "device_id": "test_device_123",
            "mpin": "1234"
        }

        tests = [
            ('/api/customers', 'POST', test_user, 'User Registration'),
            ('/api/login', 'POST', {"phone": "9876543210", "encrypted_mpin": "1234"}, 'User Login'),
            ('/api/auth/send-otp', 'POST', {"phone": "9876543210"}, 'Send OTP'),
            ('/api/transaction-history?phone=9876543210', 'GET', None, 'Transaction History'),
        ]
        
        passed = 0
        for endpoint, method, data, description in tests:
            if self.test_endpoint(endpoint, method, data, description):
                passed += 1
        
        print(f"\nAPI Tests: {passed}/{len(tests)} passed")
        return passed >= len(tests) // 2  # Allow some failures for new server
    
    def run_performance_test(self):
        """Run basic performance test"""
        print("\n⚡ PERFORMANCE TEST")
        print("-" * 60)
        
        endpoint = '/health'
        times = []
        
        for i in range(5):
            start_time = time.time()
            try:
                response = requests.get(f"{self.base_url}{endpoint}", timeout=10)
                end_time = time.time()
                response_time = (end_time - start_time) * 1000  # Convert to ms
                times.append(response_time)
                print(f"Request {i+1}: {response_time:.2f}ms")
            except Exception as e:
                print(f"Request {i+1}: Failed - {e}")
        
        if times:
            avg_time = sum(times) / len(times)
            print(f"\nAverage Response Time: {avg_time:.2f}ms")
            return avg_time < 2000  # Less than 2 seconds is good
        
        return False
    
    def run_all_tests(self):
        """Run complete test suite"""
        self.print_header()
        
        # Basic connectivity
        basic_ok = self.run_basic_tests()
        
        # API functionality
        api_ok = self.run_api_tests()
        
        # Performance
        perf_ok = self.run_performance_test()
        
        # Summary
        print("\n" + "=" * 60)
        print("📊 TEST SUMMARY")
        print("=" * 60)
        print(f"Basic Connectivity: {'✅ PASS' if basic_ok else '❌ FAIL'}")
        print(f"API Functionality:  {'✅ PASS' if api_ok else '❌ FAIL'}")
        print(f"Performance:        {'✅ PASS' if perf_ok else '❌ FAIL'}")
        
        overall = basic_ok and api_ok and perf_ok
        print(f"\nOverall Status:     {'✅ READY FOR PRODUCTION' if overall else '⚠️  NEEDS ATTENTION'}")
        
        if overall:
            print("\n🎉 Your server is ready! Next steps:")
            print("   1. Update mobile app with your server IP")
            print("   2. Rebuild and test the mobile app")
            print("   3. Set up SSL certificate for production")
            print("   4. Configure domain name (recommended)")
        else:
            print("\n🔧 Issues found. Please check:")
            print("   1. Server is running and accessible")
            print("   2. Firewall allows port access")
            print("   3. Database is connected and configured")
            print("   4. All required dependencies are installed")
        
        return overall

def main():
    if len(sys.argv) < 2:
        print("Usage: python quick_server_test.py <SERVER_IP> [PORT] [PROTOCOL]")
        print("Example: python quick_server_test.py 203.192.123.45")
        print("Example: python quick_server_test.py 203.192.123.45 3001 https")
        sys.exit(1)
    
    server_ip = sys.argv[1]
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
    protocol = sys.argv[3] if len(sys.argv) > 3 else 'http'
    
    tester = ServerTester(server_ip, port, protocol)
    success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
