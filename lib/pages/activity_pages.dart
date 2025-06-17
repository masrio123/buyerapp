import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/place_order_rating.dart'; // <<< PERBAIKAN: Import PorterFoundPage dari sini
import '../services/history_service.dart';
import '../models/history.dart';
import '../services/cart_service.dart';
import '../models/porter.dart';
import 'dart:async';
import 'package:petraporter_buyer/app_shell.dart';
import 'package:intl/intl.dart';

class ActivityPages extends StatefulWidget {
  const ActivityPages({Key? key}) : super(key: key);

  @override
  State<ActivityPages> createState() => _ActivityPagesState();
}

class _ActivityPagesState extends State<ActivityPages> {
  late Future<List<Order>> _futureOrders;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _futureOrders = HistoryService.fetchCustomerDetail();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _futureOrders = HistoryService.fetchCustomerDetail();
    });
  }

  void _handleShowDetails(Order order) {
    final status = order.orderStatus.toLowerCase();

    // Jika order sudah selesai atau dibatalkan, tampilkan popup ringkasan
    if (status == 'finished' ||
        status == 'canceled' ||
        status == 'telah sampai ke customer') {
      _showOrderDetailPopup(context, order);
    }
    // Jika order masih aktif, buka halaman live tracking
    else if (order.id.isNotEmpty && int.tryParse(order.id) != null) {
      _navigateToLiveTracking(int.parse(order.id));
    }
    // Fallback jika ID tidak valid
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID tidak valid untuk melihat detail.'),
        ),
      );
    }
  }

  void _navigateToLiveTracking(int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final porterResult = await CartService.searchPorter(orderId);
      Navigator.pop(context); // Tutup loading

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          // <<< PERBAIKAN: Memanggil PorterFoundPage yang sudah di-import
          builder:
              (_) =>
                  PorterFoundPage(orderId: orderId, porterResult: porterResult),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat detail order: $e')));
    }
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;

    switch (status.toLowerCase()) {
      case 'on-delivery':
        iconData = Icons.local_shipping;
        iconColor = Colors.blue.shade700;
        break;
      case 'finished':
      case 'telah sampai ke customer':
        iconData = Icons.check_circle;
        iconColor = Colors.green.shade700;
        break;
      case 'canceled':
        iconData = Icons.cancel;
        iconColor = Colors.red.shade700;
        break;
      case 'pending':
      case 'waiting for acceptance':
      case 'waiting':
      case 'received': // status 'accepted' di backend
        iconData = Icons.hourglass_top;
        iconColor = Colors.orange.shade700;
        break;
      default:
        iconData = Icons.receipt_long;
        iconColor = const Color(0xFFFF7622);
    }

    return Icon(iconData, size: 36, color: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Activity',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sen',
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOrders,
                child: FutureBuilder<List<Order>>(
                  future: _futureOrders,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No order history found.'),
                      );
                    }

                    final orders = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: _buildStatusIcon(order.orderStatus),
                            title: Text(
                              order.date.isNotEmpty ? order.date : '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Porter: ${order.porter ?? "N/A"}'),
                                Text('Order ID: ${order.id}'),
                              ],
                            ),
                            onTap: () => _handleShowDetails(order),
                            trailing: ElevatedButton(
                              onPressed: () => _handleShowDetails(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7622),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Details',
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailPopup(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        "Order Receipt",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text("ID: ${order.id}")),
                    const SizedBox(height: 20),
                    _buildDetailRow(label: "Tanggal", value: order.date),
                    _buildDetailRow(
                      label: "Status",
                      value: order.orderStatus,
                      valueColor: Colors.green.shade700,
                    ),
                    const Divider(height: 30),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...order.items.map(
                              (resto) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resto.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (resto.note != null &&
                                      resto.note!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        '“${resto.note!}”',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  ...resto.items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text('${item.quantity}x'),
                                          const SizedBox(width: 16),
                                          Expanded(child: Text(item.name)),
                                          Text(
                                            currencyFormatter.format(
                                              item.price,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 30),
                    _buildDetailRow(
                      label: "Subtotal",
                      value: currencyFormatter.format(order.totalPrice),
                    ),
                    _buildDetailRow(
                      label: "Ongkos Kirim",
                      value: currencyFormatter.format(order.shippingCost),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      label: "TOTAL",
                      value: currencyFormatter.format(order.grandTotal),
                      isTotal: true,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
