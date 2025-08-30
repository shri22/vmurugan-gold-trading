class ValidationConfig {
  static const bool isDemoMode = false; // Production mode
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
}
