import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/porter.dart';

class CartService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> customerID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customer_id');
  }

  static Future<int?> getLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_location_id');
  }

  static Future<Map<String, dynamic>> createCart() async {
    final token = await getToken();
    final customer_id = await customerID();
    final tenantLocationId = await getLocationId();

    print('user_id : $customer_id dan location_id : $tenantLocationId');

    if (token == null || customer_id == null) {
      throw Exception('Token or user ID not found');
    }

    final response = await http.post(
      Uri.parse('$baseURL/cart'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'customer_id': customer_id,
        'tenant_location_id': tenantLocationId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'message': data['message'], 'cart': data['cart']};
    } else {
      throw Exception('${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addToCart(
    int cartId,
    int productId,
    int quantity,
  ) async {
    print("cart_id  : $cartId, product_id : $productId store to database");

    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseURL/cart-items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cart_id': cartId,
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Berhasil menambahkan produk ke keranjang");
      return jsonDecode(response.body);
    } else {
      final errorMessage = jsonDecode(response.body);
      print(
        "❌ Gagal menambahkan produk: ${response.statusCode} - ${errorMessage['message'] ?? response.body}",
      );
      throw Exception('${errorMessage['message'] ?? 'Unknown error'}');
    }
  }

  static Future<Map<String, dynamic>> checkoutCart(int cartId) async {
    print("🛒 Melakukan checkout untuk cart_id: $cartId");

    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseURL/cart/$cartId/checkout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Checkout berhasil");
      return jsonDecode(response.body);
    } else {
      final errorMessage = jsonDecode(response.body);
      print(
        "❌ Gagal checkout: ${response.statusCode} - ${errorMessage['message'] ?? response.body}",
      );
      throw Exception('${errorMessage['message'] ?? 'Unknown error'}');
    }
  }

  static Future<PorterResult> searchPorter(int orderId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseURL/orders/search-porter/$orderId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print("✅ Berhasil mendapatkan porter: ${jsonData['message']}");
      return PorterResult.fromJson(jsonData);
    } else {
      final errorMessage = jsonDecode(response.body);
      print(
        "❌ Gagal mendapatkan porter: ${response.statusCode} - ${errorMessage['message'] ?? response.body}",
      );
      throw Exception('Gagal mengambil data porter');
    }
  }
}
