class PorterResult {
  final String message;
  final String totalPrice;
  final String shippingCost;
  final String grandTotal;
  final String porterName;
  final String porterNrp;
  final String porterDepartment;
  final List<OrderStatus> status; // ✅ Tambahan field status

  PorterResult({
    required this.message,
    required this.totalPrice,
    required this.shippingCost,
    required this.grandTotal,
    required this.porterName,
    required this.porterNrp,
    required this.porterDepartment,
    required this.status,
  });

  factory PorterResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final porter = data['porter'];

    return PorterResult(
      message: json['message'],
      totalPrice: data['total_price'],
      shippingCost: data['shipping_cost'],
      grandTotal: data['grand_total'],
      porterName: porter['name'],
      porterNrp: porter['nrp'],
      porterDepartment: porter['department'],
      status:
          (json['status'] as List).map((e) => OrderStatus.fromJson(e)).toList(),
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
