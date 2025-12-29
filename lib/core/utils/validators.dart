class Validators {
  /// Validates if an MPIN is strong enough based on server-side rules.
  /// Returns a string with the error message if weak, or null if strong.
  static String? validateMPINStrength(String mpin) {
    if (mpin.isEmpty) {
      return 'MPIN is required';
    }
    
    if (mpin.length != 4) {
      return 'MPIN must be 4 digits';
    }
    
    if (!RegExp(r'^[0-9]{4}$').hasMatch(mpin)) {
      return 'MPIN must contain only numbers';
    }
    
    // Check for identical digits (e.g., 1111, 0000)
    if (mpin[0] == mpin[1] && mpin[1] == mpin[2] && mpin[2] == mpin[3]) {
      return 'MPIN cannot have all identical digits';
    }
    
    // Check for sequential digits (e.g., 1234, 4321, 6789, 9876)
    final digits = mpin.split('').map(int.parse).toList();
    
    bool isForwardSequential = true;
    bool isBackwardSequential = true;
    
    for (int i = 0; i < 3; i++) {
      if (digits[i + 1] != digits[i] + 1) {
        isForwardSequential = false;
      }
      if (digits[i + 1] != digits[i] - 1) {
        isBackwardSequential = false;
      }
    }
    
    if (isForwardSequential || isBackwardSequential) {
      return 'MPIN cannot be a simple sequence of digits';
    }
    
    // Common weak patterns
    const weakPatterns = ['1212', '1010', '2020', '2580', '0852'];
    if (weakPatterns.contains(mpin)) {
      return 'This MPIN is too common. Please choose a stronger one.';
    }
    
    return null;
  }
}
