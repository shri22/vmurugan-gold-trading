/// Utility functions for number formatting with custom rounding logic
class NumberFormatter {
  /// Rounds a double to exactly 3 decimal places with custom rounding logic:
  /// - If 4th decimal digit is > 5 (6,7,8,9): Round UP the 3rd decimal digit
  /// - If 4th decimal digit is ≤ 5 (0,1,2,3,4,5): Keep 3rd decimal digit as-is (truncate)
  /// 
  /// Examples:
  /// - 2.3456 → 2.346 (4th digit is 6, round up)
  /// - 1.2347 → 1.235 (4th digit is 7, round up)
  /// - 2.3455 → 2.345 (4th digit is 5, keep as-is)
  /// - 1.2343 → 1.234 (4th digit is 3, keep as-is)
  /// - 3.4560 → 3.456 (4th digit is 0, keep as-is)
  static double roundToThreeDecimals(double value) {
    // Multiply by 10000 to get 4 decimal places as whole number
    // Example: 2.3456 * 10000 = 23456
    double multiplied = value * 10000;
    
    // Get the integer part (removes any decimals beyond 4th place)
    int intValue = multiplied.floor();
    
    // Extract the 4th decimal digit
    // Example: 23456 % 10 = 6
    int fourthDecimal = intValue % 10;
    
    // Get the first 3 decimal places
    // Example: 23456 ~/ 10 = 2345
    int threeDecimalValue = intValue ~/ 10;
    
    // Apply custom rounding logic
    if (fourthDecimal > 5) {
      // Round up: increment the 3rd decimal digit
      threeDecimalValue += 1;
    }
    // If fourthDecimal <= 5, keep as-is (no change needed)
    
    // Convert back to double with 3 decimal places
    // Example: 2346 / 1000 = 2.346
    return threeDecimalValue / 1000.0;
  }
  
  /// Formats a double to exactly 3 decimal places string with custom rounding
  /// Returns format: "x.xxx"
  /// 
  /// Examples:
  /// - 2.3456 → "2.346"
  /// - 1.2347 → "1.235"
  /// - 2.3455 → "2.345"
  /// - 1.2343 → "1.234"
  static String formatToThreeDecimals(double value) {
    double rounded = roundToThreeDecimals(value);
    return rounded.toStringAsFixed(3);
  }
}

