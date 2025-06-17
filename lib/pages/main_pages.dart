// ===================================================================
// FILE 1: pages/main_page.dart
// (Ganti seluruh isi file ini dengan kode di bawah)
// ===================================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan path import di bawah ini dengan struktur folder Anda
import 'package:petraporter_buyer/pages/tenant_pages.dart';
import 'package:petraporter_buyer/login/login.dart';
import 'package:petraporter_buyer/models/cart_model.dart';
import '../services/home_service.dart';
import '../models/tenant_location.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int? _selectedLocationId;
  List<TenantLocation> _locations = [];
  bool _isLoading = true;
  String? _errorMessage;
  final CartModel _cart = CartModel();

  @override
  void initState() {
    super.initState();
    loadTenantLocations();
  }

  Future<void> loadTenantLocations() async {
    try {
      final locations = await HomeService.fetchTenantLocations();
      final savedLocationId = await _loadSavedLocationId();

      if (mounted) {
        setState(() {
          _locations = locations;
          if (locations.isNotEmpty) {
            final exists = locations.any((l) => l.id == savedLocationId);
            _selectedLocationId = exists ? savedLocationId : locations.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengambil lokasi. Coba lagi nanti.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSelectedLocationId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_location_id', id);
  }

  Future<int?> _loadSavedLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_location_id');
  }

  String get _selectedLocationName {
    if (_selectedLocationId == null || _locations.isEmpty) {
      return 'Pilih Lokasi';
    }
    final loc = _locations.firstWhere(
      (l) => l.id == _selectedLocationId,
      orElse: () => TenantLocation(id: 0, locationName: 'Pilih Lokasi'),
    );
    return loc.locationName;
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // <<< PERBAIKAN: Fungsi baru untuk menangani perubahan lokasi
  void _handleLocationChange(BuildContext dialogContext, int newLocationId) {
    // Jika lokasi baru berbeda DAN keranjang tidak kosong
    if (newLocationId != _selectedLocationId && _cart.totalItems > 0) {
      _showConfirmClearCartDialog(dialogContext, newLocationId);
    } else {
      // Jika keranjang kosong atau lokasi sama, langsung ubah
      _changeLocation(dialogContext, newLocationId);
    }
  }

  // <<< PERBAIKAN: Fungsi untuk mengubah lokasi dan mengosongkan keranjang
  void _changeLocation(BuildContext dialogContext, int newLocationId) {
    Navigator.of(dialogContext).pop(); // Tutup dialog picker
    if (_cart.totalItems > 0) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi diubah dan keranjang telah dikosongkan.'),
        ),
      );
    }
    setState(() => _selectedLocationId = newLocationId);
    _saveSelectedLocationId(newLocationId);
  }

  // <<< PERBAIKAN: Dialog konfirmasi untuk mengosongkan keranjang
  void _showConfirmClearCartDialog(
    BuildContext dialogContext,
    int newLocationId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Ganti Lokasi?"),
            content: const Text(
              "Keranjang Anda berisi item dari lokasi saat ini. Mengganti lokasi akan mengosongkan keranjang Anda. Lanjutkan?",
            ),
            actions: [
              TextButton(
                child: const Text("Batal"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text(
                  "Lanjutkan",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog konfirmasi
                  _changeLocation(dialogContext, newLocationId);
                },
              ),
            ],
          ),
    );
  }

  void _showLocationPicker(BuildContext ctx) {
    if (_locations.isEmpty) return;

    showDialog(
      context: ctx,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Lokasi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _locations.map((loc) {
                    return RadioListTile<int>(
                      title: Text(
                        loc.locationName,
                        style: const TextStyle(fontFamily: 'Sen', fontSize: 16),
                      ),
                      value: loc.id,
                      groupValue: _selectedLocationId,
                      onChanged: (value) {
                        if (value != null) {
                          _handleLocationChange(dialogContext, value);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showLocationSelectionRequiredDialog(String requiredLocation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Akses Ditolak"),
            content: Text(
              "Untuk mengakses kantin ini, silakan ubah lokasi Anda menjadi '$requiredLocation' terlebih dahulu di bagian atas.",
            ),
            actions: [
              TextButton(
                child: const Text("Mengerti"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/cart.png', width: 45, height: 60),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CART TENANT',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                            height: 2.0,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showLocationPicker(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerLeft,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedLocationName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black),
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text.rich(
                TextSpan(
                  text: 'Halo, ',
                  style: TextStyle(fontSize: 25),
                  children: [
                    TextSpan(
                      text: 'Selamat Datang!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Text(
                'Silahkan Pilih Kantin Yang Dituju',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_locations.isEmpty)
      return const Center(child: Text('Belum ada lokasi kantin tersedia.'));

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.8,
      children:
          _locations.map((loc) {
            return _buildKantinCard(loc.id, 'KANTIN\n${loc.locationName}');
          }).toList(),
    );
  }

  Widget _buildKantinCard(int id, String title) {
    return GestureDetector(
      onTap: () {
        final tappedLocationName = title.split('\n').last;
        if (_selectedLocationName == tappedLocationName) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => TenantPages(
                    vendorId: id,
                    vendorName: title,
                    cart: _cart,
                    onCartUpdated: () => setState(() {}),
                  ),
            ),
          );
        } else {
          _showLocationSelectionRequiredDialog(tappedLocationName);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF7622),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Image(image: AssetImage('assets/kantin.png'), height: 105),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
