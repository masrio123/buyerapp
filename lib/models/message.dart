int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.round();
  return 0;
}

class Sender {
  final int id;
  final String name;

  Sender({required this.id, required this.name});

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: _parseInt(json['id']), // PERBAIKAN: Menggunakan parser aman
      name: json['porter_name'] ?? json['customer_name'] ?? 'Unknown User',
    );
  }
}

class Message {
  final int id;
  final int orderId;
  final String message;
  final DateTime createdAt;

  final Sender? porter;
  final Sender? customer;

  Message({
    required this.id,
    required this.orderId,
    required this.message,
    required this.createdAt,
    this.porter,
    this.customer,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: _parseInt(json['id']), // PERBAIKAN: Menggunakan parser aman
      orderId: _parseInt(
        json['order_id'],
      ), // PERBAIKAN: Menggunakan parser aman
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      porter: json['porter'] != null ? Sender.fromJson(json['porter']) : null,
      customer:
          json['customer'] != null ? Sender.fromJson(json['customer']) : null,
    );
  }
}
