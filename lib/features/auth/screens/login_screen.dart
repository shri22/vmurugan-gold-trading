import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../main.dart';
import 'customer_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _mpinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.getPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                
                // Logo and Welcome Section
                Center(
                  child: Column(
                    children: [
                      VMUruganLogo(
                        size: 120,
                        primaryColor: Colors.red,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Welcome To VMurugan Jewellers',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your trusted partner for digital gold investments',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Login Form
                Text(
                  'Login to your account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'Enter your mobile number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  validator: _validatePhone,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // MPIN Input
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  controller: _mpinController,
                  label: 'Enter MPIN',
                  hint: 'Enter your 4-digit MPIN',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter MPIN';
                    }
                    if (value.length != 4) {
                      return 'MPIN must be 4 digits';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Login Button
                CustomButton(
                  text: 'Login with MPIN',
                  onPressed: _isLoading ? null : _handleMPINLogin,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  type: ButtonType.primary,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Alternative Login Options
                Center(
                  child: Column(
                    children: [
                      Text(
                        'or',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),



                      const SizedBox(height: AppSpacing.md),

                      CustomButton(
                        text: 'Login with Biometric',
                        onPressed: _handleBiometricLogin,
                        type: ButtonType.outline,
                        icon: Icons.fingerprint,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          'Register',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Terms and Privacy
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Please enter only numbers';
    }
    return null;
  }

  void _handleMPINLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final phone = _phoneController.text.trim();
        final mpin = _mpinController.text.trim();

        // Validate MPIN length
        if (mpin.length != 4) {
          _showErrorMessage('Please enter 4-digit MPIN');
          return;
        }

        // Check server connectivity
        final isServerReachable = await AuthService.isServerReachable();
        if (!isServerReachable) {
          _showErrorMessage('Server not reachable. Please check your internet connection.');
          return;
        }

        // Attempt login with encrypted MPIN
        final result = await AuthService.loginWithMPIN(
          phone: phone,
          mpin: mpin,
        );

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to home page
          _navigateToHome();
        } else {
          _showErrorMessage(result['message'] ?? 'Login failed');
        }
      } catch (e) {
        print('❌ Login error: $e');
        _showErrorMessage('Login failed: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _validateCustomer(String phone) async {
    try {
      // Check if customer exists in Firebase
      final result = await ApiService.getCustomerByPhone(phone);
      return result['success'] && result['customer'] != null;
    } catch (e) {
      print('Error validating customer: $e');
      return false;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }



  void _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate biometric authentication
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // For demo, always succeed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Biometric authentication successful!'),
        backgroundColor: AppColors.success,
      ),
    );

    // Navigate to home after successful biometric login
    await Future.delayed(const Duration(milliseconds: 500));
    _navigateToHome();
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerRegistrationScreen(),
      ),
    );
  }

  void _navigateToOTP() {
    // TODO: Navigate to OTP verification screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP sent to ${_phoneController.text}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _navigateToHome() {
    // Navigate directly to home page after successful login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }
}
