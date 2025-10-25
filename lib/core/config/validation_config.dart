class ValidationConfig {
  static const bool isDemoMode = false; // Production mode - Firebase SMS

  // Payment sandbox mode configuration (for Worldline testing)
  static const bool isPaymentSandboxMode = true; // Enable ₹1-₹10 payments
  static const String _demoOtp = '123456';
  static const Duration demoOtpExpiry = Duration(minutes: 5);
  static const Duration productionOtpExpiry = Duration(minutes: 5);

  static String getModeDescription() {
    return isDemoMode ? 'Demo Mode' : 'Production Mode';
  }

  static String getOtp() {
    return _demoOtp;
  }

  static bool validateOtp(String enteredOtp, String storedOtp) {
    return enteredOtp == storedOtp;
  }

  // Additional methods for ValidationConfigScreen
  static String get currentMode => getModeDescription();

  static String get demoOtp => _demoOtp;

  static Map<String, dynamic> getConfigSummary() {
    return {
      'mode': currentMode,
      'isDemoMode': isDemoMode,
      'demoOtp': demoOtp,
      'demoOtpExpiry': demoOtpExpiry.inMinutes,
      'productionOtpExpiry': productionOtpExpiry.inMinutes,
    };
  }

  static String getProductionSwitchInstructions() {
    return 'To switch to production mode:\n'
           '1. Set isDemoMode = false in validation_config.dart\n'
           '2. Rebuild the application\n'
           '3. Test with real OTP service';
  }

  // Validation methods
  static bool validatePhoneNumber(String phone) {
    return phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  static bool validateMpin(String mpin) {
    return mpin.length == 4 && RegExp(r'^[0-9]+$').hasMatch(mpin);
  }

  static bool validatePanCard(String pan) {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan);
  }

  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool validateName(String name) {
    return name.trim().length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  // Payment amount validation
  static double getMinimumPaymentAmount() {
    return isPaymentSandboxMode ? 1.0 : 100.0;
  }

  static double getMaximumPaymentAmount() {
    return isPaymentSandboxMode ? 10.0 : 1000000.0;
  }

  static String? validatePaymentAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    final minAmount = getMinimumPaymentAmount();
    final maxAmount = getMaximumPaymentAmount();

    if (amount < minAmount) {
      return isPaymentSandboxMode
        ? 'Minimum amount is ₹$minAmount for sandbox testing'
        : 'Minimum amount is ₹${minAmount.toInt()}';
    }

    if (amount > maxAmount) {
      return isPaymentSandboxMode
        ? 'Maximum amount is ₹$maxAmount for sandbox testing'
        : 'Maximum amount is ₹${maxAmount.toInt()}';
    }

    return null;
  }
}
