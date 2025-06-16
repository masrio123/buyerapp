import 'dart:async';
import 'package:flutter/material.dart';

// Import AppShell untuk memastikan kita bisa kembali ke 'rumah' yang benar.
import 'package:petraporter_buyer/app_shell.dart';
// Sesuaikan path import di bawah ini jika diperlukan
import 'package:petraporter_buyer/models/porter.dart';
import 'package:petraporter_buyer/models/history.dart';
import 'package:petraporter_buyer/services/cart_service.dart';

// Halaman ini tidak lagi diperlukan karena logikanya sudah pindah ke halaman keranjang (MyCartPage).
// Saya tetap sertakan di sini sesuai permintaan, tetapi idealnya ini dihapus
// dan alurnya dimulai dari MyCartPage.
class PlaceOrderRating extends StatefulWidget {
  final int cartId;

  const PlaceOrderRating({super.key, required this.cartId});

  @override
  State<PlaceOrderRating> createState() => _PlaceOrderRatingState();
}

class _PlaceOrderRatingState extends State<PlaceOrderRating> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Place Order")),
      body: Center(
        child:
            _isPlacingOrder
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA13),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () => _showConfirmDialog(context),
                  child: const Text(
                    'PLACE ORDER',
                    style: TextStyle(fontFamily: 'Sen'),
                  ),
                ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text(
              'Konfirmasi',
              style: TextStyle(fontFamily: 'Sen'),
            ),
            content: const Text(
              'Proses orderan sekarang?',
              style: TextStyle(fontFamily: 'Sen'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(fontFamily: 'Sen')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handlePlaceOrder();
                },
                child: const Text('Ya', style: TextStyle(fontFamily: 'Sen')),
              ),
            ],
          ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final checkoutResponse = await CartService.checkoutCart(widget.cartId);
      if (!mounted) return;

      if (checkoutResponse['order'] == null) {
        throw Exception("Struktur respons checkout tidak valid.");
      }
      final orderData = checkoutResponse['order'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => SearchingPorterPage(
                orderId: orderData['id'],
                subtotal: orderData['subtotal'] ?? 0,
                deliveryFee: orderData['delivery_fee'] ?? 0,
                total: orderData['total'] ?? 0,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal melakukan checkout: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}

// Halaman 2: Animasi saat mencari porter
class SearchingPorterPage extends StatefulWidget {
  final int orderId;
  final int subtotal;
  final int deliveryFee;
  final int total;

  const SearchingPorterPage({
    Key? key,
    required this.orderId,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  }) : super(key: key);

  @override
  State<SearchingPorterPage> createState() => _SearchingPorterPageState();
}

class _SearchingPorterPageState extends State<SearchingPorterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _startSearching();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSearching() async {
    setState(() => _isError = false);
    try {
      await Future.wait([
        CartService.searchPorter(widget.orderId),
        Future.delayed(const Duration(seconds: 4)), // UX Delay
      ]);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => PorterFoundPage(
                orderId: widget.orderId,
                subtotal: widget.subtotal,
                deliveryFee: widget.deliveryFee,
                total: widget.total,
              ),
        ),
      );
    } catch (e) {
      print("gagal mencari porter karena $e");
      if (!mounted) return;
      _controller.stop();
      setState(() => _isError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child:
            !_isError
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _controller,
                      child: Image.asset('assets/loading.png', width: 60),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mencari Porter...',
                      style: TextStyle(fontFamily: 'Sen', fontSize: 18),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal menemukan porter',
                      style: TextStyle(fontFamily: 'Sen', fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _controller.repeat();
                        _startSearching();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
      ),
    );
  }
}

// Halaman 3: Detail order setelah porter ditemukan
class PorterFoundPage extends StatefulWidget {
  final int orderId;
  final int subtotal;
  final int deliveryFee;
  final int total;

  const PorterFoundPage({
    Key? key,
    required this.orderId,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  }) : super(key: key);

  @override
  State<PorterFoundPage> createState() => _PorterFoundPageState();
}

