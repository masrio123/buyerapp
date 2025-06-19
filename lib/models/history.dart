import 'package:flutter/material.dart';

// Kelas utama untuk merepresentasikan satu order dalam riwayat.
class Order {
  final String date;
  final String? porter;
  final String id;
  final String orderStatus;
  final num grandTotal;
  final num totalPrice;
  final num shippingCost;
  final List<RestaurantOrder> items;

  Order({
    required this.date,
    this.porter,
    required this.id,
    required this.orderStatus,
    required this.grandTotal,
    required this.totalPrice,
    required this.shippingCost,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String? porterName;
    if (json['porter'] != null && json['porter'] is Map<String, dynamic>) {
      porterName = json['porter']['name'];
    }

    return Order(
      date: json['order_date'] ?? '',
      porter: porterName,
      id: json['order_id']?.toString() ?? '-',
      orderStatus: json['order_status'] ?? 'N/A',
      grandTotal: num.tryParse(json['grand_total'].toString()) ?? 0,
      totalPrice: num.tryParse(json['total_price'].toString()) ?? 0,
      shippingCost: num.tryParse(json['shipping_cost'].toString()) ?? 0,
      items:
          (json['items'] as List<dynamic>?)?.map<RestaurantOrder>((tenantJson) {
            return RestaurantOrder.fromJson(tenantJson);
          }).toList() ??
          [],
    );
  }
}

// Kelas untuk mengelompokkan item dan catatan per tenant/restoran.
class RestaurantOrder {
  final String name;
  final List<OrderItem> items;
  final String? note;

  RestaurantOrder({required this.name, required this.items, this.note});

  factory RestaurantOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = json['products'] ?? json['items'];

    return RestaurantOrder(
      name: json['tenant_name'] ?? 'Tenant Dihapus',
      note: json['note'],
      items:
          (itemsList as List<dynamic>?)
              ?.map<OrderItem>((itemJson) => OrderItem.fromJson(itemJson))
              .toList() ??
          [],
    );
  }
}

// Kelas untuk merepresentasikan satu item produk dalam sebuah order.
class OrderItem {
  final String name;
  final int quantity;
  final num price;
  final String? notes;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['product_name'] ?? 'Produk Dihapus',
      quantity: json['quantity'] ?? 0,
      price: num.tryParse(json['price'].toString()) ?? 0,
      notes: json['notes'],
    );
  }
}
