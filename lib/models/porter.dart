class PorterResult {
  final String message;
  final String totalPrice;
  final String shippingCost;
  final String grandTotal;
  final String porterName;
  final String porterNrp;
  final String porterDepartment;

  PorterResult({
    required this.message,
    required this.totalPrice,
    required this.shippingCost,
    required this.grandTotal,
    required this.porterName,
    required this.porterNrp,
    required this.porterDepartment,
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
    );
  }
}
