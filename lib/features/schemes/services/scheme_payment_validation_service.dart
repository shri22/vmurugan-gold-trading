import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/metal_type.dart';
import '../../../core/services/customer_service.dart';
import '../models/scheme_installment_model.dart';

class SchemePaymentValidationService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Validate if customer can make payment for a scheme
  /// Returns validation result with message
  static Future<SchemePaymentValidationResult> validateSchemePayment({
    required String schemeId,
    required String customerPhone,
    required double amount,
  }) async {
    try {
      print('🔍 VALIDATION: Starting validation for scheme_id: $schemeId');
      print('🔍 VALIDATION: Customer phone: $customerPhone');
      print('🔍 VALIDATION: Amount: $amount');

      // Get scheme details first
      final schemeDetails = await _getSchemeDetails(schemeId);

      print('🔍 VALIDATION: Scheme details result: $schemeDetails');

      if (schemeDetails == null) {
        print('❌ VALIDATION: Scheme not found for scheme_id: $schemeId');
        return SchemePaymentValidationResult(
          canPay: false,
          message: 'Scheme not found for ID: $schemeId',
          errorType: ValidationErrorType.schemeNotFound,
        );
      }

      print('✅ VALIDATION: Scheme found, type: ${schemeDetails['scheme_type']}');

      final schemeType = schemeDetails['scheme_type'] as String;
      
      // For FLEXI schemes, always allow payment (no restrictions)
      if (schemeType == 'GOLDFLEXI' || schemeType == 'SILVERFLEXI') {
        return SchemePaymentValidationResult(
          canPay: true,
          message: 'Payment allowed for flexible scheme',
          errorType: null,
        );
      }

      // For PLUS schemes (GOLDPLUS, SILVERPLUS), check monthly payment restrictions
      if (schemeType == 'GOLDPLUS' || schemeType == 'SILVERPLUS') {
        return await _validateMonthlyPayment(schemeId, customerPhone, schemeType);
      }

      return SchemePaymentValidationResult(
        canPay: false,
        message: 'Unknown scheme type',
        errorType: ValidationErrorType.unknownSchemeType,
      );

    } catch (e) {
      print('Error validating scheme payment: $e');
      return SchemePaymentValidationResult(
        canPay: false,
        message: 'Validation error: ${e.toString()}',
        errorType: ValidationErrorType.systemError,
      );
    }
  }

  /// Validate monthly payment for PLUS schemes
  static Future<SchemePaymentValidationResult> _validateMonthlyPayment(
    String schemeId,
    String customerPhone,
    String schemeType,
  ) async {
    try {
      // Get current month and year
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Check if there's already a successful payment this month
      final hasPaymentThisMonth = await _hasSuccessfulPaymentThisMonth(
        schemeId,
        customerPhone,
        currentMonth,
        currentYear,
      );

      if (hasPaymentThisMonth) {
        return SchemePaymentValidationResult(
          canPay: false,
          message: 'You have already made your payment for this month. Please pay next month.',
          errorType: ValidationErrorType.monthlyPaymentAlreadyMade,
        );
      }

      return SchemePaymentValidationResult(
        canPay: true,
        message: 'Payment allowed for this month',
        errorType: null,
      );

    } catch (e) {
      print('Error validating monthly payment: $e');
      return SchemePaymentValidationResult(
        canPay: false,
        message: 'Error checking monthly payment status',
        errorType: ValidationErrorType.systemError,
      );
    }
  }

  /// Check if customer has successful payment this month
  static Future<bool> _hasSuccessfulPaymentThisMonth(
    String schemeId,
    String customerPhone,
    int month,
    int year,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/schemes/$schemeId/payments/monthly-check?month=$month&year=$year'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['has_payment'] == true;
      }

      return false;
    } catch (e) {
      print('Error checking monthly payment: $e');
      return false;
    }
  }

  /// Get scheme details
  static Future<Map<String, dynamic>?> _getSchemeDetails(String schemeId) async {
    try {
      final url = '$_baseUrl/api/schemes/details/$schemeId';
      print('🔍 GET SCHEME DETAILS: Calling URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 GET SCHEME DETAILS: Response status: ${response.statusCode}');
      print('🔍 GET SCHEME DETAILS: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ GET SCHEME DETAILS: Scheme found');
          return data['scheme'];
        } else {
          print('❌ GET SCHEME DETAILS: Success=false, message: ${data['message']}');
        }
      } else {
        print('❌ GET SCHEME DETAILS: HTTP error ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('❌ GET SCHEME DETAILS: Exception: $e');
      return null;
    }
  }

  /// Ensure single scheme ID for FLEXI schemes
  static Future<String?> getOrCreateFlexiSchemeId({
    required String customerPhone,
    required MetalType metalType,
  }) async {
    try {
      final schemeType = metalType == MetalType.gold ? 'GOLDFLEXI' : 'SILVERFLEXI';
      
      // Check if customer already has a FLEXI scheme of this type
      final existingScheme = await _getExistingFlexiScheme(customerPhone, schemeType);
      
      if (existingScheme != null) {
        return existingScheme['scheme_id'] as String;
      }

      // Create new FLEXI scheme if none exists
      return await _createFlexiScheme(customerPhone, metalType, schemeType);

    } catch (e) {
      print('Error getting/creating flexi scheme: $e');
      return null;
    }
  }

  /// Get existing FLEXI scheme for customer
  static Future<Map<String, dynamic>?> _getExistingFlexiScheme(
    String customerPhone,
    String schemeType,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/schemes/$customerPhone'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final schemes = data['schemes'] as List;
          
          // Find existing FLEXI scheme of the same type
          for (final scheme in schemes) {
            if (scheme['scheme_type'] == schemeType && scheme['status'] == 'ACTIVE') {
              return scheme;
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error getting existing flexi scheme: $e');
      return null;
    }
  }

  /// Create new FLEXI scheme
  static Future<String?> _createFlexiScheme(
    String customerPhone,
    MetalType metalType,
    String schemeType,
  ) async {
    try {
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerName = customerInfo['name'] ?? 'Customer';

      final response = await http.post(
        Uri.parse('$_baseUrl/api/schemes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer_phone': customerPhone,
          'customer_name': customerName,
          'scheme_type': schemeType,
          'monthly_amount': 0.0, // FLEXI schemes don't have fixed monthly amount
          'terms_accepted': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['scheme_id'] as String;
        }
      }

      return null;
    } catch (e) {
      print('Error creating flexi scheme: $e');
      return null;
    }
  }
}

/// Result of scheme payment validation
class SchemePaymentValidationResult {
  final bool canPay;
  final String message;
  final ValidationErrorType? errorType;

  const SchemePaymentValidationResult({
    required this.canPay,
    required this.message,
    this.errorType,
  });

  @override
  String toString() {
    return 'SchemePaymentValidationResult(canPay: $canPay, message: $message, errorType: $errorType)';
  }
}

/// Types of validation errors
enum ValidationErrorType {
  schemeNotFound,
  monthlyPaymentAlreadyMade,
  unknownSchemeType,
  systemError,
}
