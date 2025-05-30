import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petraporter_buyer/pages/main_pages.dart'; // Untuk clipboard

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
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi', style: TextStyle(fontFamily: 'Sen')),
        content: const Text('Proses orderan sekarang?', style: TextStyle(fontFamily: 'Sen')),
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
                  builder: (_) => const SearchingPorterPage(
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
  final int subtotal;
  final int deliveryFee;
  final int total;

  const SearchingPorterPage({
    Key? key,
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

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    Future.delayed(const Duration(seconds: 4), () {
      _controller.dispose();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PorterFoundPage(
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
              child: Image.asset('assets/loading.png', width: 60), // Ganti icon animasi sesuai selera
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
  final int subtotal;
  final int deliveryFee;
  final int total;

  const PorterFoundPage({
    Key? key,
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
      'owner': 'A.N Jovan Marcel'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final porter = porterList[random.nextInt(porterList.length)];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        title: const Text('Porter Found!', style: TextStyle(fontFamily: 'Sen', fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(_getPorterPhoto(porter['name']!)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    porter['name']!,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Sen'),
                  ),
                  Text(porter['id']!, style: const TextStyle(fontSize: 16, fontFamily: 'Sen')),
                  Text(porter['major']!, style: const TextStyle(fontSize: 16, fontFamily: 'Sen')),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.phone, color: Colors.green)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.chat, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            const Text('TOTAL PAYMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Sen')),
            const SizedBox(height: 10),
            _buildPriceRow('Total Price', subtotal),
            _buildPriceRow('Delivery Fee', deliveryFee),
            const Divider(),
            _buildPriceRow('TOTAL', total, bold: true),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    porter['account']!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Sen'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: porter['account']!));
                  },
                  child: const Text('COPY', style: TextStyle(fontFamily: 'Sen', fontSize: 16)),
                )
              ],
            ),
            Text(porter['owner']!, style: const TextStyle(fontSize: 16, fontFamily: 'Sen')),
            const SizedBox(height: 30),
            const Text('Status Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Sen')),
            const SizedBox(height: 10),
            ...[
              'Pesanan diterima oleh restoran',
              'Sedang disiapkan',
              'Telah dijemput porter',
              'Segera tiba',
            ].map((step) => _buildProgressStep(step)).toList(),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RatingPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rate Order', style: TextStyle(fontSize: 16, fontFamily: 'Sen', color: Colors.white)),
              ),
            ),
          ],
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
          const Icon(Icons.radio_button_checked, color: Colors.orange, size: 20),
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
    return 'assets/default_porter.jpg'; // fallback jika tidak cocok
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
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _selectedStars = index + 1),
                    icon: Icon(
                      Icons.star,
                      color: index < _selectedStars ? Colors.orange : Colors.grey[300],
                      size: 50,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30), // << Kiri kanan kecil
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
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back To Home', style: TextStyle(fontFamily: 'Sen', fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
