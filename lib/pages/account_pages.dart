import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
// Note: These imports might need to be adjusted based on your project structure.
// import 'main_pages.dart';
// import 'activity_pages.dart';

// --- PERUBAHAN --- Warna primer dan sekunder untuk tema baru
const Color _primaryColor = Color(0xFFFF7622);
const Color _backgroundColor = Color(0xFFFFFFFF); // Background putih bersih
const Color _textColor = Color(0xFF333333);
const Color _subtleTextColor = Colors.grey;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Customer? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  /// Mengambil data detail customer dari service.
  Future<void> _fetchCustomer() async {
    // Simulasi loading
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final customer = await CustomerService.fetchCustomerDetail();
      if (mounted) {
        setState(() {
          _customer = customer;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Gagal mengambil data customer: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal memuat data profile.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCustomer,
        color: _primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_customer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 60),
              const SizedBox(height: 16),
              const Text(
                "Gagal memuat data profile.\nSilakan periksa koneksi Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _subtleTextColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _fetchCustomer,
                icon: const Icon(Icons.refresh),
                label: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildInfoDetails(),
          // --- PERUBAHAN --- Tombol logout dihilangkan dari sini
        ],
      ),
    );
  }

  /// Header profil yang lebih ringkas
  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/avatar.png'),
          backgroundColor: Colors.black12,
        ),
        const SizedBox(height: 16),
        Text(
          _customer!.customerName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _customer!.identityNumber,
          style: const TextStyle(fontSize: 16, color: _subtleTextColor),
        ),
      ],
    );
  }

  /// Widget baru untuk menampilkan detail informasi dalam kartu
  Widget _buildInfoDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            label: "Departemen",
            value: _customer!.department.departmentName,
            icon: Icons.business_center_outlined,
          ),
          const Divider(height: 1),
          _buildInfoRow(
            label: "Nomor Rekening",
            value: _customer!.bankUser.accountNumber,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  /// Widget untuk satu baris informasi
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: _textColor)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _subtleTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- PERUBAHAN --- Widget tombol logout dihapus seluruhnya
}
