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
      return Order(
        date: orderJson['order_date'] ?? '',
        porter:
            orderJson['porter'] != null
                ? orderJson['porter']['name']
                : 'Belum Ada Porter',
        id: orderJson['order_id']?.toString() ?? '-',
        order_status: orderJson['order_status'],
        grandTotal: orderJson['grand_total'] ?? 0,
        items:
            (orderJson['items'] as List<dynamic>).map<RestaurantOrder>((
              tenantJson,
            ) {
              return RestaurantOrder(
                name: tenantJson['tenant_name'] ?? '',
                note: tenantJson['note'],
                items:
                    (tenantJson['items'] as List<dynamic>).map<OrderItem>((
                      itemJson,
                    ) {
                      return OrderItem(
                        name: itemJson['product_name'] ?? '',
                        quantity: itemJson['quantity'] ?? 0,
                        price: itemJson['price'] ?? 0,
                      );
                    }).toList(),
              );
            }).toList(),
      );
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
