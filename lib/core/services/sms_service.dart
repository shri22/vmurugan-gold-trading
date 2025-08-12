import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/sms_config.dart';

/// SMS Service for sending real OTPs to mobile numbers
/// Supports multiple SMS providers for reliability
class SmsService {
  // Base URLs for different providers
  static const String _textlocalBaseUrl = 'https://api.textlocal.in/send/';
  static const String _twilioBaseUrl = 'https://api.twilio.com/2010-04-01/Accounts';
  static const String _msg91BaseUrl = 'https://api.msg91.com/api/v5/otp';
  static const String _fast2smsBaseUrl = 'https://www.fast2sms.com/dev/bulkV2';

  /// Send OTP via SMS to the specified phone number
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber, String otp) async {
    try {
      // Check if SMS service is configured
      if (!SmsConfig.isConfigured()) {
        throw Exception('SMS service not configured. Please update sms_config.dart with your API credentials.');
      }

      print('📱 SmsService: Sending OTP $otp to $phoneNumber via ${SmsConfig.provider}');

      switch (SmsConfig.provider) {
        case 'textlocal':
          return await _sendViaTextLocal(phoneNumber, otp);
        case 'twilio':
          return await _sendViaTwilio(phoneNumber, otp);
        case 'msg91':
          return await _sendViaMsg91(phoneNumber, otp);
        case 'fast2sms':
          return await _sendViaFast2SMS(phoneNumber, otp);
        default:
          throw Exception('Unknown SMS provider: ${SmsConfig.provider}');
      }
    } catch (e) {
      print('❌ SmsService: Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
        'provider': SmsConfig.provider,
      };
    }
  }

  /// Send OTP via TextLocal (Popular in India)
  static Future<Map<String, dynamic>> _sendViaTextLocal(String phoneNumber, String otp) async {
    try {
      final message = 'Your VMurugan verification code is: $otp. Valid for 5 minutes. Do not share this code with anyone.';

      final response = await http.post(
        Uri.parse(_textlocalBaseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'apikey': SmsConfig.textlocalApiKey,
          'numbers': phoneNumber,
          'message': message,
          'sender': SmsConfig.textlocalSender,
        },
      );

      print('📤 TextLocal Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': 'OTP sent successfully via TextLocal',
            'provider': 'textlocal',
            'messageId': data['messages']?[0]?['id'],
          };
        } else {
          throw Exception('TextLocal error: ${data['errors']?[0]?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('TextLocal SMS failed: $e');
    }
  }

  /// Send OTP via Twilio (Global provider)
  static Future<Map<String, dynamic>> _sendViaTwilio(String phoneNumber, String otp) async {
    try {
      final message = 'Your VMurugan verification code is: $otp. Valid for 5 minutes. Do not share this code.';

      final credentials = base64Encode(utf8.encode('${SmsConfig.twilioAccountSid}:${SmsConfig.twilioAuthToken}'));

      final response = await http.post(
        Uri.parse('$_twilioBaseUrl/${SmsConfig.twilioAccountSid}/Messages.json'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': SmsConfig.twilioFromNumber,
          'To': phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber',
          'Body': message,
        },
      );

      print('📤 Twilio Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'OTP sent successfully via Twilio',
          'provider': 'twilio',
          'messageId': data['sid'],
        };
      } else {
        final error = json.decode(response.body);
        throw Exception('Twilio error: ${error['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Twilio SMS failed: $e');
    }
  }

  /// Send OTP via MSG91 (Popular in India)
  static Future<Map<String, dynamic>> _sendViaMsg91(String phoneNumber, String otp) async {
    try {
      // Format phone number for MSG91 (remove +91 if present, ensure 10 digits)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (formattedPhone.startsWith('91') && formattedPhone.length == 12) {
        formattedPhone = formattedPhone.substring(2);
      }
      if (formattedPhone.length != 10) {
        throw Exception('Invalid phone number format. Expected 10 digits, got ${formattedPhone.length}');
      }

      print('📤 MSG91 Request:');
      print('📞 Phone: $formattedPhone');
      print('🔐 OTP: $otp');
      print('📋 Auth Key: ${SmsConfig.msg91ApiKey.substring(0, 8)}...');
      print('📤 Sender ID: ${SmsConfig.msg91SenderId}');

      // Try template-based SMS first (for production)
      Map<String, String> requestBody;
      String endpoint;

      if (SmsConfig.msg91TemplateId != 'YOUR_TEMPLATE_ID' && SmsConfig.msg91TemplateId.isNotEmpty) {
        // Use template-based SMS (recommended for production)
        endpoint = '$_msg91BaseUrl/send';
        requestBody = {
          'template_id': SmsConfig.msg91TemplateId,
          'sender': SmsConfig.msg91SenderId,
          'short_url': '0',
          'mobiles': '91$formattedPhone',
          'var1': otp, // OTP variable for template
        };
        print('📋 Using Template ID: ${SmsConfig.msg91TemplateId}');
      } else {
        // Fallback to direct SMS (for testing) - using different endpoint
        final message = 'Your VMurugan verification code is: $otp. Valid for 5 minutes. Do not share this code.';
        endpoint = 'https://api.msg91.com/api/sendhttp.php';
        requestBody = {
          'authkey': SmsConfig.msg91ApiKey,
          'mobiles': formattedPhone,
          'message': message,
          'sender': SmsConfig.msg91SenderId,
          'route': '4',
          'country': '91',
        };
        print('📋 Using Direct SMS (no template) - Testing Mode');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      print('📤 MSG91 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 MSG91 Response Data: $data');

        if (data['type'] == 'success') {
          return {
            'success': true,
            'message': 'OTP sent successfully via MSG91',
            'provider': 'msg91',
            'messageId': data['request_id'],
          };
        } else {
          final errorMsg = data['message'] ?? data['error'] ?? 'Unknown error';
          print('❌ MSG91 Error: $errorMsg');
          throw Exception('MSG91 error: $errorMsg');
        }
      } else {
        print('❌ MSG91 HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('MSG91 SMS failed: $e');
    }
  }

  /// Send OTP via Fast2SMS (Indian provider)
  static Future<Map<String, dynamic>> _sendViaFast2SMS(String phoneNumber, String otp) async {
    try {
      final message = 'Your VMurugan verification code is: $otp. Valid for 5 minutes. Do not share this code.';

      final response = await http.post(
        Uri.parse(_fast2smsBaseUrl),
        headers: {
          'authorization': SmsConfig.fast2smsApiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender_id': SmsConfig.fast2smsSenderId,
          'message': message,
          'language': 'english',
          'route': 'p',
          'numbers': phoneNumber,
        }),
      );

      print('📤 Fast2SMS Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['return'] == true) {
          return {
            'success': true,
            'message': 'OTP sent successfully via Fast2SMS',
            'provider': 'fast2sms',
            'messageId': data['request_id'],
          };
        } else {
          throw Exception('Fast2SMS error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Fast2SMS SMS failed: $e');
    }
  }

  /// Get SMS provider status and configuration
  static Map<String, dynamic> getProviderInfo() {
    return SmsConfig.getStatus();
  }

  /// Test SMS service configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    try {
      if (!SmsConfig.isConfigured()) {
        return {
          'success': false,
          'message': 'SMS provider ${SmsConfig.provider} is not configured. Please add API credentials.',
          'provider': SmsConfig.provider,
          'instructions': SmsConfig.getSetupInstructions(),
        };
      }

      return {
        'success': true,
        'message': 'SMS provider ${SmsConfig.provider} is configured and ready',
        'provider': SmsConfig.provider,
        'status': SmsConfig.getStatus(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Configuration test failed: $e',
        'provider': SmsConfig.provider,
      };
    }
  }
}
