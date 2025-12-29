import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_http_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/sql_server_config.dart';
import 'otp_verification_screen.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/validators.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  final String? phoneNumber;

  const CustomerRegistrationScreen({super.key, this.phoneNumber});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();
  final _mpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();

  bool _isLoading = false;
  bool _obscureMpin = true;
  bool _obscureConfirmMpin = true;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    // Initialize phone number if provided
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _registerCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    // Validate MPIN
    final mpin = _mpinController.text.trim();
    final confirmMpin = _confirmMpinController.text.trim();

    // Validate MPIN Strength
    final mpinError = Validators.validateMPINStrength(mpin);
    if (mpinError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mpinError)),
      );
      return;
    }

    if (mpin != confirmMpin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MPIN and Confirm MPIN do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check server connectivity
      final isServerReachable = await AuthService.isServerReachable();
      if (!isServerReachable) {
        throw Exception('Server not reachable. Please check your internet connection.');
      }

      // Register with encrypted MPIN
      final result = await AuthService.registerWithEncryptedMPIN(
        phone: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        panCard: _panController.text.trim().toUpperCase(),
        mpin: mpin,
        deviceId: 'FLUTTER_APP_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['success'] == true) {
        if (mounted) {
          // Registration successful, save phone for future quick logins
          final phone = _phoneController.text.trim();
          await AuthService.savePhoneNumber(phone);

          // Save MPIN for future logins
          await AuthService.setMPIN(mpin);

          // Complete login and save state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_phone', phone);

          // CRITICAL FIX: Save customer data in the format CustomerService expects
          await prefs.setString('customer_phone', phone);
          await prefs.setString('customer_name', _nameController.text.trim());
          await prefs.setString('customer_email', _emailController.text.trim());
          await prefs.setString('customer_address', _addressController.text.trim());
          await prefs.setString('customer_pan_card', _panController.text.trim().toUpperCase());

          // Save customer data if available from server response
          if (result['customer'] != null) {
            await prefs.setString('user_data', jsonEncode(result['customer']));
            final customerData = result['customer'];
            await prefs.setString('customer_id', customerData['id']?.toString() ?? '');
          }

          // IMPORTANT: Mark customer as registered
          await prefs.setBool('customer_registered', true);

          print('✅ Registration: Customer data saved in CustomerService format');
          print('  📞 customer_phone: $phone');
          print('  👤 customer_name: ${_nameController.text.trim()}');

          // Also save to CustomerService for backward compatibility
          await CustomerService.saveLoginSession(phone);

          print('✅ Registration completed and phone saved for quick login: $phone');

          // Register FCM Token for notifications
          await FCMService.registerTokenOnLogin();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registration completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to home screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRegistrationSuccessDialog(String? customerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Registration Successful!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to V Murugan Jewellery Digital Gold!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            if (customerId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          color: Colors.amber[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Customer ID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            customerId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyCustomerId(customerId),
                            icon: Icon(
                              Icons.copy,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            tooltip: 'Copy Customer ID',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please save this Customer ID for future reference. You can use it for customer support and scheme management.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                '✨ You can now start investing in digital gold with live market prices!\n'
                '💎 Multiple investment schemes available\n'
                '📱 Track your portfolio in real-time',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Start Investing',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _copyCustomerId(String customerId) {
    Clipboard.setData(ClipboardData(text: customerId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer ID $customerId copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToOTPVerification() {
    final phone = _phoneController.text.trim();

    // Show success message for registration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Registration successful! Please verify your mobile number.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to OTP verification screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerificationScreen(phoneNumber: phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Customer Registration'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
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
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 48,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure your gold investments with verified identity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form Fields
              _buildTextField(
                controller: _phoneController,
                label: 'Mobile Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (value.length != 10) {
                    return 'Enter valid 10-digit mobile number';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter valid email address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _panController,
                label: 'PAN Card Number',
                icon: Icons.credit_card,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PAN card number is required';
                  }
                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.toUpperCase())) {
                    return 'Enter valid PAN card number (e.g., ABCDE1234F)';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(10),
                  UpperCaseTextFormatter(),
                ],
              ),

              const SizedBox(height: 16),

              // MPIN Field
              _buildTextField(
                controller: _mpinController,
                label: 'Create 4-Digit MPIN',
                icon: Icons.lock,
                obscureText: _obscureMpin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                suffixIcon: IconButton(
                  icon: Icon(_obscureMpin ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureMpin = !_obscureMpin;
                    });
                  },
                ),
                validator: (value) {
                  return Validators.validateMPINStrength(value ?? '');
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),

              const SizedBox(height: 16),

              // Confirm MPIN Field
              _buildTextField(
                controller: _confirmMpinController,
                label: 'Confirm MPIN',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmMpin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmMpin ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmMpin = !_obscureConfirmMpin;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your MPIN';
                  }
                  if (value != _mpinController.text) {
                    return 'MPIN does not match';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),

              const SizedBox(height: 24),

              // Terms and Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    activeColor: const Color(0xFFFFD700),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                              color: Color(0xFFDAA520),
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchURL('https://api.vmuruganjewellery.co.in:3001/terms-of-service'),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Color(0xFFDAA520),
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchURL('https://api.vmuruganjewellery.co.in:3001/privacy-policy'),
                          ),
                          const TextSpan(text: '. My transaction data will be securely stored for business analytics.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool obscureText = false,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        counterText: maxLength != null ? '' : null, // Hide counter for MPIN fields
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
