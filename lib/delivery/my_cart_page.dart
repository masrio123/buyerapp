import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Sesuaikan path import di bawah ini jika diperlukan
import 'package:petraporter_buyer/delivery/place_order_rating.dart';
import 'package:petraporter_buyer/services/cart_service.dart';
import 'package:petraporter_buyer/models/delivery.dart';
import 'package:petraporter_buyer/models/cart_model.dart';

class MyCartPage extends StatefulWidget {
  final CartModel cart;
  final VoidCallback
  onClear; // Callback untuk membersihkan keranjang di MainPage

  const MyCartPage({super.key, required this.cart, required this.onClear});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  // State untuk alur baru
  List<DeliveryPoint> _deliveryPoints = [];
  DeliveryPoint? _selectedPoint;
  bool _isLoadingLocations = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryPoints();
  }

  /// 1. Mengambil daftar lokasi pengantaran dari server saat halaman dimuat.
  Future<void> _fetchDeliveryPoints() async {
    try {
      final points = await CartService.getDeliveryPoints();
      if (mounted) {
        setState(() {
          _deliveryPoints = points;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
        _showErrorDialog('Gagal memuat lokasi pengiriman: $e');
      }
    }
  }

  /// 2. Menangani seluruh proses checkout setelah tombol ditekan.
  Future<void> _handleCheckout() async {
    // Validasi: pastikan lokasi sudah dipilih
    if (_selectedPoint == null) {
      _showErrorDialog('Silakan pilih lokasi pengantaran terlebih dahulu.');
      return;
    }

    // --- PERBAIKAN: Validasi tambahan sebelum checkout ---
    if (!_areVendorsInSameBuilding()) {
      _showErrorDialog(
        'Pesanan dari tenant yang berbeda gedung tidak dapat diproses bersamaan.',
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // Langkah A: Buat keranjang baru di server
      final cartResult = await CartService.createCart(_selectedPoint!.id);
      final int cartId = cartResult['cart']['id'];
      print('✅ Keranjang berhasil dibuat: ID = $cartId');

      // Langkah B: Tambahkan semua item ke keranjang yang baru dibuat
      for (var vendor in widget.cart.vendors) {
        for (var item in widget.cart.itemsOf(vendor)) {
          await CartService.addToCart(
            cartId,
            item['id'],
            1,
          ); // Asumsi kuantitas selalu 1
        }
      }
      print('✅ Semua item berhasil ditambahkan ke keranjang server.');

      // Langkah C: Lakukan checkout
      final checkoutResult = await CartService.checkoutCart(cartId);

      if (checkoutResult == null || checkoutResult['order'] == null) {
        throw Exception("Struktur respons checkout dari server tidak valid.");
      }

      final orderData = checkoutResult['order'];
      if (orderData['id'] == null) {
        throw Exception("Respons checkout tidak berisi ID order.");
      }

      print('✅ Checkout berhasil untuk order ID: ${orderData['id']}');

      final int newOrderId = orderData['id'];
      final int newSubtotal = orderData['total_price'];
      final int newDeliveryFee = orderData['shipping_cost'];
      final int newTotal = orderData['grand_total'];

      // Langkah D: Bersihkan keranjang lokal dan navigasi
      widget.onClear();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => SearchingPorterPage(
                  orderId: newOrderId,
                  subtotal: newSubtotal,
                  deliveryFee: newDeliveryFee,
                  total: newTotal,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Proses checkout gagal: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  String _formatCurrency(int amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  // --- FUNGSI BARU UNTUK VALIDASI LOKASI ---
  bool _areVendorsInSameBuilding() {
    final vendors = widget.cart.vendors;
    // Jika hanya ada 0 atau 1 vendor, dianggap valid.
    if (vendors.length <= 1) {
      return true;
    }

    // Ambil nama gedung dari vendor pertama. Asumsi format: "KANTIN\nGedung W"
    final firstBuilding = vendors.first.split('\n').last;

    // Periksa apakah semua vendor lain berada di gedung yang sama.
    for (int i = 1; i < vendors.length; i++) {
      final currentBuilding = vendors[i].split('\n').last;
      if (firstBuilding != currentBuilding) {
        return false; // Ditemukan perbedaan, langsung return false.
      }
    }

    return true; // Semua vendor di gedung yang sama.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontFamily: 'Sen', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body:
          widget.cart.vendors.isEmpty
              ? const Center(
                child: Text(
                  'KERANJANG KOSONG',
                  style: TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(child: _buildCartItems()),
                  _buildDeliverySection(),
                  _buildSummaryAndButton(),
                ],
              ),
    );
  }

  Widget _buildCartItems() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          widget.cart.vendors.map((vendor) {
            final items = widget.cart.itemsOf(vendor);
            return Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    vendor,
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontFamily: 'Sen'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatCurrency(item['price']),
                            style: const TextStyle(
                              fontFamily: 'Sen',
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                widget.cart.removeItemByVendorAndIndex(
                                  vendor,
                                  index,
                                );
                                widget.onClear();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDeliverySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lokasi Pengantaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sen',
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingLocations)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_deliveryPoints.isEmpty)
                const Text('Gagal memuat lokasi pengantaran.')
              else
                DropdownButtonFormField<DeliveryPoint>(
                  value: _selectedPoint,
                  hint: const Text('Pilih tujuan Anda'),
                  isExpanded: true,
                  items:
                      _deliveryPoints.map((point) {
                        return DropdownMenuItem(
                          value: point,
                          child: Text(
                            point.name,
                            style: const TextStyle(fontFamily: 'Sen'),
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPoint = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryAndButton() {
    final totalQuantity = widget.cart.totalItems;
    int shippingCost = 0;
    if (totalQuantity > 0) {
      if (totalQuantity <= 2) {
        shippingCost = 2000;
      } else if (totalQuantity <= 4) {
        shippingCost = 5000;
      } else if (totalQuantity <= 10) {
        shippingCost = 10000;
      } else {
        shippingCost = 10000 + ((totalQuantity - 10) * 1000).ceil();
      }
    }

    final subtotal = widget.cart.totalPrice;
    final grandTotal = subtotal + shippingCost;

    // --- PERBAIKAN: Variabel untuk status validasi ---
    final bool isLocationValid = _areVendorsInSameBuilding();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 10,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Ongkos Kirim', shippingCost),
            const Divider(height: 24),
            _buildSummaryRow('Total', grandTotal, isBold: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7622),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Sen',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // --- PERBAIKAN: Logika onPressed diperbarui ---
                onPressed:
                    (isLocationValid &&
                            _selectedPoint != null &&
                            !_isPlacingOrder)
                        ? _handleCheckout
                        : null,
                child:
                    _isPlacingOrder
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Text('Place Order'),
              ),
            ),
            // --- PERBAIKAN: Menampilkan pesan peringatan ---
            if (!isLocationValid)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Pesanan dari tenant yang berbeda gedung tidak dapat diproses bersamaan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 1,
                    fontFamily: 'Sen',
                  ),
                ),
              ),
          ],
        ),
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
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
