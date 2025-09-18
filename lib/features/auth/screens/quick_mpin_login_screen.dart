import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/vmurugan_logo.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/auto_logout_service.dart';
import '../../../core/services/secure_http_client.dart';
import '../../../core/config/client_server_config.dart';
import '../../../main.dart';
import 'phone_entry_screen.dart';

/// Quick MPIN login screen for returning customers
/// Shows only MPIN input with saved phone number
class QuickMpinLoginScreen extends StatefulWidget {
  const QuickMpinLoginScreen({super.key});

  @override
  State<QuickMpinLoginScreen> createState() => _QuickMpinLoginScreenState();
}

class _QuickMpinLoginScreenState extends State<QuickMpinLoginScreen> {
  final _mpinController = TextEditingController();
  final List<TextEditingController> _mpinControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _mpinFocusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  bool _obscureText = true;
  String? _savedPhone;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  @override
  void dispose() {
    _mpinController.dispose();
    for (var controller in _mpinControllers) {
      controller.dispose();
    }
    for (var focusNode in _mpinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedPhone() async {
    final phone = await AuthService.getSavedPhoneNumber();
    if (mounted) {
      setState(() {
        _savedPhone = phone;
      });
    }
  }

  Future<void> _loginWithMpin() async {
    final mpin = _mpinControllers.map((c) => c.text).join();
    if (mpin.length != 4) {
      _showError('Please enter 4-digit MPIN');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_savedPhone != null) {
        // Encrypt MPIN before sending to server
        final encryptedMpin = EncryptionService.encryptMPIN(mpin);
        print('🔐 Quick Login - Encrypted MPIN: $encryptedMpin');

        // HTTPS only for production security
        print('🌐 Connecting to: ${ClientServerConfig.userLoginEndpoint}');

        final response = await SecureHttpClient.post(
          Uri.parse('${ClientServerConfig.userLoginEndpoint}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'VMurugan-Mobile-App/1.0',
          },
          body: jsonEncode({
            'phone': _savedPhone!,
            'encrypted_mpin': encryptedMpin,
          }),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Connection timeout. Please check your internet connection and try again.');
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['success'] == true) {
            // Save login state
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_logged_in', true);
            await prefs.setString('user_phone', _savedPhone!);
            await prefs.setString('user_data', jsonEncode(data['customer']));

            // IMPORTANT: Mark customer as registered
            await prefs.setBool('customer_registered', true);

            // Also save to CustomerService for backward compatibility
            await CustomerService.saveLoginSession(_savedPhone!);

            print('✅ Quick MPIN Login successful for ${_savedPhone}');
            print('✅ Customer marked as registered');

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
            _showError(data['message'] ?? 'Invalid MPIN. Please try again.');
          }
        } else {
          final errorData = jsonDecode(response.body);
          _showError(errorData['message'] ?? 'Login failed. Please try again.');
        }
      } else {
        _showError('No saved phone number found.');
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
      print('Quick MPIN login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _usePhoneLogin() {
    // Go back to phone entry for different number
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PhoneEntryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.getPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              
              // Logo
              const VMuruganLogo(size: 80),
              const SizedBox(height: AppSpacing.xl),
              
              // Welcome back message
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Phone number display
              if (_savedPhone != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _savedPhone!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              
              // MPIN Input
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Your MPIN',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Beautiful 4-Box MPIN Input
                    _buildMpinBoxes(),
                    const SizedBox(height: AppSpacing.md),

                    // Show/Hide MPIN Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          child: Text(
                            _obscureText ? 'Show MPIN' : 'Hide MPIN',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Login Button
                    CustomButton(
                      text: 'Login',
                      onPressed: _isLoading ? null : _loginWithMpin,
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Use different phone option
              TextButton.icon(
                onPressed: _usePhoneLogin,
                icon: const Icon(Icons.phone_android),
                label: const Text('Use Different Phone Number'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Beautiful 4-box MPIN input with dark green and gold theme
  Widget _buildMpinBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4332), // Dark green background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _mpinFocusNodes[index].hasFocus
                ? const Color(0xFFFFD700) // Gold when focused
                : const Color(0xFF2D5A3D), // Lighter green when not focused
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2), // Gold glow
                blurRadius: _mpinFocusNodes[index].hasFocus ? 8 : 0,
                spreadRadius: _mpinFocusNodes[index].hasFocus ? 1 : 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: _mpinControllers[index],
            focusNode: _mpinFocusNodes[index],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            obscureText: _obscureText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700), // Gold text
            ),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: _obscureText ? '•' : '',
              hintStyle: const TextStyle(
                color: Color(0xFF95A99C), // Light green hint
                fontSize: 24,
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                // Move to next field
                if (index < 3) {
                  _mpinFocusNodes[index + 1].requestFocus();
                } else {
                  // All fields filled, attempt login
                  _mpinFocusNodes[index].unfocus();
                  _loginWithMpin();
                }
              } else if (value.isEmpty && index > 0) {
                // Move to previous field on backspace
                _mpinFocusNodes[index - 1].requestFocus();
              }

              // Update UI for focus changes
              setState(() {});
            },
            onTap: () {
              setState(() {});
            },
          ),
        );
      }),
    );
  }
}
