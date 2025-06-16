import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'main_pages.dart';
import 'activity_pages.dart';

// Kelas 'AccountPages' yang lama sudah tidak diperlukan dan dihapus.
// Kita sekarang langsung mengekspor 'ProfilePage' sebagai halaman utama untuk tab ini.

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
    fetchCustomer();
  }

  /// Mengambil data detail customer dari service.
  /// Menangani state loading dan error.
  Future<void> fetchCustomer() async {
    try {
      final customer = await CustomerService.fetchCustomerDetail();
      // Praktik terbaik: Cek apakah widget masih ada di tree sebelum memanggil setState
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
          _isLoading =
              false; // Hentikan loading meskipun gagal agar tidak stuck
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading indicator selama data diambil
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Tampilkan pesan error jika data customer gagal didapat (null)
    if (_customer == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Gagal memuat data profile.\nSilakan coba lagi nanti.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Tampilan utama jika data berhasil didapat
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Halaman
              const Text(
                "My Profile",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Bagian Avatar dan Nama
              Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/avatar.png'),
                    backgroundColor: Colors.black12,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer!.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Customer',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Daftar Detail Profile
              ProfileItem(
                label: "Identity Number",
                value: _customer!.identityNumber,
              ),
              ProfileItem(
                label: "Departemen",
                value: _customer!.department.departmentName,
              ),
              ProfileItem(
                label: "Nomor Rekening",
                value: _customer!.bankUser.accountNumber,
              ),
            ],
          ),
        ),
      ),
      // PENTING: Bagian bottomNavigationBar sudah dipindahkan ke app_shell.dart
      // dan DIHAPUS dari file ini untuk memperbaiki masalah navigasi.
    );
  }
}

/// Widget reusable untuk menampilkan satu baris item profile (label dan value).
class ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const ProfileItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}
