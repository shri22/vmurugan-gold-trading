// WORLDLINE PAYMENT SCREEN - Official Flutter Plugin Implementation
// Following Payment_GateWay.md specifications exactly

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, Directory, File, FileMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weipl_checkout_flutter/weipl_checkout_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/payment_response.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/secure_http_client.dart';

class EnhancedPaymentScreen extends StatefulWidget {
  final double amount;
  final double goldGrams;
  final String description;
  final String? metalType; // 'gold' or 'silver' - determines which merchant to use
  final Function(PaymentResponse) onPaymentComplete;

  const EnhancedPaymentScreen({
    super.key,
    required this.amount,
    required this.goldGrams,
    required this.description,
    this.metalType = 'gold', // Default to gold
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

  // Worldline Flutter Plugin instance - LAZY INITIALIZATION
  WeiplCheckoutFlutter? _wlCheckoutFlutter;
  bool _isSDKInitialized = false;

  @override
  void initState() {
    super.initState();
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _logToFile('🔍 WORLDLINE FLUTTER PLUGIN - initState() called');
    _logToFile('🔍 Amount: ₹${widget.amount.round()} (converted from ${widget.amount})');
    _logToFile('🔍 Description: ${widget.description}');
    _logToFile('⚠️ SDK will be initialized ONLY when user clicks "Start Payment"');

    // DO NOT initialize Worldline SDK here - wait for user action
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
    if (_isSDKInitialized) {
      _logToFile('⚠️ SDK already initialized, skipping...');
      return;
    }

    _logToFile('🔧 Initializing Worldline SDK for the first time...');
    _wlCheckoutFlutter = WeiplCheckoutFlutter();
    _wlCheckoutFlutter!.on(WeiplCheckoutFlutter.wlResponse, _handleWorldlineResponse);
    _isSDKInitialized = true;
    _logToFile('✅ Worldline SDK initialized and event listeners set up');
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

  @override
  void dispose() {
    _logScrollController.dispose();
    _mainScrollController.dispose();
    print('🔍 WORLDLINE FLUTTER PLUGIN - dispose() called');
    super.dispose();
  }

  /// Handle Worldline payment response according to official documentation
  void _handleWorldlineResponse(Map<dynamic, dynamic> response) {
    // Log to file instead of on-screen display
    _logToFile('🎯 WORLDLINE RESPONSE RECEIVED: $response');
    _logToFile('🔍 RESPONSE KEYS: ${response.keys.toList()}');
    _logToFile('🔍 RESPONSE TYPE: ${response.runtimeType}');

    // Debug each key-value pair
    response.forEach((key, value) {
      _logToFile('🔍 $key: $value (${value.runtimeType})');
    });

    // Extract detailed error information for display
    final detailedErrorInfo = _extractDetailedErrorInfo(response);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      PaymentResponse paymentResponse;

      try {
        // Parse response according to official Flutter documentation format
        // Expected format: response.paymentMethod.paymentTransaction.statusCode
        if (response.containsKey('paymentMethod') &&
            response['paymentMethod'] != null &&
            response['paymentMethod'].containsKey('paymentTransaction') &&
            response['paymentMethod']['paymentTransaction'] != null) {

          var paymentMethod = response['paymentMethod'];
          var paymentTransaction = paymentMethod['paymentTransaction'];

          String statusCode = paymentTransaction['statusCode']?.toString() ?? '';
          String statusMessage = paymentTransaction['statusMessage']?.toString() ?? '';
          String transactionId = paymentTransaction['identifier']?.toString() ?? '';
          String bankRefId = paymentTransaction['bankReferenceIdentifier']?.toString() ?? '';
          String amount = paymentTransaction['amount']?.toString() ?? '';

          _logToFile('🔍 Status Code: $statusCode');
          _logToFile('🔍 Status Message: $statusMessage');
          _logToFile('🔍 Transaction ID: $transactionId');
          _logToFile('🔍 Bank Reference ID: $bankRefId');
          _logToFile('🔍 Amount: $amount');

          if (statusCode == '0300') {
            // Success - according to official docs
            paymentResponse = PaymentResponse(
              status: PaymentStatus.success,
              amount: widget.amount,
              currency: 'INR',
              paymentMethod: 'Worldline',
              timestamp: DateTime.now(),
              transactionId: transactionId,
              gatewayTransactionId: bankRefId,
              additionalData: {
                'amount': widget.amount,
                'timestamp': DateTime.now().toIso8601String(),
                'paymentMethod': 'Worldline',
                'worldlineTransactionId': transactionId,
                'bankReferenceId': bankRefId,
                'statusMessage': statusMessage,
              },
            );
            _statusMessage = 'Payment completed successfully!';
          } else if (statusCode == '0398') {
            // Initiated - according to official docs
            paymentResponse = PaymentResponse(
              status: PaymentStatus.pending,
              amount: widget.amount,
              currency: 'INR',
              paymentMethod: 'Worldline',
              timestamp: DateTime.now(),
              transactionId: transactionId,
              gatewayTransactionId: bankRefId,
              additionalData: {
                'amount': widget.amount,
                'timestamp': DateTime.now().toIso8601String(),
                'paymentMethod': 'Worldline',
                'worldlineTransactionId': transactionId,
                'bankReferenceId': bankRefId,
                'statusMessage': statusMessage,
              },
            );
            _statusMessage = 'Payment initiated - awaiting confirmation';
          } else {
            // Failed or other status (0399, 0396, 0392)
            paymentResponse = PaymentResponse(
              status: PaymentStatus.failed,
              amount: widget.amount,
              currency: 'INR',
              paymentMethod: 'Worldline',
              timestamp: DateTime.now(),
              transactionId: transactionId,
              gatewayTransactionId: bankRefId,
              errorMessage: statusMessage.isNotEmpty ? statusMessage : 'Payment failed',
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

          paymentResponse = PaymentResponse(
            status: PaymentStatus.failed,
            amount: widget.amount,
            currency: 'INR',
            paymentMethod: 'Worldline',
            timestamp: DateTime.now(),
            transactionId: '',
            errorMessage: errorDesc,
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
            _logToFile('🔍 LEGACY RESPONSE FORMAT DETECTED');
            String msg = response['msg'] ?? '';
            _logToFile('🔍 Raw msg content: $msg');

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

              if (statusCode == '0300') {
                // Success
                paymentResponse = PaymentResponse(
                  status: PaymentStatus.success,
                  amount: widget.amount,
                  currency: 'INR',
                  paymentMethod: 'Worldline',
                  timestamp: DateTime.now(),
                  transactionId: transactionId,
                  gatewayTransactionId: gatewayTxnId.isNotEmpty ? gatewayTxnId : bankRefId,
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
                  amount: widget.amount,
                  currency: 'INR',
                  paymentMethod: 'Worldline',
                  timestamp: DateTime.now(),
                  transactionId: transactionId,
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
          amount: widget.amount,
          currency: 'INR',
          paymentMethod: 'Worldline',
          timestamp: DateTime.now(),
          transactionId: '',
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

      // Complete the payment flow
      widget.onPaymentComplete(paymentResponse);

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
        'metalType': widget.metalType ?? 'gold', // PRODUCTION: Determines which merchant (779285 for gold, 779295 for silver)
      };

      _logToFile('📤 TOKEN REQUEST: $url');
      _logToFile('📤 Payload: ${jsonEncode(payload)}');
      _logToFile('💰 AMOUNT CONVERSION DEBUG:');
      _logToFile('💰 Original Amount: ₹${widget.amount} (${widget.amount.runtimeType})');
      _logToFile('💰 Decimal Amount: ${widget.amount.toStringAsFixed(2)} (decimal format)');
      _logToFile('💰 Final String: "${amountAsDecimal}" (${amountAsDecimal.runtimeType})');
      _logToFile('💰 String Length: ${amountAsDecimal.length} characters');
      _logToFile('💰 Contains Decimal: ${amountAsDecimal.contains('.')}');
      _logToFile('🏪 Metal Type: ${widget.metalType ?? 'gold'} (Merchant: ${widget.metalType == 'silver' ? '779295' : '779285'})');

      final response = await SecureHttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
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

    // CRITICAL FIX: Initialize SDK only when user clicks "Start Payment"
    if (!_isSDKInitialized) {
      _logToFile('🔧 Initializing Worldline SDK now (user clicked Start Payment)...');
      _setupWorldlineEventListeners();
      // Wait for SDK to be ready
      await Future.delayed(const Duration(milliseconds: 300));
    }

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
              "itemId": "GOLD_PURCHASE",
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
      _logToFile('🔧 Plugin Method: _wlCheckoutFlutter.open()');
      _logToFile('📋 Final Payment Options: ${jsonEncode(paymentOptions)}');

      // CRITICAL FIX: Delay Worldline SDK presentation to avoid "presentation in progress" error
      // Wait for Flutter view to be fully presented before opening Worldline
      await Future.delayed(const Duration(milliseconds: 800));

      _logToFile('⏳ Delayed 800ms to ensure Flutter view is ready');

      // Ensure SDK is initialized
      if (_wlCheckoutFlutter == null) {
        _logToFile('❌ CRITICAL ERROR: Worldline SDK not initialized!');
        throw Exception('Worldline SDK not initialized');
      }

      // Open Worldline checkout using official plugin
      _wlCheckoutFlutter!.open(paymentOptions);

      _logToFile('✅ Worldline checkout opened successfully - waiting for response...');

    } catch (e) {
      _logToFile('❌ Error initializing Worldline payment: $e');
      throw Exception('Failed to initialize payment: $e');
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

}
