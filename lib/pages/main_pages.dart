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

  // Variabel _cart didefinisikan di sini, sebagai anggota dari _MainPageState.
  final CartModel _cart = CartModel();

  @override
  void initState() {
    super.initState();
    loadTenantLocations();
  }

  /// Memuat lokasi tenant dari service dan juga memuat lokasi terakhir yang disimpan.
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

  /// Menyimpan ID lokasi yang dipilih ke SharedPreferences.
  Future<void> _saveSelectedLocationId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_location_id', id);
  }

  /// Mengambil ID lokasi yang tersimpan dari SharedPreferences.
  Future<int?> _loadSavedLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_location_id');
  }

  /// Mendapatkan nama lokasi yang sedang dipilih untuk ditampilkan di UI.
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

  /// Proses logout pengguna dan kembali ke halaman Login.
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

  /// Menampilkan dialog untuk memilih lokasi kantin.
  void _showLocationPicker(BuildContext ctx) {
    if (_locations.isEmpty) return;

    showDialog(
      context: ctx,
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
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
                            style: const TextStyle(
                              fontFamily: 'Sen',
                              fontSize: 16,
                            ),
                          ),
                          value: loc.id,
                          groupValue: _selectedLocationId,
                          onChanged: (value) {
                            if (value != null) {
                              dialogSetState(() {
                                _selectedLocationId = value;
                              });
                              _saveSelectedLocationId(value);
                              setState(() {});
                              Navigator.of(ctx).pop();
                            }
                          },
                        );
                      }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Menampilkan dialog peringatan jika pengguna mencoba mengakses lokasi yang salah.
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
                  Image.asset('assets/cart.png', width: 45, height: 45),
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
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showLocationPicker(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
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
              const SizedBox(height: 24),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_locations.isEmpty) {
      return const Center(child: Text('Belum ada lokasi kantin tersedia.'));
    }
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
      children:
          _locations.map((loc) {
            return _buildKantinCard(loc.id, 'KANTIN\n${loc.locationName}');
          }).toList(),
    );
  }

  /// Membangun kartu untuk setiap kantin.
  /// Method ini sekarang berisi logika validasi berdasarkan lokasi yang dipilih.
  Widget _buildKantinCard(int id, String title) {
    return GestureDetector(
      onTap: () {
        // --- LOGIKA VALIDASI BARU DITERAPKAN DI SINI ---
        // 1. Dapatkan nama lokasi dari judul kartu (e.g., "Gedung W").
        final tappedLocationName = title.split('\n').last;

        // 2. Bandingkan dengan lokasi yang sedang dipilih di dropdown.
        if (_selectedLocationName == tappedLocationName) {
          // 3. Jika sama, lanjutkan ke halaman kantin.
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
          // 4. Jika berbeda, tampilkan peringatan bahwa lokasi harus diubah.
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
