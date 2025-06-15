class Order {
  final String date;
  final String porter;
  final String id;
  final String order_status;
  final int grandTotal;
  final List<RestaurantOrder> items;

  Order({
    required this.date,
    required this.porter,
    required this.id,
    required this.order_status,
    required this.grandTotal,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      date: json['order_date'] ?? '',
      porter: json['porter_name'] ?? '-',
      id: json['order_id']?.toString() ?? '-',
      order_status: json['order_status'],
      grandTotal: json['grand_total'] ?? 0, // ← Tambahkan baris ini
      items:
          (json['items'] as List<dynamic>).map<RestaurantOrder>((tenantJson) {
            return RestaurantOrder.fromJson(tenantJson);
          }).toList(),
    );
  }
}

class RestaurantOrder {
  final String name;
  final List<OrderItem> items;
  final String? note;

  RestaurantOrder({required this.name, required this.items, this.note});

  factory RestaurantOrder.fromJson(Map<String, dynamic> json) {
    return RestaurantOrder(
      name: json['tenant_name'] ?? '',
      note: json['note'],
      items:
          (json['items'] as List<dynamic>)
              .map<OrderItem>((itemJson) => OrderItem.fromJson(itemJson))
              .toList(),
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final int price;

  OrderItem({required this.name, required this.quantity, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
    );
  }
}
