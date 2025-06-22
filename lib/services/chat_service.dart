import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart'; // Sesuaikan path jika perlu
import '../constant/constant.dart'; // Sesuaikan path jika perlu
import 'dart:convert';

class ChatService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<Message>> getMessages(int orderId) async {
    final token = await getToken();
    if (token == null) throw Exception('Token not found');

    final response = await http.get(
      Uri.parse('$baseURL/chats/$orderId/messages'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true && responseData['data'] is List) {
        final List<dynamic> data = responseData['data'];
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<Message> sendMessage(int orderId, String messageText) async {
    final token = await getToken();
    if (token == null) throw Exception('Token not found');

    final response = await http.post(
      Uri.parse('$baseURL/chats/$orderId/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': messageText}),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Message.fromJson(responseData['data']);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send message');
    }
  }
}
