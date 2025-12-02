import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/secure_http_client.dart';
import '../models/payment_response.dart';

/// Omniware Payment Page Screen (UPI Mode)
/// 
/// This screen opens Omniware's payment gateway page in a WebView.
/// User can scan QR code or enter UPI ID to complete payment.
/// 
/// Advantages over UPI Intent:
/// - Instant payment status (no 1030 delay)
/// - Automatic return to app via return_url
/// - Webhooks work reliably
/// - Better user experience
class OmniwarePaymentPageScreen extends StatefulWidget {
  final double amount;
  final String metalType;
  final String description;
  final Function(PaymentResponse) onPaymentComplete;
  final double? goldGrams;
  final double? silverGrams;

  const OmniwarePaymentPageScreen({
    Key? key,
    required this.amount,
    required this.metalType,
    required this.description,
    required this.onPaymentComplete,
    this.goldGrams,
    this.silverGrams,
  }) : super(key: key);

  @override
  State<OmniwarePaymentPageScreen> createState() => _OmniwarePaymentPageScreenState();
}

class _OmniwarePaymentPageScreenState extends State<OmniwarePaymentPageScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String _statusMessage = 'Initializing payment...';
  String? _paymentPageUrl;
  Map<String, dynamic>? _formParams;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    print('\n🌐 ========== OMNIWARE PAYMENT PAGE SCREEN ========== 🌐');
    print('Amount: ₹${widget.amount}');
    print('Metal Type: ${widget.metalType}');
    print('Description: ${widget.description}');
    
    _initializePayment();
  }

  /// Initialize payment by getting payment page URL from server
  Future<void> _initializePayment() async {
    try {
      setState(() {
        _statusMessage = 'Generating payment page...';
      });

      print('📡 Requesting payment page URL from server...');

      // Get customer details
      final customerInfo = await CustomerService.getCustomerInfo();

      final response = await SecureHttpClient.post(
        '${ApiConfig.baseUrl}/api/omniware/payment-page-url',
        headers: {'Content-Type': 'application/json'},
        body: {
          'metalType': widget.metalType,
          'amount': widget.amount,
          'description': widget.description,
          'customerName': customerInfo['name'] ?? 'Customer',
          'customerEmail': customerInfo['email'] ?? 'customer@vmuruganjewellery.co.in',
          'customerPhone': customerInfo['phone'] ?? '',
          'customerAddress': customerInfo['address'] ?? '',
          'customerCity': 'Chennai',
          'customerState': 'Tamil Nadu',
          'customerCountry': 'IND',
          'customerZipCode': '600001',
          'returnUrl': 'vmurugangold://payment/success',
          'returnUrlFailure': 'vmurugangold://payment/failure',
          'returnUrlCancel': 'vmurugangold://payment/cancel',
        },
      );

      print('📥 Server response status: ${response.statusCode}');
      print('📥 Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _paymentPageUrl = data['paymentPageUrl'];
            _formParams = Map<String, dynamic>.from(data['formParams']);
            _orderId = data['orderId'];
            _statusMessage = 'Loading payment page...';
          });

          print('✅ Payment page URL received');
          print('   URL: $_paymentPageUrl');
          print('   Order ID: $_orderId');

          // Initialize WebView
          _initializeWebView();
        } else {
          throw Exception(data['error'] ?? 'Failed to generate payment page URL');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error initializing payment: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Initialize WebView with payment page
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print('🔗 Navigation request: $url');

            // Handle return URLs (payment complete/cancel/failure)
            if (url.startsWith('vmurugangold://payment/')) {
              _handleReturnUrl(url);
              return NavigationDecision.prevent;
            }

            // Handle UPI deep links (phonepe://, gpay://, paytm://, upi://, etc.)
            if (url.startsWith('upi://') ||
                url.startsWith('phonepe://') ||
                url.startsWith('gpay://') ||
                url.startsWith('paytm://') ||
                url.startsWith('paytmmp://') ||
                url.startsWith('credpay://') ||
                url.startsWith('mobikwik://') ||
                url.startsWith('bharatpe://') ||
                url.startsWith('freecharge://') ||
                url.startsWith('payzapp://') ||
                url.startsWith('bhim://') ||
                url.startsWith('slice://')) {
              print('📱 UPI deep link detected: $url');
              _launchUpiApp(url);
              return NavigationDecision.prevent;
            }

            // Allow all other URLs (payment gateway pages)
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('📄 Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
          },
        ),
      );

    // Load payment page by POSTing form data
    _loadPaymentPage();
  }

  /// Launch UPI app for payment
  Future<void> _launchUpiApp(String url) async {
    try {
      print('🚀 Launching UPI app: $url');

      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ UPI app launched successfully');

        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete payment in UPI app and return to this screen'),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        print('❌ Cannot launch UPI app: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UPI app not installed. Please install a UPI app.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error launching UPI app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open UPI app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load payment page by creating HTML form and auto-submitting
  Future<void> _loadPaymentPage() async {
    if (_paymentPageUrl == null || _formParams == null) {
      print('❌ Cannot load payment page: URL or params missing');
      return;
    }

    // Create HTML form with auto-submit
    final formFields = _formParams!.entries
        .map((e) => '<input type="hidden" name="${e.key}" value="${e.value}">')
        .join('\n');

    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Processing Payment...</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .loader {
            text-align: center;
            color: white;
        }
        .spinner {
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 4px solid white;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="loader">
        <div class="spinner"></div>
        <h2>Redirecting to Payment Gateway...</h2>
        <p>Please wait...</p>
    </div>
    <form id="paymentForm" method="POST" action="$_paymentPageUrl">
        $formFields
    </form>
    <script>
        // Auto-submit form after 1 second
        setTimeout(function() {
            document.getElementById('paymentForm').submit();
        }, 1000);
    </script>
</body>
</html>
''';

    print('📝 Loading payment page HTML...');
    await _webViewController.loadHtmlString(html);
  }

  /// Handle return URL from payment gateway
  void _handleReturnUrl(String url) {
    print('\n🔙 ========== RETURN URL RECEIVED ========== 🔙');
    print('URL: $url');

    if (url.contains('/success')) {
      print('✅ Payment SUCCESS detected from return URL');
      _checkPaymentStatus();
    } else if (url.contains('/failure')) {
      print('❌ Payment FAILURE detected from return URL');
      _handlePaymentFailure('Payment failed');
    } else if (url.contains('/cancel')) {
      print('⚠️ Payment CANCELLED by user');
      _handlePaymentCancelled();
    }
  }

  /// Check payment status from server
  Future<void> _checkPaymentStatus() async {
    if (_orderId == null) {
      print('❌ Cannot check status: Order ID missing');
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Verifying payment...';
        _isLoading = true;
      });

      print('📡 Checking payment status for Order ID: $_orderId');

      final response = await SecureHttpClient.post(
        '${ApiConfig.baseUrl}/api/omniware/check-payment-status',
        headers: {'Content-Type': 'application/json'},
        body: {
          'orderId': _orderId,
          'metalType': widget.metalType,
        },
      );

      print('📥 Status check response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];

          if (data != null && data['status'] == 'success') {
            print('✅ Payment verified as successful!');
            _handlePaymentSuccess(data);
          } else if (data != null && data['status'] == 'pending') {
            print('⏳ Payment still pending, will retry...');
            _handlePaymentFailure('Payment is still being processed. Please wait.');
          } else {
            print('❌ Payment failed or cancelled');
            _handlePaymentFailure(data?['responseMessage'] ?? 'Payment verification failed');
          }
        } else {
          _handlePaymentFailure(responseData['error'] ?? 'Payment verification failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error checking payment status: $e');
      _handlePaymentFailure('Error verifying payment: $e');
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess(dynamic data) {
    print('\n🎉 ========== PAYMENT SUCCESS ========== 🎉');
    print('Transaction ID: ${data['transactionId']}');
    print('Order ID: ${data['orderId']}');
    print('Amount: ₹${data['amount']}');
    print('Payment DateTime: ${data['paymentDatetime']}');
    print('Response Code: ${data['responseCode']}');
    print('Response Message: ${data['responseMessage']}');
    print('========================================\n');

    setState(() {
      _isLoading = false;
      _statusMessage = 'Payment successful!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! 🎉'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    final paymentResponse = PaymentResponse.success(
      transactionId: data['orderId'] ?? _orderId!,
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? widget.amount,
      paymentMethod: 'Omniware UPI',
      gatewayTransactionId: data['transactionId'],
      gatewayResponse: jsonEncode(data),
      additionalData: {
        'orderId': data['orderId'],
        'transactionId': data['transactionId'],
        'metalType': widget.metalType,
        'goldGrams': widget.goldGrams,
        'silverGrams': widget.silverGrams,
        'paymentDatetime': data['paymentDatetime'],
        'responseCode': data['responseCode'],
        'responseMessage': data['responseMessage'],
        'paymentMode': data['paymentMode'],
        'paymentChannel': data['paymentChannel'],
      },
    );

    // Call the callback to notify parent (for immediate UI updates)
    widget.onPaymentComplete(paymentResponse);

    // Also return the response via Navigator so the dialog can handle it
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('🔙 Returning payment response to dialog: ${paymentResponse.status}');
        Navigator.of(context).pop(paymentResponse);
      }
    });
  }

  /// Handle failed payment
  void _handlePaymentFailure(String message) {
    print('\n❌ ========== PAYMENT FAILURE ========== ❌');
    print('Message: $message');
    print('========================================\n');

    setState(() {
      _isLoading = false;
      _statusMessage = 'Payment failed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    final paymentResponse = PaymentResponse.failed(
      transactionId: _orderId ?? 'UNKNOWN',
      amount: widget.amount,
      paymentMethod: 'Omniware UPI',
      errorMessage: message,
    );

    widget.onPaymentComplete(paymentResponse);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(paymentResponse);
      }
    });
  }

  /// Handle cancelled payment
  void _handlePaymentCancelled() {
    print('\n⚠️ ========== PAYMENT CANCELLED ========== ⚠️\n');

    setState(() {
      _isLoading = false;
      _statusMessage = 'Payment cancelled';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled by user'),
        backgroundColor: Colors.orange,
      ),
    );

    final paymentResponse = PaymentResponse.cancelled(
      transactionId: _orderId ?? 'UNKNOWN',
      amount: widget.amount,
      paymentMethod: 'Omniware UPI',
      additionalData: {
        'reason': 'User cancelled payment',
      },
    );

    widget.onPaymentComplete(paymentResponse);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(paymentResponse);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          if (_paymentPageUrl != null)
            WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

