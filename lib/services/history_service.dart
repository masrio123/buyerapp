import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/history.dart';

class HistoryService {
  // Mendapatkan token dari SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Mendapatkan customer_id dari SharedPreferences
  static Future<String?> customerID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customer_id');
  }

  static List<Order> parseOrders(Map<String, dynamic> responseJson) {
    final List<dynamic> data = responseJson['data'] ?? [];

    return data.map<Order>((orderJson) {
      return Order.fromJson(
        orderJson,
      ); // Menggunakan factory constructor yang sudah ada
    }).toList();
  }

  // Fetch data history order customer
  static Future<List<Order>> fetchCustomerDetail() async {
    final token = await getToken();
    final custId = await customerID();

    if (token == null || custId == null) {
      throw Exception('Token atau Customer ID tidak tersedia');
    }

    final response = await http.get(
      Uri.parse('$baseURL/orders/activity/$custId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final orders = parseOrders(responseJson);
      return orders;
    } else {
      throw Exception('Failed to load customer detail');
    }
  }
}
