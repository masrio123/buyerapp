import 'package:flutter/material.dart';
import 'package:petraporter_buyer/pages/activity_pages.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_p.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_q.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_t.dart';
import 'package:petraporter_buyer/kantin/kantin_gedung_w.dart';
import '/login/login.dart';
import 'account_pages.dart';

// Custom Route untuk Kantin (Slide dari bawah)
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

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

// Custom Route untuk Activity/Account (Slide horizontal)
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

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
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
  String _selectedLocation = 'Ruang Dosen Q.325';
  final List<String> _locations = [
    'Ruang Dosen Q.325',
    'Gedung W Lantai 3',
    'Gedung P Lantai 1',
    'Gedung T Lantai 2',
  ];

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _showLocationPicker() async {
    String? tempLocation = _selectedLocation; // Untuk sementara pilihan

    await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'PILIH LOKASI',
            style: TextStyle(
              fontFamily: 'Sen',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _locations.map((loc) {
                return RadioListTile<String>(
                  title: Text(
                    loc,
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 16,
                    ),
                  ),
                  value: loc,
                  groupValue: tempLocation,
                  onChanged: (value) {
                    setState(() {
                      tempLocation = value!;
                    });
                    Navigator.of(ctx).pop(value); // Langsung close dan kirim value
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    ).then((newLocation) {
      if (newLocation != null && newLocation != _selectedLocation) {
        setState(() {
          _selectedLocation = newLocation;
        });
      }
    });
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 50),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LOKASI PENGIRIMAN',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showLocationPicker,
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
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildKantinCard('KANTIN\nGEDUNG W'),
                          _buildKantinCard('KANTIN\nGEDUNG P'),
                          _buildKantinCard('KANTIN\nGEDUNG T'),
                          _buildKantinCard('KANTIN\nGEDUNG Q'),
                        ],
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

  Widget _buildKantinCard(String title) {
    final gedung = title.split('\n').last.split(' ').last;

    return GestureDetector(
      onTap: () {
        switch (gedung) {

          case 'W':
            Navigator.push(
              context,
              SlidePageRoute(
                page: KantinGedungW(
                  cart: CartModel(),                // objek CartModel-mu
                  onCartUpdated: () {
                    setState((){});          // atau callback-mu
                  },
                ),
              ),
            );
            break;

          case 'P':
            Navigator.push(
              context,
              SlidePageRoute(
                page: KantinGedungP(
                  cart: CartModel(),                // objek CartModel-mu
                  onCartUpdated: () {
                    setState((){});          // atau callback-mu
                  },
                ),
              ),
            );
            break;

          case 'T':
            Navigator.push(
              context,
              SlidePageRoute(
                page: KantinGedungT(
                  cart: CartModel(),                // objek CartModel-mu
                  onCartUpdated: () {
                    setState((){});          // atau callback-mu
                  },
                ),
              ),
            );
            break;

          case 'Q':
            Navigator.push(
              context,
              SlidePageRoute(
                page: KantinGedungQ(
                  cart: CartModel(),                // objek CartModel-mu
                  onCartUpdated: () {
                    setState((){});          // atau callback-mu
                  },
                ),
              ),
            );
            break;
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
