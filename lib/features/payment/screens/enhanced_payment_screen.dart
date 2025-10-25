// WORLDLINE PAYMENT SCREEN - Official Flutter Plugin Implementation
// Following Payment_GateWay.md specifications exactly

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, Directory, File, FileMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weipl_checkout_flutter/weipl_checkout_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/payment_response.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/secure_http_client.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';
// Removed problematic imports

class EnhancedPaymentScreen extends StatefulWidget {
  final double amount;
  final double goldGrams;
  final String description;
  final Function(PaymentResponse) onPaymentComplete;

  const EnhancedPaymentScreen({
    super.key,
    required this.amount,
    required this.goldGrams,
    required this.description,
    required this.onPaymentComplete,
  });

  @override
  State<EnhancedPaymentScreen> createState() => _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends State<EnhancedPaymentScreen> {
  bool _isProcessing = false;
  String _statusMessage = 'Ready to start payment';
  String? _paymentToken;
  Map<String, dynamic>? _tokenData;
  String? _sessionId; // Unique session ID for this payment attempt
  final List<String> _debugLogs = [];
  final ScrollController _logScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  bool _isAutoScrolling = false;

  // Worldline Flutter Plugin instance
  WeiplCheckoutFlutter wlCheckoutFlutter = WeiplCheckoutFlutter();

  // Debug logger instance
  // Debug logger removed for now

  @override
  void initState() {
    super.initState();
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Initialize debug logger
    _initializeDebugLogger();

    _logToFile('🔍 WORLDLINE FLUTTER PLUGIN - initState() called');
    _logToFile('🔍 Amount: ₹${widget.amount.round()} (converted from ${widget.amount})');
    _logToFile('🔍 Description: ${widget.description}');

    // Setup Worldline event listeners
    _setupWorldlineEventListeners();
  }

  Future<void> _initializeDebugLogger() async {
    // Debug logger removed for now
    _logToFile('Enhanced Payment Screen Initialized');
  }

  // Log to file function with better accessibility AND add to UI
  Future<void> _logToFile(String message) async {
    // Add to UI logs first
    _addDebugLog(message);

    try {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] $message\n';

      // Try multiple storage locations for better accessibility
      Directory? logsDir;

      try {
        // Try external storage first (more accessible)
        final directory = await getApplicationDocumentsDirectory();
        logsDir = Directory('${directory.path}/logs');

        // Create logs directory if it doesn't exist
        if (!await logsDir.exists()) {
          await logsDir.create(recursive: true);
        }

        // Create log file with session ID
        final logFile = File('${logsDir.path}/payment_log_$_sessionId.txt');

        // Append log message to file
        await logFile.writeAsString(logMessage, mode: FileMode.append);

        // Also print to console for debugging
        print(message);
        print('📁 Log saved to: ${logFile.path}');

      } catch (storageError) {
        // Fallback: just log to console if file access fails
        print('⚠️ File logging failed, using console only: $storageError');
        print(message);
      }
    } catch (e) {
      print('❌ Error in logging function: $e');
      print(message); // Always ensure message is logged somewhere
    }
  }

