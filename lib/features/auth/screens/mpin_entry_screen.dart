import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/secure_http_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/config/client_server_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/auto_logout_service.dart';
import '../../../main.dart';
import 'phone_entry_screen.dart';
import 'customer_registration_screen.dart';

class MpinEntryScreen extends StatefulWidget {
  final String phoneNumber;
  
  const MpinEntryScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<MpinEntryScreen> createState() => _MpinEntryScreenState();
}

class _MpinEntryScreenState extends State<MpinEntryScreen> {
  final List<TextEditingController> _mpinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _mpinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loginWithMpin() async {
    final mpin = _mpinControllers.map((c) => c.text).join();
    if (mpin.length != 4) {
      _showError('Please enter 4-digit MPIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔐 Attempting MPIN login for: ${widget.phoneNumber}');
      print('🔐 MPIN entered: $mpin');

      // Encrypt MPIN before sending to server
      final encryptedMpin = EncryptionService.encryptMPIN(mpin);
      print('🔐 Encrypted MPIN: $encryptedMpin');

      // Use client's server API for login with secure HTTP client
      final response = await SecureHttpClient.post(
        '${ClientServerConfig.userLoginEndpoint}',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phoneNumber,
          'encrypted_mpin': encryptedMpin,
        }),
      );

      print('🔐 Login response status: ${response.statusCode}');
      print('🔐 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Save login state with user ID
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_phone', widget.phoneNumber);
          await prefs.setString('user_data', jsonEncode(data['user']));

          // IMPORTANT: Save user ID for server API calls
          await prefs.setInt('current_user_id', data['user']['id']);
          await prefs.setBool('customer_registered', true);

          // Also save to CustomerService for backward compatibility
          await CustomerService.saveLoginSession(widget.phoneNumber);

          print('✅ MPIN Login successful for ${widget.phoneNumber}');
          print('✅ User ID saved: ${data['user']['id']}');

          // Start auto-logout monitoring for logged-in user
          AutoLogoutService().startMonitoring();
          print('⏰ Auto-logout monitoring started');

          if (mounted) {
            // Navigate to main app
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        } else {
          // MPIN verification failed - show error with option to register
          _showMpinError(data['message'] ?? 'Invalid MPIN. Please try again.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
      print('MPIN login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _showMpinError(String message) {
    setState(() {
      _errorMessage = message;
    });

    // Show dialog with option to register
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'If you haven\'t registered yet, you can register now.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Go to registration
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerRegistrationScreen(
                    phoneNumber: widget.phoneNumber,
                  ),
                ),
              );
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _onMpinChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-submit when all 4 digits are entered
    if (index == 3 && value.isNotEmpty) {
      final mpin = _mpinControllers.map((c) => c.text).join();
      if (mpin.length == 4) {
        _loginWithMpin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                      size: 70,
                      primaryColor: AppColors.primaryGreen,
                      textColor: AppColors.primaryGold,
                    ),

                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Enter MPIN',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Phone number display
                    Text(
                      '+91 ${widget.phoneNumber}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Enter your 4-digit MPIN to login',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // MPIN Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _focusNodes[index].hasFocus 
                                ? AppColors.primaryGold 
                                : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _mpinControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            obscureText: true,
                            maxLength: 1,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            onChanged: (value) => _onMpinChanged(value, index),
                          ),
                        );
                      }),
                    ),
                    
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
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
                    
                    // Login Button
                    CustomButton(
                      text: 'Login',
                      onPressed: _isLoading ? null : _loginWithMpin,
                      isLoading: _isLoading,
                      icon: Icons.login,
                    ),
                  ],
                ),
              ),
              
              // Use different number option
              TextButton(
                onPressed: () {
                  // Go back to phone entry screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const PhoneEntryScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Use different number?',
                  style: TextStyle(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
