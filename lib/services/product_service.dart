import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/product.dart'; // Pastikan Tenant sudah diganti dengan TenantMenu

class ProductService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
  fetchKantinMenu(int locationID) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseURL/products/$locationID/tenants-products'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final tenants = jsonData['data']['tenants'] as List;

      final Map<String, Map<String, List<Map<String, dynamic>>>> kantinMenu =
          {};

      for (var tenantJson in tenants) {
        final tenant = TenantMenu.fromJson(tenantJson);

        kantinMenu.putIfAbsent(tenant.name, () => {});

        for (var category in tenant.categories) {
          kantinMenu[tenant.name]![category.name] =
              category.products.map((product) {
                return {'name': product.name, 'price': product.price};
              }).toList();
        }
      }

      return kantinMenu;
    } else {
      throw Exception('Failed to load menu data');
    }
  }
}
