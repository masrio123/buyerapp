import 'history.dart';

class PorterResult {
  final int orderId;
  final String message;
  final String totalPrice;
  final String shippingCost;
  final String grandTotal;
  final String porterName;
  final String porterNrp;
  final String porterDepartment;
  final List<OrderStatus> status;
  final List<RestaurantOrder> items; // Properti 'items' yang dibutuhkan

  PorterResult({
    required this.orderId,
    required this.message,
    required this.totalPrice,
    required this.shippingCost,
    required this.grandTotal,
    required this.porterName,
    required this.porterNrp,
    required this.porterDepartment,
    required this.status,
    required this.items, // Ditambahkan di constructor
  });

  factory PorterResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final porter = data['porter'];

    var restaurantItems =
        (data['items'] as List<dynamic>)
            .map<RestaurantOrder>(
              (tenantJson) => RestaurantOrder.fromJson(tenantJson),
            )
            .toList();

    return PorterResult(
      orderId: data['order_id'],
      message: json['message'],
      totalPrice: data['total_price'].toString(),
      shippingCost: data['shipping_cost'].toString(),
      grandTotal: data['grand_total'].toString(),
      porterName: porter['name'],
      porterNrp: porter['nrp'],
      porterDepartment: porter['department'],
      status:
          (json['status'] as List).map((e) => OrderStatus.fromJson(e)).toList(),
      items: restaurantItems, // Parsing data 'items'
    );
  }
}

class OrderStatus {
  final String label;
  final bool key;

  OrderStatus({required this.label, required this.key});

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(label: json['label'], key: json['key']);
  }
}
