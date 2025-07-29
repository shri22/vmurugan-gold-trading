import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/config/sms_config.dart';
import '../../../core/services/firebase_phone_auth_service.dart';
import '../../../core/config/firebase_init.dart';

/// SMS Debug Screen for testing SMS configuration and sending test OTPs
class SmsDebugScreen extends StatefulWidget {
  const SmsDebugScreen({super.key});

  @override
  State<SmsDebugScreen> createState() => _SmsDebugScreenState();
}

class _SmsDebugScreenState extends State<SmsDebugScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _configStatus;
  Map<String, dynamic>? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfigStatus();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _loadConfigStatus() {
    setState(() {
      _configStatus = SmsService.getProviderInfo();
    });
  }

  Future<void> _testConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SmsService.testConfiguration();
      setState(() {
        _testResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'message': 'Test failed: $e',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final otp = _otpController.text.trim().isEmpty ? '123456' : _otpController.text.trim();
      final result = await SmsService.sendOtp(_phoneController.text.trim(), otp);

      setState(() {
        _testResult = result;
        _isLoading = false;
      });

      if (result['success'] == true) {
        _showSuccess('Test OTP sent successfully!');
      } else {
        _showError('Failed to send OTP: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'message': 'Send failed: $e',
        };
        _isLoading = false;
      });
      _showError('Error sending OTP: $e');
    }
  }

  Future<void> _testFirebaseOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebasePhoneAuthService.sendOTP(_phoneController.text.trim());

      setState(() {
        _testResult = result;
        _isLoading = false;
      });

      if (result['success'] == true) {
        _showSuccess('🔥 Firebase OTP sent successfully! Check your SMS.');
      } else {
        _showError('Firebase OTP failed: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'message': 'Firebase test failed: $e',
        };
        _isLoading = false;
      });
      _showError('Firebase error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('SMS Configuration & Testing'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.getWidth(context) * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Status
            _buildConfigurationStatus(),
            
            const SizedBox(height: 24),
            
            // Test Configuration
            _buildTestConfiguration(),
            
            const SizedBox(height: 24),
            
            // Send Test OTP
            _buildSendTestOtp(),
            
            const SizedBox(height: 24),
            
            // Test Results
            if (_testResult != null) _buildTestResults(),
            
            const SizedBox(height: 24),
            
            // Setup Instructions
            _buildSetupInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'SMS Configuration Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_configStatus != null) ...[
            _buildStatusRow('Current Provider', _configStatus!['provider']),
            _buildStatusRow('Configured', _configStatus!['configured'] ? 'Yes' : 'No'),
            _buildStatusRow('Firebase Status', FirebaseInit.isInitialized ? 'Ready' : 'Not Initialized'),

            const SizedBox(height: 16),
            
            Text(
              'Available Providers:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ...(_configStatus!['providers'] as Map<String, dynamic>).entries.map(
              (entry) => _buildProviderRow(entry.key, entry.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRow(String key, Map<String, dynamic> provider) {
    final isConfigured = provider['configured'] as bool;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isConfigured ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConfigured ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.warning,
            color: isConfigured ? AppColors.success : AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${provider['name']} (${provider['region']})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            isConfigured ? 'Ready' : 'Not Configured',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isConfigured ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestConfiguration() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Test Configuration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Test if your SMS provider is properly configured and ready to send messages.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: _isLoading ? 'Testing...' : 'Test Configuration',
              onPressed: _isLoading ? null : _testConfiguration,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendTestOtp() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.send,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Send Test OTP',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _phoneController,
            hint: 'Enter phone number (e.g., 9715569313)',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _otpController,
            hint: 'Custom OTP (optional, default: 123456)',
            prefixIcon: Icons.lock,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _isLoading ? 'Sending...' : 'Send Custom OTP',
                  onPressed: _isLoading ? null : _sendTestOtp,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: _isLoading ? 'Sending...' : '🔥 Firebase OTP',
                  onPressed: _isLoading ? null : _testFirebaseOtp,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    final isSuccess = _testResult!['success'] == true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Test Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _testResult!['message'] ?? 'No message',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          if (_testResult!['provider'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Provider: ${_testResult!['provider']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          
          if (_testResult!['messageId'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Message ID: ${_testResult!['messageId']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Setup Instructions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Text(
              SmsConfig.getSetupInstructions(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Configuration File: lib/core/config/sms_config.dart',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
