import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petraporter_buyer/pages/main_pages.dart';
import '../services/cart_service.dart';

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
  late Future<String> _porterMessage;

  @override
  void initState() {
    super.initState();
    _porterMessage = CartService.searchPorter(widget.orderId);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Future.wait([
      _porterMessage,
      Future.delayed(const Duration(seconds: 4)),
    ]).then((values) {
      _controller.dispose();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => PorterFoundPage(
                porterMessage: values[0] as String,
                subtotal: widget.subtotal,
                deliveryFee: widget.deliveryFee,
                total: widget.total,
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
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
        ),
      ),
    );
  }
}

class PorterFoundPage extends StatelessWidget {
  final String porterMessage;
  final int subtotal;
  final int deliveryFee;
  final int total;

  const PorterFoundPage({
    Key? key,
    required this.porterMessage,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  }) : super(key: key);

  final List<Map<String, String>> porterList = const [
    {
      'name': 'Jovan M',
      'id': 'C14210299',
      'major': 'INFORMATIKA',
      'account': '2161842189',
      'owner': 'A.N Jovan Marcel',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final porter = porterList[Random().nextInt(porterList.length)];

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPorterInfo(porter),
            const Divider(height: 30),
            _buildPaymentSection(),
            const SizedBox(height: 30),
            _buildDeliverySteps(),
            const SizedBox(height: 30),
            _buildRateButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPorterInfo(Map<String, String> porter) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(_getPorterPhoto(porter['name']!)),
          ),
          const SizedBox(height: 10),
          Text(
            porter['name']!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sen',
            ),
          ),
          Text(
            porter['id']!,
            style: const TextStyle(fontSize: 16, fontFamily: 'Sen'),
          ),
          Text(
            porter['major']!,
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

  Widget _buildPaymentSection() {
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
        _buildPriceRow('Total Price', subtotal),
        _buildPriceRow('Delivery Fee', deliveryFee),
        const Divider(),
        _buildPriceRow('TOTAL', total, bold: true),
      ],
    );
  }

  Widget _buildDeliverySteps() {
    final steps = [
      'Pesanan diterima oleh restoran',
      'Sedang disiapkan',
      'Telah dijemput porter',
      'Segera tiba',
    ];

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
        ...steps.map((step) => _buildProgressStep(step)).toList(),
      ],
    );
  }

  Widget _buildRateButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RatingPage()),
            ),
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

  Widget _buildPriceRow(String label, int amount, {bool bold = false}) {
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
          'Rp ${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Sen',
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_checked,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontFamily: 'Sen'),
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
    if (name.contains('Jovan')) return 'assets/porter1.png';
    return 'assets/default_porter.jpg';
  }
}

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _selectedStars = 5;
  final TextEditingController _controller = TextEditingController();

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
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                    ),
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
                child: const Text(
                  'Back To Home',
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
