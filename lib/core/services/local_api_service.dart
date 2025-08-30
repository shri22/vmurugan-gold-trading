import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalApiService {
  static Future<Map<String, dynamic>> saveTransaction(Map<String, dynamic> transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactions = await getTransactions();
      transactions.add(transaction);
      
      await prefs.setString('transactions', jsonEncode(transactions));
      
      return {'success': true, 'message': 'Transaction saved locally'};
    } catch (e) {
      throw Exception('Error saving transaction locally: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');
      
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error getting local transactions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> saveCustomerInfo(Map<String, dynamic> customer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_info', jsonEncode(customer));
      
      return {'success': true, 'message': 'Customer info saved locally'};
    } catch (e) {
      throw Exception('Error saving customer info locally: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCustomerInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerJson = prefs.getString('customer_info');
      
      if (customerJson != null) {
        return jsonDecode(customerJson);
      }
      
      return null;
    } catch (e) {
      print('Error getting local customer info: $e');
      return null;
    }
  }
}
