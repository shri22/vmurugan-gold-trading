import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../main.dart';

/// Enhanced authentication screen with complete flow
/// Phone → Registration Check → OTP → MPIN Setup/Login
class EnhancedPhoneEntryScreen extends StatefulWidget {
  const EnhancedPhoneEntryScreen({super.key});

  @override
  State<EnhancedPhoneEntryScreen> createState() => _EnhancedPhoneEntryScreenState();
}

enum AuthStep {
  phoneEntry,
  registration,
  otpVerification,
  mpinSetup,
  mpinLogin,
}

class _EnhancedPhoneEntryScreenState extends State<EnhancedPhoneEntryScreen> {
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _mpinController = TextEditingController();
  final TextEditingController _confirmMpinController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<TextEditingController> _mpinBoxControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _confirmMpinBoxControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _loginMpinBoxControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _mpinFocusNodes = List.generate(4, (index) => FocusNode());
  final List<FocusNode> _confirmMpinFocusNodes = List.generate(4, (index) => FocusNode());
  final List<FocusNode> _loginMpinFocusNodes = List.generate(4, (index) => FocusNode());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  // Form keys
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _mpinFormKey = GlobalKey<FormState>();

  // State variables
  AuthStep _currentStep = AuthStep.phoneEntry;
  bool _isLoading = false;
  bool _isRegisteredUser = false;
  String _generatedOtp = '';
  String _demoOtp = ''; // Store demo OTP to display
  bool _canResendOtp = false;
  int _resendTimer = 30;
  Timer? _timer;
  bool _obscureMpin = true;
  bool _obscureConfirmMpin = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _mpinController.dispose();
    _confirmMpinController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var controller in _mpinBoxControllers) {
      controller.dispose();
    }
    for (var controller in _confirmMpinBoxControllers) {
      controller.dispose();
    }
    for (var controller in _loginMpinBoxControllers) {
      controller.dispose();
    }
    for (var focusNode in _mpinFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _confirmMpinFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _loginMpinFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // Step 1: Check phone number
  Future<void> _checkPhoneNumber() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      print('📱 Enhanced Auth: Checking phone number: $phone');

      // Check if phone is registered
      final isRegistered = await AuthService.isPhoneRegistered(phone);

      if (mounted) {
        setState(() {
          _isRegisteredUser = isRegistered;
          _isLoading = false;
        });

        if (isRegistered) {
          // Existing user - check if they have MPIN
          final hasMpin = await AuthService.hasMPIN();
          if (hasMpin) {
            // Go to MPIN login
            setState(() {
              _currentStep = AuthStep.mpinLogin;
            });
          } else {
            // Generate OTP for first-time login
            await _generateOtp();
          }
        } else {
          // New user - go to registration
          setState(() {
            _currentStep = AuthStep.registration;
          });
        }
      }
    } catch (e) {
      print('❌ Enhanced Auth: Error checking phone: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error checking phone number: $e');
      }
    }
  }

  // Step 2: Register new user
  Future<void> _registerUser() async {
    if (!_registrationFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('📝 Enhanced Auth: Registering new user');

      // Generate OTP first
      await _generateOtp();

      setState(() {
        _isLoading = false;
        _currentStep = AuthStep.otpVerification;
      });
    } catch (e) {
      print('❌ Enhanced Auth: Error during registration: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error during registration: $e');
      }
    }
  }

  // Step 3: Generate and send OTP via SMS
  Future<void> _generateOtp() async {
    try {
      final phone = _phoneController.text.trim();

      // Show loading state
      setState(() {
        _isLoading = true;
      });

      final otp = await AuthService.generateOTP(phone);

      if (mounted) {
        setState(() {
          _generatedOtp = otp;
          // Store demo OTP for display (6-digit OTP)
          if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
            _demoOtp = otp;
          }
          _currentStep = AuthStep.otpVerification;
          _isLoading = false;
        });

        _startResendTimer();

        // Show success message based on OTP type
        if (otp == 'FIREBASE_OTP') {
          _showSuccess('🔥 FREE Firebase OTP sent to ${phone.substring(phone.length - 4)}! Check your SMS.');
        } else if (_demoOtp.isNotEmpty) {
          _showSuccess('🎭 Demo Mode: Your OTP is $otp');
        } else {
          _showSuccess('📱 OTP sent to your mobile number ending with ${phone.substring(phone.length - 4)}');
        }
      }
    } catch (e) {
      print('❌ Enhanced Auth: Error generating OTP: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if it's a demo fallback
        if (e.toString().contains('SMS failed, using demo OTP')) {
          // Extract OTP from error message for demo
          final otpMatch = RegExp(r'demo OTP: (\d{6})').firstMatch(e.toString());
          if (otpMatch != null) {
            final demoOtp = otpMatch.group(1)!;
            setState(() {
              _generatedOtp = demoOtp;
              _demoOtp = demoOtp; // Store for display
              _currentStep = AuthStep.otpVerification;
            });
            _startResendTimer();
            _showSuccess('🎭 Demo Mode: Your OTP is $demoOtp');
            return;
          }
        }

        _showError('Error sending OTP: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Step 4: Verify OTP
  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await AuthService.verifyOTP(otp);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (isValid) {
          if (!_isRegisteredUser) {
            // New user - save to Firebase first
            await _saveUserToFirebase();
          }

          // Check if user has MPIN
          final hasMpin = await AuthService.hasMPIN();
          if (hasMpin) {
            // Complete login
            await _completeLogin();
          } else {
            // Go to MPIN setup
            setState(() {
              _currentStep = AuthStep.mpinSetup;
            });
          }
        } else {
          _showError('Invalid OTP. Please try again.');
          _clearOtp();
        }
      }
    } catch (e) {
      print('❌ Enhanced Auth: Error verifying OTP: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error verifying OTP: $e');
      }
    }
  }

  // Step 5: Save user to Firebase
  Future<void> _saveUserToFirebase() async {
    try {
      final result = await FirebaseService.saveCustomer(
        phone: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        panCard: _panController.text.trim(),
        deviceId: 'enhanced_auth_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Registration failed');
      }

      print('✅ Enhanced Auth: User saved to Firebase');
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Step 6: Setup MPIN
  Future<void> _setupMpin() async {
    // Validate MPIN boxes
    final mpin = _mpinBoxControllers.map((c) => c.text).join();
    final confirmMpin = _confirmMpinBoxControllers.map((c) => c.text).join();

    if (mpin.length != 4) {
      _showError('Please enter 4-digit MPIN');
      return;
    }

    if (confirmMpin.length != 4) {
      _showError('Please confirm your MPIN');
      return;
    }

    if (mpin != confirmMpin) {
      _showError('MPIN does not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.setMPIN(mpin);
      await _completeLogin();
    } catch (e) {
      print('❌ Enhanced Auth: Error setting up MPIN: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error setting up MPIN: $e');
      }
    }
  }

  // Step 7: Login with MPIN
  Future<void> _loginWithMpin() async {
    final mpin = _loginMpinBoxControllers.map((c) => c.text).join();

    if (mpin.length != 4) {
      _showError('Please enter 4-digit MPIN');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await AuthService.verifyMPIN(mpin);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (isValid) {
          await _completeLogin();
        } else {
          _showError('Invalid MPIN. Please try again.');
          _mpinController.clear();
        }
      }
    } catch (e) {
      print('❌ Enhanced Auth: Error during MPIN login: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error during login: $e');
      }
    }
  }

  // Complete login and navigate to main app
  Future<void> _completeLogin() async {
    try {
      await AuthService.completeLogin(_phoneController.text.trim());

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );

        _showSuccess('Welcome to VMUrugan!');
      }
    } catch (e) {
      _showError('Error completing login: $e');
    }
  }

  // Helper methods
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

  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResendOtp) return;

    try {
      await _generateOtp();
      _showSuccess('OTP resent successfully');
    } catch (e) {
      _showError('Error resending OTP: $e');
    }
  }

  void _goBack() {
    switch (_currentStep) {
      case AuthStep.phoneEntry:
        Navigator.pop(context);
        break;
      case AuthStep.registration:
        setState(() {
          _currentStep = AuthStep.phoneEntry;
        });
        break;
      case AuthStep.otpVerification:
        setState(() {
          _currentStep = _isRegisteredUser ? AuthStep.phoneEntry : AuthStep.registration;
        });
        break;
      case AuthStep.mpinSetup:
        setState(() {
          _currentStep = AuthStep.otpVerification;
        });
        break;
      case AuthStep.mpinLogin:
        setState(() {
          _currentStep = AuthStep.phoneEntry;
        });
        break;
    }
  }

  // Validation methods
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your address';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }
    return null;
  }

  String? _validatePan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your PAN card number';
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) {
      return 'Please enter a valid PAN card number';
    }
    return null;
  }

  String? _validateMpin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a 4-digit MPIN';
    }
    if (value.length != 4) {
      return 'MPIN must be exactly 4 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'MPIN must contain only numbers';
    }
    return null;
  }

  String? _validateConfirmMpin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your MPIN';
    }
    if (value != _mpinController.text) {
      return 'MPIN does not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      resizeToAvoidBottomInset: true,
      appBar: _currentStep != AuthStep.phoneEntry ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextColor(context)),
          onPressed: _goBack,
        ),
        title: Text(
          _getStepTitle(),
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
      ) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: Responsive.getWidth(context) * 0.05,
            right: Responsive.getWidth(context) * 0.05,
            top: Responsive.getWidth(context) * 0.05,
            bottom: MediaQuery.of(context).viewInsets.bottom + Responsive.getWidth(context) * 0.05,
          ),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case AuthStep.phoneEntry:
        return 'Phone Entry';
      case AuthStep.registration:
        return 'Registration';
      case AuthStep.otpVerification:
        return 'Verify OTP';
      case AuthStep.mpinSetup:
        return 'Setup MPIN';
      case AuthStep.mpinLogin:
        return 'Enter MPIN';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AuthStep.phoneEntry:
        return _buildPhoneEntryStep();
      case AuthStep.registration:
        return _buildRegistrationStep();
      case AuthStep.otpVerification:
        return _buildOtpVerificationStep();
      case AuthStep.mpinSetup:
        return _buildMpinSetupStep();
      case AuthStep.mpinLogin:
        return _buildMpinLoginStep();
    }
  }

  Widget _buildPhoneEntryStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: Responsive.getHeight(context) * 0.08),

          // Logo
          VMuruganLogo(
            size: Responsive.getWidth(context) * 0.18,
            primaryColor: AppColors.primaryGreen,
            textColor: AppColors.primaryGold,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // Welcome Text
          Text(
            'Welcome to VMurugan',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.02),

          Text(
            'Enter your phone number to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // Phone Number Input
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  hint: 'Enter your phone number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validatePhone,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Checking...' : 'Continue',
                    onPressed: _isLoading ? null : _checkPhoneNumber,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Info Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'ll check if you\'re already registered and guide you through the process.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.08),

          // Footer
          Text(
            'Secure • Trusted • Regulated',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationStep() {
    return Form(
      key: _registrationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          VMuruganLogo(
            size: Responsive.getWidth(context) * 0.12,
            primaryColor: AppColors.primaryGreen,
            textColor: AppColors.primaryGold,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Title
          Text(
            'Create Your Account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.02),

          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
            ),
            child: Text(
              _phoneController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Registration Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                CustomTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  prefixIcon: Icons.person,
                  validator: _validateName,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // Address Field
                CustomTextField(
                  controller: _addressController,
                  hint: 'Address',
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                  validator: _validateAddress,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // PAN Card Field
                CustomTextField(
                  controller: _panController,
                  hint: 'PAN Card Number',
                  prefixIcon: Icons.credit_card,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(text: newValue.text.toUpperCase());
                    }),
                  ],
                  validator: _validatePan,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Processing...' : 'Send OTP',
                    onPressed: _isLoading ? null : _registerUser,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Info Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'ll send an OTP to verify your phone number, then you can set up your MPIN.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: Responsive.getHeight(context) * 0.04),

        // Logo
        VMuruganLogo(
          size: Responsive.getWidth(context) * 0.15,
          primaryColor: AppColors.primaryGreen,
          textColor: AppColors.primaryGold,
        ),

        SizedBox(height: Responsive.getHeight(context) * 0.06),

        // Title
        Text(
          'Verify Your Phone',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: Responsive.getHeight(context) * 0.02),

        Text(
          'Enter the 6-digit code sent to',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          _phoneController.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),

        // Demo OTP Display (if available) - Clean Design
        if (_demoOtp.isNotEmpty) ...[
          SizedBox(height: Responsive.getHeight(context) * 0.03),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadowColor(context),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Demo OTP',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _demoOtp,
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: Responsive.getHeight(context) * 0.06),

        // OTP Input Fields - Optimized for iPhone SE (375px width)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (i) => _buildOtpField(i),
            ),
          ),
        ),

        SizedBox(height: Responsive.getHeight(context) * 0.04),

        // Verify Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: _isLoading ? 'Verifying...' : 'Verify OTP',
            onPressed: _isLoading ? null : _verifyOtp,
            isLoading: _isLoading,
          ),
        ),

        SizedBox(height: Responsive.getHeight(context) * 0.04),

        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the code? ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: _canResendOtp ? _resendOtp : null,
              child: Text(
                _canResendOtp ? 'Resend' : 'Resend in ${_resendTimer}s',
                style: TextStyle(
                  color: _canResendOtp ? AppColors.primaryGold : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    final bool hasValue = _otpControllers[index].text.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpFocusNodes[index].hasFocus
            ? AppColors.primaryGold
            : AppColors.getBorderColor(context),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadowColor(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          obscureText: false,
          enableInteractiveSelection: true,
          autofocus: index == 0,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
          cursorColor: AppColors.primaryGold,
          cursorWidth: 2,
          cursorHeight: 16,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).previousFocus();
            }

            // Auto-verify when all fields are filled
            final otp = _otpControllers.map((c) => c.text).join();
            if (otp.length == 6) {
              _verifyOtp();
            }

            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildMpinSetupStep() {
    return Form(
      key: _mpinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // Logo
          VMuruganLogo(
            size: Responsive.getWidth(context) * 0.15,
            primaryColor: AppColors.primaryGreen,
            textColor: AppColors.primaryGold,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: Icon(
              Icons.check,
              size: 40,
              color: AppColors.success,
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Title
          Text(
            'Account Created!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.02),

          Text(
            'Set up your 4-digit MPIN for secure access',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // MPIN Setup Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create MPIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 24),

                // Create MPIN - Clean Design
                Text(
                  'Create MPIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMpinBoxes(_mpinBoxControllers, _mpinFocusNodes, _obscureMpin),

                const SizedBox(height: 24),

                // Confirm MPIN - Clean Design
                Text(
                  'Confirm MPIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMpinBoxes(_confirmMpinBoxControllers, _confirmMpinFocusNodes, _obscureConfirmMpin),

                const SizedBox(height: 16),

                // Show/Hide MPIN Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _obscureMpin ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureMpin = !_obscureMpin;
                          _obscureConfirmMpin = !_obscureConfirmMpin;
                        });
                      },
                      child: Text(
                        _obscureMpin ? 'Show MPIN' : 'Hide MPIN',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Setup Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Setting up...' : 'Complete Setup',
                    onPressed: _isLoading ? null : _setupMpin,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Security Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your MPIN is your secure key to access the app.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use a unique 4-digit combination\n• Don\'t share it with anyone\n• You can change it later in settings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMpinLoginStep() {
    return Form(
      key: _mpinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Logo
          VMuruganLogo(
            size: Responsive.getWidth(context) * 0.15,
            primaryColor: AppColors.primaryGreen,
            textColor: AppColors.primaryGold,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // Welcome Back Text
          Text(
            'Welcome Back!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.02),

          Text(
            'Enter your MPIN to continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.02),

          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
            ),
            child: Text(
              _phoneController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.06),

          // MPIN Input
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter MPIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 24),

                // Beautiful 4-box MPIN input - Clean Design
                _buildMpinBoxes(_loginMpinBoxControllers, _loginMpinFocusNodes, _obscureMpin),

                const SizedBox(height: 16),

                // Show/Hide MPIN Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _obscureMpin ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureMpin = !_obscureMpin;
                        });
                      },
                      child: Text(
                        _obscureMpin ? 'Show MPIN' : 'Hide MPIN',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Logging in...' : 'Login',
                    onPressed: _isLoading ? null : _loginWithMpin,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getHeight(context) * 0.04),

          // Security Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your MPIN is encrypted and secure. Never share it with anyone.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Beautiful clean 4-box MPIN input - Same design as OTP
  Widget _buildMpinBoxes(List<TextEditingController> controllers, List<FocusNode> focusNodes, bool obscureText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              Expanded(
                child: Container(
                  height: 60,
                  constraints: const BoxConstraints(
                    minWidth: 50,
                    maxWidth: 70,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controllers[i].text.isNotEmpty
                        ? AppColors.primaryGold // Gold when filled
                        : AppColors.primaryGreen, // Green border (same as OTP)
                      width: controllers[i].text.isNotEmpty ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: controllers[i].text.isNotEmpty
                          ? AppColors.primaryGold.withOpacity(0.3)
                          : AppColors.primaryGreen.withOpacity(0.2),
                        blurRadius: controllers[i].text.isNotEmpty ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: controllers[i],
                    focusNode: focusNodes[i],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    obscureText: obscureText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: controllers[i].text.isNotEmpty
                        ? AppColors.primaryGold // Gold when filled
                        : AppColors.primaryGreen, // Green when empty (same as OTP)
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: obscureText ? '●' : '',
                      hintStyle: TextStyle(
                        color: AppColors.getSecondaryTextColor(context),
                        fontSize: 20,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        // Move to next field
                        if (i < 3) {
                          focusNodes[i + 1].requestFocus();
                        } else {
                          // All fields filled
                          focusNodes[i].unfocus();

                          // Handle auto-submit for different MPIN types
                          if (controllers == _mpinBoxControllers) {
                            // MPIN setup - check if both MPIN and confirm are complete
                            final mpin = _mpinBoxControllers.map((c) => c.text).join();
                            final confirmMpin = _confirmMpinBoxControllers.map((c) => c.text).join();
                            if (mpin.length == 4 && confirmMpin.length == 4) {
                              _setupMpin();
                            }
                          } else if (controllers == _loginMpinBoxControllers) {
                            // MPIN login - auto-submit when complete
                            _loginWithMpin();
                          }
                        }
                      } else if (value.isEmpty && i > 0) {
                        // Move to previous field on backspace
                        focusNodes[i - 1].requestFocus();
                      }

                      // Update UI for focus changes
                      setState(() {});
                    },
                    onTap: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
