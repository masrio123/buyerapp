class Tenant {
  final int id;
  final String name;
  final int tenantLocationId;

  Tenant({
    required this.id,
    required this.name,
    required this.tenantLocationId,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      tenantLocationId: json['tenant_location_id'],
    );
  }
}
