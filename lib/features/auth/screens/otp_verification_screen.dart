import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/config/sql_server_config.dart';
import 'customer_registration_screen.dart';
import 'quick_mpin_login_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _generateInitialOTP();
  }

  void _generateInitialOTP() async {
    try {
      // Generate OTP when screen loads
      final otp = await AuthService.generateOTP(widget.phoneNumber);

      // Show demo OTP if available (for testing)
      if (mounted && otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showSnackBar('🎭 Demo Mode: Your OTP is $otp', AppColors.primaryGold);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error generating OTP: $e', AppColors.error);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.getPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // OTP Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sms,
                  size: 40,
                  color: AppColors.white,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Title and Description
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'We have sent a 6-digit verification code to',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              Text(
                '+91 ${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: Responsive.getWidth(context) / 8,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          borderSide: const BorderSide(color: AppColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGold,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) => _onOTPChanged(value, index),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Verify Button
              CustomButton(
                text: 'Verify OTP',
                onPressed: _isLoading ? null : _handleVerifyOTP,
                isLoading: _isLoading,
                isFullWidth: true,
                type: ButtonType.primary,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Resend OTP Section
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
                    onTap: _canResend ? _handleResendOTP : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendTimer}s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _canResend ? AppColors.primaryGold : AppColors.grey,
                        fontWeight: FontWeight.w600,
                        decoration: _canResend ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Change Number
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Change mobile number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handleVerifyOTP();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _handleVerifyOTP() async {
    final otpCode = _getOTPCode();

    if (otpCode.length != 6) {
      _showSnackBar('Please enter complete OTP', AppColors.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use HTTPS API-based OTP verification
      final response = await AuthService.makeSecureRequest(
        '/auth/verify-otp',
        method: 'POST',
        body: {
          'phone': widget.phoneNumber,
          'otp': otpCode,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
        final data = response;

        if (data['success'] == true) {
          // Save login state using AuthService
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_phone', widget.phoneNumber);
          await prefs.setString('user_data', jsonEncode(data['customer']));

          // CRITICAL FIX: Save customer data in the format CustomerService expects
          final customerData = data['customer'] ?? {};
          await prefs.setString('customer_phone', widget.phoneNumber);
          await prefs.setString('customer_name', customerData['name'] ?? 'Customer');
          await prefs.setString('customer_email', customerData['email'] ?? '');
          await prefs.setString('customer_address', customerData['address'] ?? '');
          await prefs.setString('customer_pan_card', customerData['pan_card'] ?? '');
          await prefs.setString('customer_id', customerData['id']?.toString() ?? '');
          await prefs.setBool('customer_registered', true);

          print('✅ OTP Verification: Customer data saved in CustomerService format');

          // Also save to CustomerService for backward compatibility
          await CustomerService.saveLoginSession(widget.phoneNumber);

          _showSnackBar('OTP verified successfully!', AppColors.success);

          // Wait a moment for the success message to be visible
          await Future.delayed(const Duration(seconds: 1));

          // Navigate based on user type
          if (mounted) {
            if (data['isNewUser'] == true) {
              // Case 1: First Time Install - New user goes to registration
              // This will set up MPIN and save phone for future quick logins
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerRegistrationScreen(
                    phoneNumber: widget.phoneNumber,
                  ),
                ),
              );
            } else {
              // Case 3: Registered User on New Device - Existing user verified
              // Save phone for future quick logins and go to MPIN login
              await AuthService.savePhoneNumber(widget.phoneNumber);

              // Mark as registered customer
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('customer_registered', true);

              print('✅ Existing user verified - going to MPIN login');

              // Go to MPIN login screen for existing users
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuickMpinLoginScreen(),
                ),
              );
            }
          }
        } else {
          _showSnackBar(data['message'] ?? 'Invalid OTP. Please try again.', AppColors.error);
          _clearOTP();
        }
      } else {
        final errorData = response;
        _showSnackBar(errorData['message'] ?? 'Verification failed. Please try again.', AppColors.error);
        _clearOTP();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Network error. Please check your connection.', AppColors.error);
      _clearOTP();
      print('OTP verification error: $e');
    }
  }

  void _handleResendOTP() async {
    if (!_canResend) return;

    try {
      // Generate new OTP using AuthService
      final otp = await AuthService.generateOTP(widget.phoneNumber);

      _showSnackBar('OTP sent successfully!', AppColors.success);
      _startResendTimer();
      _clearOTP();

      // Show demo OTP if available (for testing)
      if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showSnackBar('🎭 Demo Mode: Your OTP is $otp', AppColors.primaryGold);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error sending OTP: $e', AppColors.error);
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
