import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/place_order_rating.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_p.dart';

class MyCartPage extends StatefulWidget {
  final CartModel cart;
  final VoidCallback onClear;

  const MyCartPage({Key? key, required this.cart, required this.onClear})
      : super(key: key);

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  int subtotal = 0;
  int totalShipping = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  void _calculateTotals() {
    subtotal = 0;
    totalShipping = 0;

    for (var vendor in widget.cart.vendors) {
      final items = widget.cart.itemsOf(vendor);
      subtotal += items.fold<int>(0, (sum, it) => sum + (it['price'] as int));
      totalShipping += _calculateShippingCost(items.length);
    }

    total = subtotal + totalShipping;
  }

  @override
  Widget build(BuildContext context) {
    _calculateTotals();

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.cart.vendors.isEmpty
          ? const Center(
        child: Text(
          'KERANJANG KOSONG',
          style: TextStyle(fontFamily: 'Sen'),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 45, left: 20, right: 20),
            child: Row(
              children: [
                const SizedBox(width: 25),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                const SizedBox(width: 30),
                const Text(
                  'My Cart',
                  style: TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ...widget.cart.vendors.map((vendor) {
                  final items = widget.cart.itemsOf(vendor);

                  return ExpansionTile(
                    title: Text(
                      vendor,
                      style: const TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: List.generate(
                      items.length,
                          (index) => ListTile(
                        title: Text(
                          items[index]['name'],
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 15,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp${(items[index]['price'] as int) ~/ 1000},000',
                              style: const TextStyle(
                                fontFamily: 'Sen',
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                widget.cart.removeItemByVendorAndIndex(
                                    vendor, index);
                                widget.onClear();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', subtotal),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Ongkos Kirim', totalShipping),
                    const SizedBox(height: 12),
                    const Divider(thickness: 1),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Total', total, isBold: true),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchingPorterPage(
                                subtotal: subtotal,
                                deliveryFee: totalShipping,
                                total: total,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7622),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'PLACE ORDER',
                          style: TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Sen',
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 22 : 18,
            color: Colors.black,
          ),
        ),
        Text(
          'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          style: TextStyle(
            fontFamily: 'Sen',
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 20 : 18,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  int _calculateShippingCost(int itemCount) {
    if (itemCount >= 5) {
      return 8000;
    } else if (itemCount >= 2) {
      return 4000;
    } else {
      return 2000;
    }
  }
}
