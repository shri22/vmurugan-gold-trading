import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/onboarding_model.dart';
import '../widgets/onboarding_page.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingModel> _pages = OnboardingData.onboardingPages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip and Replay
            _buildTopBar(),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(onboardingData: _pages[index]);
                },
              ),
            ),
            
            // Bottom Section with Indicator and Navigation
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Replay Button (only show if not on first page)
          _currentPage > 0
              ? TextButton.icon(
                  onPressed: _replayOnboarding,
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                  ),
                )
              : const SizedBox(width: 80),
          
          // Logo/Title
          Text(
            'Digi Gold',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          
          // Skip Button (only show if not on last page)
          _currentPage < _pages.length - 1
              ? TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Skip'),
                )
              : const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: EdgeInsets.all(
        AppSpacing.responsive(context, mobile: 24, tablet: 32),
      ),
      child: Column(
        children: [
          // Page Indicator
          PageIndicator(
            currentPage: _currentPage,
            totalPages: _pages.length,
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Navigation Buttons
          Row(
            children: [
              // Previous Button
              if (_currentPage > 0)
                Expanded(
                  child: CustomButton(
                    text: 'Previous',
                    onPressed: _previousPage,
                    type: ButtonType.outline,
                    icon: Icons.arrow_back,
                  ),
                ),
              
              if (_currentPage > 0) const SizedBox(width: AppSpacing.md),
              
              // Next/Get Started Button
              Expanded(
                flex: _currentPage == 0 ? 1 : 1,
                child: _currentPage < _pages.length - 1
                    ? CustomButton(
                        text: 'Next',
                        onPressed: _nextPage,
                        type: ButtonType.primary,
                        icon: Icons.arrow_forward,
                        isFullWidth: true,
                      )
                    : GradientButton(
                        text: 'Get Started',
                        onPressed: _getStarted,
                        gradient: AppColors.goldGreenGradient,
                        icon: Icons.rocket_launch,
                        isFullWidth: true,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _navigateToLogin();
  }

  void _replayOnboarding() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() {
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}

// Onboarding Entry Point Widget
class OnboardingWrapper extends StatelessWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd check if user has seen onboarding before
    // For now, we'll always show onboarding
    return const OnboardingScreen();
  }
}
