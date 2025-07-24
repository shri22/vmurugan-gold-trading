import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../models/onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel onboardingData;

  const OnboardingPage({
    super.key,
    required this.onboardingData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.getPadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          
          // Image/Icon Section
          Container(
            width: Responsive.getWidth(context) * 0.7,
            height: Responsive.getHeight(context) * 0.35,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildImageContent(context),
          ),
          
          const Spacer(flex: 1),
          
          // Title
          Text(
            onboardingData.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              onboardingData.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    // For now, we'll use icons since we don't have actual images
    // In a real app, you'd use Image.asset(onboardingData.imagePath)
    
    IconData iconData;
    switch (onboardingData.title) {
      case 'Invest in Digital Gold':
        iconData = Icons.diamond;
        break;
      case '11-Month Gold Scheme':
        iconData = Icons.savings;
        break;
      case 'Real-Time Gold Prices':
        iconData = Icons.trending_up;
        break;
      case 'Secure Digital Vault':
        iconData = Icons.security;
        break;
      default:
        iconData = Icons.star;
    }

    return Center(
      child: Icon(
        iconData,
        size: Responsive.getWidth(context) * 0.25,
        color: AppColors.white,
      ),
    );
  }
}

// Page Indicator Widget
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index 
                ? AppColors.primaryGold 
                : AppColors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
