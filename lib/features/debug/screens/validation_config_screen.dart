import 'package:flutter/material.dart';
import '../../../core/config/validation_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ValidationConfigScreen extends StatelessWidget {
  const ValidationConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ValidationConfig.getConfigSummary();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Configuration'),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Mode Card
            _buildModeCard(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Configuration Details
            _buildConfigCard(config),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Instructions Card
            _buildInstructionsCard(),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Test Validation Card
            _buildTestCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ValidationConfig.isDemoMode ? Icons.science : Icons.security,
                  color: ValidationConfig.isDemoMode ? Colors.orange : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Mode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: ValidationConfig.isDemoMode 
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ValidationConfig.isDemoMode 
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ValidationConfig.currentMode.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ValidationConfig.isDemoMode ? Colors.orange[700] : Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ValidationConfig.currentMode.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (ValidationConfig.isDemoMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Demo OTP: ${ValidationConfig.demoOtp}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...config.entries.map((entry) => _buildConfigRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              _formatKey(key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Switch Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...ValidationConfig.getProductionSwitchInstructions().asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  entry.value,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Validation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTestRow('Phone Number', '9876543210', ValidationConfig.validatePhoneNumber('9876543210')),
            _buildTestRow('MPIN', '1234', ValidationConfig.validateMpin('1234')),
            _buildTestRow('PAN Card', 'ABCDE1234F', ValidationConfig.validatePanCard('ABCDE1234F')),
            _buildTestRow('Email', 'test@example.com', ValidationConfig.validateEmail('test@example.com')),
            _buildTestRow('Name', 'John Doe', ValidationConfig.validateName('John Doe')),
            if (ValidationConfig.isDemoMode)
              _buildTestRow('Demo OTP', ValidationConfig.demoOtp, ValidationConfig.validateOtp(ValidationConfig.demoOtp, ValidationConfig.demoOtp)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRow(String label, String value, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }
}
