import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/customer.dart';

class CustomerService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<Customer> fetchCustomerDetail() async {
    final token = await getToken();
    final userId = await getUserId();

    if (token == null || userId == null) {
      throw Exception('Token atau User ID tidak ditemukan.');
    }

    final response = await http.get(
      Uri.parse('$baseURL/customers/$userId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Logika parsing sekarang sepenuhnya ditangani oleh Customer.fromJson
      return Customer.fromJson(data);
    } else {
      throw Exception('Failed to load customer detail: ${response.statusCode}');
    }
  }

  // --- PERUBAHAN ---
  // Fungsi ini dihapus karena sudah tidak relevan.
  // static String getBankName(int id) { ... }
}
