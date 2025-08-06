import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/config/sql_server_config.dart';

class ChangeMpinScreen extends StatefulWidget {
  const ChangeMpinScreen({super.key});

  @override
  State<ChangeMpinScreen> createState() => _ChangeMpinScreenState();
}

class _ChangeMpinScreenState extends State<ChangeMpinScreen> {
  // Controllers for MPIN input boxes
  final List<TextEditingController> _currentMpinControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _newMpinControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _confirmMpinControllers = List.generate(4, (index) => TextEditingController());

  // Focus nodes for MPIN input boxes
  final List<FocusNode> _currentMpinFocusNodes = List.generate(4, (index) => FocusNode());
  final List<FocusNode> _newMpinFocusNodes = List.generate(4, (index) => FocusNode());
  final List<FocusNode> _confirmMpinFocusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  bool _obscureCurrentMpin = true;
  bool _obscureNewMpin = true;
  bool _obscureConfirmMpin = true;
  String _errorMessage = '';

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in _currentMpinControllers) {
      controller.dispose();
    }
    for (var controller in _newMpinControllers) {
      controller.dispose();
    }
    for (var controller in _confirmMpinControllers) {
      controller.dispose();
    }

    // Dispose focus nodes
    for (var node in _currentMpinFocusNodes) {
      node.dispose();
    }
    for (var node in _newMpinFocusNodes) {
      node.dispose();
    }
    for (var node in _confirmMpinFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// Build MPIN input boxes
  Widget _buildMpinBoxes(List<TextEditingController> controllers, List<FocusNode> focusNodes, bool obscure) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNodes[index].hasFocus 
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
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: obscure,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty && index < 3) {
                focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
              
              // Clear error when user starts typing
              if (_errorMessage.isNotEmpty) {
                setState(() {
                  _errorMessage = '';
                });
              }
            },
          ),
        );
      }),
    );
  }

  /// Validate and change MPIN
  Future<void> _changeMpin() async {
    final currentMpin = _currentMpinControllers.map((c) => c.text).join();
    final newMpin = _newMpinControllers.map((c) => c.text).join();
    final confirmMpin = _confirmMpinControllers.map((c) => c.text).join();

    // Validation
    if (currentMpin.length != 4) {
      _showError('Please enter your current 4-digit MPIN');
      return;
    }

    if (newMpin.length != 4) {
      _showError('Please enter new 4-digit MPIN');
      return;
    }

    if (confirmMpin.length != 4) {
      _showError('Please confirm your new MPIN');
      return;
    }

    if (newMpin != confirmMpin) {
      _showError('New MPIN and confirm MPIN do not match');
      return;
    }

    if (currentMpin == newMpin) {
      _showError('New MPIN must be different from current MPIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get user phone from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('user_phone');
      
      if (userPhone == null) {
        _showError('User session not found. Please login again.');
        return;
      }

      // Encrypt MPINs
      final encryptedCurrentMpin = EncryptionService.encryptMPIN(currentMpin);
      final encryptedNewMpin = EncryptionService.encryptMPIN(newMpin);

      print('🔐 ChangeMpinScreen: Changing MPIN for user: $userPhone');

      // Call API to change MPIN
      final response = await http.post(
        Uri.parse('http://${SqlServerConfig.serverIP}:3001/api/change-mpin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': userPhone,
          'current_encrypted_mpin': encryptedCurrentMpin,
          'new_encrypted_mpin': encryptedNewMpin,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ ChangeMpinScreen: MPIN changed successfully');
          _showSuccessDialog();
        } else {
          _showError(data['message'] ?? 'Failed to change MPIN');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? 'Failed to change MPIN');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ ChangeMpinScreen: Error changing MPIN: $e');
      _showError('Network error. Please check your connection and try again.');
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('MPIN Changed'),
          ],
        ),
        content: const Text(
          'Your MPIN has been changed successfully. Please use your new MPIN for future logins.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to profile
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Clear all MPIN inputs
  void _clearAllInputs() {
    for (var controller in _currentMpinControllers) {
      controller.clear();
    }
    for (var controller in _newMpinControllers) {
      controller.clear();
    }
    for (var controller in _confirmMpinControllers) {
      controller.clear();
    }
    _currentMpinFocusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Change MPIN'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Change Your MPIN',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your current MPIN and create a new one',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Current MPIN Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current MPIN',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureCurrentMpin = !_obscureCurrentMpin;
                            });
                          },
                          child: Icon(
                            _obscureCurrentMpin ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMpinBoxes(_currentMpinControllers, _currentMpinFocusNodes, _obscureCurrentMpin),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // New MPIN Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New MPIN',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureNewMpin = !_obscureNewMpin;
                            });
                          },
                          child: Icon(
                            _obscureNewMpin ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMpinBoxes(_newMpinControllers, _newMpinFocusNodes, _obscureNewMpin),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm MPIN Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Confirm New MPIN',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureConfirmMpin = !_obscureConfirmMpin;
                            });
                          },
                          child: Icon(
                            _obscureConfirmMpin ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.primaryGold,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMpinBoxes(_confirmMpinControllers, _confirmMpinFocusNodes, _obscureConfirmMpin),
                  ],
                ),
              ),

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _clearAllInputs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changeMpin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Changing...' : 'Change MPIN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