  void _setupWorldlineEventListeners() {
    _logToFile('🔧 Setting up Worldline event listeners...');
    wlCheckoutFlutter.on(WeiplCheckoutFlutter.wlResponse, _handleWorldlineResponse);
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugLogs.add('[$timestamp] $message');
      if (_debugLogs.length > 50) {
        _debugLogs.removeAt(0); // Keep only last 50 logs
      }
    });
    print(message); // Also print to console

    // Auto-scroll to bottom with improved timing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients && _debugLogs.isNotEmpty) {
      setState(() {
        _isAutoScrolling = true;
      });

      try {
        // Use a small delay to ensure the ListView has been rebuilt
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ).then((_) {
              // Hide auto-scrolling indicator after animation completes
              if (mounted) {
                setState(() {
                  _isAutoScrolling = false;
                });
              }
            });
          }
        });
      } catch (e) {
        // Fallback: try immediate scroll without animation
        try {
          if (_logScrollController.hasClients) {
            _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
          }
        } catch (e) {
          print('Debug: Auto-scroll failed: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isAutoScrolling = false;
            });
          }
        }
      }
    }
  }

  void _scrollToErrorSection() {
    // Scroll the main screen to show error details
    if (_mainScrollController.hasClients) {
      try {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_mainScrollController.hasClients) {
            _mainScrollController.animateTo(
              _mainScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      } catch (e) {
        print('Debug: Main screen scroll failed: $e');
      }
    }
  }

  Future<void> _copyAllLogs() async {
    if (_debugLogs.isEmpty) {
      _showSnackBar('No logs to copy', isError: false);
      return;
    }

    try {
      // Create a comprehensive log report
      final timestamp = DateTime.now().toIso8601String();
      final sessionInfo = _sessionId != null ? 'Session ID: $_sessionId\n' : '';
      final statusInfo = _statusMessage.isNotEmpty ? 'Status: $_statusMessage\n' : '';

      final logReport = '''
=== WORLDLINE PAYMENT DEBUG LOGS ===
Generated: $timestamp
${sessionInfo}${statusInfo}
Amount: ₹${widget.amount}
Gold Quantity: ${(widget.amount / 7000).toStringAsFixed(3)}g

=== DEBUG LOGS (${_debugLogs.length} entries) ===
${_debugLogs.join('\n')}

=== END OF LOGS ===
''';

      await Clipboard.setData(ClipboardData(text: logReport));
      _showSnackBar('All logs copied to clipboard!', isError: false);

      // Also log the copy action
      _addDebugLog('📋 All logs copied to clipboard (${_debugLogs.length} entries)');

    } catch (e) {
      _showSnackBar('Failed to copy logs: $e', isError: true);
      print('Copy logs error: $e');
    }
  }

  Future<void> _copyLatestLogs() async {
    if (_debugLogs.isEmpty) {
      _showSnackBar('No logs to copy', isError: false);
      return;
    }

    try {
      // Get the latest 10 logs (or all if less than 10)
      final latestLogs = _debugLogs.length > 10
          ? _debugLogs.sublist(_debugLogs.length - 10)
          : _debugLogs;

      final timestamp = DateTime.now().toIso8601String();
      final sessionInfo = _sessionId != null ? 'Session ID: $_sessionId\n' : '';

      final logReport = '''
=== LATEST WORLDLINE PAYMENT LOGS ===
Generated: $timestamp
${sessionInfo}Amount: ₹${widget.amount}

=== LATEST ${latestLogs.length} LOG ENTRIES ===
${latestLogs.join('\n')}

=== END OF LATEST LOGS ===
''';

      await Clipboard.setData(ClipboardData(text: logReport));
      _showSnackBar('Latest ${latestLogs.length} logs copied!', isError: false);

    } catch (e) {
      _showSnackBar('Failed to copy latest logs: $e', isError: true);
      print('Copy latest logs error: $e');
    }
  }

  Future<void> _copyLogEntry(String logEntry) async {
    try {
      await Clipboard.setData(ClipboardData(text: logEntry));
      _showSnackBar('Log entry copied!', isError: false);
    } catch (e) {
      _showSnackBar('Failed to copy log entry: $e', isError: true);
      print('Copy log entry error: $e');
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Show immediate user feedback for payment result
  Future<void> _showPaymentResultToUser(PaymentResponse response) async {
    try {
      _logToFile('📱 Showing payment result dialog to user...');

      if (!mounted) {
        _logToFile('❌ Widget not mounted, skipping user feedback');
        return;
      }

      String title;
      String message;
      IconData icon;
      Color iconColor;
      Color backgroundColor;

      switch (response.status) {
        case PaymentStatus.success:
          title = '✅ Payment Successful!';
          message = 'Your payment of ₹${response.amount.toStringAsFixed(2)} has been processed successfully.\n\nTransaction ID: ${response.transactionId}';
          icon = Icons.check_circle;
          iconColor = Colors.green;
          backgroundColor = Colors.green.shade50;

          // Show success snackbar
          _showSnackBar('Payment Successful! ₹${response.amount.toStringAsFixed(2)}', isError: false);
          break;

        case PaymentStatus.failed:
          title = '❌ Payment Failed';

          // Use user-friendly error message
          final userFriendlyMessage = response.getUserFriendlyErrorMessage();
          message = 'Your payment of ₹${response.amount.toStringAsFixed(2)} could not be processed.\n\n';
          message += '$userFriendlyMessage\n\n';

          // Add technical details if available
          if (response.gatewayErrorCode != null && response.gatewayErrorCode!.isNotEmpty) {
            message += 'Error Code: ${response.gatewayErrorCode}\n';
          }

          if (response.transactionId.isNotEmpty) {
            message += '\nReference ID: ${response.transactionId}';
          }

          icon = Icons.error;
          iconColor = Colors.red;
          backgroundColor = Colors.red.shade50;

          // Show error snackbar with user-friendly message
          _showSnackBar('Payment Failed: $userFriendlyMessage', isError: true);
          break;

        case PaymentStatus.pending:
          title = '⏳ Payment Pending';

          // Use user-friendly message for pending status
          final userFriendlyMessage = response.getUserFriendlyErrorMessage();
          message = 'Your payment of ₹${response.amount.toStringAsFixed(2)} is being processed.\n\n';
          message += '$userFriendlyMessage\n\n';
          message += 'We will notify you once the payment is confirmed.';

          if (response.transactionId.isNotEmpty) {
            message += '\n\nTransaction ID: ${response.transactionId}';
          }

          icon = Icons.hourglass_empty;
          iconColor = Colors.orange;
          backgroundColor = Colors.orange.shade50;

          // Show pending snackbar
          _showSnackBar('Payment Pending - Processing...', isError: false);
          break;

        default:
          title = '❓ Payment Status Unknown';
          message = 'The payment status is unclear. Please check your transaction history or contact support.\n\nTransaction ID: ${response.transactionId}';
          icon = Icons.help;
          iconColor = Colors.grey;
          backgroundColor = Colors.grey.shade50;

          // Show unknown status snackbar
          _showSnackBar('Payment Status Unknown', isError: true);
          break;
      }

      _logToFile('📱 Showing dialog: $title');

      // Show detailed dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (response.status == PaymentStatus.failed && response.additionalData != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Technical Details:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (response.additionalData!.containsKey('statusCode'))
                              Text('Status Code: ${response.additionalData!['statusCode']}'),
                            if (response.additionalData!.containsKey('errorCode'))
                              Text('Error Code: ${response.additionalData!['errorCode']}'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logToFile('📱 User dismissed payment result dialog');
                },
                child: Text(
                  response.status == PaymentStatus.failed ? 'Try Again' : 'OK',
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (response.status == PaymentStatus.failed)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Close payment screen
                    _logToFile('📱 User closed payment screen after failure');
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          );
        },
      );

      _logToFile('✅ Payment result dialog completed');
    } catch (e) {
      _logToFile('❌ Error showing payment result to user: $e');
      // Fallback: show simple snackbar
      if (mounted) {
        _showSnackBar(
          response.status == PaymentStatus.success
            ? 'Payment Successful!'
            : 'Payment ${response.status.name}: ${response.errorMessage ?? "Please check transaction history"}',
          isError: response.status != PaymentStatus.success,
        );
      }
    }
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    _mainScrollController.dispose();
    print('🔍 WORLDLINE FLUTTER PLUGIN - dispose() called');
    super.dispose();
  }

  /// Handle Worldline payment response according to official documentation
  void _handleWorldlineResponse(Map<dynamic, dynamic> response) async {
    _logToFile('');
    _logToFile('🎯🎯🎯 WORLDLINE RESPONSE RECEIVED 🎯🎯🎯');
    _logToFile('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    _logToFile('🔍 Response Type: ${response.runtimeType}');
    _logToFile('🔍 Response Keys: ${response.keys.toList()}');
    _logToFile('🔍 Full Response JSON: ${jsonEncode(response)}');

    // CRITICAL DEBUG: Log the exact response structure
    _logToFile('');
    _logToFile('🔍🔍🔍 DETAILED RESPONSE ANALYSIS 🔍🔍🔍');
    response.forEach((key, value) {
      _logToFile('  📋 Key: "$key" (${key.runtimeType}) = Value: "$value" (${value.runtimeType})');
    });
    _logToFile('');

    // Debug each key-value pair in detail
    _logToFile('🔍 DETAILED KEY-VALUE ANALYSIS:');
    response.forEach((key, value) {
      _logToFile('  🔑 $key: $value (Type: ${value.runtimeType})');
      if (value is Map) {
        _logToFile('    📋 Nested Map Keys: ${value.keys.toList()}');
        value.forEach((nestedKey, nestedValue) {
          _logToFile('      🔸 $nestedKey: $nestedValue (Type: ${nestedValue.runtimeType})');
        });
      }
    });
    _logToFile('');

    // Enhanced error analysis for Invalid Request
    _analyzeWorldlineError(response);

    // Extract detailed error information for display
    final detailedErrorInfo = _extractDetailedErrorInfo(response);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      PaymentResponse paymentResponse;

      try {
        _logToFile('🔄 PARSING WORLDLINE RESPONSE...');

        // Parse response according to official Flutter documentation format
        // Expected format: response.paymentMethod.paymentTransaction.statusCode
        if (response.containsKey('paymentMethod') &&
            response['paymentMethod'] != null &&
            response['paymentMethod'].containsKey('paymentTransaction') &&
            response['paymentMethod']['paymentTransaction'] != null) {

          _logToFile('✅ STANDARD FORMAT DETECTED: response.paymentMethod.paymentTransaction');

          var paymentMethod = response['paymentMethod'];
          var paymentTransaction = paymentMethod['paymentTransaction'];

          String statusCode = paymentTransaction['statusCode']?.toString() ?? '';
          String statusMessage = paymentTransaction['statusMessage']?.toString() ?? '';
          String transactionId = paymentTransaction['identifier']?.toString() ?? '';
          String bankRefId = paymentTransaction['bankReferenceIdentifier']?.toString() ?? '';
          String amount = paymentTransaction['amount']?.toString() ?? '';

          _logToFile('📊 EXTRACTED PAYMENT DATA:');
          _logToFile('  🔢 Status Code: "$statusCode"');
          _logToFile('  💬 Status Message: "$statusMessage"');
          _logToFile('  🆔 Transaction ID: "$transactionId"');
          _logToFile('  🏦 Bank Reference ID: "$bankRefId"');
          _logToFile('  💰 Amount: "$amount"');

          // ENHANCED SUCCESS DETECTION: Handle multiple success status codes
          _logToFile('');
          _logToFile('🔍🔍🔍 CHECKING SUCCESS STATUS CODE 🔍🔍🔍');
          _logToFile('📥 Status Code to Check: "$statusCode"');
          _logToFile('📥 Status Message: "$statusMessage"');
          _logToFile('📥 Transaction ID: "$transactionId"');
          _logToFile('📥 Bank Reference ID: "$bankRefId"');

          final isSuccess = _isSuccessStatusCode(statusCode);
          _logToFile('🎯 SUCCESS CHECK RESULT: $isSuccess');

          if (isSuccess) {
            _logToFile('');
            _logToFile('🎉🎉🎉 SUCCESS DETECTED! 🎉🎉🎉');
            _logToFile('✅ Status code "$statusCode" is considered successful');
            paymentResponse = PaymentResponse(
              status: PaymentStatus.success,
              transactionId: transactionId,
              amount: widget.amount,
              currency: 'INR',
              paymentMethod: 'Worldline',
              timestamp: DateTime.now(),
              gatewayTransactionId: bankRefId,
              errorMessage: null,
              gatewayErrorCode: statusCode,
              gatewayErrorMessage: statusMessage,
              failureReason: null, // Success case
              additionalData: {
                'amount': widget.amount,
                'timestamp': DateTime.now().toIso8601String(),
                'paymentMethod': 'Worldline',
                'worldlineTransactionId': transactionId,
                'bankReferenceId': bankRefId,
                'statusMessage': statusMessage,
                'statusCode': statusCode,
                'fullResponse': response,
                'detailedErrorInfo': detailedErrorInfo,
              },
            );
            _statusMessage = 'Payment completed successfully!';
          } else if (statusCode == '0398') {
            _logToFile('⏳ PENDING STATUS DETECTED: Status code 0398 (Initiated)');
            // Initiated - according to official docs
            paymentResponse = PaymentResponse(
              status: PaymentStatus.pending,
              transactionId: transactionId,
              amount: widget.amount,
              currency: 'INR',
              paymentMethod: 'Worldline',
              timestamp: DateTime.now(),
              gatewayTransactionId: bankRefId,
              errorMessage: null,
              gatewayErrorCode: statusCode,
              gatewayErrorMessage: statusMessage,
              failureReason: 'Payment is being processed. Please wait.',
              additionalData: {
                'amount': widget.amount,
                'timestamp': DateTime.now().toIso8601String(),
                'paymentMethod': 'Worldline',
                'worldlineTransactionId': transactionId,
                'bankReferenceId': bankRefId,
                'statusMessage': statusMessage,
                'statusCode': statusCode,
                'fullResponse': response,
                'detailedErrorInfo': detailedErrorInfo,
              },
            );
            _statusMessage = 'Payment initiated - awaiting confirmation';
          } else {
            _logToFile('');
            _logToFile('❌❌❌ FAILURE DETECTED! ❌❌❌');
            _logToFile('❌ Status code "$statusCode" is NOT in success list');
            _logToFile('❌ Status message: "$statusMessage"');
            _logToFile('❌ Transaction ID: "$transactionId"');
            _logToFile('❌ Bank Reference ID: "$bankRefId"');
            _logToFile('❌ This status code is NOT recognized as successful');
            // Failed or other status (0399, 0396, 0392)
            final failureReason = detailedErrorInfo['failureReason']?.toString() ??
                                 _generateUserFriendlyFailureReason(statusCode, statusMessage);

            paymentResponse = PaymentResponse(
              status: PaymentStatus.failed,
              transactionId: transactionId,
              amount: widget.amount,
              currency: 'INR',
              paymentMethod: 'Worldline',
              timestamp: DateTime.now(),
              gatewayTransactionId: bankRefId,
              errorMessage: statusMessage.isNotEmpty ? statusMessage : 'Payment failed',
              gatewayErrorCode: statusCode,
              gatewayErrorMessage: statusMessage,
              failureReason: failureReason,
              additionalData: {
                'amount': widget.amount,
                'timestamp': DateTime.now().toIso8601String(),
                'paymentMethod': 'Worldline',
                'worldlineTransactionId': transactionId,
                'bankReferenceId': bankRefId,
                'statusCode': statusCode,
                'statusMessage': statusMessage,
                'detailedErrorInfo': detailedErrorInfo, // Add detailed error info
                'fullResponse': response, // Include full response for debugging
              },
            );
            _statusMessage = 'Payment failed: $statusMessage';
            _scrollToErrorSection(); // Auto-scroll to show error details
          }
        } else if (response.containsKey('paymentMethod') &&
                   response['paymentMethod'] != null &&
                   response['paymentMethod'].containsKey('error')) {
          // Error response format
          var error = response['paymentMethod']['error'];
          String errorCode = error['code']?.toString() ?? '';
          String errorDesc = error['desc']?.toString() ?? 'Unknown error';

          print('🔍 Error Code: $errorCode');
          print('🔍 Error Description: $errorDesc');

          final failureReason = _generateUserFriendlyFailureReason(errorCode, errorDesc);

          paymentResponse = PaymentResponse(
            status: PaymentStatus.failed,
            transactionId: '',
            amount: widget.amount,
            currency: 'INR',
            paymentMethod: 'Worldline',
            timestamp: DateTime.now(),
            errorMessage: errorDesc,
            gatewayErrorCode: errorCode,
            gatewayErrorMessage: errorDesc,
            failureReason: failureReason,
            additionalData: {
              'amount': widget.amount,
              'timestamp': DateTime.now().toIso8601String(),
              'paymentMethod': 'Worldline',
              'errorCode': errorCode,
              'detailedErrorInfo': detailedErrorInfo,
              'fullResponse': response,
            },
          );
          _statusMessage = 'Payment failed: $errorDesc';
          _scrollToErrorSection(); // Auto-scroll to show error details
        } else {
          // Handle unexpected response format - log all details for debugging
          _logToFile('❌ UNEXPECTED RESPONSE FORMAT - DEBUGGING INFO:');
          _logToFile('🔍 Available keys: ${response.keys.toList()}');
          _logToFile('🔍 Full response: $response');

          // Check for legacy format (msg/merchant_code) as fallback
          if (response.containsKey('msg')) {
            _logToFile('🔄 LEGACY RESPONSE FORMAT DETECTED');
            String msg = response['msg'] ?? '';
            _logToFile('📝 Raw msg content: "$msg"');

            List<String> msgParts = msg.split('|');
            _logToFile('🔍 Split into ${msgParts.length} parts: $msgParts');

            if (msgParts.length >= 3) {
              // Parse all available fields from pipe-separated format
              String statusCode = msgParts[0].trim(); // 0399
              String statusMessage = msgParts[1].trim(); // failure
              String errorDescription = msgParts[2].trim(); // Transaction Cancelled : ERROR CODE TPPGE161
              String transactionId = msgParts.length > 3 ? msgParts[3].trim() : '';
              String bankRefId = msgParts.length > 4 ? msgParts[4].trim() : '';
              String gatewayTxnId = msgParts.length > 5 ? msgParts[5].trim() : '';
              String amount = msgParts.length > 6 ? msgParts[6].trim() : '';
              String customerInfo = msgParts.length > 7 ? msgParts[7].trim() : '';
              String timestamp = msgParts.length > 8 ? msgParts[8].trim() : '';

              _logToFile('🔍 Parsed - Status: $statusCode, Message: $statusMessage');
              _logToFile('🔍 Parsed - Error: $errorDescription');
              _logToFile('🔍 Parsed - TxnID: $transactionId, BankRef: $bankRefId, GatewayTxn: $gatewayTxnId');
              _logToFile('🔍 Parsed - Amount: $amount, Customer: $customerInfo, Time: $timestamp');

              // Extract error code from description (e.g., "ERROR CODE TPPGE161")
              String? errorCode;
              final errorCodeMatch = RegExp(r'ERROR CODE (\w+)').firstMatch(errorDescription);
              if (errorCodeMatch != null) {
                errorCode = errorCodeMatch.group(1);
                _logToFile('🔍 Extracted error code: $errorCode');
              }

              // ENHANCED SUCCESS DETECTION: Handle multiple success status codes
              _logToFile('🔍 CHECKING SUCCESS STATUS CODE (Legacy Format)...');
              if (_isSuccessStatusCode(statusCode)) {
                _logToFile('🎉🎉🎉 SUCCESS DETECTED (Legacy Format)! 🎉🎉🎉');
                _logToFile('✅ Status code "$statusCode" is considered successful');
                paymentResponse = PaymentResponse(
                  status: PaymentStatus.success,
                  transactionId: transactionId,
                  amount: widget.amount,
                  currency: 'INR',
                  paymentMethod: 'Worldline',
                  timestamp: DateTime.now(),
                  gatewayTransactionId: gatewayTxnId.isNotEmpty ? gatewayTxnId : bankRefId,
                  errorMessage: null,
                  additionalData: {
                    'amount': widget.amount,
                    'timestamp': DateTime.now().toIso8601String(),
                    'paymentMethod': 'Worldline',
                    'worldlineTransactionId': transactionId,
                    'bankReferenceId': bankRefId,
                    'gatewayTransactionId': gatewayTxnId,
                    'statusCode': statusCode,
                    'customerInfo': customerInfo,
                    'paymentTimestamp': timestamp,
                    'detailedErrorInfo': detailedErrorInfo,
                    'fullResponse': response,
                  },
                );
                _statusMessage = 'Payment completed successfully!';
              } else {
                _logToFile('');
                _logToFile('❌❌❌ FAILURE DETECTED (Legacy Format)! ❌❌❌');
                _logToFile('❌ Status code "$statusCode" is NOT in success list');
                _logToFile('❌ Error Code: "$errorCode"');
                _logToFile('❌ Error Description: "$errorDescription"');
                _logToFile('❌ Transaction ID: "$transactionId"');
                _logToFile('❌ This status code is NOT recognized as successful');
                // Failed or other status (0399, 0396, 0392)
                String failureMessage = errorCode != null
                    ? '$errorDescription (Code: $errorCode)'
                    : errorDescription.isNotEmpty
                        ? errorDescription
                        : statusMessage.isNotEmpty
                            ? statusMessage
                            : 'Payment failed';

                paymentResponse = PaymentResponse(
                  status: PaymentStatus.failed,
                  transactionId: transactionId,
                  amount: widget.amount,
                  currency: 'INR',
                  paymentMethod: 'Worldline',
                  timestamp: DateTime.now(),
                  gatewayTransactionId: gatewayTxnId.isNotEmpty ? gatewayTxnId : bankRefId,
                  errorMessage: failureMessage,
                  additionalData: {
                    'amount': widget.amount,
                    'timestamp': DateTime.now().toIso8601String(),
                    'paymentMethod': 'Worldline',
                    'worldlineTransactionId': transactionId,
                    'bankReferenceId': bankRefId,
                    'gatewayTransactionId': gatewayTxnId,
                    'statusCode': statusCode,
                    'statusMessage': statusMessage,
                    'errorCode': errorCode,
                    'errorDescription': errorDescription,
                    'customerInfo': customerInfo,
                    'paymentTimestamp': timestamp,
                    'detailedErrorInfo': detailedErrorInfo,
                    'fullResponse': response,
                  },
                );
                _statusMessage = 'Payment failed: $failureMessage';
                _scrollToErrorSection(); // Auto-scroll to show error details
              }
            } else {
              throw Exception('Invalid legacy response format - insufficient parts');
            }
          } else {
            // Try to extract any meaningful error information
            String errorMessage = 'Unknown payment error - unexpected response format';
            if (response.containsKey('error')) {
              errorMessage = response['error'].toString();
            } else if (response.containsKey('message')) {
              errorMessage = response['message'].toString();
            } else if (response.containsKey('status')) {
              errorMessage = 'Payment status: ${response['status']}';
            }

            throw Exception('Unexpected response format: $errorMessage');
          }
        }
      } catch (e) {
        print('❌ Error parsing Worldline response: $e');
        print('🔍 Original response: $response');
        paymentResponse = PaymentResponse(
          status: PaymentStatus.failed,
          transactionId: '',
          amount: widget.amount,
          currency: 'INR',
          paymentMethod: 'Worldline',
          timestamp: DateTime.now(),
          errorMessage: 'Error processing payment response: ${e.toString()}',
          additionalData: {
            'amount': widget.amount,
            'timestamp': DateTime.now().toIso8601String(),
            'paymentMethod': 'Worldline',
            'error': e.toString(),
            'originalResponse': response,
          },
        );
        _statusMessage = 'Error processing payment response: ${e.toString()}';
      }

      setState(() {});

      // CRITICAL: Save ALL transactions to database for record keeping and debugging
      _logToFile('');
      _logToFile('🔄🔄🔄 ABOUT TO SAVE TRANSACTION TO DATABASE 🔄🔄🔄');
      _logToFile('📅 Timestamp: ${DateTime.now().toIso8601String()}');
      _logToFile('📊 Payment Response Status: ${paymentResponse.status}');
      _logToFile('🆔 Transaction ID: ${paymentResponse.transactionId}');
      _logToFile('💰 Amount: ₹${paymentResponse.amount}');

      await _saveAllTransactionsToDatabase(paymentResponse);

      _logToFile('✅ Database save operation completed');

      // Create notification for the transaction
      _logToFile('🔔 Creating transaction notification...');
      await _createTransactionNotification(paymentResponse);
      _logToFile('✅ Notification creation completed');

      // CRITICAL FIX: Show immediate user feedback based on payment status
      _logToFile('📱 Showing user feedback for payment result...');
      await _showPaymentResultToUser(paymentResponse);

      // Complete the payment flow
      _logToFile('🏁 Completing payment flow...');
      widget.onPaymentComplete(paymentResponse);
      _logToFile('✅ Payment flow completed');

      // DO NOT auto-close the payment screen - let user review error details
      // User will manually close using the back button or close button
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worldline Payment'),
        backgroundColor: Colors.amber,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Debug logs button (disabled for now)
          // IconButton(
          //   icon: const Icon(Icons.bug_report),
          //   onPressed: () {
          //     // Debug screen removed
          //   },
          //   tooltip: 'View Debug Logs',
          // ),
          // Scroll to top button
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: () {
              if (_mainScrollController.hasClients) {
                _mainScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
            tooltip: 'Scroll to Top',
          ),
          // Show close button when payment is not processing
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close Payment Screen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _mainScrollController,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Summary Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:', style: TextStyle(fontSize: 16)),
                        Text(
                          '₹${widget.amount.round()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gold Quantity:', style: TextStyle(fontSize: 16)),
                        Text(
                          '${widget.goldGrams.toStringAsFixed(3)}g',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Description:', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            widget.description,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Gateway Info
            Card(
              elevation: 2,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.security,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Secure Payment by Worldline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your payment is secured with bank-grade encryption',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // Payment Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing Payment...'),
                      ],
                    )
                  : Text(
                      'Pay ₹${widget.amount.round()} via Netbanking',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Payment Status Message
            if (_statusMessage.isNotEmpty && !_isProcessing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('failed') || _statusMessage.contains('Error')
                      ? Colors.red.shade50
                      : _statusMessage.contains('success')
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                  border: Border.all(
                    color: _statusMessage.contains('failed') || _statusMessage.contains('Error')
                        ? Colors.red.shade300
                        : _statusMessage.contains('success')
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _statusMessage.contains('failed') || _statusMessage.contains('Error')
                              ? Icons.error_outline
                              : _statusMessage.contains('success')
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                          color: _statusMessage.contains('failed') || _statusMessage.contains('Error')
                              ? Colors.red.shade700
                              : _statusMessage.contains('success')
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _statusMessage.contains('failed') || _statusMessage.contains('Error')
                                  ? Colors.red.shade700
                                  : _statusMessage.contains('success')
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_statusMessage.contains('failed') || _statusMessage.contains('Error')) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility, color: Colors.blue.shade700, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Review Debug Information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Check the real-time debug logs below\n'
                              '• Review the complete Worldline response\n'
                              '• Note any error codes or validation failures\n'
                              '• Click "Close & Review Error Details" when ready',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Log file info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment logs are being saved to:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mobile: /Android/data/com.vmuruganjewellery.digi_gold/files/logs/payment_log_$_sessionId.txt',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Server: sql_server_api/logs/worldline_${DateTime.now().toIso8601String().split('T')[0]}.log',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Real-time Debug Logs Section
            if (_debugLogs.isNotEmpty) ...[
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Real-time Debug Logs (${_debugLogs.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              fontSize: 14,
                            ),
                          ),
                          if (_isAutoScrolling) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Copy latest logs button (last 10)
                          IconButton(
                            onPressed: () => _copyLatestLogs(),
                            icon: Icon(Icons.content_copy,
                                size: 16, color: Colors.orange[700]),
                            tooltip: 'Copy Latest 10 Logs',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          // Copy all logs button
                          IconButton(
                            onPressed: () => _copyAllLogs(),
                            icon: Icon(Icons.copy_all,
                                size: 18, color: Colors.orange[700]),
                            tooltip: 'Copy All Logs',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          // Manual scroll to bottom button
                          IconButton(
                            onPressed: () => _scrollToBottom(),
                            icon: Icon(Icons.keyboard_arrow_down,
                                size: 20, color: Colors.orange[700]),
                            tooltip: 'Scroll to Latest Logs',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black87,
                        ),
                        child: ListView.builder(
                          controller: _logScrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _debugLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _debugLogs[index],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ),
                                  // Copy individual log entry button
                                  IconButton(
                                    onPressed: () => _copyLogEntry(_debugLogs[index]),
                                    icon: const Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    tooltip: 'Copy this log entry',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manual Close/Cancel Button
            if (!_isProcessing)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(_statusMessage.contains('failed') || _statusMessage.contains('Error')
                      ? Icons.close : Icons.cancel),
                  label: Text(
                    _statusMessage.contains('failed') || _statusMessage.contains('Error')
                        ? 'Close & Review Error Details'
                        : 'Cancel Payment',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusMessage.contains('failed') || _statusMessage.contains('Error')
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // Debug floating action button disabled for now
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Debug screen removed
      //   },
      //   icon: const Icon(Icons.bug_report),
      //   label: const Text('Debug Logs'),
      //   backgroundColor: const Color(0xFFDC143C),
      //   foregroundColor: Colors.white,
      //   tooltip: 'View comprehensive payment debug logs',
      // ),
    );
  }

  /// Get payment token from server - Following Payment_GateWay.md
  Future<Map<String, dynamic>?> _getPaymentToken() async {
    try {
      final customerInfo = await CustomerService.getCustomerInfo();
      final customerId = customerInfo?['phone'] ?? 'GUEST_${DateTime.now().millisecondsSinceEpoch}';

      _logToFile('🔍 Getting token for Customer ID: $customerId');

      final url = 'https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/token';

      // CRITICAL FIX: Use decimal format for hash consistency with server
      // Server generates hash with "7.00" format, Flutter must send same format
      final amountAsDecimal = widget.amount.toStringAsFixed(2);

      final payload = {
        'amount': amountAsDecimal, // Send amount as decimal string (e.g., "7.00")
        'orderId': 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
        'customerId': customerId,
      };

      _logToFile('📤 TOKEN REQUEST: $url');
      _logToFile('📤 Payload: ${jsonEncode(payload)}');
      _logToFile('� SSL Certificate: Development mode - accepting self-signed certificates');
      _logToFile('�💰 AMOUNT CONVERSION DEBUG:');
      _logToFile('💰 Original Amount: ₹${widget.amount} (${widget.amount.runtimeType})');
      _logToFile('💰 Decimal Amount: ${widget.amount.toStringAsFixed(2)} (decimal format)');
      _logToFile('💰 Final String: "${amountAsDecimal}" (${amountAsDecimal.runtimeType})');
      _logToFile('💰 String Length: ${amountAsDecimal.length} characters');
      _logToFile('💰 Contains Decimal: ${amountAsDecimal.contains('.')}');

      // Use SecureHttpClient for SSL certificate handling
      final response = await SecureHttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      _logToFile('📥 TOKEN RESPONSE: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logToFile('✅ Token received successfully');
        _logToFile('📋 Token Data: ${jsonEncode(data)}');
        return data;
      } else {
        _logToFile('❌ Token request failed: ${response.statusCode}');
        _logToFile('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      _logToFile('❌ Token request error: $e');
      return null;
    }
  }

  /// Start payment process - Official Worldline Flutter Plugin
  Future<void> _startPayment() async {
    _logToFile('🚀 STARTING WORLDLINE PAYMENT - Official Flutter Plugin');

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Getting payment token...';
    });

    try {
      // Step 1: Get payment token from server
      final tokenData = await _getPaymentToken();

      if (tokenData == null) {
        _logToFile('❌ CRITICAL ERROR: Failed to get payment token from server');
        throw Exception('Failed to get payment token from server');
      }

      _logToFile('✅ Token received, preparing Worldline payment...');
      _logToFile('🔑 Token: ${tokenData['token']?.toString().substring(0, 20)}...');

      setState(() {
        _tokenData = tokenData;
        _paymentToken = tokenData['token'];
        _statusMessage = 'Initializing Worldline payment...';
      });

      _logToFile('✅ Token received: ${_paymentToken?.substring(0, 20)}...');

      // Step 2: Initialize Worldline Flutter Plugin
      await _initializeWorldlinePayment();

    } catch (e) {
      _logToFile('❌ PAYMENT ERROR: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Payment failed: $e';
        _scrollToErrorSection(); // Auto-scroll to show error details
      });
    }
  }

  /// Initialize Worldline payment using official Flutter plugin
  Future<void> _initializeWorldlinePayment() async {
    _logToFile('🔧 Initializing Worldline payment...');

    if (_tokenData == null || _paymentToken == null) {
      _logToFile('❌ CRITICAL ERROR: No payment token available');
      throw Exception('No payment token available');
    }

    try {
      final consumerData = _tokenData!['consumerDataFields'];
      _logToFile('📋 Consumer Data Fields: ${jsonEncode(consumerData)}');

      // Create payment options following official Flutter documentation
      final paymentOptions = {
        "features": {
          "enableAbortResponse": true,
          "enableExpressPay": true,
          "enableInstrumentDeRegistration": true,
          "enableMerTxnDetails": true,
          "showPGResponseMsg": true, // Keep for debugging
        },
        "consumerData": {
          "deviceId": "ANDROIDSH2", // Use SHA-512 for better security as per docs
          "token": _paymentToken!,
          "paymentMode": "all", // Allow all payment modes
          "merchantLogoUrl": "https://www.paynimo.com/CompanyDocs/company-logo-vertical.png",
          "merchantId": consumerData['merchantId'],
          "currency": "INR",
          "consumerId": consumerData['consumerId'],
          "consumerMobileNo": consumerData['consumerMobileNo'],
          "consumerEmailId": consumerData['consumerEmailId'],
          "txnId": consumerData['txnId'],

          // CRITICAL: Include ALL fields used in hash generation for validation
          "accountNo": consumerData['accountNo'],
          "debitStartDate": consumerData['debitStartDate'],
          "debitEndDate": consumerData['debitEndDate'],
          "maxAmount": consumerData['maxAmount'],
          "amountType": consumerData['amountType'],
          "frequency": consumerData['frequency'],
          "cardNumber": consumerData['cardNumber'],
          "expMonth": consumerData['expMonth'],
          "expYear": consumerData['expYear'],
          "cvvCode": consumerData['cvvCode'],

          "items": [
            {
              "itemId": "first", // CRITICAL: Scheme code for TID T1098761 as per Worldline support (CASE SENSITIVE)
              "amount": consumerData['amount'], // CRITICAL: Use exact same amount from server
              "comAmt": "0"
            }
          ],
          "customStyle": {
            "PRIMARY_COLOR_CODE": "#DC143C", // VMurugan brand color
            "SECONDARY_COLOR_CODE": "#FFFFFF",
            "BUTTON_COLOR_CODE_1": "#DC143C",
            "BUTTON_COLOR_CODE_2": "#FFFFFF"
          }
        }
      };

      // Log payload structure (debug logger removed)
      _logToFile('Complete Worldline Payment Payload logged');

      // Log detailed payload analysis
      await _logPayloadStructureAnalysis(paymentOptions, consumerData);

      _logToFile('📤 Payment Options: ${jsonEncode(paymentOptions)}');

      // CRITICAL: Debug hash validation fields
      _logToFile('🔍 HASH VALIDATION DEBUG:');
      _logToFile('🔍 merchantId: "${consumerData['merchantId']}"');
      _logToFile('🔍 txnId: "${consumerData['txnId']}"');
      _logToFile('🔍 amount: "${consumerData['amount']}"');
      _logToFile('🔍 accountNo: "${consumerData['accountNo']}"');
      _logToFile('🔍 consumerId: "${consumerData['consumerId']}"');
      _logToFile('🔍 consumerMobileNo: "${consumerData['consumerMobileNo']}"');
      _logToFile('🔍 consumerEmailId: "${consumerData['consumerEmailId']}"');
      _logToFile('🔍 debitStartDate: "${consumerData['debitStartDate']}"');
      _logToFile('🔍 debitEndDate: "${consumerData['debitEndDate']}"');
      _logToFile('🔍 maxAmount: "${consumerData['maxAmount']}"');
      _logToFile('🔍 amountType: "${consumerData['amountType']}"');
      _logToFile('🔍 frequency: "${consumerData['frequency']}"');
      _logToFile('🔍 cardNumber: "${consumerData['cardNumber']}"');
      _logToFile('🔍 expMonth: "${consumerData['expMonth']}"');
      _logToFile('🔍 expYear: "${consumerData['expYear']}"');
      _logToFile('🔍 cvvCode: "${consumerData['cvvCode']}"');

      setState(() {
        _statusMessage = 'Opening Worldline payment gateway...';
      });

      _logToFile('🚀 CALLING WORLDLINE FLUTTER PLUGIN...');
      _logToFile('🔧 Plugin Method: wlCheckoutFlutter.open()');
      _logToFile('📋 Final Payment Options: ${jsonEncode(paymentOptions)}');

      // Open Worldline checkout using official plugin
      wlCheckoutFlutter.open(paymentOptions);

      _logToFile('✅ Worldline checkout opened successfully - waiting for response...');

    } catch (e) {
      _logToFile('❌ Error initializing Worldline payment: $e');
      throw Exception('Failed to initialize payment: $e');
    }
  }

  /// Send error details to server for persistent logging
  Future<void> _sendErrorToServer(Map<String, dynamic> errorAnalysis, Map<dynamic, dynamic> response) async {
    try {
      final serverUrl = 'https://api.vmuruganjewellery.co.in:3001/api/payments/worldline/error-capture';

      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'sessionId': _sessionId,
        'errorAnalysis': errorAnalysis,
        'fullResponse': response,
        'paymentContext': {
          'amount': widget.amount,
          'orderId': _sessionId, // Use session ID as order ID
          'customerId': _sessionId, // Use session ID as customer ID
          'merchantCode': 'T1098761', // Back to your original merchant
        },
        'deviceInfo': {
          'platform': 'Flutter',
          'version': '1.0.0',
        }
      };

      _logToFile('📤 Sending error details to server...');

      final httpResponse = await SecureHttpClient.post(
        serverUrl,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (httpResponse.statusCode == 200) {
        _logToFile('✅ Error details sent to server successfully');
      } else {
        _logToFile('❌ Failed to send error to server: ${httpResponse.statusCode}');
        _logToFile('❌ Server response: ${httpResponse.body}');
      }
    } catch (e) {
      _logToFile('❌ Exception sending error to server: $e');
    }
  }

  /// Extract detailed error information from Worldline response for debugging
  Map<String, dynamic> _extractDetailedErrorInfo(Map<dynamic, dynamic> response) {
    final errorInfo = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'sessionId': _sessionId,
      'responseKeys': response.keys.toList(),
      'responseType': response.runtimeType.toString(),
    };

    // Extract standard payment transaction details
    if (response.containsKey('paymentMethod') &&
        response['paymentMethod'] != null &&
        response['paymentMethod'].containsKey('paymentTransaction')) {

      var paymentTransaction = response['paymentMethod']['paymentTransaction'];
      errorInfo['statusCode'] = paymentTransaction['statusCode']?.toString() ?? 'N/A';
      errorInfo['statusMessage'] = paymentTransaction['statusMessage']?.toString() ?? 'N/A';
      errorInfo['transactionId'] = paymentTransaction['identifier']?.toString() ?? 'N/A';
      errorInfo['bankRefId'] = paymentTransaction['bankReferenceIdentifier']?.toString() ?? 'N/A';
      errorInfo['amount'] = paymentTransaction['amount']?.toString() ?? 'N/A';
      errorInfo['errorType'] = 'Payment Transaction Error';

      // Extract gateway-specific error information for PaymentResponse
      errorInfo['gatewayErrorCode'] = paymentTransaction['statusCode']?.toString();
      errorInfo['gatewayErrorMessage'] = paymentTransaction['statusMessage']?.toString();

      // Generate user-friendly failure reason
      errorInfo['failureReason'] = _generateUserFriendlyFailureReason(
        paymentTransaction['statusCode']?.toString() ?? '',
        paymentTransaction['statusMessage']?.toString() ?? ''
      );
    }

    // Extract error details if present
    if (response.containsKey('paymentMethod') &&
        response['paymentMethod'] != null &&
        response['paymentMethod'].containsKey('error')) {

      var error = response['paymentMethod']['error'];
      errorInfo['errorCode'] = error['code']?.toString() ?? 'N/A';
      errorInfo['errorDescription'] = error['desc']?.toString() ?? 'N/A';
      errorInfo['errorType'] = 'Payment Method Error';
    }

    // Extract legacy format details
    if (response.containsKey('msg')) {
      String msg = response['msg'] ?? '';
      List<String> msgParts = msg.split('|');

      errorInfo['legacyFormat'] = true;
      errorInfo['legacyMessage'] = msg;
      errorInfo['legacyParts'] = msgParts;

      if (msgParts.isNotEmpty) {
        errorInfo['legacyStatus'] = msgParts[0];
        errorInfo['legacyMessage'] = msgParts.length > 1 ? msgParts[1] : 'N/A';
        errorInfo['legacyTxnId'] = msgParts.length > 5 ? msgParts[5] : 'N/A';
      }
      errorInfo['errorType'] = 'Legacy Format Error';
    }

    // Extract any other error fields
    if (response.containsKey('error')) {
      errorInfo['genericError'] = response['error'].toString();
      errorInfo['errorType'] = 'Generic Error';
    }

    if (response.containsKey('message')) {
      errorInfo['genericMessage'] = response['message'].toString();
    }

    if (response.containsKey('status')) {
      errorInfo['genericStatus'] = response['status'].toString();
    }

    // Add full response for complete debugging
    errorInfo['fullResponse'] = response;

    return errorInfo;
  }

  /// Generate user-friendly failure reason from gateway response
  String _generateUserFriendlyFailureReason(String statusCode, String statusMessage) {
    final code = statusCode.toLowerCase();
    final message = statusMessage.toLowerCase();

    // Handle specific Worldline status codes
    if (code == '0300') {
      return 'Payment completed successfully!';
    } else if (code == '0398') {
      return 'Payment was cancelled by user.';
    } else if (code == '0399') {
      return 'Payment failed. Please try again.';
    } else if (code.startsWith('03')) {
      // Other 03xx codes are generally success variants
      return 'Payment completed successfully!';
    }

    // Handle error patterns in status message
    if (message.contains('insufficient')) {
      return 'Insufficient funds in your account. Please check your balance and try again.';
    } else if (message.contains('declined') || message.contains('reject')) {
      return 'Your card was declined. Please try with a different card or contact your bank.';
    } else if (message.contains('expired')) {
      return 'Your card has expired. Please use a valid card.';
    } else if (message.contains('cvv') || message.contains('cvc')) {
      return 'Invalid CVV/CVC. Please check your card details and try again.';
    } else if (message.contains('network') || message.contains('connection')) {
      return 'Network error occurred. Please check your internet connection and try again.';
    } else if (message.contains('timeout')) {
      return 'Payment timed out. Please try again.';
    } else if (message.contains('auth')) {
      return 'Authentication failed. Please verify your credentials and try again.';
    } else if (message.contains('invalid')) {
      return 'Invalid payment details. Please check your information and try again.';
    } else if (message.contains('cancel')) {
      return 'Payment was cancelled. You can try again when ready.';
    } else if (message.contains('fail')) {
      return 'Payment failed. Please try again or contact support.';
    }

    // If we have a status message, use it as is
    if (statusMessage.isNotEmpty && statusMessage != 'N/A') {
      return statusMessage;
    }

    // Default based on status code patterns
    if (code.startsWith('0')) {
      return 'Payment failed. Please try again or contact support.';
    }

    return 'Payment status unknown. Please contact support.';
  }

  /// Enhanced error analysis specifically for Worldline Invalid Request scenarios
  Future<void> _analyzeWorldlineError(Map<dynamic, dynamic> response) async {
    try {
      final errorAnalysis = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'responseType': response.runtimeType.toString(),
        'responseKeys': response.keys.toList(),
        'responseSize': response.length,
      };

      // Check for Invalid Request indicators
      bool isInvalidRequest = false;
      String? errorMessage;
      String? errorCode;

      // Check various error formats
      if (response.containsKey('msg')) {
        final msg = response['msg']?.toString() ?? '';
        if (msg.toLowerCase().contains('invalid') ||
            msg.toLowerCase().contains('error') ||
            msg.contains('TPPGE')) {
          isInvalidRequest = true;
          errorMessage = msg;

          // Extract error code if present
          final errorCodeMatch = RegExp(r'ERROR CODE (\w+)').firstMatch(msg);
          if (errorCodeMatch != null) {
            errorCode = errorCodeMatch.group(1);
          }
        }
        errorAnalysis['msgField'] = msg;
      }

      if (response.containsKey('error')) {
        isInvalidRequest = true;
        errorMessage = response['error']?.toString();
        errorAnalysis['errorField'] = errorMessage;
      }

      if (response.containsKey('paymentTransaction')) {
        final paymentTransaction = response['paymentTransaction'];
        if (paymentTransaction is Map) {
          final statusCode = paymentTransaction['statusCode']?.toString();
          final statusMessage = paymentTransaction['statusMessage']?.toString();

          if (statusCode != '0300') { // 0300 is success
            isInvalidRequest = true;
            errorMessage = statusMessage;
            errorCode = statusCode;
          }

          errorAnalysis['paymentTransaction'] = {
            'statusCode': statusCode,
            'statusMessage': statusMessage,
            'identifier': paymentTransaction['identifier'],
            'amount': paymentTransaction['amount'],
          };
        }
      }

      errorAnalysis['isInvalidRequest'] = isInvalidRequest;
      errorAnalysis['errorMessage'] = errorMessage;
      errorAnalysis['errorCode'] = errorCode;

      // Analyze potential causes for Invalid Request
      if (isInvalidRequest) {
        final potentialCauses = <String>[];

        if (errorCode == 'TPPGE161') {
          potentialCauses.add('Hash validation failed - check hash generation algorithm');
        }

        if (errorMessage?.contains('merchant') == true) {
          potentialCauses.add('Merchant configuration issue - check merchant ID and credentials');
        }

        if (errorMessage?.contains('amount') == true) {
          potentialCauses.add('Amount format issue - check decimal formatting and currency');
        }

        if (errorMessage?.contains('token') == true) {
          potentialCauses.add('Token validation failed - check token generation and expiry');
        }

        if (errorMessage?.contains('scheme') == true) {
          potentialCauses.add('Scheme code issue - verify "FIRST" scheme code for merchant T1098761');
        }

        errorAnalysis['potentialCauses'] = potentialCauses;

        // Log specific error analysis (debug logger removed)
        _logToFile('Worldline Invalid Request Detected: ${jsonEncode(errorAnalysis)}');

        // CRITICAL: Send error to server for persistent logging
        await _sendErrorToServer(errorAnalysis, response);
      }

      // Always log the analysis for debugging (debug logger removed)
      _logToFile('Worldline Response Analysis: ${jsonEncode(errorAnalysis)}');

    } catch (e) {
      _logToFile('Failed to analyze Worldline error: $e');
    }
  }

  /// Log detailed payload structure analysis for debugging
  Future<void> _logPayloadStructureAnalysis(
    Map<String, dynamic> paymentOptions,
    Map<String, dynamic> consumerData,
  ) async {
    try {
      final analysis = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'payloadStructure': {
          'hasFeatures': paymentOptions.containsKey('features'),
          'hasConsumerData': paymentOptions.containsKey('consumerData'),
          'featuresCount': paymentOptions['features']?.length ?? 0,
          'consumerDataFieldsCount': paymentOptions['consumerData']?.length ?? 0,
        },
        'consumerDataAnalysis': {
          'hasToken': consumerData.containsKey('token'),
          'hasMerchantId': consumerData.containsKey('merchantId'),
          'hasAmount': consumerData.containsKey('amount'),
          'hasTxnId': consumerData.containsKey('txnId'),
          'hasConsumerId': consumerData.containsKey('consumerId'),
          'hasSchemeCode': true, // Always FIRST for our merchant
        },
        'criticalFields': {
          'merchantId': consumerData['merchantId']?.toString(),
          'txnId': consumerData['txnId']?.toString(),
          'amount': consumerData['amount']?.toString(),
          'consumerId': consumerData['consumerId']?.toString(),
          'currency': 'INR',
          'schemeCode': 'first',
        },
        'hashValidationFields': {
          'merchantId': consumerData['merchantId']?.toString(),
          'txnId': consumerData['txnId']?.toString(),
          'amount': consumerData['amount']?.toString(),
          'accountNo': consumerData['accountNo']?.toString(),
          'consumerId': consumerData['consumerId']?.toString(),
          'consumerMobileNo': consumerData['consumerMobileNo']?.toString(),
          'consumerEmailId': consumerData['consumerEmailId']?.toString(),
          'debitStartDate': consumerData['debitStartDate']?.toString(),
          'debitEndDate': consumerData['debitEndDate']?.toString(),
          'maxAmount': consumerData['maxAmount']?.toString(),
          'amountType': consumerData['amountType']?.toString(),
          'frequency': consumerData['frequency']?.toString(),
          'cardNumber': consumerData['cardNumber']?.toString(),
          'expMonth': consumerData['expMonth']?.toString(),
          'expYear': consumerData['expYear']?.toString(),
          'cvvCode': consumerData['cvvCode']?.toString(),
        },
        'itemsAnalysis': {
          'itemCount': paymentOptions['consumerData']?['items']?.length ?? 0,
          'firstItem': paymentOptions['consumerData']?['items']?[0],
          'schemeCodeCorrect': paymentOptions['consumerData']?['items']?[0]?['itemId'] == 'first',
        },
        'amountValidation': {
          'originalAmount': widget.amount,
          'consumerDataAmount': consumerData['amount'],
          'itemAmount': paymentOptions['consumerData']?['items']?[0]?['amount'],
          'amountConsistency': consumerData['amount'] == paymentOptions['consumerData']?['items']?[0]?['amount'],
        },
      };

      // Check for potential issues
      final issues = <String>[];

      if (consumerData['merchantId'] != 'T1098761') {
        issues.add('Merchant ID mismatch - expected T1098761');
      }

      if (paymentOptions['consumerData']?['items']?[0]?['itemId'] != 'first') {
        issues.add('Scheme code mismatch - expected FIRST');
      }

      if (consumerData['amount'] != paymentOptions['consumerData']?['items']?[0]?['amount']) {
        issues.add('Amount inconsistency between consumerData and items');
      }

      // Check currency if present in consumerData, otherwise assume INR is used in payment options
      final currency = consumerData['currency'] ?? 'INR';
      if (currency != 'INR') {
        issues.add('Currency mismatch - expected INR, found: $currency');
      }

      analysis['potentialIssues'] = issues;
      analysis['issueCount'] = issues.length;

      _logToFile('Worldline Payload Structure Analysis: ${jsonEncode(analysis)}');

    } catch (e) {
      _logToFile('Failed to analyze payload structure: $e');
    }
  }

  /// Enhanced success status code detection for different payment methods
  bool _isSuccessStatusCode(String statusCode) {
    _logToFile('');
    _logToFile('🔍🔍🔍 SUCCESS STATUS CODE CHECK 🔍🔍🔍');
    _logToFile('📥 Input Status Code: "$statusCode"');
    _logToFile('📥 Input Type: ${statusCode.runtimeType}');
    _logToFile('📥 Input Length: ${statusCode.length}');
    _logToFile('📥 Input Uppercase: "${statusCode.toUpperCase()}"');

    // COMPREHENSIVE LIST: All known success status codes for Worldline payments
    const successCodes = [
      // Standard Worldline success codes
      '0300', '0301', '0302', '0303', '0304', '0305', '0306', '0307', '0308', '0309',
      '0310', '0311', '0312', '0313', '0314', '0315', '0316', '0317', '0318', '0319',
      '0320', '0321', '0322', '0323', '0324', '0325', '0326', '0327', '0328', '0329',
      '0330', '0331', '0332', '0333', '0334', '0335', '0336', '0337', '0338', '0339',
      '0340', '0341', '0342', '0343', '0344', '0345', '0346', '0347', '0348', '0349',
      '0350', '0351', '0352', '0353', '0354', '0355', '0356', '0357', '0358', '0359',
      '0360', '0361', '0362', '0363', '0364', '0365', '0366', '0367', '0368', '0369',
      '0370', '0371', '0372', '0373', '0374', '0375', '0376', '0377', '0378', '0379',
      '0380', '0381', '0382', '0383', '0384', '0385', '0386', '0387', '0388', '0389',
      '0390', '0391', '0392', '0393', '0394', '0395', '0396', '0397', '0398', '0399',

      // HTTP success codes
      '200', '201', '202', '204',

      // String success indicators
      'SUCCESS', 'COMPLETED', 'APPROVED', 'PAID', 'CONFIRMED', 'ACCEPTED',
      'SUCCESSFUL', 'TRANSACTION_SUCCESS', 'PAYMENT_SUCCESS',

      // Single character indicators
      'Y', 'S', 'T', // Y=Yes, S=Success, T=True

      // Bank specific codes
      'TXN_SUCCESS', 'CAPTURED', 'SETTLED'
      'S', // Success short code
      '00', // Standard bank success code
      '000', // Alternative success code
    ];

    _logToFile('📋 Supported Success Codes: $successCodes');

    final statusCodeUpper = statusCode.toUpperCase();
    bool isSuccess = successCodes.contains(statusCodeUpper);

    _logToFile('🔍 Checking if "$statusCodeUpper" is in success codes...');
    for (String code in successCodes) {
      final matches = code == statusCodeUpper;
      _logToFile('  🔸 "$code" == "$statusCodeUpper" ? $matches');
      if (matches) {
        _logToFile('  ✅ MATCH FOUND!');
        break;
      }
    }

    // Additional success detection logic for edge cases
    if (!isSuccess) {
      _logToFile('🔍 Checking additional success patterns...');

      // Check if status contains success keywords
      if (statusCodeUpper.contains('SUCCESS') ||
          statusCodeUpper.contains('APPROVED') ||
          statusCodeUpper.contains('COMPLETED') ||
          statusCodeUpper.contains('PAID')) {
        _logToFile('  ✅ SUCCESS KEYWORD FOUND in "$statusCode"');
        isSuccess = true;
      }

      // Check for numeric success patterns (0xxx codes)
      if (statusCode.startsWith('0') && statusCode.length == 4) {
        final numericCode = int.tryParse(statusCode);
        if (numericCode != null && numericCode >= 300 && numericCode <= 399) {
          _logToFile('  ✅ SUCCESS NUMERIC PATTERN FOUND: "$statusCode" (300-399 range)');
          isSuccess = true;
        }
      }
    }

    _logToFile('🎯 FINAL RESULT: "$statusCode" -> ${isSuccess ? "✅ SUCCESS" : "❌ NOT SUCCESS"}');
    _logToFile('');

    return isSuccess;
  }

  /// Save ALL payment transactions to database for debugging and record keeping
  Future<void> _saveAllTransactionsToDatabase(PaymentResponse response) async {
    _logToFile('');
    _logToFile('💾💾💾 SAVING TRANSACTION TO DATABASE 💾💾💾');
    _logToFile('📅 Timestamp: ${DateTime.now().toIso8601String()}');

    try {
      _logToFile('📊 TRANSACTION DATA TO SAVE:');
      _logToFile('  🆔 Transaction ID: "${response.transactionId}"');
      _logToFile('  📊 Status: ${response.status} (${response.status.name.toUpperCase()})');
      _logToFile('  💰 Amount: ₹${response.amount}');
      _logToFile('  🥇 Gold Grams: ${widget.goldGrams}');
      _logToFile('  💳 Payment Method: ${response.paymentMethod}');
      _logToFile('  🏦 Gateway Transaction ID: "${response.gatewayTransactionId ?? ''}"');
      _logToFile('  📋 Additional Data Present: ${response.additionalData != null}');

      if (response.additionalData != null) {
        _logToFile('  📋 Additional Data Content: ${jsonEncode(response.additionalData)}');
      }

      _logToFile('🔄 Calling CustomerService.saveTransactionWithCustomerData...');

      // Save to database regardless of success or failure
      final success = await CustomerService.saveTransactionWithCustomerData(
        transactionId: response.transactionId,
        type: 'BUY',
        amount: response.amount,
        goldGrams: widget.goldGrams,
        goldPricePerGram: response.amount / widget.goldGrams, // Calculate price per gram
        paymentMethod: response.paymentMethod,
        status: response.status.name.toUpperCase(),
        gatewayTransactionId: response.gatewayTransactionId ?? '',
        additionalData: response.additionalData,
      );

      _logToFile('📤 CustomerService.saveTransactionWithCustomerData returned: $success');

      if (success) {
        _logToFile('✅✅✅ TRANSACTION SAVED SUCCESSFULLY TO DATABASE! ✅✅✅');
      } else {
        _logToFile('❌❌❌ FAILED TO SAVE TRANSACTION TO DATABASE! ❌❌❌');
      }
    } catch (e) {
      _logToFile('💥💥💥 CRITICAL ERROR SAVING TRANSACTION TO DATABASE! 💥💥💥');
      _logToFile('❌ Error: $e');
      _logToFile('❌ Stack trace: ${e.toString()}');
    }

    _logToFile('');
  }

  /// Create notification for transaction
  Future<void> _createTransactionNotification(PaymentResponse response) async {
    try {
      _logToFile('🔔 Creating notification for transaction: ${response.transactionId}');

      final notificationService = NotificationService();

      if (response.status == PaymentStatus.success) {
        // Success notification
        await notificationService.createNotification(
          type: NotificationType.paymentSuccess,
          title: 'Payment Successful! 🎉',
          message: 'Your payment of ₹${response.amount.toStringAsFixed(2)} was successful. You have purchased ${widget.goldGrams.toStringAsFixed(3)}g of gold.',
          priority: NotificationPriority.high,
          data: {
            'transactionId': response.transactionId,
            'amount': response.amount,
            'goldGrams': widget.goldGrams,
            'paymentMethod': response.paymentMethod,
            'timestamp': response.timestamp.toIso8601String(),
          },
        );
        _logToFile('✅ Success notification created');
      } else if (response.status == PaymentStatus.failed) {
        // Failure notification
        await notificationService.createNotification(
          type: NotificationType.paymentFailed,
          title: 'Payment Failed ❌',
          message: 'Your payment of ₹${response.amount.toStringAsFixed(2)} failed. ${response.errorMessage ?? "Please try again."}',
          priority: NotificationPriority.high,
          data: {
            'transactionId': response.transactionId,
            'amount': response.amount,
            'goldGrams': widget.goldGrams,
            'paymentMethod': response.paymentMethod,
            'errorMessage': response.errorMessage,
            'timestamp': response.timestamp.toIso8601String(),
          },
        );
        _logToFile('✅ Failure notification created');
      } else {
        // Pending notification
        await notificationService.createNotification(
          type: NotificationType.paymentPending,
          title: 'Payment Pending ⏳',
          message: 'Your payment of ₹${response.amount.toStringAsFixed(2)} is being processed. We will notify you once it\'s complete.',
          priority: NotificationPriority.normal,
          data: {
            'transactionId': response.transactionId,
            'amount': response.amount,
            'goldGrams': widget.goldGrams,
            'paymentMethod': response.paymentMethod,
            'timestamp': response.timestamp.toIso8601String(),
          },
        );
        _logToFile('✅ Pending notification created');
      }
    } catch (e) {
      _logToFile('❌ Error creating notification: $e');
    }
  }

}
