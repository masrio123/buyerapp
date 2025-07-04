import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:petraporter_buyer/delivery/place_order_rating.dart';
import 'package:petraporter_buyer/services/cart_service.dart';
import 'package:petraporter_buyer/models/delivery.dart';
import 'package:petraporter_buyer/models/cart_model.dart';

class MyCartPage extends StatefulWidget {
  final CartModel cart;
  final VoidCallback onClear;

  const MyCartPage({super.key, required this.cart, required this.onClear});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  List<DeliveryPoint> _deliveryPoints = [];
  DeliveryPoint? _selectedPoint;
  bool _isLoadingLocations = true;
  bool _isPlacingOrder = false;

  final Map<int, TextEditingController> _notesControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchDeliveryPoints();
    // Inisialisasi controller untuk setiap item yang sudah ada
    for (var vendor in widget.cart.vendors) {
      for (var cartItem in widget.cart.itemsOf(vendor)) {
        final productId = cartItem.product['id'] as int;
        _notesControllers[productId] = TextEditingController(
          text: cartItem.note,
        );
      }
    }
  }

  @override
  void dispose() {
    _notesControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

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

  Future<void> _handleCheckout() async {
    if (_selectedPoint == null) {
      _showErrorDialog('Silakan pilih lokasi pengantaran terlebih dahulu.');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // 1. Buat keranjang baru di server
      final cartResult = await CartService.createCart(_selectedPoint!.id);
      final int cartId = cartResult['cart']['id'];

      // 2. Tambahkan semua item dari local cart ke keranjang di server
      for (var vendor in widget.cart.vendors) {
        for (var cartItem in widget.cart.itemsOf(vendor)) {
          final productId = cartItem.product['id'] as int;
          await CartService.addToCart(
            cartId,
            productId,
            1,
          ); // Asumsi kuantitas selalu 1 per item
        }
      }

      // 3. Kumpulkan semua notes dari text controllers
      final List<Map<String, dynamic>> notesPayload = [];
      for (var cartItem in widget.cart.itemsOf(widget.cart.vendors.first)) {
        // Cukup loop sekali untuk semua item
        final productId = cartItem.product['id'] as int;
        final noteText = _notesControllers[productId]?.text.trim();

        if (noteText != null && noteText.isNotEmpty) {
          notesPayload.add({'product_id': productId, 'note': noteText});
        }
      }

      // 4. Lakukan checkout dengan mengirim ID keranjang dan payload notes
      final checkoutResult = await CartService.checkoutCart(
        cartId,
        notesPayload,
      );
      final orderData = checkoutResult['order'];
      final int newOrderId = orderData['id'];

      widget.onClear();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchingPorterPage(orderId: newOrderId),
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
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
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
                  initiallyExpanded: true,
                  title: Text(
                    vendor,
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    ...List.generate(items.length, (index) {
                      final cartItem = items[index];
                      final itemData = cartItem.product;
                      final productId = itemData['id'] as int;

                      if (_notesControllers[productId] == null) {
                        _notesControllers[productId] = TextEditingController(
                          text: cartItem.note,
                        );
                      }

                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              itemData['name'],
                              style: const TextStyle(fontFamily: 'Sen'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatCurrency(itemData['price']),
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
                                      _notesControllers.remove(productId);
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
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: TextField(
                              controller: _notesControllers[productId],
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Tambahkan catatan...',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFF7622),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
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
                  onChanged:
                      (newValue) => setState(() => _selectedPoint = newValue),
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
      if (totalQuantity <= 2)
        shippingCost = 2000;
      else if (totalQuantity <= 4)
        shippingCost = 5000;
      else if (totalQuantity <= 10)
        shippingCost = 10000;
      else
        shippingCost = 10000 + ((totalQuantity - 10) * 1000).ceil();
    }
    final subtotal = widget.cart.totalPrice;
    final grandTotal = subtotal + shippingCost;
    final bool isCheckoutEnabled = _selectedPoint != null && !_isPlacingOrder;

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
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: isCheckoutEnabled ? _handleCheckout : null,
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
