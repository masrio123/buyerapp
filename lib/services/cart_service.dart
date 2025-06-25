import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/constant.dart';
import '../models/porter.dart';
import '../models/delivery.dart';

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
    return prefs.getInt('selected_location_id') ?? 1;
  }

  static Future<Map<String, dynamic>> createCart(int deliveryId) async {
    final token = await getToken();
    final customer_id = await customerID();
    final tenantLocationId = await getLocationId();

    if (token == null || customer_id == null) {
      throw Exception('Token atau ID Pengguna tidak ditemukan.');
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
        'delivery_id': deliveryId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'message': data['message'], 'cart': data['cart']};
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Gagal membuat keranjang.');
    }
  }

  static Future<Map<String, dynamic>> addToCart(
    int cartId,
    int productId,
    int quantity,
  ) async {
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
      return jsonDecode(response.body);
    } else {
      final errorMessage = jsonDecode(response.body);
      throw Exception(errorMessage['message'] ?? 'Gagal menambahkan item.');
    }
  }

  // --- FUNGSI INI TELAH DIPERBAIKI ---
  static Future<Map<String, dynamic>> checkoutCart(
    int cartId,
    List<Map<String, dynamic>> notes,
  ) async {
    final token = await getToken();
    final body = jsonEncode({'notes': notes});

    final response = await http.post(
      Uri.parse('$baseURL/cart/$cartId/checkout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // Logika baru untuk menangani dan membersihkan pesan error
      final errorBody = jsonDecode(response.body);
      String serverMessage =
          errorBody['message'] ?? 'Terjadi kesalahan tidak diketahui.';

      // Cek jika pesan error spesifik tentang porter tidak tersedia
      if (serverMessage.toLowerCase().contains('no porter available')) {
        // Lemparkan exception dengan pesan yang bersih dan ramah pengguna
        throw Exception(
          "Tidak ada porter yang tersedia saat ini. Silakan coba lagi nanti.",
        );
      } else {
        // Untuk error lain, lemparkan pesan yang lebih umum
        throw Exception("Proses checkout gagal. Silakan coba lagi.");
      }
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseURL/orders/cancel/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = jsonDecode(response.body);
      throw Exception(errorMessage['message'] ?? 'Gagal membatalkan pesanan.');
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
      return PorterResult.fromJson(jsonData);
    } else {
      final errorMessage = jsonDecode(response.body);
      throw Exception(
        errorMessage['message'] ?? 'Gagal mengambil data porter.',
      );
    }
  }

  static Future<List<DeliveryPoint>> getDeliveryPoints() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseURL/delivery-points'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> data = jsonData['data'];
      return data.map((item) => DeliveryPoint.fromJson(item)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal mengambil titik pengantaran.');
    }
  }

  static Future<Map<String, dynamic>> ratePorter({
    required int orderId,
    required int rating,
    String? review,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.post(
      Uri.parse('$baseURL/orders/rate-porter/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rating': rating, 'review': review ?? ''}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Berhasil memberikan rating',
      };
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Gagal memberikan rating',
      };
    }
  }
}
