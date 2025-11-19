import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SecureHttpClient {
  static final SecureHttpClient _instance = SecureHttpClient._internal();
  factory SecureHttpClient() => _instance;
  SecureHttpClient._internal();

  static late http.Client _client;

  static void initialize() {
    // Use custom HttpClient that accepts self-signed certificates
    final httpClient = createHttpClient();
    _client = IOClient(httpClient);
  }

  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      final response = await _client
          .get(uri, headers: defaultHeaders)
          .timeout(timeout ?? const Duration(seconds: 30));

      return response;
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      throw Exception('Server communication failed.');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid server response format.');
    } catch (e) {
      print('Unexpected error in GET request: $e');
      throw Exception('Request failed: $e');
    }
  }

  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      String? requestBody;
      if (body != null) {
        if (body is Map || body is List) {
          requestBody = jsonEncode(body);
        } else {
          requestBody = body.toString();
        }
      }

      final response = await _client
          .post(
            uri,
            headers: defaultHeaders,
            body: requestBody,
            encoding: encoding,
          )
          .timeout(timeout ?? const Duration(seconds: 30));

      return response;
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      throw Exception('Server communication failed.');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid server response format.');
    } catch (e) {
      print('Unexpected error in POST request: $e');
      throw Exception('Request failed: $e');
    }
  }

  static Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      String? requestBody;
      if (body != null) {
        if (body is Map || body is List) {
          requestBody = jsonEncode(body);
        } else {
          requestBody = body.toString();
        }
      }

      final response = await _client
          .put(
            uri,
            headers: defaultHeaders,
            body: requestBody,
            encoding: encoding,
          )
          .timeout(timeout ?? const Duration(seconds: 30));

      return response;
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      throw Exception('Server communication failed.');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid server response format.');
    } catch (e) {
      print('Unexpected error in PUT request: $e');
      throw Exception('Request failed: $e');
    }
  }

  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse(url);
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      String? requestBody;
      if (body != null) {
        if (body is Map || body is List) {
          requestBody = jsonEncode(body);
        } else {
          requestBody = body.toString();
        }
      }

      final response = await _client
          .delete(
            uri,
            headers: defaultHeaders,
            body: requestBody,
            encoding: encoding,
          )
          .timeout(timeout ?? const Duration(seconds: 30));

      return response;
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      throw Exception('Server communication failed.');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid server response format.');
    } catch (e) {
      print('Unexpected error in DELETE request: $e');
      throw Exception('Request failed: $e');
    }
  }

  static void dispose() {
    _client.close();
  }

  // Helper method to handle SSL certificate validation for self-signed certificates
  static HttpClient createHttpClient() {
    final client = HttpClient();
    
    // Allow self-signed certificates for development/testing
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // In production, you should implement proper certificate validation
      // For now, we'll accept all certificates to handle self-signed ones
      print('Warning: Accepting certificate for $host:$port');
      return true;
    };
    
    return client;
  }

  // Method to test connection with SSL handling
  static Future<bool> testConnection(String url) async {
    try {
      final response = await get(url);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
