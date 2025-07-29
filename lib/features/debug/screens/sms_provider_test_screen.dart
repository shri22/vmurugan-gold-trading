import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/config/sms_config.dart';

/// SMS Provider Testing Screen
/// Test different SMS providers easily
class SmsProviderTestScreen extends StatefulWidget {
  const SmsProviderTestScreen({super.key});

  @override
  State<SmsProviderTestScreen> createState() => _SmsProviderTestScreenState();
}

class _SmsProviderTestScreenState extends State<SmsProviderTestScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _lastResult = '';
  String _generatedOtp = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _testMSG91() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = 'Testing MSG91...';
    });

    try {
      // Generate OTP
      final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      _generatedOtp = otp;

      // Test MSG91 SMS
      final result = await SmsService.sendOtp(_phoneController.text.trim(), otp);
      
      setState(() {
        _lastResult = '''
✅ MSG91 Test Result:
📱 Phone: ${_phoneController.text.trim()}
🔐 OTP: $otp
📊 Success: ${result['success']}
📝 Message: ${result['message']}
🆔 Message ID: ${result['messageId'] ?? 'N/A'}
🔧 Provider: ${result['provider'] ?? 'N/A'}

🔍 Debug Info:
📋 Auth Key: ${SmsConfig.msg91ApiKey.substring(0, 8)}...
📤 Sender ID: ${SmsConfig.msg91SenderId}
📞 Phone Format: +91${_phoneController.text.trim()}
        ''';
      });

      if (result['success'] == true) {
        _showSuccess('SMS sent successfully! Check your phone.');
      } else {
        _showError('SMS failed: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _lastResult = '❌ MSG91 Error: $e';
      });
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDemo() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate demo OTP
      final otp = '1234'; // Fixed demo OTP
      _generatedOtp = otp;

      setState(() {
        _lastResult = '''
🎭 Demo Mode Result:
📱 Phone: ${_phoneController.text.trim()}
🔐 Demo OTP: $otp
✅ Status: Success (Demo)
📝 Note: Use this OTP to test the flow
        ''';
      });

      _showSuccess('Demo OTP generated: $otp');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Provider Testing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Configuration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚙️ Current Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Provider: ${SmsConfig.provider}'),
                  Text('MSG91 Auth Key: ${SmsConfig.msg91ApiKey.contains("YOUR_MSG91") ? "❌ Not Set" : "✅ Configured"}'),
                  Text('Sender ID: ${SmsConfig.msg91SenderId}'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Phone Input
            CustomTextField(
              controller: _phoneController,
              hint: 'Enter phone number (10 digits)',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 24),
            
            // Test Buttons
            Text(
              '🧪 Test SMS Providers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // MSG91 Test
            CustomButton(
              text: 'Test MSG91 SMS',
              onPressed: _isLoading ? null : _testMSG91,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
            
            const SizedBox(height: 12),
            
            // Demo Test
            CustomButton(
              text: 'Test Demo Mode',
              onPressed: _isLoading ? null : _testDemo,
              isFullWidth: true,
            ),
            
            const SizedBox(height: 24),
            
            // Results
            if (_lastResult.isNotEmpty) ...[
              Text(
                '📊 Test Results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _lastResult,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Setup Instructions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Sign up at msg91.com\n'
                    '2. Get your API key from dashboard\n'
                    '3. Update SmsConfig.msg91ApiKey\n'
                    '4. Test with your phone number\n'
                    '5. Use Demo Mode for immediate testing',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
