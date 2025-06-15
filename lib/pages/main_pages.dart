import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petraporter_buyer/pages/activity_pages.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_p.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_w.dart';
import '/login/login.dart';
import 'account_pages.dart';
import '../services/home_service.dart';
import '../models/tenant_location.dart';

class SlidePageRoute extends PageRouteBuilder {
  final Widget page;

  SlidePageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}

class HorizontalSlideRoute extends PageRouteBuilder {
  final Widget page;

  HorizontalSlideRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuad;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}

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

  Future<void> _saveSelectedLocationId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_location_id', id);
  }

  Future<int?> _loadSavedLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_location_id');
  }

  @override
  void initState() {
    super.initState();
    loadTenantLocations();
  }

  Future<void> loadTenantLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations = await HomeService.fetchTenantLocations();
      final savedLocationId = await _loadSavedLocationId();

      setState(() {
        _locations = locations;
        if (locations.isNotEmpty) {
          // Validasi apakah savedLocationId ada di daftar lokasi
          final exists = locations.any((l) => l.id == savedLocationId);
          _selectedLocationId = exists ? savedLocationId : locations.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil lokasi. Coba lagi nanti.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String get _selectedLocation {
    final loc = _locations.firstWhere(
      (l) => l.id == _selectedLocationId,
      orElse: () => TenantLocation(id: 0, locationName: 'Belum dipilih'),
    );
    return loc.locationName;
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLocationPicker(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) {
        int? tempLocationId = _selectedLocationId;

        return AlertDialog(
          title: const Text('Pilih Lokasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                _locations.map((loc) {
                  return RadioListTile<int>(
                    title: Text(
                      loc.locationName,
                      style: const TextStyle(fontFamily: 'Sen', fontSize: 16),
                    ),
                    value: loc.id,
                    groupValue: tempLocationId,
                    onChanged: (value) {
                      setState(() {
                        _selectedLocationId = value!;
                      });
                      _saveSelectedLocationId(value!); // ⬅️ Tambahkan ini
                      Navigator.of(ctx).pop(value);
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Sen',
        scaffoldBackgroundColor: Colors.white,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: () => _logout(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/cart.png', // pastikan path dan nama file benar
                          width: 45,
                          height: 45,
                        ),
                        const SizedBox(width: 8),
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
                              GestureDetector(
                                onTap: () => _showLocationPicker(context),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedLocation,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text.rich(
                      TextSpan(
                        text: 'Halo, ',
                        style: TextStyle(fontSize: 25),
                        children: [
                          TextSpan(
                            text: 'Selamat Siang!',
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
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage != null
                              ? Center(child: Text(_errorMessage!))
                              : _locations.isEmpty
                              ? const Center(
                                child: Text(
                                  'Belum ada lokasi kantin tersedia.',
                                ),
                              )
                              : GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                                children:
                                    _locations.map((loc) {
                                      return _buildKantinCard(
                                        loc.id,
                                        'KANTIN\n${loc.locationName}',
                                      );
                                    }).toList(),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                HorizontalSlideRoute(page: ActivityPages()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                HorizontalSlideRoute(page: AccountPages()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF7622),
          unselectedItemColor: Colors.grey,
          iconSize: 35,
          selectedFontSize: 15,
          unselectedFontSize: 15,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildKantinCard(int id, String title) {
    final gedung = title.split('\n').last.trim().toUpperCase();

    Widget page;

    page = KantinGedungW(
      vendorId: id,
      vendorName: title,
      cart: CartModel(),
      onCartUpdated: () => setState(() {}),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(context, SlidePageRoute(page: page));
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
