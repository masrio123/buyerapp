import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/tenant_location.dart';
import '../models/tenant.dart';

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

  static Future<List<Tenant>> fetchTenantByLocation(int locationId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseURL/location/$locationId/tenants'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((item) => Tenant.fromJson(item))
            .toList();
      } else {
        throw Exception(decoded['message'] ?? 'Unexpected response structure');
      }
    } else {
      throw Exception('Failed to load tenants for location ID $locationId');
    }
  }
}
