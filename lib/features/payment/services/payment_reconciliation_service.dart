import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';

/// Payment Reconciliation Service
/// Handles automatic verification of pending payments
/// Ensures payments are never lost when users don't return to app
class PaymentReconciliationService {
  
  /// Check and reconcile pending payments on app startup
  /// Call this in main.dart after app initialization
  static Future<Map<String, dynamic>> checkPendingPayments() async {
    try {
      print('🔍 Checking for pending payments...');
      
      // Get customer phone
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('customer_phone');
      
      if (phone == null || phone.isEmpty) {
        print('⚠️ No customer phone found, skipping payment check');
        return {'success': false, 'message': 'Not logged in'};
      }

      // Get JWT token
      final token = await AuthService.getBackendToken();
      if (token == null) {
        print('⚠️ No auth token found');
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Call backend to get pending payments
      final url = '${ApiConfig.baseUrl}/payment/pending/$phone';
      print('📡 Fetching pending payments from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final pendingCount = data['pending_count'] ?? 0;
          final transactions = data['transactions'] ?? [];
          
          print('✅ Found $pendingCount pending transactions');
          
          if (pendingCount > 0) {
            print('📋 Pending transactions:');
            for (var txn in transactions) {
              print('   - ${txn['transaction_id']}: ${txn['status']} (${txn['minutes_pending']} min)');
            }
            
            // Show notification to user
            _showPendingPaymentsNotification(pendingCount);
          } else {
            print('✅ No pending payments found');
          }
          
          return {
            'success': true,
            'pending_count': pendingCount,
            'transactions': transactions
          };
        }
      } else {
        print('❌ API error: ${response.statusCode}');
      }
      
      return {'success': false, 'message': 'Failed to check pending payments'};
      
    } catch (e) {
      print('❌ Payment check error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Verify a specific transaction status
  /// Useful for manual retry after payment
  static Future<Map<String, dynamic>> verifyTransaction(String transactionId) async {
    try {
      print('🔍 Verifying transaction: $transactionId');
      
      // Get JWT token
      final token = await AuthService.getBackendToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '${ApiConfig.baseUrl}/payment/verify/$transactionId';
      print('📡 Verification URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final status = data['status'];
          final needsUpdate = data['needs_update'] ?? false;
          
          print('✅ Transaction verification complete:');
          print('   Status: $status');
          print('   Updated: $needsUpdate');
          
          return {
            'success': true,
            'status': status,
            'needs_update': needsUpdate,
            'data': data
          };
        }
      } else {
        print('❌ Verification API error: ${response.statusCode}');
      }
      
      return {'success': false, 'message': 'Verification failed'};
      
    } catch (e) {
      print('❌ Transaction verification error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Reconcile all pending payments for current user
  /// Checks each pending transaction and updates status
  static Future<Map<String, dynamic>> reconcileAllPending() async {
    try {
      print('🔄 Starting full payment reconciliation...');
      
      // First, get all pending payments
      final pendingResult = await checkPendingPayments();
      
      if (pendingResult['success'] != true) {
        return pendingResult;
      }

      final transactions = pendingResult['transactions'] as List? ?? [];
      
      if (transactions.isEmpty) {
        print('✅ No pending payments to reconcile');
        return {'success': true, 'reconciled': 0, 'message': 'No pending payments'};
      }

      int reconciled = 0;
      int success = 0;
      int failed = 0;

      // Verify each transaction
      for (var txn in transactions) {
        final txnId = txn['transaction_id'];
        final result = await verifyTransaction(txnId);
        
        if (result['success'] == true) {
          reconciled++;
          
          if (result['status'] == 'SUCCESS') {
            success++;
          } else if (result['status'] == 'FAILED') {
            failed++;
          }
        }
        
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('✅ Reconciliation complete:');
      print('   Total: ${transactions.length}');
      print('   Reconciled: $reconciled');
      print('   Success: $success');
      print('   Failed: $failed');

      return {
        'success': true,
        'total': transactions.length,
        'reconciled': reconciled,
        'success_count': success,
        'failed_count': failed
      };

    } catch (e) {
      print('❌ Reconciliation error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Show notification to user about pending payments
  static void _showPendingPaymentsNotification(int count) {
    // TODO: Show in-app notification or banner
    print('📱 Notification: You have $count pending payment(s) being verified');
  }

  /// Check if automatic payment checking is enabled
  static Future<bool> isAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_check_payments') ?? true;
  }

  /// Enable/disable automatic payment checking
  static Future<void> setAutoCheckEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_check_payments', enabled);
  }

  /// Get last payment check timestamp
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_payment_check');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Update last payment check timestamp
  static Future<void> updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_payment_check', DateTime.now().millisecondsSinceEpoch);
  }
}
