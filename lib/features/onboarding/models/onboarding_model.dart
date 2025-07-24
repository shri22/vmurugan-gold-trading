class OnboardingModel {
  final String title;
  final String description;
  final String imagePath;
  final String? animationPath; // For Lottie animations if needed later

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.animationPath,
  });
}

class OnboardingData {
  static const List<OnboardingModel> onboardingPages = [
    OnboardingModel(
      title: 'Invest in Digital Gold',
      description: 'Start your gold investment journey with as little as ₹1. Buy, sell, and store gold digitally with complete security.',
      imagePath: 'assets/images/onboarding_1.png',
    ),
    OnboardingModel(
      title: '11-Month Gold Scheme',
      description: 'Join our exclusive 11-month gold accumulation scheme. Invest ₹2000 monthly and watch your gold portfolio grow.',
      imagePath: 'assets/images/onboarding_2.png',
    ),
    OnboardingModel(
      title: 'Real-Time Gold Prices',
      description: 'Get live gold prices updated every minute. Make informed investment decisions with accurate market data.',
      imagePath: 'assets/images/onboarding_3.png',
    ),
    OnboardingModel(
      title: 'Secure Digital Vault',
      description: 'Your gold is stored securely in our digital vault. Track your holdings, view certificates, and manage your portfolio.',
      imagePath: 'assets/images/onboarding_4.png',
    ),
  ];
}
