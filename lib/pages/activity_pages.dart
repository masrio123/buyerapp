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
    return Scaffold(
      backgroundColor: Colors.white,
      // Menggunakan SafeArea agar konten tidak menabrak status bar
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PERBAIKAN: Menyamakan padding dengan halaman My Profile ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Activity',
                style: TextStyle(
                  color: Colors.black,
                  fontSize:
                      28, // Ukuran font diperbesar agar terlihat seperti judul
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sen',
                ),
              ),
            ),
            // --- Sisa Body dibungkus dengan Expanded ---
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
                      // Menghapus padding atas dari sini karena sudah ada di Column utama
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
                            leading: const Icon(
                              Icons.receipt_long,
                              size: 36,
                              color: Color(0xFFFF7622),
                            ),
                            title: Text(
                              order.date.isNotEmpty ? order.date : '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PorterFoundPage(
                                          orderId: int.parse(order.id),
                                          subtotal: 0,
                                          deliveryFee: 0,
                                          total: 0,
                                        ),
                                  ),
                                );
                              } else {
                                String message = 'Order ID tidak valid';
                                if (order.order_status == 'canceled') {
                                  message = 'Order Telah dibatalkan';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
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
            ),
          ],
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
                      Text(
                        "Date: ${order.date.isNotEmpty ? order.date : '-'}\n",
                      ),
                      for (final resto in order.items) ...[
                        Text(
                          resto.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        for (final item in resto.items)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.name} x${item.quantity}'),
                              ),
                              Text('Rp${item.price}'),
                            ],
                          ),
                        if (resto.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Catatan: ${resto.note!}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const Divider(),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        "TOTAL PAYMENT",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Price'),
                          Text('Rp${order.grandTotal}'),
                        ],
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Delivery Fee'), Text('Rp6000')],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp${order.grandTotal + 6000}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7622),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
