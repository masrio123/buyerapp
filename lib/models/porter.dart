import 'history.dart'; // Pastikan import ini benar

class PorterResult {
  // PERBAIKAN 1: Tambahkan properti 'success'
  final bool success;

  final int orderId;
  final String message;
  final String totalPrice;
  final String shippingCost;
  final String grandTotal;
  final String porterName;
  final String porterNrp;
  final String porterDepartment;
  final String bankName;
  final String accountNumbers;
  final String username;
  final List<OrderStatus> status;
  final List<RestaurantOrder> items;

  PorterResult({
    // PERBAIKAN 2: Tambahkan 'success' di constructor
    required this.success,
    required this.orderId,
    required this.message,
    required this.totalPrice,
    required this.shippingCost,
    required this.grandTotal,
    required this.porterName,
    required this.porterNrp,
    required this.porterDepartment,
    required this.bankName,
    required this.accountNumbers,
    required this.username,
    required this.status,
    required this.items,
  });

  // PERBAIKAN 3: Factory dibuat lebih aman untuk menangani semua kasus
  factory PorterResult.fromJson(Map<String, dynamic> json) {
    // Baca flag 'success'. Jika tidak ada, anggap false agar aman.
    final isSuccess = json['success'] ?? false;
    final data = json['data'];

    // Jika operasi gagal (tidak ada porter) atau data null,
    // buat objek dengan nilai default agar aplikasi tidak crash.
    if (isSuccess == false || data == null) {
      return PorterResult(
        success: isSuccess,
        message: json['message'] ?? 'Gagal memuat data.',
        orderId: 0,
        totalPrice: '0',
        shippingCost: '0',
        grandTotal: '0',
        porterName: '',
        porterNrp: '',
        porterDepartment: '',
        bankName: '',
        accountNumbers: '',
        username: '',
        status: [],
        items: [],
      );
    }

    // Jika operasi sukses dan data ada, lanjutkan parsing seperti biasa.
    final porter =
        data['porter'] ?? {}; // Default ke map kosong jika porter null

    var restaurantItems =
        (data['items'] as List<dynamic>?)
            ?.map<RestaurantOrder>(
              (tenantJson) => RestaurantOrder.fromJson(tenantJson),
            )
            .toList() ??
        [];

    return PorterResult(
      success: isSuccess,
      orderId: data['order_id'] ?? 0,
      message: json['message'] ?? '',
      totalPrice: data['total_price']?.toString() ?? '0',
      shippingCost: data['shipping_cost']?.toString() ?? '0',
      grandTotal: data['grand_total']?.toString() ?? '0',
      porterName: porter['name'] ?? 'N/A',
      porterNrp: porter['nrp'] ?? 'N/A',
      porterDepartment: porter['department'] ?? 'N/A',
      bankName: porter['bank_name'] ?? 'N/A',
      accountNumbers: porter['account_numbers'] ?? 'N/A',
      username: porter['username'] ?? 'N/A',
      status:
          (json['status'] as List?)
              ?.map((e) => OrderStatus.fromJson(e))
              .toList() ??
          [],
      items: restaurantItems,
    );
  }
}

class OrderStatus {
  final String label;
  final bool key;

  OrderStatus({required this.label, required this.key});

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(label: json['label'] ?? '', key: json['key'] ?? false);
  }
}
