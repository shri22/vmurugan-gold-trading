import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/config/sql_server_config.dart';
import '../../../core/services/auth_service.dart';
import 'mpin_entry_screen.dart';
import 'customer_registration_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
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
      // Check if phone number is registered by trying to get customer info
      final response = await http.get(
        Uri.parse('http://${SqlServerConfig.serverIP}:3001/api/customers/$phone'),
        headers: {'Content-Type': 'application/json'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          // Phone number is registered - go to MPIN entry
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            print('✅ Phone number registered - going to MPIN entry');
            
            // Save phone number for future use
            await AuthService.savePhoneNumber(phone);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MpinEntryScreen(phoneNumber: phone),
              ),
            );
          } else {
            // Phone number not registered - go to registration
            _goToRegistration(phone);
          }
        } else if (response.statusCode == 404) {
          // Phone number not registered - show registration option
          _showRegistrationOption(phone);
        } else {
          _showError('Server error. Please try again.');
        }
      }
    } catch (e) {
      print('Phone check error: $e');
      if (mounted) {
        _showError('Network error. Please check your connection.');
      }
    } finally {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
          ),
        ),
      ),
    );
  }
}
