import 'package:flutter/material.dart';
// PENTING: Sesuaikan path di bawah ini dengan struktur folder Anda!
import '../pages/main_pages.dart';
import '../pages/activity_pages.dart';
import '../pages/account_pages.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // State untuk melacak tab mana yang sedang aktif.
  int _selectedIndex = 0;

  // Daftar semua halaman utama Anda.
  static const List<Widget> _widgetOptions = <Widget>[
    MainPage(), // Index 0
    ActivityPages(), // Index 1
    ProfilePage(), // Index 2
  ];

  // Fungsi yang akan dipanggil saat salah satu tab ditekan.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Order'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFFF7622),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,

        // --- PERUBAHAN DI SINI ---
        // Menambah ukuran ikon dan font agar navbar terlihat lebih besar.
        iconSize: 35, // Ukuran ikon diperbesar (default: 24)
        selectedFontSize: 15, // Ukuran font label yang aktif (default: 14)
        unselectedFontSize:
            13, // Ukuran font label yang tidak aktif (default: 12)
        // Menambah sedikit padding di bawah ikon
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        unselectedLabelStyle: const TextStyle(height: 1.5),
      ),
    );
  }
}
