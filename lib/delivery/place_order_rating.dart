import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import AppShell untuk memastikan kita bisa kembali ke 'rumah' yang benar.
import 'package:petraporter_buyer/app_shell.dart';
// Sesuaikan path import di bawah ini jika diperlukan
import 'package:petraporter_buyer/models/porter.dart';
import 'package:petraporter_buyer/services/cart_service.dart';
import 'package:intl/intl.dart';

// Halaman ini tidak lagi relevan, tapi tetap disertakan agar tidak error
class PlaceOrderRating extends StatefulWidget {
  final int cartId;
  const PlaceOrderRating({super.key, required this.cartId});
  @override
  State<PlaceOrderRating> createState() => _PlaceOrderRatingState();
}

class _PlaceOrderRatingState extends State<PlaceOrderRating> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Place Order")),
      body: const Center(child: Text("This page is deprecated.")),
    );
  }
}

// Halaman 2: Mencari & Menunggu Konfirmasi Porter
class SearchingPorterPage extends StatefulWidget {
  final int orderId;
  const SearchingPorterPage({
    Key? key,
    required this.orderId,
    int? subtotal,
    int? deliveryFee,
    int? total,
  }) : super(key: key);
  @override
  State<SearchingPorterPage> createState() => _SearchingPorterPageState();
}

class _SearchingPorterPageState extends State<SearchingPorterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _pollingTimer;
  String _statusMessage = 'Mencari Porter Terbaik Untukmu...';
  bool _showRetryOptions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _startPolling();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (!mounted) return;
    _pollingTimer?.cancel();
    _checkOrderStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) _checkOrderStatus();
    });
  }

  Future<void> _checkOrderStatus() async {
    if (!mounted) return;
    setState(() => _showRetryOptions = false);

    try {
      final result = await CartService.searchPorter(widget.orderId);
      if (!mounted) return;

      if (result.message.toLowerCase().contains("sistem menunjuk porter")) {
        _pollingTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => PorterFoundPage(
                  orderId: widget.orderId,
                  porterResult: result,
                ),
          ),
        );
      } else {
        setState(() {
          _statusMessage = result.message;
          if (result.message.toLowerCase().contains("menunggu porter") ||
              result.message.toLowerCase().contains("tidak ada porter")) {
            _showRetryOptions = true;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Gagal menemukan porter yang tersedia.";
        _showRetryOptions = true;
      });
      _pollingTimer?.cancel();
    }
  }

  Future<void> _handleCancelOrder() async {
    try {
      await CartService.cancelOrder(widget.orderId);
      if (!mounted) return;

      _pollingTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order berhasil dibatalkan."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membatalkan order: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_showRetryOptions)
              RotationTransition(
                turns: _animationController,
                child: Image.asset('assets/loading.png', width: 60),
              )
            else
              const Icon(Icons.error_outline, size: 60, color: Colors.red),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Sen', fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            if (_showRetryOptions)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _handleCancelOrder,
                    child: const Text(
                      'Batalkan Order',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _animationController.repeat();
                      _startPolling();
                    },
                    child: const Text('Cari Lagi'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// Halaman PorterFoundPage (Desain Ulang Total)
// ===================================================================
class PorterFoundPage extends StatefulWidget {
  final int orderId;
  final PorterResult porterResult;

  const PorterFoundPage({
    Key? key,
    required this.orderId,
    required this.porterResult,
  }) : super(key: key);

  @override
  State<PorterFoundPage> createState() => _PorterFoundPageState();
}

class _PorterFoundPageState extends State<PorterFoundPage> {
  late Future<PorterResult?> _porterFuture;
  Timer? _timer;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _porterFuture = Future.value(widget.porterResult);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _refreshPorterStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshPorterStatus() {
    if (!mounted) return;
    setState(() {
      _porterFuture = CartService.searchPorter(widget.orderId);
    });
  }

  void _showOrderDetailsDialog(BuildContext context, PorterResult porter) {
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
                        "Order Details",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text("ID: #${porter.orderId}")),
                    const Divider(height: 30),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...porter.items.map(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Tracking Order',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AppShell()),
                (route) => false,
              ),
        ),
      ),
      body: FutureBuilder<PorterResult?>(
        future: _porterFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                '❌ Error: ${snapshot.error ?? "Data tidak ditemukan"}',
              ),
            );
          }

          final porter = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildPorterInfo(porter),
              const SizedBox(height: 24),
              _buildViewOrderButton(context, porter),
              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 24),
              _buildPaymentSection(porter),
              const SizedBox(height: 24),
              _buildDeliverySteps(porter),
              const SizedBox(height: 40),
              _buildRateButton(context, porter),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPorterInfo(PorterResult porter) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage(_getPorterPhoto(porter.porterName)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              porter.porterName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sen',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              porter.porterNrp,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Sen',
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              porter.porterDepartment,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Sen',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewOrderButton(BuildContext context, PorterResult porter) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Lihat Detail Pesanan'),
        onPressed: () => _showOrderDetailsDialog(context, porter),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
            fontSize: 2,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        _buildPriceRow(
          'Total Price',
          currencyFormatter.format(_parseAmountToNum(porter.totalPrice)),
        ),
        _buildPriceRow(
          'Delivery Fee',
          currencyFormatter.format(_parseAmountToNum(porter.shippingCost)),
        ),
        const Divider(height: 24),
        _buildPriceRow(
          'TOTAL',
          currencyFormatter.format(_parseAmountToNum(porter.grandTotal)),
          bold: true,
        ),
        const SizedBox(height: 20),
        _buildCopyableInfo(porter.porterNrp, 'A.N ${porter.porterName}'),
      ],
    );
  }

  Widget _buildCopyableInfo(String accountNumber, String accountName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7622).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accountNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(accountName, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nomor rekening disalin!')),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF7622),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('COPY'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySteps(PorterResult porter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATUS PENGIRIMAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(porter.status.length, (index) {
          final step = porter.status[index];
          return _buildProgressStep(
            step: step,
            isFirst: index == 0,
            isLast: index == porter.status.length - 1,
          );
        }),
      ],
    );
  }

  Widget _buildRateButton(BuildContext context, PorterResult porter) {
    final bool isFinished = porter.status.any(
      (s) => s.label.toLowerCase().contains('sampai') && s.key,
    );
    if (!isFinished) return const SizedBox.shrink();

    return Center(
      child: ElevatedButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RatingPage(orderId: porter.orderId),
              ),
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

  Widget _buildPriceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Sen',
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // <<< PERBAIKAN TOTAL: Tata letak & logika diubah
  Widget _buildProgressStep({
    required OrderStatus step,
    required bool isFirst,
    required bool isLast,
  }) {
    const activeColor = Color(0xFFFF7622);
    final inactiveColor = Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 2,
                height: 12,
                color:
                    isFirst
                        ? Colors.transparent
                        : (step.key ? activeColor : inactiveColor),
              ),
              Icon(
                step.key ? Icons.check_circle : Icons.radio_button_unchecked,
                color: step.key ? activeColor : inactiveColor,
                size: 24,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : inactiveColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 24.0),
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
          ),
        ],
      ),
    );
  }

  num _parseAmountToNum(dynamic amount) {
    if (amount is num) return amount;
    if (amount is String) return num.tryParse(amount) ?? 0;
    return 0;
  }

  String _getPorterPhoto(String name) => 'assets/avatar.png';
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
      appBar: AppBar(
        title: const Text(
          'Beri Rating',
          style: TextStyle(fontFamily: 'Sen', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
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
                              ? const Color(0xFFFF7622)
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontFamily: 'Sen', color: Colors.grey),
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
