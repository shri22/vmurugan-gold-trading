import '../../features/schemes/models/scheme_installment_model.dart';
import '../enums/metal_type.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_service.dart';

class SchemeManagementService {
  static final SchemeManagementService _instance = SchemeManagementService._internal();
  factory SchemeManagementService() => _instance;
  SchemeManagementService._internal();

  /// Get customer's active schemes
  Future<List<SchemeModel>> getCustomerSchemes(String customerPhone) async {
    try {
      // This would typically call your API to get schemes
      // For now, return empty list - will be implemented with actual API calls
      return [];
    } catch (e) {
      print('Error getting customer schemes: $e');
      return [];
    }
  }

  /// Get customer's scheme for specific metal type
  Future<SchemeModel?> getCustomerSchemeByMetal(String customerPhone, MetalType metalType) async {
    try {
      final schemes = await getCustomerSchemes(customerPhone);
      return schemes
          .where((scheme) => scheme.metalType == metalType && scheme.isActive)
          .isNotEmpty
          ? schemes.where((scheme) => scheme.metalType == metalType && scheme.isActive).first
          : null;
    } catch (e) {
      print('Error getting customer scheme by metal: $e');
      return null;
    }
  }

  /// Create new scheme with installments
  Future<SchemeModel> createScheme({
    required String customerPhone,
    required String customerName,
    required double monthlyAmount,
    required MetalType metalType,
    int durationMonths = 15,
  }) async {
    try {
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo['customer_id'] ?? '';

      final now = DateTime.now();
      final schemeId = await _generateSchemeId(customerId, metalType);

      // Create scheme
      final scheme = SchemeModel(
        schemeId: schemeId,
        customerId: customerId,
        customerPhone: customerPhone,
        customerName: customerName,
        monthlyAmount: monthlyAmount,
        durationMonths: durationMonths,
        schemeType: metalType == MetalType.gold ? 'GOLDPLUS' : 'SILVERPLUS',
        metalType: metalType,
        status: 'ACTIVE',
        startDate: now,
        totalAmount: 0.0,
        totalMetalGrams: 0.0,
        completedInstallments: 0,
        businessId: 'VMURUGAN_001',
        createdAt: now,
        updatedAt: now,
      );

      // Create all 15 installments
      final installments = await _createSchemeInstallments(scheme);

      // Save scheme to database
      await _saveSchemeToDatabase(scheme);

      // Save installments to database
      for (final installment in installments) {
        await _saveInstallmentToDatabase(installment);
      }

      return scheme.copyWith(installments: installments);
    } catch (e) {
      print('Error creating scheme: $e');
      rethrow;
    }
  }

  /// Create all 15 installments for a scheme
  Future<List<SchemeInstallmentModel>> _createSchemeInstallments(SchemeModel scheme) async {
    final installments = <SchemeInstallmentModel>[];

    for (int i = 1; i <= scheme.durationMonths; i++) {
      final dueDate = DateTime(
        scheme.startDate.year,
        scheme.startDate.month + i - 1,
        scheme.startDate.day,
      );

      final installment = SchemeInstallmentModel(
        installmentId: '${scheme.schemeId}_INST_${i.toString().padLeft(2, '0')}',
        schemeId: scheme.schemeId,
        customerPhone: scheme.customerPhone,
        installmentNumber: i,
        amount: scheme.monthlyAmount,
        metalGrams: 0.0, // Will be calculated at payment time based on current price
        metalPricePerGram: 0.0, // Will be set at payment time
        metalType: scheme.metalType,
        status: InstallmentStatus.pending,
        dueDate: dueDate,
        businessId: scheme.businessId,
        createdAt: scheme.createdAt,
        updatedAt: scheme.updatedAt,
      );

      installments.add(installment);
    }

    return installments;
  }