class _PorterFoundPageState extends State<PorterFoundPage> {
  late Future<PorterResult?> _porterFuture;
  bool _porterCancelled = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startFetchingPorter();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !_porterCancelled) {
        _startFetchingPorter();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startFetchingPorter() {
    if (!mounted) return;
    setState(() {
      _porterFuture = CartService.searchPorter(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        title: const Text(
          'Porter Found!',
          style: TextStyle(fontFamily: 'Sen', fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // --- PERBAIKAN ---
            // Saat kembali, kita kembali ke 'rumah' (AppShell).
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AppShell()),
              (route) => false,
            );
          },
        ),
      ),
      body: FutureBuilder<PorterResult?>(
        future: _porterFuture,
        builder: (context, snapshot) {
          if (_porterCancelled) {
            return _buildPorterCancelledWidget();
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data?.porterName == null) {
            _porterCancelled = true;
            return _buildPorterCancelledWidget();
          }

          final porter = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPorterInfo(porter),
                const Divider(height: 30),
                _buildPaymentSection(porter),
                const SizedBox(height: 30),
                _buildDeliverySteps(porter),
                const SizedBox(height: 30),
                _buildRateButton(context, porter),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPorterCancelledWidget() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Order Dibatalkan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Porter membatalkan orderan ini. Apa yang ingin Anda lakukan?",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _porterCancelled = false);
                      _startFetchingPorter();
                    },
                    child: const Text("Cari Porter Baru"),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await CartService.cancelOrder(widget.orderId);
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AppShell()),
                          (route) => false,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Gagal membatalkan order: $e"),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Batalkan Order",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPorterInfo(PorterResult porter) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(_getPorterPhoto(porter.porterName)),
          ),
          const SizedBox(height: 10),
          Text(
            porter.porterName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sen',
            ),
          ),
          Text(
            porter.porterNrp,
            style: const TextStyle(fontSize: 16, fontFamily: 'Sen'),
          ),
          Text(
            porter.porterDepartment,
            style: const TextStyle(fontSize: 16, fontFamily: 'Sen'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.phone, color: Colors.green),
              SizedBox(width: 10),
              Icon(Icons.chat, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(PorterResult porter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOTAL PAYMENT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sen',
          ),
        ),
        const SizedBox(height: 10),
        _buildPriceRow('Total Price', porter.totalPrice),
        _buildPriceRow('Delivery Fee', porter.shippingCost),
        const Divider(),
        _buildPriceRow('TOTAL', porter.grandTotal, bold: true),
      ],
    );
  }

  Widget _buildDeliverySteps(PorterResult porter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Pengiriman',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sen',
          ),
        ),
        const SizedBox(height: 10),
        ...porter.status.map((step) => _buildProgressStep(step)).toList(),
      ],
    );
  }

  Widget _buildRateButton(BuildContext context, PorterResult porter) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RatingPage(orderId: porter.orderId),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A00),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Rate Order',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Sen',
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, dynamic amount, {bool bold = false}) {
    int intAmount;
    if (amount is int) {
      intAmount = amount;
    } else if (amount is String) {
      intAmount = double.tryParse(amount)?.round() ?? 0;
    } else {
      intAmount = 0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Sen',
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'Rp ${_formatCurrency(intAmount)}',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Sen',
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(OrderStatus step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            step.key ? Icons.check_circle : Icons.radio_button_unchecked,
            color: step.key ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Sen',
                color: step.key ? Colors.black : Colors.grey,
                fontWeight: step.key ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) => amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  String _getPorterPhoto(String name) => 'assets/porter1.png';
}

// Halaman 4: Halaman untuk memberi rating
class RatingPage extends StatefulWidget {
  final int orderId;
  const RatingPage({Key? key, required this.orderId}) : super(key: key);
  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _selectedStars = 5;
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRating() async {
    setState(() => _isLoading = true);
    try {
      final result = await CartService.ratePorter(
        orderId: widget.orderId,
        rating: _selectedStars,
        review: _controller.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success']) {
        // --- PERBAIKAN ---
        // Ini adalah akhir dari siklus order. Kembali ke 'rumah' (AppShell).
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset('assets/portericon.png', height: 150),
              const SizedBox(height: 20),
              const Text(
                'Rate Your Delivery',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sen',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setState(() => _selectedStars = index + 1),
                    icon: Icon(
                      Icons.star,
                      color:
                          index < _selectedStars
                              ? Colors.orange
                              : Colors.grey[300],
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write your review...',
                    hintStyle: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text(
                          'Submit & Back To Home',
                          style: TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
