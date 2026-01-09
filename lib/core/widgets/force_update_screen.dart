import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';
import 'vmurugan_logo.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String message;
  final String updateUrl;

  const ForceUpdateScreen({
    super.key,
    required this.message,
    required this.updateUrl,
  });

  Future<void> _launchUpdateUrl() async {
    final Uri url = Uri.parse(updateUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $updateUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const VMuruganLogo(size: 100),
              const SizedBox(height: 48),
              const Icon(
                Icons.system_update,
                size: 64,
                color: AppColors.primaryGold,
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Update Now',
                onPressed: _launchUpdateUrl,
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Please update the app to the latest version to continue using our services safely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
