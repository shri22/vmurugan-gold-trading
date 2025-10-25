import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../core/services/secure_http_client.dart';
import '../../../core/services/firebase_phone_auth_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/config/sql_server_config.dart';
import '../../../core/services/auth_service.dart';
import 'mpin_entry_screen.dart';
import 'customer_registration_screen.dart';

enum AuthStep {
  phoneEntry,
  otpVerification,
}

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // State variables
  AuthStep _currentStep = AuthStep.phoneEntry;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isRegisteredUser = false;
  String _phoneNumber = '';

  // OTP related
  bool _canResendOtp = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPhoneNumber() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    if (phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('📱 PhoneEntry: Checking phone number: $phone');

      // Check if phone number is registered
      final isRegistered = await AuthService.isPhoneRegistered(phone);

      if (mounted) {
        setState(() {
          _isRegisteredUser = isRegistered;
          _phoneNumber = phone;
          _isLoading = false;
        });

        print('📋 PhoneEntry: Phone $phone is ${isRegistered ? "registered" : "new"}');

        // Always send Firebase OTP regardless of registration status
        await _sendFirebaseOTP();
      }
    } catch (e) {
      print('❌ PhoneEntry: Phone check error: $e');
      if (mounted) {
        _showError('Network error. Please check your connection.');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendFirebaseOTP() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔥 PhoneEntry: Sending Firebase OTP to $_phoneNumber');

      // Send OTP using Firebase Phone Authentication
      final result = await FirebasePhoneAuthService.sendOTP(_phoneNumber);

      if (mounted) {
        if (result['success'] == true) {
          print('✅ PhoneEntry: Firebase OTP sent successfully');

          setState(() {
            _currentStep = AuthStep.otpVerification;
            _isLoading = false;
          });

          _startResendTimer();
          _showSuccess('OTP sent to +91 $_phoneNumber');
        } else {
          print('❌ PhoneEntry: Firebase OTP failed: ${result['message']}');
          _showError(result['message'] ?? 'Failed to send OTP. Please try again.');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ PhoneEntry: Firebase OTP error: $e');
      if (mounted) {
        _showError('Failed to send OTP. Please check your connection.');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otpCode = _getOTPCode();

    if (otpCode.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔐 PhoneEntry: Verifying OTP: $otpCode');

      // Verify OTP using Firebase
      final result = await FirebasePhoneAuthService.verifyOTP(otpCode);

      if (mounted) {
        if (result['success'] == true) {
          print('✅ PhoneEntry: OTP verified successfully');

          // Save phone number
          await AuthService.savePhoneNumber(_phoneNumber);

          setState(() {
            _isLoading = false;
          });

          // Navigate based on user type
          if (_isRegisteredUser) {
            print('📱 PhoneEntry: Existing user - going to MPIN entry');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MpinEntryScreen(phoneNumber: _phoneNumber),
              ),
            );
          } else {
            print('📝 PhoneEntry: New user - going to registration');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerRegistrationScreen(phoneNumber: _phoneNumber),
              ),
            );
          }
        } else {
          print('❌ PhoneEntry: OTP verification failed: ${result['message']}');
          _showError(result['message'] ?? 'Invalid OTP. Please try again.');
          _clearOTP();
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ PhoneEntry: OTP verification error: $e');
      if (mounted) {
        _showError('Verification failed. Please try again.');
        _clearOTP();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResendOtp) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔄 PhoneEntry: Resending Firebase OTP to $_phoneNumber');

      final result = await FirebasePhoneAuthService.resendOTP(_phoneNumber);

      if (mounted) {
        if (result['success'] == true) {
          print('✅ PhoneEntry: Firebase OTP resent successfully');
          _startResendTimer();
          _showSuccess('OTP resent to +91 $_phoneNumber');
        } else {
          _showError(result['message'] ?? 'Failed to resend OTP');
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ PhoneEntry: Resend OTP error: $e');
      if (mounted) {
        _showError('Failed to resend OTP. Please try again.');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToRegistration(String phone) {
    print('✅ Phone number not registered - going to registration');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerRegistrationScreen(phoneNumber: phone),
      ),
    );
  }

  void _startResendTimer() {
    _canResendOtp = false;
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResendOtp = true;
        });
        timer.cancel();
      }
    });
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when all 6 digits are entered
        if (_getOTPCode().length == 6) {
          _verifyOTP();
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _goBack() {
    if (_currentStep == AuthStep.otpVerification) {
      setState(() {
        _currentStep = AuthStep.phoneEntry;
        _clearOTP();
        _timer?.cancel();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _showRegistrationOption(String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone Number Not Registered'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The phone number +91 $phone is not registered.'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to register now?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToRegistration(phone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDebugDialog(Map<String, dynamic> testResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone Formatting Debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugRow('Original', testResult['original'] ?? 'N/A'),
              _buildDebugRow('Cleaned', testResult['cleaned'] ?? 'N/A'),
              _buildDebugRow('Formatted', testResult['formatted'] ?? 'N/A'),
              _buildDebugRow('Is Valid', testResult['isValid']?.toString() ?? 'N/A'),
              _buildDebugRow('Length', testResult['length']?.toString() ?? 'N/A'),
              _buildDebugRow('Expected Length', testResult['expectedLength']?.toString() ?? 'N/A'),
              _buildDebugRow('Has Country Code', testResult['startsWithCountryCode']?.toString() ?? 'N/A'),
              _buildDebugRow('First Digit', testResult['firstDigitAfterCountryCode'] ?? 'N/A'),
              if (testResult['error'] != null)
                _buildDebugRow('Error', testResult['error']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentStep != AuthStep.phoneEntry ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _goBack,
        ),
        title: Text(
          _getStepTitle(),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case AuthStep.phoneEntry:
        return 'Phone Entry';
      case AuthStep.otpVerification:
        return 'Verify OTP';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AuthStep.phoneEntry:
        return _buildPhoneEntryStep();
      case AuthStep.otpVerification:
        return _buildOtpVerificationStep();
    }
  }

  Widget _buildPhoneEntryStep() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const VMuruganLogo(
                size: 80,
                primaryColor: AppColors.primaryGreen,
                textColor: AppColors.primaryGold,
              ),

              const SizedBox(height: 40),

              // Welcome Text
              Text(
                'Welcome to V Murugan Gold Trading',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Enter your mobile number to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Phone Number Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    prefixIcon: const Icon(Icons.phone, color: AppColors.primaryGold),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onSubmitted: (_) => _checkPhoneNumber(),
                ),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Continue Button
              CustomButton(
                text: 'Continue',
                onPressed: _isLoading ? null : _checkPhoneNumber,
                isLoading: _isLoading,
                icon: Icons.arrow_forward,
              ),

              // Debug Section (only in debug mode)
              if (kDebugMode) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Debug: Phone Formatting Test',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final phoneNumber = _phoneController.text.trim();
                          if (phoneNumber.isNotEmpty) {
                            final testResult = FirebasePhoneAuthService.testPhoneFormatting(phoneNumber);
                            _showDebugDialog(testResult);
                          } else {
                            _showError('Enter a phone number first');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Test Phone Format', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'By continuing, you agree to our Terms & Conditions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationStep() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const VMuruganLogo(
                size: 60,
                primaryColor: AppColors.primaryGreen,
                textColor: AppColors.primaryGold,
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'Verify OTP',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Enter the 6-digit code sent to\n+91 $_phoneNumber',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return Container(
                    width: 45,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _otpControllers[index].text.isNotEmpty
                            ? AppColors.primaryGold
                            : AppColors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => _onOTPChanged(value, index),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  );
                }),
              ),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Verify Button
              CustomButton(
                text: 'Verify OTP',
                onPressed: _isLoading ? null : _verifyOTP,
                isLoading: _isLoading,
                icon: Icons.verified_user,
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _canResendOtp ? _resendOTP : null,
                    child: Text(
                      _canResendOtp ? 'Resend' : 'Resend in ${_resendTimer}s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _canResendOtp ? AppColors.primaryGold : AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            _isRegisteredUser
                ? 'Existing user - will proceed to MPIN login'
                : 'New user - will proceed to registration',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
