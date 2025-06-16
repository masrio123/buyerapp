import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/place_order_rating.dart';
import '../services/history_service.dart';
import '../models/history.dart';

class ActivityPages extends StatefulWidget {
  const ActivityPages({Key? key}) : super(key: key);

  @override
  State<ActivityPages> createState() => _ActivityPagesState();
}

class _ActivityPagesState extends State<ActivityPages> {
  late Future<List<Order>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _futureOrders = HistoryService.fetchCustomerDetail();
  }

  // Fungsi untuk refresh data
  Future<void> _refreshOrders() async {
    setState(() {
      _futureOrders = HistoryService.fetchCustomerDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN ---
    // MaterialApp dan BottomNavigationBar dihapus. Sekarang langsung return Scaffold.
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<Order>>(
          future: _futureOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No order history found.'));
            }

            final orders = snapshot.data!;

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, size: 36),
                    title: Text(
                      order.date.isNotEmpty ? order.date : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Porter: ${order.porter}'),
                        Text('Order ID: ${order.id}'),
                      ],
                    ),
                    onTap: () {
                      if (order.id != null &&
                          int.tryParse(order.id) != null &&
                          order.order_status != 'canceled') {
                        // --- PERBAIKAN ---
                        // Menggunakan push agar pengguna bisa kembali ke halaman riwayat aktivitas.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PorterFoundPage(
                                  // Sebaiknya data ini juga diambil dari detail order,
                                  // bukan hardcoded 0.
                                  orderId: int.parse(order.id),
                                  subtotal: 0,
                                  deliveryFee: 0,
                                  total: 0,
                                ),
                          ),
                        );
                      } else {
                        // Logika untuk menampilkan SnackBar sudah benar.
                        String message = 'Order ID tidak valid';
                        if (order.order_status == 'canceled') {
                          message = 'Order Telah dibatalkan';
                        }
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                    trailing: ElevatedButton(
                      onPressed: () => _showOrderDetail(context, order),
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
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Order Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
