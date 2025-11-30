import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vmurugan_logo.dart';

class ConsolidatedReportScreen extends StatelessWidget {
  final String? customerPhone;
  const ConsolidatedReportScreen({Key? key, this.customerPhone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const VMuruganAppBarLogo(
          logoSize: 28,
          fontSize: 16,
          textColor: AppColors.primaryGreen,
        ),
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: const Center(child: Text('Consolidated Report - Coming Soon')),
    );
  }
}

