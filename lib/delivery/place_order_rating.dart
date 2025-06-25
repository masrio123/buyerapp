// KODE LENGKAP DALAM SATU FILE DART (SUDAH DIPERBAIKI)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:petraporter_buyer/app_shell.dart';
import 'package:petraporter_buyer/models/porter.dart';
import '../pages/chat_pages.dart';
import '../services/cart_service.dart';

// --- UI Theming ---
const Color _primaryColor = Color(0xFFFF7622);
const Color _backgroundColor = Color(0xFFF8F9FA);

// ===================================================================
// HALAMAN 1 (SearchingPorterPage)
// ===================================================================
class SearchingPorterPage extends StatefulWidget {
  final int orderId;
  const SearchingPorterPage({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<SearchingPorterPage> createState() => _SearchingPorterPageState();
}

class _SearchingPorterPageState extends State<SearchingPorterPage>
    with TickerProviderStateMixin {
  late AnimationController _sonarAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _sonarAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _pollingTimer;

  String _statusMessage = 'Mencari Porter Terbaik Untukmu...';
  bool _isPollingActive = true;
  bool _isTerminalFailure = false;

  @override
  void initState() {
    super.initState();
    _sonarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _sonarAnimation = CurvedAnimation(
      parent: _sonarAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _startPolling();
  }

  @override
  void dispose() {
    _sonarAnimationController.dispose();
    _fadeAnimationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Mencari porter yang tersedia...';
      _isPollingActive = true;
      _isTerminalFailure = false;
      if (!_sonarAnimationController.isAnimating) {
        _sonarAnimationController.repeat();
      }
    });

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _isPollingActive) {
        _checkOrderStatus();
      }
    });
    _checkOrderStatus();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() => _isPollingActive = false);
      if (_sonarAnimationController.isAnimating) {
        _sonarAnimationController.stop();
      }
    }
  }

  Future<void> _checkOrderStatus() async {
    if (!mounted) return;

    try {
      final result = await CartService.searchPorter(widget.orderId);
      if (!mounted) return;

      if (result.success == false) {
        setState(() {
          _statusMessage = result.message;
        });
        return;
      }

      final message = result.message.toLowerCase();

      // Pengecekan status apakah sudah diterima oleh porter
      final bool hasPorterAccepted = result.status.any((status) {
        final label = status.label.toLowerCase();
        return (label.contains('received') ||
                label.contains('diterima') ||
                label.contains('accepted') ||
                label.contains('dikonfirmasi')) &&
            status.key == true;
      });

      // --- PERBAIKAN UTAMA DI SINI ---
      // Navigasi HANYA jika status sudah diterima, bukan karena pesan dari server.
      if (hasPorterAccepted) {
        _stopPolling();
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => PorterFoundPage(
                  orderId: widget.orderId,
                  porterResult: result,
                ),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
        return; // Hentikan eksekusi setelah navigasi
      }

      // Logika untuk menampilkan pesan kegagalan permanen (mis. semua porter menolak)
      final bool isTotalFailure =
          message.contains("tidak ada porter yang tersedia") ||
          message.contains("semua porter menolak") ||
          message.contains("timeout") ||
          message.contains("gagal menemukan porter");

      if (isTotalFailure) {
        _stopPolling();
        setState(() {
          _statusMessage = result.message; // Gunakan pesan dari server
          _isTerminalFailure = true;
        });
        _showSearchOrCancelDialog();
        return;
      }

      // Logika untuk memperbarui teks status di layar pencarian
      String updatedMessage = result.message;

      // Cek apakah ada status yang menandakan sedang dalam proses menunggu
      final bool hasPorterInProcess = result.status.any((status) {
        final label = status.label.toLowerCase();
        return (label.contains('waiting') ||
                label.contains('menunggu') ||
                label.contains('processing') ||
                label.contains('finding')) &&
            status.key == true;
      });

      // Jika ya, gunakan pesan yang lebih spesifik
      if (hasPorterInProcess) {
        updatedMessage = 'Menunggu konfirmasi dari porter...';
      }
      // Jika tidak ada status proses, dan pesan dari server tidak spesifik,
      // maka kembalikan ke pesan default.
      else if (message.contains('porter ditemukan') ||
          message.contains('order sudah memiliki porter')) {
        updatedMessage = 'Mencari porter yang tersedia...';
      }

      setState(() {
        _statusMessage = updatedMessage;
      });
    } catch (e) {
      _stopPolling();
      setState(() {
        _statusMessage =
            "Gagal terhubung ke server. Periksa koneksi internet Anda.";
        _isTerminalFailure = true;
      });
      _showSearchOrCancelDialog();
    }
  }

  Future<void> _performCancellation() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      _stopPolling();
      await CartService.cancelOrder(widget.orderId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Order berhasil dibatalkan."),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal membatalkan order: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) setState(() => _isTerminalFailure = true);
    }
  }

  Future<void> _handleCancelOrder() async {
    final bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text("Konfirmasi Pembatalan"),
            content: const Text(
              "Apakah Anda yakin ingin membatalkan pesanan ini?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text("Tidak"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text("Ya, Batalkan"),
              ),
            ],
          ),
    );

    if (confirmCancel == true) {
      _performCancellation();
    }
  }

  void _showSearchOrCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Pencarian Gagal"),
          content: Text(_statusMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performCancellation();
              },
              child: const Text(
                "Batalkan Pesanan",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _startPolling();
              },
              child: const Text(
                "Cari Lagi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, _primaryColor.withOpacity(0.1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPollingActive)
                  _buildSearchingAnimation()
                else if (_isTerminalFailure)
                  Icon(
                    Icons.search_off_rounded,
                    size: 100,
                    color: Colors.red.shade300,
                  )
                else
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 100,
                    color: Colors.grey,
                  ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                if (_isPollingActive)
                  ElevatedButton.icon(
                    onPressed: _handleCancelOrder,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Batalkan Pesanan',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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

  Widget _buildSearchingAnimation() {
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _sonarAnimation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withOpacity(0.2),
            ),
          ),
          Container(
            height: 80,
            width: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor,
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// HALAMAN 2 (PorterFoundPage)
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
    symbol: 'Rp ',
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
                        "Detail Pesanan",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text("ID Pesanan: #${porter.orderId}")),
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
                                        'Catatan Tenant: "${resto.note!}"',
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
                                        left: 8.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${item.quantity}x',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(child: Text(item.name)),
                                              Text(
                                                currencyFormatter.format(
                                                  item.price,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.notes != null &&
                                              item.notes!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 35,
                                                top: 4,
                                              ),
                                              child: Text(
                                                'Catatan: "${item.notes!}"',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                ),
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
                    const Divider(height: 24, thickness: 1),
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'Subtotal Pesanan',
                      currencyFormatter.format(
                        _parseAmountToNum(porter.totalPrice),
                      ),
                    ),
                    _buildPriceRow(
                      'Ongkos Kirim',
                      currencyFormatter.format(
                        _parseAmountToNum(porter.shippingCost),
                      ),
                    ),
                    const Divider(height: 24),
                    _buildPriceRow(
                      'GRAND TOTAL',
                      currencyFormatter.format(
                        _parseAmountToNum(porter.grandTotal),
                      ),
                      bold: true,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Tutup',
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Lacak Pesanan Anda',
          style: TextStyle(fontFamily: 'Sen', fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
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
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
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
            padding: const EdgeInsets.all(16),
            children: [
              _buildPorterInfo(porter),
              const SizedBox(height: 16),
              _buildPaymentSection(porter),
              const SizedBox(height: 16),
              _buildDeliverySteps(porter),
              const SizedBox(height: 24),
              _buildRateButton(context, porter),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPorterInfo(PorterResult porter) {
    // --- PERBAIKAN MASALAH 1: LOGIKA TOMBOL CHAT ---
    // Logika diubah menjadi: Tombol chat hilang HANYA JIKA order sudah selesai.
    final bool isOrderFinished = porter.status.any((s) {
      final label = s.label.toLowerCase();
      return (label.contains('finished') ||
              label.contains('selesai') ||
              label.contains('sampai')) &&
          s.key;
    });

    // canChat bernilai true jika order BELUM selesai
    final bool canChat = !isOrderFinished;
    // --- AKHIR PERBAIKAN ---

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage(_getPorterPhoto(porter.porterName)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Porter Anda",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    porter.porterName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    porter.porterDepartment,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Text(
                    porter.porterNrp,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canChat)
                  SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: _primaryColor,
                      ),
                      tooltip: 'Chat Porter',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatPage(
                                  orderId: porter.orderId,
                                  recipientName: porter.porterName,
                                  recipientAvatarUrl: 'assets/avatar.png',
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: _primaryColor),
                    tooltip: 'Detail Pesanan',
                    onPressed: () => _showOrderDetailsDialog(context, porter),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(PorterResult porter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(
              'Subtotal',
              currencyFormatter.format(_parseAmountToNum(porter.totalPrice)),
            ),
            _buildPriceRow(
              'Ongkos Kirim',
              currencyFormatter.format(_parseAmountToNum(porter.shippingCost)),
            ),
            const Divider(height: 24),
            _buildPriceRow(
              'TOTAL',
              currencyFormatter.format(_parseAmountToNum(porter.grandTotal)),
              bold: true,
            ),
            const SizedBox(height: 16),
            _buildCopyableInfo(
              porter.username,
              porter.accountNumbers,
              porter.bankName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableInfo(
    String accountName,
    String accountNumber,
    String bankName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "A.N. $accountName",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text("Bank: $bankName"),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined, color: _primaryColor),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nomor rekening disalin!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySteps(PorterResult porter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Pengiriman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...List.generate(porter.status.length, (index) {
              final step = porter.status[index];
              return _buildProgressStep(
                step: step,
                isFirst: index == 0,
                isLast: index == porter.status.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRateButton(BuildContext context, PorterResult porter) {
    final bool isFinished = porter.status.any(
      (s) => s.label.toLowerCase().contains('sampai') && s.key,
    );
    if (!isFinished) return const SizedBox.shrink();

    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.star_border_rounded, color: Colors.white),
        label: const Text(
          'Beri Penilaian',
          style: TextStyle(color: Colors.white),
        ),
        onPressed:
            () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        RatingPage(orderId: porter.orderId),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
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

  Widget _buildProgressStep({
    required OrderStatus step,
    required bool isFirst,
    required bool isLast,
  }) {
    const activeColor = _primaryColor;
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

// ===================================================================
// HALAMAN 3 (RatingPage)
// ===================================================================
class RatingPage extends StatefulWidget {
  final int orderId;
  const RatingPage({Key? key, required this.orderId}) : super(key: key);
  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _selectedStars = 5;
  bool _isLoading = false;
  final TextEditingController _reviewController = TextEditingController();

  final Map<int, String> _ratingDescriptions = {
    1: 'Sangat Buruk',
    2: 'Buruk',
    3: 'Cukup',
    4: 'Bagus',
    5: 'Luar Biasa!',
  };

  Future<void> _submitRating() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await CartService.ratePorter(
        orderId: widget.orderId,
        rating: _selectedStars,
        review: _reviewController.text.trim(),
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppShell()),
          (route) => false,
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Beri Rating',
          style: TextStyle(
            fontFamily: 'Sen',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 60,
                backgroundColor: _primaryColor,
                child: Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bagaimana Pengirimannya?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sen',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _ratingDescriptions[_selectedStars] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontFamily: 'Sen',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () => setState(() => _selectedStars = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.star,
                        color:
                            index < _selectedStars
                                ? _primaryColor
                                : Colors.grey[300],
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // === Tambahkan Input Review di bawah rating ===
              TextField(
                controller: _reviewController,
                minLines: 2,
                maxLines: 5,
                maxLength: 250,
                decoration: InputDecoration(
                  labelText: 'Tulis review untuk porter (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.rate_review_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Kirim Penilaian',
                            style: TextStyle(
                              fontFamily: 'Sen',
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Lewati',
                  style: TextStyle(fontFamily: 'Sen', color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
