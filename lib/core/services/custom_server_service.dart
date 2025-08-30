import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomServerService {
  static const String baseUrl = 'https://103.124.152.220:3001';

  static Future<Map<String, dynamic>> saveTransaction(Map<String, dynamic> transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/transaction/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to save transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving transaction: $e');
    }
  }

  static Future<Map<String, dynamic>> saveCustomer(Map<String, dynamic> customer) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customer),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to save customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving customer: $e');
    }
  }

  static Future<void> logAnalytics({required String event, Map<String, dynamic>? data}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/analytics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'event': event, 'data': data}),
      );
    } catch (e) {
      print('Analytics logging failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getDashboardData({required String adminToken}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting dashboard data: $e');
    }
  }
}
