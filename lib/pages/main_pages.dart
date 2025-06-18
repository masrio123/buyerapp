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

  void _handleLocationChange(BuildContext dialogContext, int newLocationId) {
    if (newLocationId != _selectedLocationId && _cart.totalItems > 0) {
      _showConfirmClearCartDialog(dialogContext, newLocationId);
    } else {
      _changeLocation(dialogContext, newLocationId);
    }
  }

  void _changeLocation(BuildContext dialogContext, int newLocationId) {
    Navigator.of(dialogContext).pop(); // Tutup dialog picker
    if (_cart.totalItems > 0) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi diubah dan keranjang telah dikosongkan.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _selectedLocationId = newLocationId);
    _saveSelectedLocationId(newLocationId);
  }

  void _showConfirmClearCartDialog(
    BuildContext dialogContext,
    int newLocationId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Pilih Lokasi Anda', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _locations.map((loc) {
                    return RadioListTile<int>(
                      title: Text(
                        loc.locationName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      value: loc.id,
                      groupValue: _selectedLocationId,
                      onChanged: (value) {
                        if (value != null) {
                          _handleLocationChange(dialogContext, value);
                        }
                      },
                      activeColor: primaryColor,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 24),
          const Text.rich(
            TextSpan(
              text: 'Halo, ',
              style: TextStyle(fontSize: 26, color: textColor),
              children: [
                TextSpan(
                  text: 'Selamat Datang!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Silakan Pilih Kantin Yang Dituju',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/cart.png',
          width: 50,
          height: 50,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.shopping_cart, size: 50),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'CART KANTIN',
                style: TextStyle(
                  fontSize: 18, // Ukuran disesuaikan
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
              InkWell(
                onTap: () => _showLocationPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _selectedLocationName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22, // Ukuran lebih besar
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: textColor),
          onPressed: () => _logout(context),
        ),
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

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _locations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return _buildKantinCard(loc.id, loc.locationName);
      },
    );
  }

  Widget _buildKantinCard(int id, String locationName) {
    return GestureDetector(
      onTap: () {
        if (_selectedLocationName == locationName) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => TenantPages(
                    vendorId: id,
                    vendorName: "Kantin $locationName",
                    cart: _cart,
                    onCartUpdated: () => setState(() {}),
                  ),
            ),
          );
        } else {
          _showLocationSelectionRequiredDialog(locationName);
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.asset(
                'assets/kantin.png',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.grey,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kantin',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
