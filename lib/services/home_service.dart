import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/constant.dart';
import '../models/tenant_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<TenantLocation>> fetchTenantLocations() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseURL/tenant-locations'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => TenantLocation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load tenant locations');
    }
  }
}
