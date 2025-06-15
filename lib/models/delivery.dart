class DeliveryPoint {
  final int id;
  final String name;

  DeliveryPoint({required this.id, required this.name});

  factory DeliveryPoint.fromJson(Map<String, dynamic> json) {
    return DeliveryPoint(id: json['id'], name: json['delivery_point_name']);
  }
}
