import 'package:flutter_test/flutter_test.dart';
import 'package:digi_gold/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter.roundToThreeDecimals', () {
    test('rounds up when 4th decimal is greater than 5', () {
      // 4th decimal is 6 - should round up
      expect(NumberFormatter.roundToThreeDecimals(2.3456), 2.346);
      
      // 4th decimal is 7 - should round up
      expect(NumberFormatter.roundToThreeDecimals(1.2347), 1.235);
      
      // 4th decimal is 8 - should round up
      expect(NumberFormatter.roundToThreeDecimals(3.1238), 3.124);
      
      // 4th decimal is 9 - should round up
      expect(NumberFormatter.roundToThreeDecimals(4.5679), 4.568);
    });

    test('keeps as-is when 4th decimal is 5 or less', () {
      // 4th decimal is 5 - should keep as-is
      expect(NumberFormatter.roundToThreeDecimals(2.3455), 2.345);
      
      // 4th decimal is 4 - should keep as-is
      expect(NumberFormatter.roundToThreeDecimals(1.2344), 1.234);
      
      // 4th decimal is 3 - should keep as-is
      expect(NumberFormatter.roundToThreeDecimals(1.2343), 1.234);
      
      // 4th decimal is 2 - should keep as-is
      expect(NumberFormatter.roundToThreeDecimals(5.6782), 5.678);
      
      // 4th decimal is 1 - should keep as-is
      expect(NumberFormatter.roundToThreeDecimals(7.8901), 7.890);
      
      // 4th decimal is 0 - should keep as-is
      expect(NumberFormatter.roundToThreeDecimals(3.4560), 3.456);
    });

    test('handles edge cases', () {
      // Very small number
      expect(NumberFormatter.roundToThreeDecimals(0.0001), 0.000);
      
      // Zero
      expect(NumberFormatter.roundToThreeDecimals(0.0), 0.000);
      
      // Large number
      expect(NumberFormatter.roundToThreeDecimals(1234.5678), 1234.568);
      
      // Number with exactly 3 decimals
      expect(NumberFormatter.roundToThreeDecimals(5.123), 5.123);
    });
  });

  group('NumberFormatter.formatToThreeDecimals', () {
    test('formats to exactly 3 decimal places string', () {
      expect(NumberFormatter.formatToThreeDecimals(2.3456), '2.346');
      expect(NumberFormatter.formatToThreeDecimals(1.2347), '1.235');
      expect(NumberFormatter.formatToThreeDecimals(2.3455), '2.345');
      expect(NumberFormatter.formatToThreeDecimals(1.2343), '1.234');
      expect(NumberFormatter.formatToThreeDecimals(3.4560), '3.456');
    });

    test('always shows 3 decimal places even for whole numbers', () {
      expect(NumberFormatter.formatToThreeDecimals(5.0), '5.000');
      expect(NumberFormatter.formatToThreeDecimals(10.1), '10.100');
      expect(NumberFormatter.formatToThreeDecimals(0.0), '0.000');
    });
  });

  group('Real-world gold/silver calculation examples', () {
    test('calculates gold grams correctly', () {
      // Example: ₹5000 / ₹6500 per gram = 0.7692307692... grams
      // 4th decimal is 2, should keep as-is → 0.769 grams
      double amount = 5000.0;
      double pricePerGram = 6500.0;
      double grams = amount / pricePerGram;
      expect(NumberFormatter.formatToThreeDecimals(grams), '0.769');
    });

    test('calculates silver grams correctly', () {
      // Example: ₹1000 / ₹85 per gram = 11.7647058823... grams
      // 4th decimal is 7, should round up → 11.765 grams
      double amount = 1000.0;
      double pricePerGram = 85.0;
      double grams = amount / pricePerGram;
      expect(NumberFormatter.formatToThreeDecimals(grams), '11.765');
    });

    test('handles rounding up scenario', () {
      // Example: ₹10000 / ₹6543 per gram = 1.5283567... grams
      // 4th decimal is 3, should keep as-is → 1.528 grams
      double amount = 10000.0;
      double pricePerGram = 6543.0;
      double grams = amount / pricePerGram;
      expect(NumberFormatter.formatToThreeDecimals(grams), '1.528');
    });
  });
}

