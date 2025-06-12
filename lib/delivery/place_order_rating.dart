import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petraporter_buyer/models/history.dart';
import 'package:petraporter_buyer/pages/main_pages.dart';
import '../services/cart_service.dart';
import '../models/porter.dart';
import 'dart:async';

class PlaceOrderRating extends StatelessWidget {
  const PlaceOrderRating({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00AA13),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: () => _showConfirmDialog(context),
          child: const Text('PLACE ORDER', style: TextStyle(fontFamily: 'Sen')),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => const SearchingPorterPage(
                            orderId: 1,
                            subtotal: 45000,
                            deliveryFee: 8000,
                            total: 53000,
                          ),
                    ),
                  );
                },
                child: const Text('Ya', style: TextStyle(fontFamily: 'Sen')),
              ),
            ],
          ),
    );
  }
}

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startSearching();
  }

  void _startSearching() async {
    setState(() {
      _isError = false;
      _isLoading = true;
    });

    try {
      final porterFuture = CartService.searchPorter(widget.orderId);
      final results = await Future.wait([
        porterFuture,
        Future.delayed(const Duration(seconds: 4)),
      ]);

      if (!mounted) return;
      _controller.dispose();

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
      _controller.stop(); // stop animasi
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.dispose();
    } catch (e, stack) {
      debugPrint('Dispose error: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child:
            _isLoading
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
                        _controller.reset();
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
  late Future<PorterResult> _porterFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _porterFuture = _fetchPorter();

    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      setState(() {
        _porterFuture = _fetchPorter();
      });
    });
  }

  Future<PorterResult> _fetchPorter() {
    return CartService.searchPorter(widget.orderId);
  }

  @override
  void dispose() {
    try {
      _timer?.cancel();
    } catch (e, stackTrace) {
      debugPrint('Error saat dispose: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      super.dispose();
    }
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
              (route) => false, // Hapus semua halaman sebelumnya
            );
          },
        ),
      ),
      body: FutureBuilder<PorterResult>(
        future: _porterFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data! == null) {
            return const Center(child: Text('Porter tidak ditemukan.'));
          }

          final porter = snapshot.data!;

          return Padding(
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
    // Konversi dynamic amount ke int
    int intAmount;

    if (amount is int) {
      intAmount = amount;
    } else if (amount is String) {
      // Parsing string ke double dulu, lalu dibulatkan ke int
      double? parsed = double.tryParse(amount);
      intAmount = parsed?.round() ?? 0;
    } else {
      intAmount = 0; // default fallback
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _getPorterPhoto(String name) {
    return 'assets/porter1.png';
  }
}

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
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CartService.ratePorter(
        orderId: widget.orderId,
        rating: _selectedStars,
        review: _controller.text,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 135),
          child: Column(
            children: [
              const SizedBox(height: 20),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 5,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write your review...',
                      hintStyle: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
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
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Submit & Back To Home',
                          style: TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
