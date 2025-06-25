import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan path import di bawah ini dengan struktur folder Anda
import 'package:petraporter_buyer/pages/tenant_pages.dart';
import 'package:petraporter_buyer/login/login.dart';
import 'package:petraporter_buyer/models/cart_model.dart';
import '../services/home_service.dart';
import '../models/tenant_location.dart';

// --- STYLING CONSTANTS ---
const primaryColor = Color(0xFFFF7622);
const backgroundColor = Color(0xFFF8F9FA);
const textColor = Color(0xFF333333);
const cardColor = Colors.white;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // _selectedLocationId sekarang melacak lokasi dari item di keranjang.
  int? _selectedLocationId;
  String _selectedLocationName = '';

  List<TenantLocation> _locations = [];
  bool _isLoading = true;
  String? _errorMessage;
  final CartModel _cart = CartModel();

  @override
  void initState() {
    super.initState();
    // Memuat data lokasi dan juga lokasi terakhir yang tersimpan
    // untuk sinkronisasi dengan state keranjang.
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      final locations = await HomeService.fetchTenantLocations();
      final savedLocationId = await _loadSavedLocationId();

      if (mounted) {
        setState(() {
          _locations = locations;
          if (locations.isNotEmpty) {
            // Set lokasi terpilih dari data yang tersimpan jika valid
            final exists = locations.any((l) => l.id == savedLocationId);
            if (exists) {
              _selectedLocationId = savedLocationId;
              _selectedLocationName =
                  locations
                      .firstWhere((l) => l.id == savedLocationId)
                      .locationName;
            }
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

  // --- FUNGSI PERSISTENCE (SHARED PREFERENCES) ---
  Future<void> _saveSelectedLocationId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_location_id', id);
  }

  Future<int?> _loadSavedLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_location_id');
  }

  // --- FUNGSI LOGOUT ---
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

  // --- LOGIKA UTAMA: PENANGANAN SAAT KARTU KANTIN DI-TAP ---
  void _handleKantinTap(int tappedId, String tappedName) {
    // Skenario 1: Keranjang kosong, atau pengguna memilih kantin yang sama
    // dengan isi keranjang. Langsung masuk.
    if (_cart.totalItems == 0 || tappedId == _selectedLocationId) {
      _navigateToTenant(tappedId, tappedName);
    }
    // Skenario 2: Keranjang berisi item dari lokasi lain. Tampilkan dialog.
    else {
      _showConfirmSwitchLocationDialog(tappedId, tappedName);
    }
  }

  // --- FUNGSI NAVIGASI KE HALAMAN MENU TENANT ---
  void _navigateToTenant(int locationId, String locationName) {
    // Set lokasi saat ini sebagai lokasi terpilih
    setState(() {
      _selectedLocationId = locationId;
      _selectedLocationName = locationName;
    });
    _saveSelectedLocationId(locationId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TenantPages(
              vendorId: locationId,
              vendorName: "Kantin $locationName",
              cart: _cart,
              onCartUpdated: () => setState(() {}),
            ),
      ),
    );
  }

  // --- DIALOG BARU UNTUK KONFIRMASI PINDAH LOKASI ---
  void _showConfirmSwitchLocationDialog(
    int newLocationId,
    String newLocationName,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Ganti Lokasi Kantin?"),
            content: Text(
              "Keranjang Anda berisi item dari Kantin $_selectedLocationName. "
              "Pindah ke Kantin $newLocationName akan mengosongkan keranjang. Lanjutkan?",
            ),
            actions: [
              TextButton(
                child: const Text("Batal"),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text(
                  "Ya, Lanjutkan",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Tutup dialog

                  // Kosongkan keranjang
                  setState(() => _cart.clear());

                  // Tampilkan notifikasi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Keranjang dikosongkan & lokasi diubah.'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  // Lanjutkan navigasi ke kantin baru
                  _navigateToTenant(newLocationId, newLocationName);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _buildHomePage(),
      ),
    );
  }

  // --- UI WIDGETS ---
  Widget _buildHomePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header kini lebih simpel
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Silakan pilih kantin yang dituju',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_outlined,
                  color: textColor,
                  size: 28,
                ),
                tooltip: 'Logout',
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
        // Langsung ke daftar kantin
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Belum ada lokasi kantin tersedia.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return _buildKantinCard(loc.id, loc.locationName);
      },
    );
  }

  // --- KARTU KANTIN DENGAN LOGIKA BARU ---
  Widget _buildKantinCard(int id, String locationName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: () => _handleKantinTap(id, locationName),
        child: SizedBox(
          height: 120, // Ukuran kartu diperbesar
          child: Row(
            children: [
              Image.asset(
                'assets/kantin.png',
                height: 120,
                width: 120, // Gambar juga diperbesar
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 120,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.grey,
                      size: 60,
                    ),
                  );
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kantin',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locationName,
                        style: const TextStyle(
                          fontSize: 20, // Font diperbesar
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Lihat Menu',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
