import 'dart:convert';
import 'package:crypto/crypto.dart';

/// HMAC Helper for Request Signing
/// 
/// This class provides utilities for generating HMAC signatures
/// to secure API requests and prevent tampering.
/// 
/// Usage:
/// ```dart
/// final signature = HMACHelper.generateSignature(
///   data: {'amount': 1000, 'customer_id': 'VM25'},
///   timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
/// );
/// 
/// // Add to API request headers
/// headers: {
///   'X-Signature': signature,
///   'X-Timestamp': timestamp.toString(),
///   'X-Customer-Id': customerId,
/// }
/// ```
class HMACHelper {
  // ⚠️ SECURITY NOTE: This secret should match the server's HMAC_SECRET
  // In production, this should be:
  // 1. Stored in a secure location (not hardcoded)
  // 2. Obfuscated using flutter_dotenv or similar
  // 3. Different per environment (dev/staging/prod)
  static const String _HMAC_SECRET = 'VMURUGAN_HMAC_SECRET_CHANGE_IN_PRODUCTION_2025';
  
  /// Generate HMAC-SHA256 signature for API request
  /// 
  /// Parameters:
  /// - [data]: Request data (body for POST, query params for GET)
  /// - [timestamp]: Unix timestamp in seconds
  /// - [secret]: Optional custom secret (defaults to _HMAC_SECRET)
  /// 
  /// Returns: Hex-encoded HMAC signature
  static String generateSignature({
    required Map<String, dynamic> data,
    required int timestamp,
    String? secret,
  }) {
    try {
      // Use provided secret or default
      final hmacSecret = secret ?? _HMAC_SECRET;
      
      // Create message: JSON(data) + timestamp
      final jsonData = jsonEncode(data);
      final message = jsonData + timestamp.toString();
      
      // Generate HMAC-SHA256
      final key = utf8.encode(hmacSecret);
      final bytes = utf8.encode(message);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      
      // Return hex-encoded signature
      return digest.toString();
    } catch (e) {
      print('❌ HMAC signature generation failed: $e');
      rethrow;
    }
  }
  
  /// Get current Unix timestamp in seconds
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  
  /// Validate if timestamp is within acceptable range
  /// 
  /// Parameters:
  /// - [timestamp]: Unix timestamp to validate
  /// - [toleranceSeconds]: Maximum age in seconds (default: 300 = 5 minutes)
  /// 
  /// Returns: true if timestamp is valid
  static bool isTimestampValid({
    required int timestamp,
    int toleranceSeconds = 300,
  }) {
    final now = getCurrentTimestamp();
    final diff = (now - timestamp).abs();
    return diff <= toleranceSeconds;
  }
  
  /// Generate signed request headers
  /// 
  /// Parameters:
  /// - [data]: Request data
  /// - [customerId]: Customer identifier
  /// 
  /// Returns: Map of headers to add to API request
  static Map<String, String> generateSignedHeaders({
    required Map<String, dynamic> data,
    required String customerId,
  }) {
    final timestamp = getCurrentTimestamp();
    final signature = generateSignature(
      data: data,
      timestamp: timestamp,
    );
    
    return {
      'X-Signature': signature,
      'X-Timestamp': timestamp.toString(),
      'X-Customer-Id': customerId,
    };
  }
}

/// Example Usage:
/// 
/// ```dart
/// // In your API service
/// Future<Response> makeSignedRequest({
///   required String endpoint,
///   required Map<String, dynamic> data,
///   required String customerId,
/// }) async {
///   final headers = HMACHelper.generateSignedHeaders(
///     data: data,
///     customerId: customerId,
///   );
///   
///   return await http.post(
///     Uri.parse(endpoint),
///     headers: {
///       'Content-Type': 'application/json',
///       ...headers,
///     },
///     body: jsonEncode(data),
///   );
/// }
/// ```