  /// Pay installment
  Future<SchemeInstallmentModel> payInstallment({
    required String installmentId,
    required double metalPricePerGram,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      // Get installment
      final installment = await _getInstallmentById(installmentId);
      if (installment == null) {
        throw Exception('Installment not found');
      }

      // Calculate metal grams based on current price
      final metalGrams = installment.amount / metalPricePerGram;

      // Update installment
      final updatedInstallment = installment.copyWith(
        metalGrams: metalGrams,
        metalPricePerGram: metalPricePerGram,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        status: InstallmentStatus.paid,
        paidDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save updated installment
      await _updateInstallmentInDatabase(updatedInstallment);

      // Update scheme progress
      await _updateSchemeProgress(installment.schemeId);

      return updatedInstallment;
    } catch (e) {
      print('Error paying installment: $e');
      rethrow;
    }
  }

  /// Get installment by ID
  Future<SchemeInstallmentModel?> _getInstallmentById(String installmentId) async {
    // This would query the database for the installment
    // For now, return null - will be implemented with actual database calls
    return null;
  }

  /// Update scheme progress after installment payment
  Future<void> _updateSchemeProgress(String schemeId) async {
    try {
      // Get all paid installments for this scheme
      final paidInstallments = await _getPaidInstallmentsCount(schemeId);
      final totalMetalGrams = await _getTotalMetalGrams(schemeId);
      final totalAmount = await _getTotalPaidAmount(schemeId);

      // Update scheme in database
      await _updateSchemeInDatabase(schemeId, {
        'completed_installments': paidInstallments,
        'total_metal_grams': totalMetalGrams,
        'total_amount': totalAmount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating scheme progress: $e');
    }
  }

  /// Generate unique scheme ID
  Future<String> _generateSchemeId(String customerId, MetalType metalType) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final metalPrefix = metalType == MetalType.gold ? 'G' : 'S';
    return '${customerId}_${metalPrefix}SCH_$timestamp';
  }

  /// Database operations (to be implemented with actual database calls)
  Future<void> _saveSchemeToDatabase(SchemeModel scheme) async {
    // Implementation depends on your database choice (Firebase, SQL Server, etc.)
    print('Saving scheme to database: ${scheme.schemeId}');
  }

  Future<void> _saveInstallmentToDatabase(SchemeInstallmentModel installment) async {
    // Implementation depends on your database choice
    print('Saving installment to database: ${installment.installmentId}');
  }

  Future<void> _updateInstallmentInDatabase(SchemeInstallmentModel installment) async {
    // Implementation depends on your database choice
    print('Updating installment in database: ${installment.installmentId}');
  }

  Future<void> _updateSchemeInDatabase(String schemeId, Map<String, dynamic> updates) async {
    // Implementation depends on your database choice
    print('Updating scheme in database: $schemeId');
  }

  Future<int> _getPaidInstallmentsCount(String schemeId) async {
    // Query database for paid installments count
    return 0;
  }

  Future<double> _getTotalMetalGrams(String schemeId) async {
    // Query database for total metal grams
    return 0.0;
  }

  Future<double> _getTotalPaidAmount(String schemeId) async {
    // Query database for total paid amount
    return 0.0;
  }

  /// Get scheme status for main screen display
  Future<Map<String, dynamic>> getSchemeStatusForMainScreen(String customerPhone) async {
    try {
      final goldScheme = await getCustomerSchemeByMetal(customerPhone, MetalType.gold);
      final silverScheme = await getCustomerSchemeByMetal(customerPhone, MetalType.silver);

      return {
        'gold': {
          'hasScheme': goldScheme != null,
          'scheme': goldScheme,
          'buttonText': goldScheme?.nextInstallmentText ?? 'Join Now',
          'isNextInstallment': goldScheme != null && goldScheme.completedInstallments > 0,
        },
        'silver': {
          'hasScheme': silverScheme != null,
          'scheme': silverScheme,
          'buttonText': silverScheme?.nextInstallmentText ?? 'Join Now',
          'isNextInstallment': silverScheme != null && silverScheme.completedInstallments > 0,
        },
      };
    } catch (e) {
      print('Error getting scheme status: $e');
      return {
        'gold': {
          'hasScheme': false,
          'scheme': null,
          'buttonText': 'Join Now',
          'isNextInstallment': false,
        },
        'silver': {
          'hasScheme': false,
          'scheme': null,
          'buttonText': 'Join Now',
          'isNextInstallment': false,
        },
      };
    }
  }
}
